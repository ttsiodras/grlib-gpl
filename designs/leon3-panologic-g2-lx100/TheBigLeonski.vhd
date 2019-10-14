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
end TheBigLeonski;

architecture arch of TheBigLeonski is

    -- Instantiate our Leon3 here.
    component leon3mp
      port (
        resetn   : in  std_ulogic;
        clk      : in  std_ulogic; 	-- 25 MHz main clock
        iu_error : out std_ulogic;

        dsuact   : out std_ulogic; -- debug signal connectd to a LED

        rx       : out std_ulogic; -- UART1 tx data
        tx       : in  std_ulogic; -- UART1 rx data
    );
    end component;


    signal CLK : std_logic;
    signal RST : std_logic;
    signal LED_RED : std_logic;
    signal LED_GREEN : std_logic;
    signal LED_BLUE : std_logic;

    -- This is how we reset the Leon3 CPU over the USB bus
    signal myRST : std_logic := '1';

    -- The real UART signals - not used though, since... "grmon -u"
    signal rx : std_ulogic;
    signal tx : std_ulogic;

    -- indicator LED to know if DSU is active
    signal dsuact : std_ulogic;
    -- indicator LED to see if we are dead :-)
    signal iu_error : std_ulogic;

    -- Heartbeat LED connected to main clock - verifying 25MHz
    signal heartbeat : std_logic := '1';
    signal counter : integer  := 0;
begin
    -- LED indicators for two debug signals: IU on the CPU, DSU active
    LED_RED <= std_logic(iu_error);
    LED_GREEN <= std_logic(dsuact);
    LED_BLUE <= heartbeat;

    process (RST, CLK, iu_error, dsuact)
    begin
        if (RST /= '1' and CLK'event and CLK='1') then
            -- To verify that the clock outside the LEON actually works
            -- at the frequency I expect (25MHz) I hooked a heartbeat LED
            counter <= counter + 1;
            if counter = 25000000 then
                counter <= 0;
                heartbeat <= not heartbeat;
            end if;

            -- Programmatically reset the board. This proved to be absolutely 
            -- essential, since the LEON3/DSU clock is NOT WORKING until
            -- I send a reset through this. To be clear - I verified this
            -- via the heartbeat_led_dsu I connected inside leon3mp.vhd.
            -- if (WE='1') then
            --     case Addr is
            --         when X"2000" => myRST <= '1';
            --         when X"2001" => myRST <= '0';
            --         when others => myRST <= '0';
            --     end case;
            -- else
            --     myRST <= myRST;
            -- end if;
        end if;
    end process;

    LeonTheProfessional : leon3mp
        port map (
            resetn => myRST,
            clk => CLK,
            iu_error => iu_error,
            dsuact => dsuact,
            rx => rx,
            tx => tx,
            IO => IO
        );

end arch;
