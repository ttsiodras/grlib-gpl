-----------------------------------------------------------------------------
--  LEON3 Demonstration design test bench
--  Copyright (C) 2016 Cobham Gaisler
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
  signal dsu_tx : std_logic;
  signal dsu_rx : std_logic;

  component leon3mp
    port (
      clk   : in  std_ulogic;       -- main clock
      resetn : in  std_ulogic;
      iu_error : out std_ulogic;
      dsuact : out std_ulogic;
      dsu_rx : out std_ulogic; -- UART1 tx data
      dsu_tx : in  std_ulogic  -- UART1 rx data
  );
  end component;

  constant CLK_PERIOD : time := 20 ns;

begin
  d3 : leon3mp
    port map (
        clk => CLK,
        resetn => rstn,
        iu_error => iu_error,
        dsuact => dsuact,
        dsu_rx => dsu_rx,
        dsu_tx => dsu_tx
    );

  clk <= not clk after CLK_PERIOD/2;

  process
  begin
    wait for 50*CLK_PERIOD;
    if to_x01(iu_error) = '0' then wait on iu_error; end if;
    assert (to_x01(iu_error) = '0') 
      report "*** IU in error mode, simulation halted ***"
      severity failure;  
  end process;

  dsucom : process
    procedure dsucfg(signal dsurx : in std_ulogic; signal dsutx : out std_ulogic) is
      variable w32 : std_logic_vector(31 downto 0);
      variable c8  : std_logic_vector(7 downto 0);
      constant txp : time := 320 * 1 ns;
      variable l : line;
    begin
      dsutx <= '1';
      write(l, String'("Resetting for 40 cycles"));
      writeline(output, l);
      rstn <= '1';
      wait for 40*CLK_PERIOD;
      rstn <= '0';
      write(l, String'("Reset complete."));
      writeline(output, l);
      write(l, String'("Waiting for peripherals to settle."));
      writeline(output, l);
    end procedure;
  begin
    dsucfg(dsu_tx, dsu_rx);
    wait;
  end process;
end;
