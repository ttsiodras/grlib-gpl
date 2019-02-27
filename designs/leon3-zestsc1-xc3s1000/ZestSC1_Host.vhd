-- ZestSC1 Host Interface Code
-- File name: ZestSC1_Host.vhd
-- Version: 1.10
-- Date: 14/3/2006

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

library UNISIM;
use UNISIM.VComponents.all;

entity ZestSC1_Host is
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
        -- Streaming interface
        User_CLK : out std_logic;
        User_RST : out std_logic;
        DCMLocked : out std_logic;

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
end ZestSC1_Host;

architecture arch of ZestSC1_Host is

    -- Reset block
    component ROC
        port
        (
            O : out std_logic
        );
    end component;
    attribute box_type : string;
    attribute box_type of ROC: component is "black_box";

    -- DCMs
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
      port (CLK0 : out std_ulogic; 
            CLK180 : out std_ulogic; 
            CLK270 : out std_ulogic; 
            CLK2X : out std_ulogic; 
            CLK2X180 : out std_ulogic; 
            CLK90 : out std_ulogic; 
            CLKDV : out std_ulogic; 
            CLKFX : out std_ulogic; 
            CLKFX180 : out std_ulogic; 
            LOCKED : out std_ulogic; 
            PSDONE : out std_ulogic; 
            STATUS : out std_logic_vector(7 downto 0); 
            CLKFB : in std_ulogic; 
            CLKIN : in std_ulogic; 
            DSSEN : in std_ulogic; 
            PSCLK : in std_ulogic; 
            PSEN : in std_ulogic; 
            PSINCDEC : in std_ulogic; 
            RST : in std_ulogic); 
    end component; 
    attribute box_type of DCM: component is "black_box";

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

    -- Component Attribute specification for Stream clock DCM 
    attribute CLK_FEEDBACK of StreamDCM: label is "1X"; 
    attribute CLKDV_DIVIDE of StreamDCM: label is 2.0;
    attribute CLKFX_DIVIDE of StreamDCM: label is 1; 
    attribute CLKFX_MULTIPLY of StreamDCM: label is 2; 
    attribute CLKIN_DIVIDE_BY_2 of StreamDCM: label is FALSE; 
    attribute CLKOUT_PHASE_SHIFT of StreamDCM: label is "NONE"; 
    attribute DESKEW_ADJUST of StreamDCM : label is "SYSTEM_SYNCHRONOUS"; 
    attribute DFS_FREQUENCY_MODE of StreamDCM: label is "LOW"; 
    attribute DLL_FREQUENCY_MODE of StreamDCM: label is "LOW"; 
    attribute DSS_MODE of StreamDCM: label is "NONE"; 
    attribute DUTY_CYCLE_CORRECTION of StreamDCM: label is TRUE;
    attribute PHASE_SHIFT of StreamDCM: label is 0; 
    attribute STARTUP_WAIT of StreamDCM: label is FALSE;

    -- Component Attribute specification for Register clock DCM 
    attribute CLK_FEEDBACK of RegDCM: label is "1X"; 
    attribute CLKDV_DIVIDE of RegDCM: label is 2.0;
    attribute CLKFX_DIVIDE of RegDCM: label is 1; 
    attribute CLKFX_MULTIPLY of RegDCM: label is 2; 
    attribute CLKIN_DIVIDE_BY_2 of RegDCM: label is FALSE; 
    attribute CLKOUT_PHASE_SHIFT of RegDCM: label is "NONE"; 
    attribute DESKEW_ADJUST of RegDCM : label is "SYSTEM_SYNCHRONOUS"; 
    attribute DFS_FREQUENCY_MODE of RegDCM: label is "LOW"; 
    attribute DLL_FREQUENCY_MODE of RegDCM: label is "LOW"; 
    attribute DSS_MODE of RegDCM: label is "NONE"; 
    attribute DUTY_CYCLE_CORRECTION of RegDCM: label is TRUE;
    attribute PHASE_SHIFT of RegDCM: label is 0; 
    attribute STARTUP_WAIT of RegDCM: label is FALSE;

    -- Declare global clock buffer
    component BUFG 
        port (I   : in std_logic;
              O   : out std_logic
	        ); 
    end component;
    attribute box_type of BUFG: component is "black_box";

    -- General signals
    signal RST : std_logic;
    signal StreamCLK : std_logic;
    signal StreamCLKFB : std_logic;
    signal RegCLK : std_logic;
    signal RegCLKFB : std_logic;

    -- Streaming interface
    signal StreamRead : std_logic;
    signal StreamWrite : std_logic;
    signal StreamDataIn : std_logic_vector(15 downto 0);
    signal StreamDataOut : std_logic_vector(15 downto 0);
    signal DataOutRegFull : std_logic;
    signal StreamBusy : std_logic;
    signal StreamDataAvailable : std_logic;
    signal StreamReadStrobe : std_logic;
    signal WriteToFIFOIn : std_logic;
    signal StreamWriteStrobe : std_logic;
    signal ReadFromFIFOOut : std_logic;
    signal ReadOK : std_logic;
    signal WriteOK : std_logic;
    signal ReadCycle : std_logic;
    signal WriteCycle : std_logic;
    signal User_DataInStrobe : std_logic;
    signal GrantPeriod : std_logic_vector(11 downto 0);
    signal Granted : std_logic;
    signal LastDir : std_logic;

    signal FX2FIFOFull : std_logic;
    signal FX2FIFOEmpty : std_logic;

    type FIFO_ARRAY_TYPE is array(15 downto 0) of std_logic_vector(15 downto 0);
    signal FIFOOut : FIFO_ARRAY_TYPE;
    signal FIFOIn : FIFO_ARRAY_TYPE;
    signal FIFOInEmpty : std_logic;

    signal FIFOOutWriteCount : std_logic_vector(3 downto 0);
    signal FIFOOutWriteCountG : std_logic_vector(3 downto 0);
    signal RegFIFOOutWriteCountG : std_logic_vector(3 downto 0);
    signal FIFOOutWriteCountInUSB : std_logic_vector(3 downto 0);

    signal FIFOOutReadCount : std_logic_vector(3 downto 0);
    signal FIFOOutReadCountG : std_logic_vector(3 downto 0);
    signal RegFIFOOutReadCountG : std_logic_vector(3 downto 0);
    signal FIFOOutReadCountInUser : std_logic_vector(3 downto 0);

    signal FIFOInWriteCount : std_logic_vector(3 downto 0);
    signal FIFOInWriteCountG : std_logic_vector(3 downto 0);
    signal RegFIFOInWriteCountG : std_logic_vector(3 downto 0);
    signal FIFOInWriteCountInUser : std_logic_vector(3 downto 0);

    signal FIFOInReadCount : std_logic_vector(3 downto 0);
    signal FIFOInReadCountG : std_logic_vector(3 downto 0);
    signal RegFIFOInReadCountG : std_logic_vector(3 downto 0);
    signal FIFOInReadCountInUSB : std_logic_vector(3 downto 0);

    signal FIFOOutDataCount : std_logic_vector(3 downto 0);
    signal FIFOInDataCount : std_logic_vector(3 downto 0);

    -- Memory mapped interface
    signal RegCS : std_logic;
    signal RegLastCS : std_logic;
    signal RegOE : std_logic;
    signal RegLastOE : std_logic;
    signal RegWR : std_logic;
    signal RegLastWR : std_logic;
    signal RegRD : std_logic;
    signal RegLastRD : std_logic;
    signal RegOutput : std_logic_vector(7 downto 0);

    -- Counter for interrupt generation
    signal IntCounter : std_logic_vector(2 downto 0);

begin

    -- Generate resets and clocks
    ROC_1 : ROC port map ( O => RST );
    User_RST <= RST;
    User_CLK <= RegCLK;

    -------------------------
    -- Streaming interface --
    -------------------------

    -- Control signals
    USB_StreamPKTEND_n <= '1';
    USB_StreamSLRD_n <= not StreamReadStrobe;
    USB_StreamSLWR_n <= not StreamWriteStrobe;
    USB_StreamSLOE_n <= '0' when (ReadCycle='1' or StreamRead='1') else '1';
    USB_StreamData <= StreamDataOut when (WriteCycle='1' or StreamWrite='1') else (others=>'Z');
    USB_StreamFIFOADDR <= "00" when (ReadCycle='1' or StreamRead='1') else "10";


    -- Generate FIFO full and empty flags for the FX2
    -- This must be done internally because the timing of the FX2 flags
    -- and read/write strobes is such that we cannot respond to the flags
    -- in one clock cycle.  The flags from the FX2 are therefore set to
    -- one empty place (full flag) and one available word (empty flag).
    process (RST, StreamCLK)
    begin
        if (RST='1') then
            FX2FIFOFull <= '1';
            FX2FIFOEmpty <= '1';
        elsif (StreamCLK'event and StreamCLK='1') then
            if (USB_StreamFlags_n(0)='1' and USB_StreamFX2Rdy='1') then
                FX2FIFOEmpty <= '0';
            elsif (StreamReadStrobe='1') then
                FX2FIFOEmpty <= '1';
            end if;

            if (USB_StreamFlags_n(1)='1' and USB_StreamFX2Rdy='1') then
                FX2FIFOFull <= '0';
            elsif (StreamWriteStrobe='1') then
                FX2FIFOFull <= '1';
            end if;
        end if;
    end process;

    -- Read and write strobe generation and registering of input and output data
    StreamReadStrobe <= '1' when (ReadCycle='0' and ReadOK='1') else '0';
    WriteToFIFOIn <= '1' when (ReadCycle='1') else '0';
    ReadOK <= '1' when (FX2FIFOEmpty='0' and StreamBusy='0' and
                        USB_StreamFX2Rdy='1' and StreamRead='1') else '0';
    process (StreamCLK)
    begin
        if (StreamCLK'event and StreamCLK='1') then
            if (StreamReadStrobe='1') then
                StreamDataIn <= USB_StreamData;
            end if;
        end if;
    end process;

    StreamWriteStrobe <= '1' when (WriteCycle='1') else '0';
    ReadFromFIFOOut <= '1' when (WriteCycle='0' and DataOutRegFull='0' and
                                 StreamDataAvailable='1') else '0';
    WriteOK <= '1' when FX2FIFOFull='0' and (StreamDataAvailable='1' or DataOutRegFull='1') and
                        USB_StreamFX2Rdy='1' and StreamWrite='1' else '0';
    process (RST, StreamCLK)
    begin
        if (RST='1') then
            DataOutRegFull <= '0';
        elsif (StreamCLK'event and StreamCLK='1') then
            if (ReadFromFIFOOut='1') then
                StreamDataOut <= FIFOOut(conv_integer(FIFOOutReadCount));
                DataOutRegFull <= '1';
            elsif (StreamWriteStrobe='1') then
                DataOutRegFull <= '0';
            end if;
        end if;
    end process;

    -- Control individual reads and writes from/to the FX2
    process (RST, StreamCLK)
    begin
        if (RST='1') then
            ReadCycle <= '0';
            WriteCycle <= '0';
        elsif (StreamCLK'event and StreamCLK='1') then

            if (ReadCycle='0') then
                ReadCycle <= ReadOK;
            else
                ReadCycle <= '0';
            end if;

            if (WriteCycle='0') then
                WriteCycle <= WriteOK;
            else
                WriteCycle <= '0';
            end if;

        end if;
    end process;

    -- Manage transfers
    -- Checks whether a transfer is needed and possible
    -- Use round robin to alternate between reads and writes
    --
    -- GrantLength limits the length of time the streaming bus is granted to
    -- reads or writes.  Set it low for rapid bus turn arounds at the expense
    -- of overall bandwidth.  Set high for larger maximum bandwidth at the 
    -- expense of slower bus turnarounds.
    process (RST, StreamCLK)
    begin
        if (RST='1') then
            StreamRead <= '0';
            StreamWrite <= '0';
            GrantPeriod <= X"000";
            Granted <= '0';
            FIFOInWriteCount <= X"0";
            FIFOOutReadCount <= X"0";
            LastDir <= '0';

        elsif (StreamCLK'event and StreamCLK='1') then

            if (Granted='0') then

                -- Not currently in a transfer
                -- Try to start a new one
                if (not (LastDir='0' and FX2FIFOFull='0' and (StreamDataAvailable='1' or DataOutRegFull='1')) and
                    FX2FIFOEmpty='0' and StreamBusy='0') then
                    -- EP2 empty flag is not set and we can receive data
                    StreamRead <= '1';
                    StreamWrite <= '0';
                    GrantPeriod <= User_StreamBusGrantLength;
                    LastDir <= '0';
                    Granted <= '1';

                elsif (FX2FIFOFull='0' and (StreamDataAvailable='1' or DataOutRegFull='1')) then
                    -- EP6 full flag is clear and we have data
                    StreamRead <= '0';
                    StreamWrite <= '1';
                    GrantPeriod <= User_StreamBusGrantLength;
                    LastDir <= '1';
                    Granted <= '1';
                end if;

            else

                GrantPeriod <= GrantPeriod - 1;
                if (GrantPeriod=X"004") then
                    -- Take grant away early as the accesses take more than 1 cycle
                    StreamRead <= '0';
                    StreamWrite <= '0';
                end if;
                if (GrantPeriod=X"001") then
                    Granted <= '0';
                end if;

            end if;

            if (WriteToFIFOIn='1') then
                FIFOInWriteCount <= FIFOInWriteCount + 1;
            end if;
            if (ReadFromFIFOOut='1') then
                FIFOOutReadCount <= FIFOOutReadCount + 1;
            end if;

        end if;
    end process;

    -- Short FIFOs for crossing clock domains
    -- User domain -> USB
    process (RST, RegCLK)
    begin
        if (RST='1') then
            FIFOOutWriteCount <= "0000";
        elsif (RegCLK'event and RegCLK='1') then
            if (User_StreamDataOutWE='1') then
                FIFOOutWriteCount <= FIFOOutWriteCount + 1;
            end if;
        end if;
    end process;
    process (RegCLK)
    begin
        if (RegCLK'event and RegCLK='1') then
            if (User_StreamDataOutWE='1') then
                FIFOOut(conv_integer(FIFOOutWriteCount)) <= User_StreamDataOut;
            end if;
        end if;
    end process;

    -- USB -> User domain
    process (RST, RegCLK)
    begin
        if (RST='1') then
            FIFOInReadCount <= "0000";
        elsif (RegCLK'event and RegCLK='1') then
            if (User_DataInStrobe='1') then
                FIFOInReadCount <= FIFOInReadCount + 1;
            end if;
        end if;
    end process;
    process (RST, StreamCLK)
    begin
        if (StreamCLK'event and StreamCLK='1') then
            if (WriteToFIFOIn='1') then
                FIFOIn(conv_integer(FIFOInWriteCount)) <= StreamDataIn;
            end if;
        end if;
    end process;

    -- Note fixup for behavioural simulation - holds the data during write strobe
    User_StreamDataIn <= FIFOIn(conv_integer(FIFOInReadCount)) after 1 ns;
    User_StreamDataInWE <= User_DataInStrobe;
    User_DataInStrobe <= not FIFOInEmpty and not User_StreamDataInBusy;

    -- Generate busy flag to User
    -- Grey code the DataOut read counter, cross clock domain and decode
    FIFOOutReadCountG <= FIFOOutReadCount(3) &
                         (FIFOOutReadCount(3) xor FIFOOutReadCount(2)) &
                         (FIFOOutReadCount(2) xor FIFOOutReadCount(1)) &
                         (FIFOOutReadCount(1) xor FIFOOutReadCount(0));
    process (RST, RegCLK)
    begin
        if (RST='1') then
            RegFIFOOutReadCountG <= "0000";
        elsif (RegCLK'event and RegClk='1') then
            RegFIFOOutReadCountG <= FIFOOutReadCountG;
        end if;
    end process;
    FIFOOutReadCountInUser <= RegFIFOOutReadCountG(3) &
                              (RegFIFOOutReadCountG(3) xor RegFIFOOutReadCountG(2)) &
                              (RegFIFOOutReadCountG(3) xor RegFIFOOutReadCountG(2) xor RegFIFOOutReadCountG(1)) &
                              (RegFIFOOutReadCountG(3) xor RegFIFOOutReadCountG(2) xor RegFIFOOutReadCountG(1) xor RegFIFOOutReadCountG(0));
    FIFOOutDataCount <= FIFOOutWriteCount-FIFOOutReadCountInUser;
    User_StreamDataOutBusy <= '1' when (FIFOOutDataCount(3)='1') else '0';

    -- Generate write enable strobe to the User
    -- Grey code the DataIn write counter, cross clock domain and decode
    FIFOInWriteCountG <= FIFOInWriteCount(3) &
                         (FIFOInWriteCount(3) xor FIFOInWriteCount(2)) &
                         (FIFOInWriteCount(2) xor FIFOInWriteCount(1)) &
                         (FIFOInWriteCount(1) xor FIFOInWriteCount(0));
    process (RST, RegCLK)
    begin
        if (RST='1') then
            RegFIFOInWriteCountG <= "0000";
        elsif (RegCLK'event and RegClk='1') then
            RegFIFOInWriteCountG <= FIFOInWriteCountG;
        end if;
    end process;
    FIFOInWriteCountInUser <= RegFIFOInWriteCountG(3) &
                              (RegFIFOInWriteCountG(3) xor RegFIFOInWriteCountG(2)) &
                              (RegFIFOInWriteCountG(3) xor RegFIFOInWriteCountG(2) xor RegFIFOInWriteCountG(1)) &
                              (RegFIFOInWriteCountG(3) xor RegFIFOInWriteCountG(2) xor RegFIFOInWriteCountG(1) xor RegFIFOInWriteCountG(0));
    FIFOInEmpty <= '1' when FIFOInWriteCountInUser=FIFOInReadCount else '0';

    -- Generate 'data available' flag to the USB chip
    FIFOOutWriteCountG <= FIFOOutWriteCount(3) &
                          (FIFOOutWriteCount(3) xor FIFOOutWriteCount(2)) &
                          (FIFOOutWriteCount(2) xor FIFOOutWriteCount(1)) &
                          (FIFOOutWriteCount(1) xor FIFOOutWriteCount(0));
    process (RST, StreamCLK)
    begin
        if (RST='1') then
            RegFIFOOutWriteCountG <= "0000";
        elsif (StreamCLK'event and StreamCLK='1') then
            RegFIFOOutWriteCountG <= FIFOOutWriteCountG;
        end if;
    end process;
    FIFOOutWriteCountInUSB <= RegFIFOOutWriteCountG(3) &
                              (RegFIFOOutWriteCountG(3) xor RegFIFOOutWriteCountG(2)) &
                              (RegFIFOOutWriteCountG(3) xor RegFIFOOutWriteCountG(2) xor RegFIFOOutWriteCountG(1)) &
                              (RegFIFOOutWriteCountG(3) xor RegFIFOOutWriteCountG(2) xor RegFIFOOutWriteCountG(1) xor RegFIFOOutWriteCountG(0));
    StreamDataAvailable <= '1' when (FIFOOutWriteCountInUSB/=FIFOOutReadCount) else '0';

    -- Generate 'space available' flag to the USB chip
    FIFOInReadCountG <= FIFOInReadCount(3) &
                        (FIFOInReadCount(3) xor FIFOInReadCount(2)) &
                        (FIFOInReadCount(2) xor FIFOInReadCount(1)) &
                        (FIFOInReadCount(1) xor FIFOInReadCount(0));
    process (RST, StreamCLK)
    begin
        if (RST='1') then
            RegFIFOInReadCountG <= "0000";
        elsif (StreamCLK'event and StreamCLK='1') then
            RegFIFOInReadCountG <= FIFOInReadCountG;
        end if;
    end process;
    FIFOInReadCountInUSB <= RegFIFOInReadCountG(3) &
                            (RegFIFOInReadCountG(3) xor RegFIFOInReadCountG(2)) &
                            (RegFIFOInReadCountG(3) xor RegFIFOInReadCountG(2) xor RegFIFOInReadCountG(1)) &
                            (RegFIFOInReadCountG(3) xor RegFIFOInReadCountG(2) xor RegFIFOInReadCountG(1) xor RegFIFOInReadCountG(0));
    FIFOInDataCount <= FIFOInWriteCount-FIFOInReadCountInUSB;
    StreamBusy <= '1' when (FIFOInDataCount(3)='1') else '0';


    -----------------------------
    -- Memory mapped interface --
    -----------------------------
    User_RegAddr <= USB_RegAddr - X"2000"; -- 8051 external memory starts at 0x2000
    User_RegWE <= RegCS and RegLastCS and RegWR and RegLastWR;
    User_RegRE <= RegCS and not RegLastCS and RegRD and not RegLastRD;
    User_RegDataIn <= USB_RegData;

    RegCS <= not USB_RegCS_n;
    RegOE <= not USB_RegOE_n;
    RegWR <= not USB_RegWR_n;
    RegRD <= not USB_RegRD_n;
    process (RegCLK)
    begin
        if (RegCLK'event and RegCLK='1') then
            RegLastCS <= RegCS;
            RegLastRD <= RegRD;
            RegLastWR <= RegWR;
            RegLastOE <= RegOE;
        end if;
    end process;

    -- Register read interface
    process (RegCLK)
    begin
        if (RegCLK'event and RegCLK='1') then
            RegOutput <= User_RegDataOut;
        end if;
    end process;

    USB_RegData <= RegOutput when (RegRD='1' and RegCS='1' and RegOE='1') else (others=>'Z');


    ---------------------------
    -- Generate an interrupt --
    ---------------------------
    -- Interrupt is active low, edge triggered and must be held for
    -- 4 cycles of the register interface clock
    process (RST, RegCLK)
    begin
        if (RST='1') then
            IntCounter <= "000";
        elsif (RegCLK'event and RegCLK='1') then
            if (User_Interrupt='1') then
                IntCounter <= "100";
            elsif (IntCounter/="000") then
                IntCounter <= IntCounter + 1;
            end if;
        end if;
    end process;
    USB_Interrupt <= not IntCounter(2);


    -------------------------------
    -- Instatiate DCMs on clocks --
    -------------------------------
    StreamDCM : DCM 
        -- synthesis translate_off 
        generic map(CLK_FEEDBACK => "1X", 
                    CLKDV_DIVIDE => 2.0,
                    CLKFX_DIVIDE => 1,
                    CLKFX_MULTIPLY => 2,
                    CLKIN_DIVIDE_BY_2 => false,
                    CLKOUT_PHASE_SHIFT => "NONE", 
                    DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", 
                    DFS_FREQUENCY_MODE => "LOW", 
                    DLL_FREQUENCY_MODE => "LOW", 
                    DSS_MODE => "NONE", 
                    DUTY_CYCLE_CORRECTION => true,
                    PHASE_SHIFT => 0, 
                    STARTUP_WAIT => false)
        -- synthesis translate_on 
        port map (CLK0 => StreamCLKFB,
                  CLKFB => StreamCLK,
                  CLKIN => USB_StreamCLK, 
                  DSSEN => '0',
                  PSCLK => '0',
                  PSEN => '0',
                  PSINCDEC => '0',
                  RST => RST); 
    StreamCLK_BUFG: BUFG
        port map (
            I => StreamCLKFB,
            O => StreamCLK
        );

    RegDCM : DCM 
        -- synthesis translate_off 
        generic map(CLK_FEEDBACK => "1X", 
                    CLKDV_DIVIDE => 2.0,
                    CLKFX_DIVIDE => 1,
                    CLKFX_MULTIPLY => 2,
                    CLKIN_DIVIDE_BY_2 => false,
                    CLKOUT_PHASE_SHIFT => "NONE", 
                    DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", 
                    DFS_FREQUENCY_MODE => "LOW", 
                    DLL_FREQUENCY_MODE => "LOW", 
                    DSS_MODE => "NONE", 
                    DUTY_CYCLE_CORRECTION => true,
                    PHASE_SHIFT => 0, 
                    STARTUP_WAIT => false)
        -- synthesis translate_on 
        port map (CLK0 => RegCLKFB,
                  CLKFB => RegCLK,
                  CLKIN => USB_RegCLK, 
                  DSSEN => '0',
                  PSCLK => '0',
                  PSEN => '0',
                  PSINCDEC => '0',
                  RST => RST,
                  LOCKED => DCMLocked); 
    RegCLK_BUFG: BUFG
        port map (
  	        I => RegCLKFB,
            O => RegCLK
  	    );

end arch;
