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
    sysrst_n    : in  std_ulogic;
    sysclk      : in  std_ulogic;
    pano_button : in  std_ulogic;
    led_red     : out std_ulogic;
    led_green   : out std_ulogic;
    led_blue    : out std_ulogic
  );
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
        tx       : in  std_ulogic -- UART1 rx data
    );
    end component;

    -- This is how we reset the Leon3 CPU
    signal myRST : std_logic := '0';

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

    signal reset_once : integer := 0;
begin
    -- LED indicators for two debug signals: IU on the CPU, DSU active
    LED_RED <= std_logic(iu_error);
    -- LED_GREEN <= std_logic(dsuact);
    LED_GREEN <= std_logic(myRST);
    LED_BLUE <= heartbeat;

    tx <= PANO_BUTTON;

    process (SYSRST_N, SYSCLK, PANO_BUTTON)
    begin
        if (SYSRST_N = '0') then
            counter <= 0;
        elsif rising_edge(SYSCLK) then
            -- To verify that the clock outside the LEON actually works
            -- at the frequency I expect (25MHz) I hooked a heartbeat LED
            myRST <= '0';
            counter <= counter + 1;
            if counter = 25000000 then
                counter <= 0;
                heartbeat <= not heartbeat;
            end if;
            if (reset_once = 0) then
                if (counter >= 12500000 and counter < 24999999) then
                    myRST <= '1';
                    reset_once <= 0;
                elsif (counter = 24999999) then
                    reset_once <= 1;
                end if;
            end if;
        end if;
    end process;

    LeonTheProfessional : leon3mp
        port map (
            resetn => myRST,
            clk => sysclk,
            iu_error => iu_error,
            dsuact => dsuact,
            rx => rx,
            tx => tx
        );

end arch;
