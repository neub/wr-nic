-------------------------------------------------------------------------------
-- Entity: dummy_time
-- File: dummy_time.vhd
-- Description: ¿?
-- Author: Javier Diaz (jdiaz@atc.ugr.es)
-- Date: 8 March 2012
-- Version: 0.01
-- To do: 
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--               GNU LESSER GENERAL PUBLIC LICENSE                             
--              -----------------------------------                            
-- This source file is free software; you can redistribute it and/or modify it
-- under the terms of the GNU Lesser General Public License as published by the
-- Free Software Foundation; either version 2.1 of the License, or (at your
-- option) any later version.                           
-- This source is distributed in the hope that it will be useful, but WITHOUT
-- ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
-- for more details. You should have received a copy of the GNU Lesser General
-- Public License along with this source; if not, download it from
-- http://www.gnu.org/licenses/lgpl-2.1.html                  
-------------------------------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;
--use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all; 

entity dummy_time is
	port(clk_sys : in std_logic;           -- data output reference clock 125MHz
	     rst_n: in std_logic; -- system reset
	     -- utc time in seconds	
    	     tm_utc        : out std_logic_vector(39 downto 0);
    	     -- number of clk_ref_i cycles
    	     tm_cycles     : out std_logic_vector(27 downto 0));
end dummy_time;

architecture Behavioral of dummy_time is

	signal OneSecond: std_logic;
	signal tm_cycles_Aux: std_logic_vector(27 downto 0);
	signal tm_utc_Aux: std_logic_vector(39 downto 0);
	constant MaxCountcycles1: std_logic_vector(27 downto 0) :="0111011100110101100100111111"; --125.000.000-1
	constant MaxCountcycles2: std_logic_vector(27 downto 0) :="0111011100110101100101000000"; --125.000.000
	constant AllOnesUTC: std_logic_vector(39 downto 0):=(others=>'1');
begin
---------------------------------------
-- Process to count cycles in a second
---------------------------------------

P_CountTM_cycles:
process(rst_n, clk_sys)
begin
	if(rst_n = '0') then
		tm_cycles_Aux <= (others=>'0');
		oneSecond <= '0';
	elsif(rising_Edge(Clk_sys)) then
		if (Tm_cycles_Aux /= MaxCountcycles2) then
			tm_cycles_Aux <= tm_cycles_Aux + 1;
		else
			tm_cycles_Aux <= (others=>'0');
		end if;
		
		if(Tm_cycles_Aux = MaxCountcycles1) then
			OneSecond <= '1';
		else
			OneSecond <= '0';
		end if;
	end if;
end process P_CountTM_cycles;

P_CountTM_UTC:
process(rst_n, clk_sys)
begin
	if(rst_n = '0') then
		tm_utc_Aux <= (others=>'0');
	elsif(rising_edge(Clk_sys)) then
		if (OneSecond='1') then
			if (tm_utc_Aux /= AllOnesUTC) then
				tm_utc_Aux <= tm_utc_Aux + 1;
			else
				tm_utc_Aux <= (others=>'0');
			end if;
		end if;
	end if;
end process P_CountTM_UTC;

tm_cycles <= tm_cycles_Aux;
tm_utc <= tm_utc_Aux;

end Behavioral;

