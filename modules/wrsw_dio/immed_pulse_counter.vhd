-------------------------------------------------------------------------------
-- Entity: immed_pulse counter
-- File: immed_pulse counter.vhd
-- Description: a simple synchronous output based on asynchronous strobe inputs that produces a N-ticks 
-- length pulse.
-- Author: Javier Díaz (jdiaz@atc.ugr.es)
-- Date: 9 July 2012
-- Version: 0.01
-- Properties: 
-- TBD
-- Todo: 
-- TBD
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
use ieee.numeric_std.all; 

entity immed_pulse_counter is
  
  generic (
-- reference clock frequency
    pulse_length_width : integer := 28
  );

  port (
    clk_i          : in std_logic;    
    rst_n_i        : in std_logic;      -- asynchronous system reset
    
	 pulse_start_i  : in std_logic;      -- asynchronous strobe for pulse generation
    pulse_length_i : in std_logic_vector(pulse_length_width-1 downto 0); -- asynchronous signal
  
    pulse_output_o : out std_logic
  );

end immed_pulse_counter;

architecture rtl of immed_pulse_counter is
 
  -- Internal registers to hold pulse duration
  signal counter : unsigned (pulse_length_width-1 downto 0);
  
  -- Signals for states
  type counter_state is (WAIT_ST, COUNTING);
  signal state   : counter_state;
  
  -- Signal for synchronization (in fact they are not so necessary for current system...)
  signal pulse_start_d0, pulse_start_d1, pulse_start_d2, pulse_start_d3 : std_logic; 
  signal nozerolength, nozerolength_aux                                 : boolean; 
  
  -- Aux
  constant zeros : std_logic_vector(pulse_length_width-1 downto 0) := (others=>'0');  
  
begin  -- architecture rtl



  synchronization: process(clk_i, rst_n_i)
  begin
	 if (rst_n_i='0') then
		pulse_start_d0  <='0';
		pulse_start_d1  <='0';
		pulse_start_d2  <='0';		
		pulse_start_d3  <='0';		
	 elsif rising_edge(clk_i) then
		pulse_start_d0<=pulse_start_i;
		pulse_start_d1<=pulse_start_d0;
		pulse_start_d2<=pulse_start_d1;
	   pulse_start_d3<=pulse_start_d2;
		nozerolength_aux<=pulse_length_i/=zeros;
		if (pulse_start_d2='1' and pulse_start_d1='0') then
			nozerolength<=nozerolength_aux;
		end if;
    end if;		
  end process;  

  state_process : process(clk_i, rst_n_i)
  begin
	 if (rst_n_i='0') then
      counter      <=(others=>'0');
      state        <=WAIT_ST;
	 elsif rising_edge(clk_i) then
      case state is
        when WAIT_ST =>
		    if pulse_start_d3='1' and nozerolength then
			   state   <=COUNTING;
				counter <=unsigned(pulse_length_i)-1;
			  else 
			    state<=WAIT_ST;
			  end if;
        when COUNTING =>
		    if (counter=0) then
			   state  <= WAIT_ST;
			 else 
				state  <= COUNTING; 
				counter<=counter-1;
			 end if;
        when others =>
		    state<=WAIT_ST;
      end case;
    end if;		
  end process;  


  output_process:process(counter, state)
  begin
    if (rst_n_i='0') then
      pulse_output_o <='0';
	 else
      case state is
        when WAIT_ST  =>
          pulse_output_o <='0';
        when COUNTING =>
			   pulse_output_o <='1';
        when others =>
          pulse_output_o <='0';
      end case;		  
    end if;
  end process;  
	 
end architecture rtl;
