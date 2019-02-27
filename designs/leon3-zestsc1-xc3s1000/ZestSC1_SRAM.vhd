-- ZestSC1 ZBT SRAM Logic Core
-- File name: ZestSC1_SRAM.vhd
-- Version: 1.00
-- Date: 6/12/2004

-- Copyright (C) 2005 Orange Tree Technologies Ltd. All rights reserved.
-- Orange Tree Technologies grants the purchaser of a ZestSC1 the right to use and
-- modify this logic core in any form including but not limited to VHDL source code or
-- EDIF netlist in FPGA designs that target the ZestSC1.
-- Orange Tree Technologies prohibits the use of this logic core or any modification of
-- it in any form including but not limited to VHDL source code or EDIF netlist in
-- FPGA or ASIC designs that target any other hardware unless the purchaser of the
-- ZestSC1 has purchased the appropriate licence from Orange Tree Technologies.
-- Contact Orange Tree Technologies if you want to purchase such a licence.

--*****************************************************************************************
--**
--**  Disclaimer: LIMITED WARRANTY AND DISCLAIMER. These designs are
--**              provided to you "as is". Orange Tree Technologies and its licensors 
--**              make and you receive no warranties or conditions, express, implied, 
--**              statutory or otherwise, and Orange Tree Technologies specifically 
--**              disclaims any implied warranties of merchantability, non-infringement,
--**              or fitness for a particular purpose. Orange Tree Technologies does not
--**              warrant that the functions contained in these designs will meet your 
--**              requirements, or that the operation of these designs will be 
--**              uninterrupted or error free, or that defects in the Designs will be 
--**              corrected. Furthermore, Orange Tree Technologies does not warrant or 
--**              make any representations regarding use or the results of the use of the 
--**              designs in terms of correctness, accuracy, reliability, or otherwise.                                               
--**
--**              LIMITATION OF LIABILITY. In no event will Orange Tree Technologies 
--**              or its licensors be liable for any loss of data, lost profits, cost or 
--**              procurement of substitute goods or services, or for any special, 
--**              incidental, consequential, or indirect damages arising from the use or 
--**              operation of the designs or accompanying documentation, however caused 
--**              and on any theory of liability. This limitation will apply even if 
--**              Orange Tree Technologies has been advised of the possibility of such 
--**              damage. This limitation shall apply notwithstanding the failure of the 
--**              essential purpose of any limited remedies herein.
--**
--*****************************************************************************************

-- The Pipelined ZBT SRAM device takes 2 clock cycles for a write and 2 clock
-- cycles for a read. This logic core has one extra pipeline stage in the write
-- path (giving 3 clock cycles) and two extra pipeline stages in the read path
-- (giving 4 clock cycles).
--
-- The user logic drives the write strobe high and the write address and
-- data in the same clock cycle. The logic core registers all command and data
-- signals and delays the data by 2 further clocks as required by the ZBT SRAM.
-- Byte write strobes are not implemented.
--
-- Read cycles are User Read command followed 4 clocks later by read data.
-- The user logic drives the read strobe high and the read address in the
-- same clock cycle, and the logic core registers all these signals. Valid data is
-- returned to the user code 4 clocks after the user code drives the read strobe
-- high. The valid data is accompanied by the active high data valid strobe. When
-- the data valid strobe is high then the read data should be registered by the
-- user code.
--
-- All accesses are single accesses, burst accesses are not implemented.
-- 
-- The SRAM clock is driven from the FPGA to the SRAM. This must arrive
-- at the SRAM before the command and write data by the SRAM hold time of at
-- least 0.5nS. This is achieved by using a DCM to generate the SRAM clock
-- about 2nS in advance of the User clock, and clocking all signals in IOB's.
-- The SRAM clock is used only as an output to the SRAM (via FDDR in IOB)
-- and does not clock any signals in the FPGA.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
library UNISIM;
use UNISIM.VComponents.all;

entity ZestSC1_SRAM is
  port (
    -- User interface
    USER_CLK: in std_logic;                       -- clock from user logic
    USER_RESET: in std_logic;                     -- reset
    USER_A: in std_logic_vector(22 downto 0);     -- 23-bit address
    USER_W: in std_logic;                         -- write strobe active high
    USER_R: in std_logic;                         -- read strobe active high
    USER_DR_VALID: out std_logic;                 -- read data valid strobe active high
    USER_DW: in std_logic_vector(17 downto 0);    -- 18-bit data bus for writing to SRAM
    USER_DR: out std_logic_vector(17 downto 0);   -- 18-bit data bus for reading from SRAM
    -- ZBT SRAM interface
    CLK_SRAM: out std_logic;
    S_A: out std_logic_vector(22 downto 0);
    S_ADV_LD_N: out std_logic;
    S_BWA_N: out std_logic;
    S_BWB_N: out std_logic;
    S_DA: inout std_logic_vector(8 downto 0);
    S_DB: inout std_logic_vector(8 downto 0);
    S_OE_N: out std_logic;
    S_WE_N: out std_logic
    );
end ZestSC1_SRAM;

architecture arch of ZestSC1_SRAM is

component DCM
      -- synthesis translate_off 
      generic (CLK_FEEDBACK : string := "1X"; 
               CLKDV_DIVIDE : real := 2.0;
               CLKFX_DIVIDE : integer := 1;
               CLKFX_MULTIPLY : integer := 4;
               CLKIN_DIVIDE_BY_2 : boolean := FALSE;
               CLKOUT_PHASE_SHIFT : string := "NONE"; 
               DESKEW_ADJUST : string := "SYSTEM_SYNCHRONOUS"; 
               DFS_FREQUENCY_MODE : string := "LOW"; 
               DLL_FREQUENCY_MODE : string := "LOW"; 
               DSS_MODE : string := "NONE"; 
               DUTY_CYCLE_CORRECTION : boolean := TRUE;
               PHASE_SHIFT : integer := 0; 
               STARTUP_WAIT : boolean := FALSE);
      -- synthesis translate_on 
 port (
   CLKIN : in std_logic;
   CLKFB : in std_logic;
   RST : in std_logic;
   PSEN : in std_logic;
   PSINCDEC : in std_logic;
   PSCLK : in std_logic;
   DSSEN : in std_logic;
   CLK0 : out std_logic;
   CLK90 : out std_logic;
   CLK180 : out std_logic;
   CLK270 : out std_logic;
   CLKDV : out std_logic;
   CLK2X : out std_logic;
   CLK2X180 : out std_logic;
   CLKFX : out std_logic;
   CLKFX180 : out std_logic;
   STATUS : out std_logic_vector (7 downto 0);
   LOCKED : out std_logic;
   PSDONE : out std_logic
   );
end component;
component BUFG
 port (
   I : in std_logic;
   O : out std_logic
   );
end component;

attribute CLK_FEEDBACK : string;
attribute CLKDV_DIVIDE : real;
attribute CLKFX_DIVIDE : integer;
attribute CLKFX_MULTIPLY : integer;
attribute CLKIN_DIVIDE_BY_2 : boolean;
attribute CLKOUT_PHASE_SHIFT : string;
attribute DESKEW_ADJUST : string;
attribute DFS_FREQUENCY_MODE : string;
attribute DLL_FREQUENCY_MODE : string;
attribute DSS_MODE : string;
attribute DUTY_CYCLE_CORRECTION : boolean;
attribute PHASE_SHIFT : integer;
attribute STARTUP_WAIT : boolean;

attribute CLK_FEEDBACK of DCM_INST: label is "1X";
attribute CLKDV_DIVIDE of DCM_INST: label is 2.0; -- (1.5,2,2.5,3,4, 5, 8, 16)
attribute CLKFX_DIVIDE of DCM_INST: label is 1;
attribute CLKFX_MULTIPLY of DCM_INST: label is 4;
attribute CLKIN_DIVIDE_BY_2 of DCM_INST: label is FALSE;
attribute DESKEW_ADJUST of DCM_INST : label is "SYSTEM_SYNCHRONOUS";
attribute DFS_FREQUENCY_MODE of DCM_INST: label is "LOW";
attribute DLL_FREQUENCY_MODE of DCM_INST: label is "LOW";
attribute DSS_MODE of DCM_INST: label is "NONE";
attribute DUTY_CYCLE_CORRECTION of DCM_INST: label is TRUE; -- (TRUE, FALSE)
attribute STARTUP_WAIT of DCM_INST: label is FALSE; -- (TRUE,FALSE)

-- Fixed phase shift to advance SRAM clock by about 2nS to ensure positive hold time
-- for command and write data at SRAM pins
-- Negative phase shift for an advanced clock relative to the input clock
-- Clock frequency is 48MHz = period of 20.833nS 
-- so 2nS is a phase shift of 2/20.833 * 256 = 25
--**************************************************************************************
-- IF A DIFFERENT CLOCK PERIOD IS USED THEN THE PHASE SHIFT MUST BE CHANGED ACCORDING
-- TO FORMULA ABOVE. NOTE THAT THE MAXIMUM PHASE SHIFT ACHIEVABLE BY A DCM IS 10nS.
--**************************************************************************************
attribute CLKOUT_PHASE_SHIFT of DCM_INST: label is "FIXED";
attribute PHASE_SHIFT of DCM_INST: label is -25; -- must be negative

component OFDDRCPE
   port (
     D0 : in std_logic;
     D1 : in std_logic;
     C0 : in std_logic;
     C1 : in std_logic;
     Q : out std_logic;
     PRE : in std_logic;
     CLR : in std_logic;
     CE : in std_logic
     );
end component;

signal GND: std_logic;
signal Clk: std_logic;
signal SramClkOut: std_logic;
signal SramClk: std_logic;
signal SramClkInv: std_logic;
signal dcm_locked: std_logic;
signal Reset: std_logic;
signal OutputEnable0_n: std_logic;
signal OutputEnable1_n: std_logic;
signal S_OutputEnable_n: std_logic;
signal Data0: std_logic_vector(17 downto 0);
signal Data1: std_logic_vector(17 downto 0);
signal S_DataOut: std_logic_vector(17 downto 0);
signal ReadDataValid0: std_logic;
signal ReadDataValid1: std_logic;
signal ReadDataValid2: std_logic;

begin

  Reset <= USER_RESET;
  Clk <= USER_CLK;

  -- Advance SRAM clock relative to internal clock to ensure positive hold
  -- time for signals at SRAM pins
  DCM_INST : DCM
    -- synthesis translate_off 
    generic map(CLK_FEEDBACK => "1X", 
                CLKDV_DIVIDE => 2.0,
                CLKFX_DIVIDE => 1,
                CLKFX_MULTIPLY => 4,
                CLKIN_DIVIDE_BY_2 => false,
                CLKOUT_PHASE_SHIFT => "FIXED", 
                DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", 
                DFS_FREQUENCY_MODE => "LOW", 
                DLL_FREQUENCY_MODE => "LOW", 
                DSS_MODE => "NONE", 
                DUTY_CYCLE_CORRECTION => true,
                PHASE_SHIFT => -25, -- See comments above
                STARTUP_WAIT => false)
    -- synthesis translate_on 
  port map (
      CLKIN => Clk,
      CLKFB => SramClk,
      RST => Reset,
      PSEN => GND,
      PSINCDEC => GND,
      PSCLK => GND,
      DSSEN => GND,
      CLK0 => SramClkOut,
      LOCKED => dcm_locked);

  CLK0_BUFG_INST : BUFG
  port map (
      I => SramClkOut,
      O => SramClk);

  GND <= '0';
  SramClkInv <= not SramClk;

  -- Use double data rate flip-flop for SRAM clock output to ensure
  -- minimum delay on clock (using just an OBUF would use slower local routing
  -- from SramClk to the OBUF)
  OFDDRCPE_CLK_SRAM : OFDDRCPE
  port map (
          D0 => '1',
          D1 => '0',
          C0 => SramClk,
          C1 => SramClkInv,
          Q => CLK_SRAM,
          PRE => '0',
          CLR => '0',
          CE => '1'
          );

  -- Byte writes are not implemented so tie byte write strobes low
  S_BWA_N <= '0';
  S_BWB_N <= '0';
  -- Burst accesses are not implemented so tie Advance/Load_n strobe low
  S_ADV_LD_N <= '0';
  -- Outputs are tri-stated by SRAM itself during writes so tie OE_n low
  S_OE_N <= '0';

  -- Register user command signals
  process (Clk)
  begin
    if Clk'event and Clk='1' then
      S_WE_N <= not USER_W;
      S_A <= USER_A;
    end if;
  end process;

  -- Write Data
  -- 3-stage pipeline
  process (Clk)
  begin
    if Clk'event and Clk='1' then
      Data0 <= USER_DW;
      Data1 <= Data0;
      S_DataOut <= Data1;
    end if;
  end process;

  -- Tri-state control
  -- Output enable strobe is user write enable delayed 3 clocks as write data
  -- is valid 3 clocks after user address and write enable
  process (Clk)
  begin
    if Clk'event and Clk='1' then
      OutputEnable0_n <= not USER_W;
      OutputEnable1_n <= OutputEnable0_n;
      S_OutputEnable_n <= OutputEnable1_n;
    end if;
  end process;
  S_DA <= S_DataOut (8 downto 0) when S_OutputEnable_n='0' else (others=>'Z');
  S_DB <= S_DataOut (17 downto 9) when S_OutputEnable_n='0' else (others=>'Z');

  -- Read Data
  process (Clk)
  begin
    if Clk'event and Clk='1' then
      USER_DR <= S_DB & S_DA;
    end if;
  end process;

  -- Read Data Valid Strobe
  -- Read data is valid 4 clocks after read strobe
  process (Clk)
  begin
    if Clk'event and Clk='1' then
      ReadDataValid0 <= USER_R;
      ReadDataValid1 <= ReadDataValid0;
      ReadDataValid2 <= ReadDataValid1;
      USER_DR_VALID <= ReadDataValid2;
    end if;
  end process;

end arch;
