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
library gaisler;
use gaisler.libdcom.all;
use gaisler.sim.all;
use gaisler.jtagtst.all;
library techmap;
use techmap.gencomp.all;
use std.textio.all;
use work.debug.all;
use work.config.all;

entity testbench is
  generic (
    fabtech   : integer := CFG_FABTECH;
    memtech   : integer := CFG_MEMTECH;
    padtech   : integer := CFG_PADTECH;
    clktech   : integer := CFG_CLKTECH;
    disas     : integer := CFG_DISAS;   -- Enable disassembly to console
    dbguart   : integer := CFG_DUART;   -- Print UART on console
    pclow     : integer := CFG_PCLOW
    );
end;

architecture behav of testbench is
  constant lresp : boolean := false;

  signal clk : std_ulogic := '0';
  signal rstn : std_ulogic := '1';
  signal iu_error : std_ulogic;
  signal dsuact : std_ulogic;
  signal tx : std_logic;
  signal rx : std_logic;
  signal tck, tms, tdi : std_ulogic;
  signal tdo : std_ulogic;

  component leon3mp
    port (
      clk   : in  std_ulogic;  -- main clock
      resetn : in  std_ulogic;
      iu_error : out std_ulogic;
      dsuact : out std_ulogic;
      rx : out std_ulogic; -- UART1 tx data
      tx : in  std_ulogic; -- UART1 rx data
      tck, tms, tdi : in std_ulogic;
      tdo : out std_ulogic;
      IO : inout std_logic_vector(46 downto 0)
  );
  end component;

  constant CLK_PERIOD : time := 20 ns;

begin
  d3 : leon3mp
    port map (
        resetn => rstn,
        clk => CLK,
        iu_error => iu_error,
        dsuact => dsuact,
        rx => rx,
        tx => tx,
        tck => tck,
        tms => tms,
        tdi => tdi,
        tdo => tdo
    );

  clk <= not clk after CLK_PERIOD/2;

  process
  begin
    wait for 30000*CLK_PERIOD;
    if to_x01(iu_error) = '0' then wait on iu_error; end if;
    assert (to_x01(iu_error) = '0') 
      report "*** IU in error mode, simulation halted ***"
      severity failure;  
  end process;

  jtagproc : process
    variable l : line;
  begin
    write(l, String'("Resetting for 40 cycles"));
    writeline(output, l);
    rstn <= '1';
    wait for 40*CLK_PERIOD;
    rstn <= '0';
    wait for 10*CLK_PERIOD;

    wait for 5000 ns;

    -- jtagcom(tdo, tck, tms, tdi, 100, 20, 16#40000000#, true);
    -- wait for 990000 ns;

    write(l, String'("Test completed."));
    writeline(output, l);
    assert false report "Reached end of test" severity failure;
    wait;
   end process;

end;
