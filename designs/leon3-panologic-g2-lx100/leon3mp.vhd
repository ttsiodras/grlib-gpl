-----------------------------------------------------------------------------
--  I adapted this code for my ZestSC1 board, based on the LEON3 design
--  for the leon3-digilent-xc3s1000.
--
--  Original Copyright is:
--
--  Copyright (C) 2004 Jiri Gaisler, Gaisler Research
------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2003 - 2008, Gaisler Research
--  Copyright (C) 2008 - 2014, Aeroflex Gaisler
--  Copyright (C) 2015 - 2017, Cobham Gaisler
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


library ieee;
use ieee.std_logic_1164.all;
library grlib, techmap;
use grlib.amba.all;
use grlib.stdlib.all;
use techmap.gencomp.all;
library gaisler;
use gaisler.memctrl.all;
use gaisler.leon3.all;
use gaisler.uart.all;
use gaisler.misc.all;
use gaisler.jtag.all;
-- pragma translate_off
use gaisler.sim.all;
-- pragma translate_on

library esa;
use esa.memoryctrl.all;

use work.config.all;

entity leon3mp is
  generic (
    fabtech       : integer := CFG_FABTECH;
    memtech       : integer := CFG_MEMTECH;
    padtech       : integer := CFG_PADTECH;
    clktech       : integer := CFG_CLKTECH;
    disas         : integer := CFG_DISAS;	-- Enable disassembly to console
    dbguart       : integer := CFG_DUART;	-- Print UART on console
    pclow         : integer := CFG_PCLOW;
    use_ahbram_sim          : integer := 0
  );
  port (
    resetn        : in  std_ulogic;
    clk           : in  std_ulogic;
    iu_error      : out std_ulogic;
    dsuact        : out std_ulogic;
    rx            : out std_ulogic;
    tx            : in  std_ulogic --;
    -- tck, tms, tdi : in std_ulogic;
    -- tdo           : out std_ulogic
  );
end;

architecture rtl of leon3mp is

   constant blength : integer := 12;
   constant fifodepth : integer := 8;
   constant maxahbm : integer := CFG_NCPU+CFG_AHB_JTAG; -- A truly "Spartan" set of AHB masters :-)
   
   signal vcc, gnd   : std_logic_vector(4 downto 0);
   signal memi  : memory_in_type;
   signal memo  : memory_out_type;
   signal wpo   : wprot_out_type;
   signal sdi   : sdctrl_in_type;
   signal sdo   : sdram_out_type;
   
   signal apbi  : apb_slv_in_type;
   signal apbo  : apb_slv_out_vector := (others => apb_none);
   signal ahbsi : ahb_slv_in_type;
   signal ahbso : ahb_slv_out_vector := (others => ahbs_none);
   signal ahbmi : ahb_mst_in_type;
   signal ahbmo : ahb_mst_out_vector := (others => ahbm_none);
   
   signal clkm, rstn, rstraw, nerror : std_ulogic;
   signal cgi   : clkgen_in_type;
   signal cgo   : clkgen_out_type;
   signal u1i, u2i, dui : uart_in_type;
   signal u1o, u2o, duo : uart_out_type;
   
   signal irqi : irq_in_vector(0 to CFG_NCPU-1);
   signal irqo : irq_out_vector(0 to CFG_NCPU-1);
   
   signal dbgi : l3_debug_in_vector(0 to CFG_NCPU-1);
   signal dbgo : l3_debug_out_vector(0 to CFG_NCPU-1);
   
   signal dsui : dsu_in_type;
   signal dsuo : dsu_out_type; 
   
   signal gpti : gptimer_in_type;
   
   signal gpioi : gpio_in_type;
   signal gpioo : gpio_out_type;
   
   signal lclk : std_ulogic;
   signal tck, tms, tdi, tdo : std_ulogic;
   
   -- my ZestSC1 board's frequency in KHz
   constant BOARD_FREQ : integer := 25000;
   -- cpu frequency in KHz will be 25000 - as per my S/P/R results,
   -- my design can easily reach this speed.
   constant CPU_FREQ : integer := BOARD_FREQ * CFG_CLKMUL / CFG_CLKDIV;
   constant IOAEN : integer := 0;
   
   attribute keep : boolean;
   attribute syn_keep : boolean;
   attribute syn_preserve : boolean;
   
  -- A "heartbeat" LED for the DSU - I used it to make sure the
  -- locally instantiated clock here beats indeed at 25MHz
  -- (search below for 25000000 to see the logic)
  signal counter_dsu : integer := 0;
  signal heartbeat_led_dsu : std_logic := '1';
begin

----------------------------------------------------------------------
---  Reset and Clock generation  -------------------------------------
----------------------------------------------------------------------
  
  vcc <= (others => '1'); gnd <= (others => '0');
  cgi.pllctrl <= "00"; cgi.pllrst <= rstraw;

  -- clk_pad : clkpad generic map (tech => padtech) port map (clk, lclk); 
  lclk <= clk;

  clkgen0 : clkgen  		-- clock generator
    generic map (clktech, CFG_CLKMUL, CFG_CLKDIV, CFG_MCTRL_SDEN, CFG_CLK_NOFB, 0, 0, 0, BOARD_FREQ)
    port map (lclk, lclk, clkm, open, open, open, open, cgi, cgo, open, open);

  rst0 : rstgen			-- reset generator
  generic map (acthigh => 1)
  port map (resetn, clkm, cgo.clklock, rstn, rstraw);

----------------------------------------------------------------------
---  AHB CONTROLLER --------------------------------------------------
----------------------------------------------------------------------

  ahb0 : ahbctrl 		-- AHB arbiter/multiplexer
  generic map (defmast => CFG_DEFMST, split => CFG_SPLIT, 
	rrobin => CFG_RROBIN, ioaddr => CFG_AHBIO,
	ioen => IOAEN, nahbm => maxahbm, nahbs => 8)
  port map (rstn, clkm, ahbmi, ahbmo, ahbsi, ahbso);

----------------------------------------------------------------------
---  LEON3 processor and DSU -----------------------------------------
----------------------------------------------------------------------

  l3 : if CFG_LEON3 = 1 generate
    cpu : for i in 0 to CFG_NCPU-1 generate
      u0 : leon3s			-- LEON3 processor      
      generic map (i, fabtech, memtech, CFG_NWIN, CFG_DSU, CFG_FPU, CFG_V8, 
  	0, CFG_MAC, pclow, CFG_NOTAG, CFG_NWP, CFG_ICEN, CFG_IREPL, CFG_ISETS, CFG_ILINE, 
  	CFG_ISETSZ, CFG_ILOCK, CFG_DCEN, CFG_DREPL, CFG_DSETS, CFG_DLINE, CFG_DSETSZ,
  	CFG_DLOCK, CFG_DSNOOP, CFG_ILRAMEN, CFG_ILRAMSZ, CFG_ILRAMADDR, CFG_DLRAMEN,
        CFG_DLRAMSZ, CFG_DLRAMADDR, CFG_MMUEN, CFG_ITLBNUM, CFG_DTLBNUM, CFG_TLB_TYPE, CFG_TLB_REP, 
        CFG_LDDEL, disas, CFG_ITBSZ, CFG_PWD, CFG_SVT, CFG_RSTADDR, CFG_NCPU-1,
        CFG_DFIXED, CFG_SCAN, CFG_MMU_PAGE, CFG_BP, CFG_NP_ASI, CFG_WRPSR)
      port map (clkm, rstn, ahbmi, ahbmo(i), ahbsi, ahbso, 
      		irqi(i), irqo(i), dbgi(i), dbgo(i));
    end generate;
    nerror <= not dbgo(0).error;
    error_pad : outpad generic map (tech => padtech) port map (iu_error, nerror);
    
    dsugen : if CFG_DSU = 1 generate
      dsu0 : dsu3			-- LEON3 Debug Support Unit
      generic map (hindex => 2, haddr => 16#900#, hmask => 16#F00#, 
         ncpu => CFG_NCPU, tbits => 30, tech => memtech, irq => 0, kbytes => CFG_ATBSZ)
      port map (rstn, clkm, ahbmi, ahbsi, ahbso(2), dbgo, dbgi, dsui, dsuo);
      dsui.enable <= '1'; 
      dsui.break <= '0'; 
      dsuact_pad : outpad generic map (tech => padtech) port map (dsuact, dsuo.active);
    end generate;
  end generate;
  nodsu : if CFG_DSU = 0 generate 
    dsuo.tstop <= '0'; dsuo.active <= '0';
  end generate;

  ahbjtaggen0 :if CFG_AHB_JTAG = 1 generate
    ahbjtag0 : ahbjtag generic map(tech => fabtech, hindex => 1)
      port map(rstn, clkm, tck, tms, tdi, tdo, ahbmi, ahbmo(1),
               open, open, open, open, open, open, open, gnd(0));
  end generate;

  -- To verify that the clock shenanigans actually work on my board,
  -- I hooked this up to LED6 (i.e. the 2nd from the right) and
  -- confirmed that the clock driving the LEON3 and the DSU and all
  -- the rest is indeed a 25MHz clock.
  process(clkm)
  begin
      if rising_edge(clkm) then
        counter_dsu <= counter_dsu + 1;
        if counter_dsu = 25000000 then
            counter_dsu <= 0;
            -- IO(45) <= heartbeat_led_dsu;
            heartbeat_led_dsu <= not heartbeat_led_dsu;
        end if;
      end if;
  end process;

----------------------------------------------------------------------
---  APB Bridge and various periherals -------------------------------
----------------------------------------------------------------------

  apb0 : apbctrl				-- AHB/APB bridge
  generic map (hindex => 1, haddr => CFG_APBADDR, nslaves => 16)
  port map (rstn, clkm, ahbsi, ahbso(1), apbi, apbo );

  ua1 : if CFG_UART1_ENABLE /= 0 generate
    uart1 : apbuart			-- UART 1
    generic map (pindex => 1, paddr => 1,  pirq => 2, console => dbguart,
	fifosize => CFG_UART1_FIFO)
    port map (rstn, clkm, apbi, apbo(1), u1i, u1o);
    u1i.extclk <= '0';
    rxd1_pad : inpad generic map (tech => padtech) port map (tx, u1i.rxd); 
    txd1_pad : outpad generic map (tech => padtech) port map (rx, u1o.txd);
  end generate;
  noua0 : if CFG_UART1_ENABLE = 0 generate apbo(1) <= apb_none; end generate;

  irqctrl : if CFG_IRQ3_ENABLE /= 0 generate
    irqctrl0 : irqmp			-- interrupt controller
    generic map (pindex => 2, paddr => 2, ncpu => CFG_NCPU)
    port map (rstn, clkm, apbi, apbo(2), irqo, irqi);
  end generate;
  irq3 : if CFG_IRQ3_ENABLE = 0 generate
    xx : for i in 0 to CFG_NCPU-1 generate
      irqi(i).irl <= "0000";
    end generate;
    apbo(2) <= apb_none;
  end generate;

  gpt : if CFG_GPT_ENABLE /= 0 generate
    timer0 : gptimer 			-- timer unit
    generic map (pindex => 3, paddr => 3, pirq => CFG_GPT_IRQ, 
	sepirq => CFG_GPT_SEPIRQ, sbits => CFG_GPT_SW, ntimers => CFG_GPT_NTIM, 
	nbits => CFG_GPT_TW)
    port map (rstn, clkm, apbi, apbo(3), gpti, open);
    gpti <= gpti_dhalt_drive(dsuo.tstop);
  end generate;

  nogpt : if CFG_GPT_ENABLE = 0 generate apbo(3) <= apb_none; end generate;

-----------------------------------------------------------------------
---  AHB RAM ----------------------------------------------------------
-----------------------------------------------------------------------

  ahbramgen : if CFG_AHBRAMEN = 1 generate
--pragma translate_off
    phys : if use_ahbram_sim = 0 generate
--pragma translate_on
    ahbram0 : ahbram
      generic map (hindex => 3, haddr => CFG_AHBRADDR, tech => CFG_MEMTECH,
                   kbytes => CFG_AHBRSZ, pipe => CFG_AHBRPIPE)
      port map (rstn, clkm, ahbsi, ahbso(3));
--pragma translate_off
    end generate;
    simram : if use_ahbram_sim /= 0 generate
      ahbram0 : ahbram_sim
      generic map (hindex => 3, haddr => CFG_AHBRADDR, tech => CFG_MEMTECH,
                   kbytes => 1024, pipe => CFG_AHBRPIPE, fname => "ram.srec")
      port map (rstn, clkm, ahbsi, ahbso(3));
    end generate;
--pragma translate_on
  end generate;
  nram : if CFG_AHBRAMEN = 0 generate ahbso(3) <= ahbs_none; end generate;

-----------------------------------------------------------------------
---  Test report module  ----------------------------------------------
-----------------------------------------------------------------------

-- pragma translate_off

  test0 : ahbrep generic map (hindex => 4, haddr => 16#200#)
	port map (rstn, clkm, ahbsi, ahbso(4));

-- pragma translate_on

-----------------------------------------------------------------------
---  Boot message  ----------------------------------------------------
-----------------------------------------------------------------------

-- pragma translate_off
  x : report_design
  generic map (
   msg1 => "Panologic G2 LX100 Demonstration design",
   fabtech => tech_table(fabtech), memtech => tech_table(memtech),
   mdel => 1
  );
-- pragma translate_on

end;
