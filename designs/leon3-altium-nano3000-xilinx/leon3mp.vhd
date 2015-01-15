-----------------------------------------------------------------------------
--  LEON3 Altium Nano3000 Top Level Module
------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2003 - 2008, Gaisler Research
--  Copyright (C) 2008 - 2014, Aeroflex Gaisler
--  Copyright (C) 2014 Martin Wilson <mrw@trimetix.co.uk>
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation; either version 2 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program; if not, write to the Free Software
--  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- 14 Jan 2015 Martin Wilson Fix problem EDCL active when disabled in config  
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library grlib, techmap;
use grlib.amba.all;
use grlib.devices.all;
use grlib.stdlib.all;
use techmap.gencomp.all;
library gaisler;
use gaisler.memctrl.all;
use gaisler.leon3.all;
use gaisler.uart.all;
use gaisler.misc.all;
use gaisler.net.all;
use gaisler.jtag.all;
-- pragma translate_off
use gaisler.sim.all;
-- pragma translate_on

library esa;
use esa.memoryctrl.all;

use work.config.all;

entity leon3mp is
  generic (
    fabtech : integer := CFG_FABTECH;   --
    memtech : integer := CFG_MEMTECH;   --
    padtech : integer := CFG_PADTECH;   --
    clktech : integer := CFG_CLKTECH;   --
    disas   : integer := CFG_DISAS;     -- 
    dbguart : integer := CFG_DUART;     -- 
    pclow   : integer := CFG_PCLOW
    );
  port (
    resetn  : in  std_logic;
    clk_ref : in  std_logic;
    errorn  : out std_logic;

    -- Ethernet signals
    erx_clk : in    std_ulogic;
    erxd    : in    std_logic_vector(3 downto 0);
    erx_dv  : in    std_ulogic;
    erx_er  : in    std_ulogic;
    erx_col : in    std_ulogic;
    erx_crs : in    std_ulogic;
    emdint  : in    std_ulogic;
    etxd    : out   std_logic_vector(3 downto 0);
    etx_en  : out   std_ulogic;
    emdc    : out   std_ulogic;
    emdio   : inout std_logic;
    erstn   : out   std_ulogic;

    -- Common Bus Memory (Flash, SRAM and SDRAM)
    bus_a              : out   std_logic_vector(24 downto 0);  --
    bus_d              : inout std_logic_vector(31 downto 0);  --
    bus_sdram_clk      : out   std_ulogic;                     --
    bus_sdram_feedback : in    std_ulogic;                     --
    bus_sdram_cke      : out   std_logic;                      --
    bus_sdram_ncs      : out   std_logic;                      --
    bus_nwe            : out   std_logic;                      -- 
    bus_sdram_nras     : out   std_logic;                      -- 
    bus_sdram_ncas     : out   std_logic;                      -- 
    bus_nbe            : out   std_logic_vector(3 downto 0);   -- 
    bus_noe            : out   std_logic;
    bus_flash_nreset   : out   std_logic;                      --
    bus_flash_ncs      : out   std_logic;
    bus_flash_nbusy    : in    std_logic;

    uart_txd : out std_logic;           -- 
    uart_rxd : in  std_logic;           -- 

    dsu_txd : out std_logic;            -- 
    dsu_rxd : in  std_logic;            -- 
    dsubre  : in  std_logic;

    plllock : out std_logic;

    ram_ncs : out std_logic;
    usb_ncs : out std_logic;

    led_romcs    : out std_logic;
    led_rombrdyn : out std_logic

    );
end;

architecture rtl of leon3mp is

  signal vcc, gnd : std_logic_vector(4 downto 0);  --
  signal memi     : memory_in_type  := memory_in_none;
  signal memo     : memory_out_type := memory_out_none;
  signal wpo      : wprot_out_type;

  signal sdo : sdram_out_type;

  signal apbi  : apb_slv_in_type;                              --
  signal apbo  : apb_slv_out_vector := (others => apb_none);   --
  signal ahbsi : ahb_slv_in_type;                              --
  signal ahbso : ahb_slv_out_vector := (others => ahbs_none);  --
  signal ahbmi : ahb_mst_in_type;                              --
  signal ahbmo : ahb_mst_out_vector := (others => ahbm_none);  --

  signal clkm, rstn, rstraw, pciclk, sdclkl, lclk, rst : std_logic;

  signal cgi : clkgen_in_type;
  signal cgo : clkgen_out_type;

  signal u1i, u2i, dui : uart_in_type;
  signal u1o, u2o, duo : uart_out_type;

  signal irqi : irq_in_vector(0 to CFG_NCPU-1);
  signal irqo : irq_out_vector(0 to CFG_NCPU-1);

  signal dbgi : l3_debug_in_vector(0 to CFG_NCPU-1);
  signal dbgo : l3_debug_out_vector(0 to CFG_NCPU-1);

  signal dsui : dsu_in_type;
  signal dsuo : dsu_out_type;

  signal ethi  : eth_in_type;
  signal etho  : eth_out_type;
  signal stati : ahbstat_in_type;

  signal gpti : gptimer_in_type;

  signal dsubren : std_logic;

  signal rxd1 : std_logic;
  signal txd1 : std_logic;

  signal romsel   : std_logic;
  signal rombusy  : std_logic;
  signal romready : std_logic;

  signal tck, tms, tdi, tdo : std_logic;

  signal mem_nwe : std_logic;

  signal eth_inclk : std_logic;

  constant BOARD_FREQ : integer := 20000;  -- Board frequency in KHz, used in clkgen
  constant CPU_FREQ   : integer := BOARD_FREQ * CFG_CLKMUL / CFG_CLKDIV;  -- cpu frequency in KHz 
  constant IOAEN      : integer := 1;  -- can enables AHB I/O area, alla CFG generics  
  constant CFG_SDEN   : integer := CFG_MCTRL_SDEN;
  constant CFG_INVCLK : integer := CFG_MCTRL_INVCLK;
  constant OEPOL      : integer := padoen_polarity(padtech);
  constant notag      : integer := 1;  --unused processor input? why 1 when default is 0?

  attribute syn_keep     : boolean;
  attribute syn_preserve : boolean;
  attribute keep         : boolean;

begin

----------------------------------------------------------------------
---                       Clock Generation                         ---
----------------------------------------------------------------------

  ram_ncs <= '1';
  usb_ncs <= '1';

  plllock <= cgo.clklock;

  cgi.pllctrl <= "00"; cgi.pllrst <= rstraw;

  clk_pad : clkpad generic map (tech => padtech)
    port map (clk_ref, lclk);
  
  pllref_pad : clkpad generic map (tech => padtech)
    port map (bus_sdram_feedback, cgi.pllref);
  
  sdclk_pad : outpad generic map (tech => padtech, slew => 1)
    port map (bus_sdram_clk, sdclkl);
  
  clkgen0 : clkgen
    generic map (tech    => clktech, clk_mul => CFG_CLKMUL, clk_div => CFG_CLKDIV,
                 sdramen => CFG_MCTRL_SDEN, noclkfb => CFG_CLK_NOFB,
                 pcien   => 0, pcidll => 0, pcisysclk => 0, freq => BOARD_FREQ)
    port map (clkin  => lclk, pciclkin => lclk, clk => clkm,
              clkn   => open, clk2x => open, sdclk => sdclkl,
              pciclk => open, cgi => cgi, cgo => cgo);

----------------------------------------------------------------------
---                       Reset Generation                         ---
----------------------------------------------------------------------

  resetn_pad : inpad generic map (tech => padtech) port map (resetn, rst);
  rst0       : rstgen
    port map (rst, clkm, cgo.clklock, rstn, rstraw);

----------------------------------------------------------------------
---                     AMBA AHB Controller                        ---
----------------------------------------------------------------------

  ahb0 : ahbctrl
    generic map (defmast => CFG_DEFMST, split => CFG_SPLIT,
                 rrobin  => CFG_RROBIN, ioaddr => CFG_AHBIO, ioen => IOAEN,
                 nahbm   => CFG_NCPU + CFG_AHB_UART + CFG_AHB_JTAG + CFG_GRETH,
                 devid   => ALTERA_DE2, nahbs => 8) 
    port map (rstn, clkm, ahbmi, ahbmo, ahbsi, ahbso);

----------------------------------------------------------------------
---                       Leon3 Processor                          ---
----------------------------------------------------------------------

  cpu : for i in 0 to CFG_NCPU-1 generate
    u0 : leon3s
      generic map (hindex     => i, fabtech => fabtech, memtech => memtech, nwindows => CFG_NWIN, dsu => CFG_DSU, fpu => CFG_FPU,
                   v8         => CFG_V8, cp => 0, mac => CFG_MAC, pclow => CFG_PCLOW, notag => CFG_NOTAG, nwp => CFG_NWP,
                   icen       => CFG_ICEN, irepl => CFG_IREPL, isets => CFG_ISETS, ilinesize => CFG_ILINE,
                   isetsize   => CFG_ISETSZ, isetlock => CFG_ILOCK, dcen => CFG_DCEN,
                   drepl      => CFG_DREPL, dsets => CFG_DSETS, dlinesize => CFG_DLINE, dsetsize => CFG_DSETSZ,
                   dsetlock   => CFG_DLOCK, dsnoop => CFG_DSNOOP, ilram => CFG_ILRAMEN, ilramsize => CFG_ILRAMSZ,
                   ilramstart => CFG_ILRAMADDR, dlram => CFG_DLRAMEN, dlramsize => CFG_DLRAMSZ, dlramstart => CFG_DLRAMADDR,
                   mmuen      => CFG_MMUEN, itlbnum => CFG_ITLBNUM, dtlbnum => CFG_DTLBNUM, tlb_type => CFG_TLB_TYPE,
                   tlb_rep    => CFG_TLB_REP, lddel => CFG_LDDEL, disas => CFG_DISAS, tbuf => CFG_ITBSZ,
                   pwd        => CFG_PWD, svt => CFG_SVT, rstaddr => CFG_RSTADDR, smp => CFG_NCPU-1,
                   cached     => 0, scantest => 0, mmupgsz => CFG_MMU_PAGE, bp => 1)
      port map (clk  => clkm, rstn => rstn, ahbi => ahbmi, ahbo => ahbmo(i), ahbsi => ahbsi, ahbso => ahbso,
                irqi => irqi(i), irqo => irqo(i), dbgi => dbgi(i), dbgo => dbgo(i));
  end generate;

----------------------------------------------------------------------
---                      Debug Support Unit                        ---
----------------------------------------------------------------------

  dsugen : if CFG_DSU = 1 generate
    dsu0 : dsu3                         -- LEON3 Debug Support Unit (slave)
      generic map (hindex => 2, haddr => 16#900#, hmask => 16#F00#,
                   ncpu   => CFG_NCPU, tbits => 30, tech => memtech, irq => 0, kbytes => CFG_ATBSZ)
      port map (rstn, clkm, ahbmi, ahbsi, ahbso(2), dbgo, dbgi, dsui, dsuo);
    dsui.enable <= '1';
    dsubre_pad : inpad generic map (tech => padtech) port map (dsubre, dsubren);  --knapp 1
    dsui.break  <= not dsubren;  --break 0 when button pressed => breaked when released => debug mode.
  end generate;
  nodsu : if CFG_DSU = 0 generate
    ahbso(2) <= ahbs_none; dsuo.tstop <= '0'; dsuo.active <= '0';  --no timer freeze, no light.
  end generate;

  errorn_pad : odpad generic map (tech => padtech) port map (errorn, dbgo(0).error);

----------------------------------------------------------------------
---                           AHB UART                             ---
----------------------------------------------------------------------

  dcomgen : if CFG_AHB_UART /= 0 generate
    dcom0 : ahbuart                     -- Debug UART
      generic map (hindex => CFG_NCPU, pindex => 7, paddr => 7)
      port map (rstn, clkm, dui, duo, apbi, apbo(7), ahbmi, ahbmo(CFG_NCPU));
    dsurx_pad : inpad generic map (tech  => padtech) port map (dsu_rxd, dui.rxd);
    dsutx_pad : outpad generic map (tech => padtech) port map (dsu_txd, duo.txd);
  end generate;
  nouah : if CFG_AHB_UART = 0 generate apbo(7) <= apb_none; end generate;

----------------------------------------------------------------------
---                           AHB JTAG                             ---
----------------------------------------------------------------------

  ahbjtaggen0 : if CFG_AHB_JTAG /= 0 generate
    ahbjtag0 : ahbjtag generic map(tech => fabtech, hindex => CFG_NCPU+CFG_AHB_UART)
      port map(rstn, clkm, tck, tms, tdi, tdo, ahbmi, ahbmo(CFG_NCPU+CFG_AHB_UART),
               open, open, open, open, open, open, open, gnd(0));
  end generate;

----------------------------------------------------------------------
---                     Memory Controllers                         ---
----------------------------------------------------------------------

  -- Initial vaues of Memory signals
  memi.writen <= '1'; memi.wrn <= "1111"; memi.bwidth <= "01";
  memi.bexcn  <= '1';

  romsel     <= not memo.romsn(0);
  rombusy    <= not romready;
  memi.brdyn <= not romready;

  -- The US write enable is shared for SDRAM and PROM / SRAM 
  mem_nwe <= sdo.sdwen and memo.writen;

  ethi.rx_clk <= eth_inclk;
  ethi.tx_clk <= eth_inclk;

  mem0 : if CFG_MCTRL_LEON2 /= 0 generate
    mctrl0 : mctrl generic map (hindex    => 3, pindex => 0,
                                paddr     => 0, srbanks => 0, ram8 => CFG_MCTRL_RAM8BIT,
                                ram16     => CFG_MCTRL_RAM16BIT, sden => CFG_MCTRL_SDEN,
                                invclk    => CFG_CLK_NOFB, sepbus => CFG_MCTRL_SEPBUS,
                                pageburst => CFG_MCTRL_PAGE, lowbus => 1)
      port map (rstn, clkm, memi, memo, ahbsi, ahbso(3), apbi, apbo(0), wpo, sdo);
    
    freset_pad : outpad generic map (tech => padtech)
      port map (bus_flash_nreset, rstn);
    
    fbusy_pad : inpad generic map (tech => padtech)
      port map (bus_flash_nbusy, romready);
    
    sdpads : if CFG_MCTRL_SDEN = 1 generate  -- SDRAM controller
      sdcke_pad : outpad generic map (tech => padtech)
        port map (bus_sdram_cke, sdo.sdcke(0));
      sdras_pad : outpad generic map (tech => padtech)
        port map (bus_sdram_nras, sdo.rasn);
      sdcas_pad : outpad generic map (tech => padtech)
        port map (bus_sdram_ncas, sdo.casn);
      sddqm_pad : outpadv generic map (width => 4, tech => padtech)
        port map (bus_nbe, sdo.dqm(3 downto 0));
    end generate;

    sdcsn_pad : outpad generic map (tech => padtech)
      port map (bus_sdram_ncs, sdo.sdcsn(0));

    addr_pad : outpadv generic map (width => 25, tech => padtech)
      port map (bus_a, memo.address(24 downto 0));

    roms_pad : outpad generic map (tech => padtech)
      port map (bus_flash_ncs, memo.romsn(0));
    
    ledcs_pad : outpad generic map (tech => padtech)
      port map (led_romcs, romsel);
    
    ledrdy_pad : outpad generic map (tech => padtech)
      port map (led_rombrdyn, rombusy);
    
    oen_pad : outpad generic map (tech => padtech)
      port map (bus_noe, memo.oen);

    wri_pad : outpad generic map (tech => padtech)
      port map (bus_nwe, mem_nwe);
    
    bdr : for i in 0 to 3 generate
      data_pad : iopadv generic map (tech => padtech, width => 8)
        port map (bus_d(31-i*8 downto 24-i*8), memo.data(31-i*8 downto 24-i*8),
                  memo.bdrive(i), memi.data(31-i*8 downto 24-i*8));
    end generate;
    
  end generate;
  nomem0 : if CFG_MCTRL_LEON2 = 0 generate ahbso(3) <= ahbs_none; end generate;

----------------------------------------------------------------------
---                     APB Bridge and Peripherals                 ---
----------------------------------------------------------------------

  apb0 : apbctrl
    generic map (hindex => 1, haddr => CFG_APBADDR)
    port map (rstn, clkm, ahbsi, ahbso(1), apbi, apbo);

----------------------------------------------------------------------
---                              UART 1                            ---
----------------------------------------------------------------------

  ua1 : if CFG_UART1_ENABLE /= 0 generate
    uart1 : apbuart
      generic map (pindex => 1, paddr => 1, pirq => 2, console => dbguart, fifosize => CFG_UART1_FIFO)
      port map (rstn, clkm, apbi, apbo(1), u1i, u1o);
    u1i.rxd    <= rxd1;
    u1i.ctsn   <= '0';
    u1i.extclk <= '0';
    txd1       <= u1o.txd;
    serrx_pad : inpad generic map (level  => cmos, voltage => x33v, tech => padtech) port map (uart_rxd, rxd1);
    sertx_pad : outpad generic map (level => cmos, voltage => x33v, tech => padtech) port map (uart_txd, txd1);
  end generate;
  noua0 : if CFG_UART1_ENABLE = 0 generate apbo(1) <= apb_none; end generate;

----------------------------------------------------------------------
---                     Interrupt Controller                       ---
----------------------------------------------------------------------

  irqctrl : if CFG_IRQ3_ENABLE /= 0 generate
    irqctrl0 : irqmp
      generic map (pindex => 2, paddr => 2, ncpu => CFG_NCPU)
      port map (rstn, clkm, apbi, apbo(2), irqo, irqi);
  end generate;
  irq3 : if CFG_IRQ3_ENABLE = 0 generate
    x : for i in 0 to CFG_NCPU-1 generate
      irqi(i).irl <= "0000";
    end generate;
    apbo(2) <= apb_none;
  end generate;

----------------------------------------------------------------------
---                     Timer Unit                                 ---
----------------------------------------------------------------------

  gpt : if CFG_GPT_ENABLE /= 0 generate
    timer0 : gptimer                    -- timer unit
      generic map (pindex => 3, paddr => 3, pirq => CFG_GPT_IRQ,
                   sepirq => CFG_GPT_SEPIRQ, sbits => CFG_GPT_SW, ntimers => CFG_GPT_NTIM,
                   nbits  => CFG_GPT_TW)
      port map (rstn, clkm, apbi, apbo(3), gpti, open);
    gpti.dhalt <= dsuo.tstop; gpti.extclk <= '0';

  end generate;
  notim : if CFG_GPT_ENABLE = 0 generate apbo(3) <= apb_none; end generate;

----------------------------------------------------------------------
---                    Ethernet MAC                                ---
----------------------------------------------------------------------

  eth0 : if CFG_GRETH = 1 generate
    e1 : greth
      generic map(hindex       => CFG_NCPU+CFG_AHB_UART+CFG_AHB_JTAG,
                  pindex       => 4, paddr => 4, pirq => 4, memtech => memtech,
                  mdcscaler    => CPU_FREQ/1000, enable_mdio => 1, fifosize => CFG_ETH_FIFO,
                  nsync        => 2, edcl => CFG_DSU_ETH, edclbufsz => CFG_ETH_BUF,
                  macaddrh     => CFG_ETH_ENM, macaddrl => CFG_ETH_ENL, phyrstadr => 1,
                  ipaddrh      => CFG_ETH_IPM, ipaddrl => CFG_ETH_IPL,
                  enable_mdint => 0)
      port map(rst   => rstn, clk => clkm, ahbmi => ahbmi,
               ahbmo => ahbmo(CFG_NCPU+CFG_AHB_UART+CFG_AHB_JTAG),
               apbi  => apbi, apbo => apbo(4), ethi => ethi, etho => etho);
  end generate;

  ethpads : if (CFG_GRETH = 1) generate
    emdio_pad : iopad generic map (level => cmos, voltage => x33v, tech => padtech)
      port map (emdio, etho.mdio_o, etho.mdio_oe, ethi.mdio_i);
    erxc_pad : clkpad generic map (level => cmos, voltage => x33v, tech => padtech)
      port map (erx_clk, eth_inclk);
    erxd_pad : inpadv generic map (level => cmos, voltage => x33v, tech => padtech, width => 4)
      port map (erxd, ethi.rxd(3 downto 0));
    erxdv_pad : inpad generic map (level => cmos, voltage => x33v, tech => padtech)
      port map (erx_dv, ethi.rx_dv);
    erxer_pad : inpad generic map (level => cmos, voltage => x33v, tech => padtech)
      port map (erx_er, ethi.rx_er);
    erxco_pad : inpad generic map (level => cmos, voltage => x33v, tech => padtech)
      port map (erx_col, ethi.rx_col);
    erxcr_pad : inpad generic map (level => cmos, voltage => x33v, tech => padtech)
      port map (erx_crs, ethi.rx_crs);
    etxd_pad : outpadv generic map (level => cmos, voltage => x33v, tech => padtech, width => 4)
      port map (etxd, etho.txd(3 downto 0));
    etxen_pad : outpad generic map (level => cmos, voltage => x33v, tech => padtech)
      port map (etx_en, etho.tx_en);
    emdc_pad : outpad generic map (level => cmos, voltage => x33v, tech => padtech)
      port map (emdc, etho.mdc);
    emrst_pad : outpad generic map (level => cmos, voltage => x33v, tech => padtech)
      port map (erstn, etho.reset);
  end generate;
  noeth : if CFG_GRETH = 0 generate apbo(4) <= apb_none; end generate;

-----------------------------------------------------------------------
---  Test report module  ----------------------------------------------
-----------------------------------------------------------------------

-- pragma translate_off

  test0 : ahbrep generic map (hindex => 7, haddr => 16#A00#)
    port map (rstn, clkm, ahbsi, ahbso(7));

-- pragma translate_on

-----------------------------------------------------------------------
---  Boot message  ----------------------------------------------------
-----------------------------------------------------------------------

-- pragma translate_off
  x : report_version
    generic map (
      msg1 => "LEON3 Altium Nano3000 design",
      msg2 => "GRLIB Version " & tost(LIBVHDL_VERSION/1000) & "." & tost((LIBVHDL_VERSION mod 1000)/100)
      & "." & tost(LIBVHDL_VERSION mod 100) & ", build " & tost(LIBVHDL_BUILD),
      msg3 => "Target technology: " & tech_table(fabtech) & ",  memory library: " & tech_table(memtech),
      mdel => 1
      );
-- pragma translate_on
end;
