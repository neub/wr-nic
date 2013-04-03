-------------------------------------------------------------------------------
-- Title      : WhiteRabbit Network Interface Card
-- Project    : WhiteRabbit
-------------------------------------------------------------------------------
-- File       : wrnic_sdb_pkg.vhd
-- Author     : Javier Díaz
-- Company    : Seven Solutions, UGR
-- Created    : 2012-07-18
-- Last update: 2012-06-19
-- Platform   : FPGA-generics
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description:
-- Standard data bus (SDB) definitions for White Rabbit Network Interface Card (WR NIC=
-- #
-------------------------------------------------------------------------------
-- Copyright (c) 2012 Javier Díaz
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2012-07-18  1.0      jdiaz           Created
-- 
-------------------------------------------------------------------------------
-- TODO: Move SDB devices definition to the corresponing package when merge

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.wishbone_pkg.all;

package wrnic_sdb_pkg is

  -----------------------------------------------------------------------------
  -- WR CORE --> TBD: move to wrcore_pkg
  -----------------------------------------------------------------------------
  constant c_xwr_core_sdb : t_sdb_product := (
    vendor_id     => x"000000000000CE42", -- CERN
    device_id     => x"00000011",
    version       => x"00000003",
    date          => x"20120305",
    name          => "WR-CORE            ");
	  
  -----------------------------------------------------------------------------
  -- WR NIC 
  -----------------------------------------------------------------------------
  constant c_xwrsw_nic_sdb : t_sdb_device := (
    abi_class     => x"0000", -- undocumented device
    abi_ver_major => x"01",
    abi_ver_minor => x"01",
    wbd_endian    => c_sdb_endian_big,
    wbd_width     => x"7", -- 8/16/32-bit port granularity
    sdb_component => (
    addr_first    => x"0000000000000000",
    addr_last     => x"000000000001ffff",  -- I think this is overestimated
    product => (
    vendor_id     => x"000000000000CE42", -- CERN
    device_id     => x"00000012",
    version       => x"00000001",
    date          => x"20000101",         -- UNKNOWN
    name          => "WR-NIC             ")));	 

  -----------------------------------------------------------------------------
  -- WR TXTSU --> TBD: Move to wrsw_txtsu_pkg
  -----------------------------------------------------------------------------
  constant c_xwrsw_txtsu_sdb : t_sdb_device := (
    abi_class     => x"0000", -- undocumented device
    abi_ver_major => x"01",
    abi_ver_minor => x"01",
    wbd_endian    => c_sdb_endian_big,
    wbd_width     => x"7", -- 8/16/32-bit port granularity
    sdb_component => (
    addr_first    => x"0000000000000000",
    addr_last     => x"00000000000000ff",
    product => (
    vendor_id     => x"000000000000CE42", -- CERN
    device_id     => x"00000014",
    version       => x"00000001",
    date          => x"20120316",
    name          => "WR-TXTSU           ")));	 
	 
  -----------------------------------------------------------------------------
  -- WRSW DIO 
  -----------------------------------------------------------------------------
  constant c_xwrsw_dio_sdb : t_sdb_product := (
    vendor_id     => x"00000000000075CB", -- SEVEN SOLUTIONS
    device_id     => x"00000002",
    version       => x"00000002",
    date          => x"20120720",
    name          => "WR-DIO-Core        ");	 

  -----------------------------------------------------------------------------
  -- WRSW DIO REGISTERS - (basic slave from wbgen2)
  -----------------------------------------------------------------------------
  constant c_xwrsw_dio_wb_sdb : t_sdb_device := (
    abi_class     => x"0000", -- undocumented device
    abi_ver_major => x"01",
    abi_ver_minor => x"01",
    wbd_endian    => c_sdb_endian_big,
    wbd_width     => x"7", -- 8/16/32-bit port granularity
    sdb_component => (
    addr_first    => x"0000000000000000",
    addr_last     => x"00000000000000ff",
    product => (
    vendor_id     => x"00000000000075CB", -- SEVEN SOLUTIONS
    device_id     => x"00000001",
    version       => x"00000002",
    date          => x"20120709",
    name          => "WR-DIO-Registers   ")));	 	

  -------------------------------------------------------------------------------
  -- WB ONEWIRE MASTER --> TBD: move wishbone_pkg
  -- ISSUE: this element have two sdb definitions with different names, this one 
  -- and the one available at WR_CORE_PKG. 
  -- The definition need to be unique and be included into wishbone_pkg
  -------------------------------------------------------------------------------

--  constant c_xwb_onewire_master_sdb : t_sdb_device := (
--    abi_class     => x"0000", -- undocumented device
--    abi_ver_major => x"01",
--    abi_ver_minor => x"01",
--    wbd_endian    => c_sdb_endian_big,
--    wbd_width     => x"7", -- 8/16/32-bit port granularity
--    sdb_component => (
--    addr_first    => x"0000000000000000",
--    addr_last     => x"00000000000000ff",
--    product => (
--    vendor_id     => x"000000000000CE42", -- CERN
--    device_id     => x"779c5443",
--    version       => x"00000001",
--    date          => x"20120305",
--    name          => "WR-1Wire-master    ")));	 
	 

  -------------------------------------------------------------------------------
  -- WB I2C MASTER --> TBD: move to wishbone_pkg
  -------------------------------------------------------------------------------

--  constant c_xwb_i2c_master_sdb : t_sdb_device := (
--    abi_class     => x"0000", -- undocumented device
--    abi_ver_major => x"01",
--    abi_ver_minor => x"01",
--    wbd_endian    => c_sdb_endian_big,
--    wbd_width     => x"7", -- 8/16/32-bit port granularity
--    sdb_component => (
--    addr_first    => x"0000000000000000",
--    addr_last     => x"00000000000000ff",
--    product => (
--    vendor_id     => x"000000000000CE42", -- CERN
--    device_id     => x"123c5443",
--    version       => x"00000001",
--    date          => x"20000101",         -- UNKNOWN
--    name          => "WB-I2C-Master      ")));	 

  -------------------------------------------------------------------------------
  -- WB GPIO --> TBD: move to wishbone_pkg
  -------------------------------------------------------------------------------

--  constant c_xwb_gpio_port_sdb : t_sdb_device := (
--    abi_class     => x"0000", -- undocumented device
--    abi_ver_major => x"01",
--    abi_ver_minor => x"01",
--    wbd_endian    => c_sdb_endian_big,
--    wbd_width     => x"7", -- 8/16/32-bit port granularity
--    sdb_component => (
--    addr_first    => x"0000000000000000",
--    addr_last     => x"00000000000000ff",
--    product => (
--    vendor_id     => x"000000000000CE42", -- CERN
--    device_id     => x"441c5143",
--    version       => x"00000001",
--    date          => x"20000101",         -- UNKNOWN
--    name          => "WB-GPIO-Port       ")));	 	 

------------------------------------------------------------------------------
-- SDB re-declaration of bridges function to include product info
------------------------------------------------------------------------------
 
  -- Use the f_xwb_bridge_*_sdb to bridge a crossbar to another
  function f_xwb_bridge_product_manual_sdb( -- take a manual bus size
      g_size        : t_wishbone_address;
      g_sdb_addr    : t_wishbone_address;
		g_sdb_product : t_sdb_product) return t_sdb_bridge;

  function f_xwb_bridge_product_layout_sdb( -- determine bus size from layout
      g_wraparound  : boolean := true;
      g_layout      : t_sdb_record_array;
      g_sdb_addr    : t_wishbone_address;
		g_sdb_product : t_sdb_product) return t_sdb_bridge;


end wrnic_sdb_pkg;

package body wrnic_sdb_pkg is	 
	 	 
  function f_xwb_bridge_product_manual_sdb(
    g_size       : t_wishbone_address;
    g_sdb_addr   : t_wishbone_address;
	 g_sdb_product: t_sdb_product) return t_sdb_bridge	 
  is
    variable result : t_sdb_bridge;
  begin
    result.sdb_child := (others => '0');
    result.sdb_child(c_wishbone_address_width-1 downto 0) := g_sdb_addr;
    
    result.sdb_component.addr_first := (others => '0');
    result.sdb_component.addr_last  := (others => '0');
    result.sdb_component.addr_last(c_wishbone_address_width-1 downto 0) := g_size;
    
    result.sdb_component.product.vendor_id := g_sdb_product.vendor_id; -- GSI
    result.sdb_component.product.device_id := g_sdb_product.device_id;
    result.sdb_component.product.version   := g_sdb_product.version;
    result.sdb_component.product.date      := g_sdb_product.date;
    result.sdb_component.product.name      := g_sdb_product.name;
    
    return result;
  end f_xwb_bridge_product_manual_sdb;
  
  function f_xwb_bridge_product_layout_sdb(
    g_wraparound  : boolean := true;
    g_layout      : t_sdb_record_array;
    g_sdb_addr    : t_wishbone_address; 
	 g_sdb_product: t_sdb_product) return t_sdb_bridge	
  is
    alias c_layout : t_sdb_record_array(g_layout'length-1 downto 0) is g_layout;

    -- How much space does the ROM need?
    constant c_used_entries : natural := c_layout'length + 1;
    constant c_rom_entries  : natural := 2**f_ceil_log2(c_used_entries); -- next power of 2
    constant c_sdb_bytes   : natural := c_sdb_device_length / 8;
    constant c_rom_bytes    : natural := c_rom_entries * c_sdb_bytes;
    
    -- Step 2. Find the size of the bus
    function f_bus_end return unsigned is
      variable result : unsigned(63 downto 0);
      variable sdb_component : t_sdb_component;
    begin
      if not g_wraparound then
        result := (others => '0');
        for i in 0 to c_wishbone_address_width-1 loop
          result(i) := '1';
        end loop;
      else
        -- The ROM will be an addressed slave as well
        result := (others => '0');
        result(c_wishbone_address_width-1 downto 0) := unsigned(g_sdb_addr);
        result := result + to_unsigned(c_rom_bytes, 64) - 1;
        
        for i in c_layout'range loop
	  sdb_component := f_sdb_extract_component(c_layout(i)(447 downto 8));
          if unsigned(sdb_component.addr_last) > result then
            result := unsigned(sdb_component.addr_last);
          end if;
        end loop;
        -- round result up to a power of two -1
        for i in 62 downto 0 loop
          result(i) := result(i) or result(i+1);
        end loop;
      end if;
      return result;
    end f_bus_end;
    
    constant bus_end : unsigned(63 downto 0) := f_bus_end;
  begin
    return f_xwb_bridge_product_manual_sdb(std_logic_vector(f_bus_end(c_wishbone_address_width-1 downto 0)), g_sdb_addr, g_sdb_product);
  end f_xwb_bridge_product_layout_sdb;
  
	 
	 
end wrnic_sdb_pkg;
