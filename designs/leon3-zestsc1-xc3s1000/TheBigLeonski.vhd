------------------------------------------------------------------
-- This is the top-level of my simple "direct-to-VHDL" translation
-- of a Mandelbrot fractal computing engine.
------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- The top-level needs to hook up with ZestSC1 connections:
entity TheBigLeonski is
    port (
        USB_StreamCLK : in std_logic;
        USB_StreamFIFOADDR : out std_logic_vector(1 downto 0);
        USB_StreamPKTEND_n : out std_logic;
        USB_StreamFlags_n : in std_logic_vector(2 downto 0);
        USB_StreamSLOE_n : out std_logic;
        USB_StreamSLRD_n : out std_logic;
        USB_StreamSLWR_n : out std_logic;
        USB_StreamFX2Rdy : in std_logic;
        USB_StreamData : inout std_logic_vector(15 downto 0);

        USB_RegCLK : in std_logic;
        USB_RegAddr : in std_logic_vector(15 downto 0);
        USB_RegData : inout std_logic_vector(7 downto 0);
        USB_RegOE_n : in std_logic;
        USB_RegRD_n : in std_logic;
        USB_RegWR_n : in std_logic;
        USB_RegCS_n : in std_logic;

        USB_Interrupt : out std_logic;

        User_Signals : inout std_logic_vector(7 downto 0);

        S_CLK : out std_logic;
        S_A : out std_logic_vector(22 downto 0);
        S_DA : inout std_logic_vector(8 downto 0);
        S_DB : inout std_logic_vector(8 downto 0);
        S_ADV_LD_N : out std_logic;
        S_BWA_N : out std_logic;
        S_BWB_N : out std_logic;
        S_OE_N : out std_logic;
        S_WE_N : out std_logic;

        IO_CLK_N : inout std_logic;
        IO_CLK_P : inout std_logic;
        IO : inout std_logic_vector(46 downto 0)
    );
end TheBigLeonski;

architecture arch of TheBigLeonski is

    -- We instantiate our Leon3
    component leon3mp
      port (
        reset : in  std_ulogic;
        clk : in  std_ulogic; 	-- 48 MHz main clock
        iu_error : out std_ulogic;

        dsubre : in std_ulogic;
        dsuact : out std_ulogic;

        rsrx : out std_ulogic; -- UART1 tx data
        rstx : in  std_ulogic  -- UART1 rx data
    );
    end component;

    -- We instantiate the ZestSC1 stuff.
    component ZestSC1_Interfaces
        port (
            -----------------------------------------------
            -- The deep dark magic of the ZestSC1 design.
            --     Don't mess with any of these.
            -----------------------------------------------
            USB_StreamCLK : in std_logic;
            USB_StreamFIFOADDR : out std_logic_vector(1 downto 0);
            USB_StreamPKTEND_n : out std_logic;
            USB_StreamFlags_n : in std_logic_vector(2 downto 0);
            USB_StreamSLOE_n : out std_logic;
            USB_StreamSLRD_n : out std_logic;
            USB_StreamSLWR_n : out std_logic;
            USB_StreamFX2Rdy : in std_logic;
            USB_StreamData : inout std_logic_vector(15 downto 0);

            USB_RegCLK : in std_logic;
            USB_RegAddr : in std_logic_vector(15 downto 0);
            USB_RegData : inout std_logic_vector(7 downto 0);
            USB_RegOE_n : in std_logic;
            USB_RegRD_n : in std_logic;
            USB_RegWR_n : in std_logic;
            USB_RegCS_n : in std_logic;

            USB_Interrupt : out std_logic;

            S_CLK: out std_logic;
            S_A: out std_logic_vector(22 downto 0);
            S_ADV_LD_N: out std_logic;
            S_BWA_N: out std_logic;
            S_BWB_N: out std_logic;
            S_DA: inout std_logic_vector(8 downto 0);
            S_DB: inout std_logic_vector(8 downto 0);
            S_OE_N: out std_logic;
            S_WE_N: out std_logic;

            -------------------------------------------------------
            -- The foundations of life, the universe and everything
            -------------------------------------------------------
            User_CLK : out std_logic;
            User_RST : out std_logic;

            ----------------------
            -- Streaming interface
            ----------------------

            -- size of USB transactions
            -- (bigger ==> faster speed, worse latency)
            User_StreamBusGrantLength : in std_logic_vector(11 downto 0);

            -- from the PC to the board
            User_StreamDataIn : out std_logic_vector(15 downto 0);
            User_StreamDataInWE : out std_logic;
            User_StreamDataInBusy : in std_logic;

            -- from the board to the PC.
            -- (actually used - to send the framebuffer data back)
            User_StreamDataOut : in std_logic_vector(15 downto 0);
            User_StreamDataOutWE : in std_logic;
            User_StreamDataOutBusy : out std_logic;

            ---------------------
            -- Register interface
            ---------------------

            -- This is used to send:
            --
            --  the topx, topy (in complex plane, so fixed point coordinates)
            --  the stepx, stepy (to move for each pixel - also fixed point)
            User_RegAddr : out std_logic_vector(15 downto 0);
            User_RegDataIn : out std_logic_vector(7 downto 0);
            User_RegDataOut : in std_logic_vector(7 downto 0);
            User_RegWE : out std_logic;
            User_RegRE : out std_logic;

            -------------------------
            -- Signals and interrupts
            -------------------------

            -- This is unused. The Linux implementation of ZestSC1's library
            -- doesn't deliver the interrupt.
            User_Interrupt : in std_logic;

            -----------------
            -- SRAM interface
            -----------------

            -- This is used to store the computed colors,
            User_SRAM_A: in std_logic_vector(22 downto 0);
            User_SRAM_W: in std_logic;
            User_SRAM_R: in std_logic;
            User_SRAM_DR_VALID: out std_logic;
            User_SRAM_DW: in std_logic_vector(17 downto 0);
            User_SRAM_DR: out std_logic_vector(17 downto 0)
        );
    end component;

    signal CLK : std_logic;
    signal RST : std_logic;
    signal LEDs : std_logic_vector(7 downto 0);

    -- Register interface
    signal Addr : std_logic_vector(15 downto 0);
    signal DataIn : std_logic_vector(7 downto 0);
    signal DataOut : std_logic_vector(7 downto 0);
    signal WE : std_logic;
    signal RE : std_logic;

    -- signals connected to the FPGA's USB inputs (coming from PC)
    signal USB_DataIn : std_logic_vector(15 downto 0);
    signal USB_DataInBusy : std_logic;
    signal USB_DataInWE : std_logic;

    -- signals connected to the FPGA's USB outputs (going to PC)
    signal USB_DataOut : std_logic_vector(15 downto 0);
    signal USB_DataOutBusy : std_logic;
    signal USB_DataOutWE : std_logic := '0';

    -- SRAM interface
    signal SRAMAddr : std_logic_vector(22 downto 0);
    signal SRAMDataOut : std_logic_vector(17 downto 0);
    signal SRAMDataIn : std_logic_vector(17 downto 0);
    signal SRAMWE : std_logic;
    signal SRAMRE : std_logic;
    signal SRAMValid : std_logic;

    -- Interrupt signal
    signal Interrupt : std_logic;

    -- The bridge to Leon - hopefully, GRMON will speak over it
    signal rsrx   : std_ulogic; -- UART1 tx data
    signal rstx   : std_ulogic; -- UART1 rx data
    signal dsubre : std_ulogic;
    signal dsuact : std_ulogic;
    signal iu_error : std_ulogic;

    -- The SRAM bridge to Leon - the 'inout' must be state-machined
    -- into the SRAMDataOut and out of SRAMDataIn
    signal data : std_logic_vector(15 downto 0);
begin

    -- Tie unused signals.
    User_Signals <= "ZZZZZZZZ";
    LEDs(7 downto 3) <= "11111";
    IO_CLK_N <= 'Z';
    IO_CLK_P <= 'Z';
    Interrupt <= '0';

    LEDs(0) <= std_logic(rsrx);
    LEDs(1) <= std_logic(iu_error);
    LEDs(2) <= std_logic(dsuact);

    IO(0) <= LEDs(0);
    IO(1) <= LEDs(1);
    IO(2) <= rsrx;
    rstx <= std_ulogic(IO(3));
    IO(4) <= 'Z';
    IO(5) <= 'Z';
    IO(6) <= 'Z';
    IO(7) <= 'Z';
    IO(8) <= 'Z';
    IO(9) <= 'Z';
    IO(10) <= 'Z';
    IO(11) <= 'Z';
    IO(12) <= 'Z';
    IO(13) <= 'Z';
    IO(14) <= 'Z';
    IO(15) <= 'Z';
    IO(16) <= 'Z';
    IO(17) <= 'Z';
    IO(18) <= 'Z';
    IO(19) <= 'Z';
    IO(20) <= 'Z';
    IO(21) <= 'Z';
    IO(22) <= 'Z';
    IO(23) <= 'Z';
    IO(24) <= 'Z';
    IO(25) <= 'Z';
    IO(26) <= 'Z';
    IO(27) <= 'Z';
    IO(28) <= 'Z';
    IO(29) <= 'Z';
    IO(30) <= 'Z';
    IO(31) <= 'Z';
    IO(32) <= 'Z';
    IO(33) <= 'Z';
    IO(34) <= 'Z';
    IO(35) <= 'Z';
    IO(36) <= 'Z';
    IO(37) <= 'Z';
    IO(38) <= 'Z';
    IO(39) <= 'Z';
    IO(40) <= 'Z';
    IO(41) <= LEDs(2);
    IO(42) <= LEDs(3);
    IO(43) <= LEDs(4);
    IO(44) <= LEDs(5);
    IO(45) <= LEDs(6);
    IO(46) <= LEDs(7);

    process (RST, CLK)
    begin
        if (RST='1') then
            SRAMDataOut <= (others => '0');
            USB_DataOutWE <= '0';
            USB_DataOut <= (others => '0');
            USB_DataInBusy <= '0';

            dsubre <= '0'; 

        elsif rising_edge(CLK) then

            -- I am handling all "pulses" in a common way - the main clock
            -- just always sets them low, but if further below they
            -- are set high, due to the way processes work in VHDL,
            -- they will be set high for just once in the next cycle.
            --
            -- This allows me to not need to introduce states to "set high",
            -- "wait one cycle", "set low", etc.

            USB_DataInBusy <= '0';
            USB_DataOutWE <= '0';

            -- -- Is the PC calling ZestSC1WriteRegister?
            -- if WE = '1' then

            --     -- It is! What address is it writing in?
            --     case Addr is
            --         when X"2060" => input_x(7 downto 0) <= DataIn;
            --         when others =>
            --     end case;

            -- end if; -- WE='1'
        end if; -- if rising_edge(CLK) ...
    end process;

    -- Instantiate components

    LeonTheProfessional : leon3mp
        port map (
            reset => RST,
            clk => CLK,
            iu_error => iu_error,
            dsuact => dsuact,
            dsubre => dsubre,
            rsrx => rsrx,
            rstx => rstx
        );

    Interfaces : ZestSC1_Interfaces
        port map (
            -- The deep dark magic of the ZestSC1 design.
            -- Don't mess with any of these.

            USB_StreamCLK => USB_StreamCLK,
            USB_StreamFIFOADDR => USB_StreamFIFOADDR,
            USB_StreamPKTEND_n => USB_StreamPKTEND_n,
            USB_StreamFlags_n => USB_StreamFlags_n,
            USB_StreamSLOE_n => USB_StreamSLOE_n,
            USB_StreamSLRD_n => USB_StreamSLRD_n,
            USB_StreamSLWR_n => USB_StreamSLWR_n,
            USB_StreamData => USB_StreamData,
            USB_StreamFX2Rdy => USB_StreamFX2Rdy,

            USB_RegCLK => USB_RegCLK,
            USB_RegAddr => USB_RegAddr,
            USB_RegData => USB_RegData,
            USB_RegOE_n => USB_RegOE_n,
            USB_RegRD_n => USB_RegRD_n,
            USB_RegWR_n => USB_RegWR_n,
            USB_RegCS_n => USB_RegCS_n,

            USB_Interrupt => USB_Interrupt,

            S_CLK => S_CLK,
            S_A => S_A,
            S_ADV_LD_N => S_ADV_LD_N,
            S_BWA_N => S_BWA_N,
            S_BWB_N => S_BWB_N,
            S_DA => S_DA,
            S_DB => S_DB,
            S_OE_N => S_OE_N,
            S_WE_N => S_WE_N,

            User_CLK => CLK,
            User_RST => RST,

            User_StreamBusGrantLength => X"000",

            User_StreamDataIn => open,
            User_StreamDataInWE => open,
            User_StreamDataInBusy => '1',

            User_StreamDataOut => X"0000",
            User_StreamDataOutWE => '0',
            User_StreamDataOutBusy => open,

            -- Register interface
            User_RegAddr => open,
            User_RegDataIn => open,
            User_RegDataOut => X"00",
            User_RegWE => open,
            User_RegRE => open,

            -- Signals and interrupts
            User_Interrupt => '0',

            -- SRAM interface
            User_SRAM_A => "00000000000000000000000",
            User_SRAM_W => '0',
            User_SRAM_R => '0',
            User_SRAM_DR_VALID => open,
            User_SRAM_DW => "000000000000000000",
            User_SRAM_DR => open
        );

end arch;
