library ieee;
use ieee.std_logic_1164.all;

use work.wrcore_pkg.all;

library work;
package wrsw_txtsu_pkg is

-- This record is in "wrsw_txtsu_pkg" too
--  type t_txtsu_timestamp is record
--    valid: std_logic;
--    tsval : std_logic_vector(31 downto 0);
--    port_id: std_logic_vector(5 downto 0);
--    frame_id: std_logic_vector(15 downto 0);
--  end record;

  type t_txtsu_timestamp_array is array(integer range <>) of t_txtsu_timestamp;

end wrsw_txtsu_pkg;
