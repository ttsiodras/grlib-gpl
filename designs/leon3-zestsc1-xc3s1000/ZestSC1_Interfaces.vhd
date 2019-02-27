-- ZestSC1 Top Level Code
-- File name: ZestSC1_Interfaces.vhd
-- Version: 1.00
-- Date: 9/2/2005

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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ZestSC1_Interfaces is
    port (
        -- User connections
        -- General connections
        User_CLK : out std_logic;                          -- User logic clock
        User_RST : out std_logic;                          -- User logic reset

        -- USB Streaming interface
        User_StreamBusGrantLength : in std_logic_vector(11 downto 0); -- Round robin grant length
                                                           -- Controls read and write grant times
                                                           -- on the streaming bus

        User_StreamDataIn : out std_logic_vector(15 downto 0); -- Stream data from host
        User_StreamDataInWE : out std_logic;               -- Stream write strobe from host
        User_StreamDataInBusy : in std_logic;              -- Busy for stream from host

        User_StreamDataOut : in std_logic_vector(15 downto 0); -- Stream data to host
        User_StreamDataOutWE : in std_logic;               -- Stream write strobe to host
        User_StreamDataOutBusy : out std_logic;            -- Busy for stream to host

        -- USB Register interface
        User_RegAddr : out std_logic_vector(15 downto 0);  -- Register interface address
        User_RegDataIn : out std_logic_vector(7 downto 0); -- Register write data
        User_RegDataOut : in std_logic_vector(7 downto 0); -- Register read data
        User_RegWE : out std_logic;                        -- Write strobe for register
        User_RegRE : out std_logic;                        -- Read strobe for register

        -- USB Interrupts
        User_Interrupt : in std_logic;                     -- Interrupt to host PC

        -- SRAM interface
        User_SRAM_A: in std_logic_vector(22 downto 0);     -- 23-bit address
        User_SRAM_W: in std_logic;                         -- write strobe active high
        User_SRAM_R: in std_logic;                         -- read strobe active high
        User_SRAM_DR_VALID: out std_logic;                 -- read data valid strobe active high
        User_SRAM_DW: in std_logic_vector(17 downto 0);    -- 18-bit data bus for writing to SRAM
        User_SRAM_DR: out std_logic_vector(17 downto 0);   -- 18-bit data bus for reading from SRAM

        -- FPGA pin connections
        -- External USB Controller interface
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

        -- External SRAM interface
        S_CLK: out std_logic;
        S_A: out std_logic_vector(22 downto 0);
        S_ADV_LD_N: out std_logic;
        S_BWA_N: out std_logic;
        S_BWB_N: out std_logic;
        S_DA: inout std_logic_vector(8 downto 0);
        S_DB: inout std_logic_vector(8 downto 0);
        S_OE_N: out std_logic;
        S_WE_N: out std_logic
    );
 
end ZestSC1_Interfaces;

architecture arch of ZestSC1_Interfaces is

component ZestSC1_Host is
    port (
        -- FPGA pin connections
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

        -- User connections
        -- General connections
        User_CLK : out std_logic;
        User_RST : out std_logic;
        DCMLocked : out std_logic;

        -- Streaming interface
        User_StreamBusGrantLength : in std_logic_vector(11 downto 0);

        User_StreamDataIn : out std_logic_vector(15 downto 0);
        User_StreamDataInWE : out std_logic;
        User_StreamDataInBusy : in std_logic;

        User_StreamDataOut : in std_logic_vector(15 downto 0);
        User_StreamDataOutWE : in std_logic;
        User_StreamDataOutBusy : out std_logic;

        -- Register interface
        User_RegAddr : out std_logic_vector(15 downto 0);
        User_RegDataIn : out std_logic_vector(7 downto 0);
        User_RegDataOut : in std_logic_vector(7 downto 0);
        User_RegWE : out std_logic;
        User_RegRE : out std_logic;

        -- Interrupts
        User_Interrupt : in std_logic
    );
end component;

component ZestSC1_SRAM is
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
end component;

signal Clk: std_logic;
signal Reset: std_logic;
signal SRAMReset : std_logic;
signal DCMLocked : std_logic;

begin

User_CLK <= Clk;
User_RST <= Reset;
SRAMReset <= Reset or not DCMLocked;

INST_ZestSC1_Host: ZestSC1_Host 
    port map (
        -- FPGA pin connections
        USB_StreamCLK => USB_StreamCLK,
        USB_StreamFIFOADDR => USB_StreamFIFOADDR,
        USB_StreamPKTEND_n => USB_StreamPKTEND_n,
        USB_StreamFlags_n => USB_StreamFlags_n,
        USB_StreamSLOE_n => USB_StreamSLOE_n,
        USB_StreamSLRD_n => USB_StreamSLRD_n,
        USB_StreamSLWR_n => USB_StreamSLWR_n,
        USB_StreamFX2Rdy => USB_StreamFX2Rdy,
        USB_StreamData => USB_StreamData,

        USB_RegCLK => USB_RegCLK,
        USB_RegAddr => USB_RegAddr,
        USB_RegData => USB_RegData,
        USB_RegOE_n => USB_RegOE_n,
        USB_RegRD_n => USB_RegRD_n,
        USB_RegWR_n => USB_RegWR_n,
        USB_RegCS_n => USB_RegCS_n,

        USB_Interrupt => USB_Interrupt,

        -- User connections
        -- General connections
        User_CLK => Clk,
        User_RST => Reset,
        DCMLocked => DCMLocked,

        -- Streaming interface
        User_StreamBusGrantLength => User_StreamBusGrantLength,

        User_StreamDataIn => User_StreamDataIn,
        User_StreamDataInWE => User_StreamDataInWE,
        User_StreamDataInBusy => User_StreamDataInBusy,

        User_StreamDataOut => User_StreamDataOut,
        User_StreamDataOutWE => User_StreamDataOutWE,
        User_StreamDataOutBusy => User_StreamDataOutBusy,

        -- Register interface
        User_RegAddr => User_RegAddr,
        User_RegDataIn => User_RegDataIn,
        User_RegDataOut => User_RegDataOut,
        User_RegWE => User_RegWE,
        User_RegRE => User_RegRE,

        -- Interrupts
        User_Interrupt => User_Interrupt
    );

INST_SRAM: ZestSC1_SRAM
    port map(
        -- User interface
        USER_CLK => Clk,
        USER_RESET => SRAMReset,
        USER_A => USER_SRAM_A,
        USER_W => USER_SRAM_W,
        USER_R => USER_SRAM_R,
        USER_DR_VALID => USER_SRAM_DR_VALID,
        USER_DW => USER_SRAM_DW,
        USER_DR => USER_SRAM_DR,

        -- ZBT SRAM interface
        CLK_SRAM => S_CLK,
        S_A => S_A,    
        S_ADV_LD_N => S_ADV_LD_N,
        S_BWA_N => S_BWA_N,
        S_BWB_N => S_BWB_N,
        S_DA => S_DA,
        S_DB => S_DB,
        S_OE_N => S_OE_N,
        S_WE_N => S_WE_N
    );

end arch;
