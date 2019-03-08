------------------------------------------------------------------
-- This is the top-level of my Leon3 implementation in my ZestSC1
------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

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

    -- Instantiate our Leon3 here.
    component leon3mp
      port (
        resetn   : in  std_ulogic;
        clk      : in  std_ulogic; 	-- 48 MHz main clock
        iu_error : out std_ulogic;

        dsuact   : out std_ulogic; -- debug signal connectd to a LED

        dsu_rx   : out std_ulogic; -- UART1 tx data
        dsu_tx   : in  std_ulogic; -- UART1 rx data
        IO       : inout std_logic_vector(46 downto 0)  -- to allow access to
                                                        -- one of the LEDs;
                                                        -- and monitor the DSU
                                                        -- clock heartbeat
    );
    end component;


    -- We instantiate the ZestSC1 interfaces - we need the USB
    -- functionality for custom reset whenever we want (and probably
    -- for a lot more things in the future)

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

            -- This is used to send just one thing for now:
            --
            -- A custom reset signal whenever we want
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

    -- This is how we reset the Leon3 CPU over the USB bus
    signal myRST : std_logic := '1';
    -- I needed a BUFD version to drive both the reset and a LED
    signal myRST_OBUFD : std_logic := '1';

    -- The UART bridge to Leon - GRMON speaks over it
    -- via a USB-TTL (connected signals: TX, RX, GND)
    signal dsu_rx : std_ulogic;
    signal dsu_tx : std_ulogic;

    -- indicator LED to know if DSU is active
    signal dsuact : std_ulogic;
    -- indicator LED to see if we are dead :-)
    signal iu_error : std_ulogic;

    -- OBUF used to forward the USB-TTL TX sent from the PC
    -- to both a LED and the DSU UART.
    signal serial_info_sent_from_PC : std_logic;
    signal serial_info_sent_from_PC_OBUFD : std_logic;

    -- Heartbeat LED connected to main clock - verifying 48MHz
    signal heartbeat : std_logic := '1';
    signal counter : integer  := 0;
begin
    -- Tie unused signals.
    User_Signals <= "ZZZZZZZZ";
    LEDs(7 downto 4) <= "1111";
    IO_CLK_N <= 'Z';
    IO_CLK_P <= 'Z';
    Interrupt <= '0';
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

    -- This costed me the last two days of debugging - I don't understand
    -- why, but the connection to the LED somehow messed up the reception
    -- of the UART signal by the PC. I need a logic analyser/scope to see
    -- what exactly happened to the signal; but all I know is that the
    -- moment I commented this out, GRMON3 saw my board.
    --
    -- LEDs(0) <= std_logic(dsu_rx);

    -- LED indicators for two debug signals: IU on the CPU, DSU active
    LEDs(1) <= std_logic(iu_error);
    LEDs(2) <= std_logic(dsuact);

    -- The bridge to the outside world:
    --
    -- 1. The USB-TTL signal sent from the PC arrives at the GPIO pin 12
    --    which is IO(3). We put it in this signal:
    serial_info_sent_from_PC <= IO(3);

    -- 2. At the same time, the DSU TX signal sent from the Leon3
    --    must reach the USB-TTL via GPIO pin 11 - that is, IO(2):
    IO(2) <= dsu_rx;

    -- 3. And since I wanted to see the TX signal sent from the PC
    --    on a LED as well, I needed to OBUFD it (ISE reported that 
    --    I could not have the same signal driving both a LED and
    --    the LEON3's "receiving"...
    dsu_tx <= std_ulogic(serial_info_sent_from_PC_OBUFD);

    -- The LED connections - notice the use of the OBUFD signals
    IO(0) <= LEDs(0);
    IO(1) <= LEDs(1);
    IO(41) <= LEDs(2);
    IO(42) <= serial_info_sent_from_PC_OBUFD;
    IO(43) <= myRST_OBUFD;
    IO(44) <= LEDs(5);
    -- IO(45) <= LEDs(6);
    -- IO(46) <= LEDs(7);
    IO(46) <= heartbeat;

    process (RST, CLK, dsu_rx, iu_error, dsuact, Addr, WE)
    begin
        if (RST /= '1' and CLK'event and CLK='1') then
            -- To verify that the clock outside the LEON actually works
            -- at the frequency I expect (48MHz) I hooked a heartbeat LED7
            -- (i.e. the 1st from the right) and confirmed the speed.
            counter <= counter + 1;
            if counter = 48000000 then
                counter <= 0;
                heartbeat <= not heartbeat;
            end if;

            -- Programmatically reset the board. This proved to be absolutely 
            -- essential, since the LEON3/DSU clock is NOT WORKING until
            -- I send a reset through this. To be clear - I verified this
            -- via the heartbeat_led_dsu I connected inside leon3mp.vhd.
            if (WE='1') then
                case Addr is
                    when X"2000" => myRST <= '1';
                    when X"2001" => myRST <= '0';
                    when others => myRST <= '0';
                end case;
            else
                myRST <= myRST;
            end if;
        end if;
    end process;

    process (RST, CLK)
    begin
        if (RST='1') then
            SRAMDataOut <= (others => '0');
            USB_DataOutWE <= '0';
            USB_DataOut <= (others => '0');
            USB_DataInBusy <= '0';

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
    dsu_rx_obuf: OBUF
         port map (
          I => serial_info_sent_from_PC,
          O => serial_info_sent_from_PC_OBUFD);

    myRST_obuf : OBUF
         port map (
          I => myRST,
          O => myRST_OBUFD);

    LeonTheProfessional : leon3mp
        port map (
            resetn => myRST,
            clk => CLK,
            iu_error => iu_error,
            dsuact => dsuact,
            dsu_rx => dsu_rx,
            dsu_tx => dsu_tx,
            IO => IO
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
            User_RegAddr => Addr,
            User_RegDataIn => DataIn,
            User_RegDataOut => DataOut,
            User_RegWE => WE,
            User_RegRE => RE,

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
