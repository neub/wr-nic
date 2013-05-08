-------------------------------------------------------------------------------
-- Title      : DIO Core
-- Project    : White Rabbit Network Interface
-------------------------------------------------------------------------------
-- File       : wrsw_dio.vhd
-- Author     : Javier Díaz
-- Company    : Seven Solutions
-- Created    : 2012-07-25
-- Last update: 2012-07-25
-- Platform   : FPGA-generic
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description: Simulation file for the xwrsw_dio.vhd file
--
-------------------------------------------------------------------------------
-- TODO:
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2012-07-25  0.1      JDiaz           Created
-- 2013-05-23  0.2      Ben.R           Adding PPS
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;

entity wrsw_dio is
  generic (
    g_interface_mode      : t_wishbone_interface_mode      := CLASSIC;
    g_address_granularity : t_wishbone_address_granularity := WORD
  );
  port (
    clk_sys_i        : in  std_logic;
    clk_ref_i        : in  std_logic;
    rst_n_i          : in  std_logic;

    dio_clk_i        : in std_logic;
    dio_pps_i        : in std_logic;
    dio_in_i         : in std_logic_vector(4 downto 0);
    dio_out_o        : out std_logic_vector(4 downto 0);
    dio_oe_n_o       : out std_logic_vector(4 downto 0);
    dio_term_en_o    : out std_logic_vector(4 downto 0);
    dio_onewire_b    : inout std_logic;
    dio_sdn_n_o      : out std_logic;
    dio_sdn_ck_n_o   : out std_logic;
    dio_led_top_o    : out std_logic;
    dio_led_bot_o    : out std_logic;

    dio_scl_b        : inout std_logic;
    dio_sda_b        : inout std_logic;
    dio_ga_o         : out std_logic_vector(1 downto 0); 

    tm_time_valid_i  : in std_logic;
    tm_seconds_i         : in std_logic_vector(39 downto 0);
    tm_cycles_i      : in std_logic_vector(27 downto 0);

    -------------------------------------------------------------------------------
    -- Wishbone bus
    -------------------------------------------------------------------------------
    wb_cyc_i   : in  std_logic;
    wb_stb_i   : in  std_logic;
    wb_we_i    : in  std_logic;
    wb_sel_i   : in  std_logic_vector(c_wishbone_data_width/8-1 downto 0);
    wb_adr_i   : in  std_logic_vector(c_wishbone_address_width-1 downto 0);
    wb_dat_i   : in  std_logic_vector(c_wishbone_data_width-1 downto 0);
    wb_dat_o   : out std_logic_vector(c_wishbone_data_width-1 downto 0);
    wb_ack_o   : out std_logic;
    wb_stall_o : out std_logic;
    wb_irq_o   : out std_logic;
    
    -- Debug signals for chipscope
    TRIG0            : out std_logic_vector(31 downto 0);
    TRIG1            : out std_logic_vector(31 downto 0);
    TRIG2            : out std_logic_vector(31 downto 0);
    TRIG3            : out std_logic_vector(31 downto 0)

  );
  end wrsw_dio; 


architecture rtl of wrsw_dio is

  -- DIO core
  component xwrsw_dio
    generic (
      g_interface_mode      : t_wishbone_interface_mode      := CLASSIC;
      g_address_granularity : t_wishbone_address_granularity := WORD
      );
    port (
      clk_sys_i : in std_logic;
      clk_ref_i : in std_logic;
      rst_n_i   : in std_logic;

      dio_clk_i      : in    std_logic;
      dio_pps_i      : in    std_logic;
      dio_in_i       : in    std_logic_vector(4 downto 0);
      dio_out_o      : out   std_logic_vector(4 downto 0);
      dio_oe_n_o     : out   std_logic_vector(4 downto 0);
      dio_term_en_o  : out   std_logic_vector(4 downto 0);
      dio_onewire_b  : inout std_logic;
      dio_sdn_n_o    : out   std_logic;
      dio_sdn_ck_n_o : out   std_logic;
      dio_led_top_o  : out   std_logic;
      dio_led_bot_o  : out   std_logic;

      dio_scl_b : inout std_logic;
      dio_sda_b : inout std_logic;
      dio_ga_o  : out std_logic_vector(1 downto 0);

      tm_time_valid_i : in std_logic;
      tm_seconds_i        : in std_logic_vector(39 downto 0);
      tm_cycles_i     : in std_logic_vector(27 downto 0);

      TRIG0 : out std_logic_vector(31 downto 0);
      TRIG1 : out std_logic_vector(31 downto 0);
      TRIG2 : out std_logic_vector(31 downto 0);
      TRIG3 : out std_logic_vector(31 downto 0);

      slave_i                      : in  t_wishbone_slave_in;
      slave_o                      : out t_wishbone_slave_out
  );
  end component;  --DIO core
  
  signal wb_out : t_wishbone_slave_out;
  signal wb_in  : t_wishbone_slave_in;
-------------------------------------------------------------------------------
begin  

U_WRAPPER_DIO : xwrsw_dio
    generic map (
      g_interface_mode      => g_interface_mode,
      g_address_granularity => g_address_granularity)

    port map(
      clk_sys_i => clk_sys_i,
      clk_ref_i => clk_ref_i,
      rst_n_i   => rst_n_i,

      dio_clk_i      => dio_clk_i,
      dio_pps_i      => dio_clk_i,
      dio_in_i       => dio_in_i,
      dio_out_o      => dio_out_o,
      dio_oe_n_o     => dio_oe_n_o,
      dio_term_en_o  => dio_term_en_o,
      
      dio_onewire_b  => dio_onewire_b,
      dio_sdn_n_o    => dio_sdn_n_o,
      dio_sdn_ck_n_o => dio_sdn_ck_n_o,
      dio_led_top_o  => dio_led_top_o,
      dio_led_bot_o  => dio_led_bot_o,

      dio_scl_b      => dio_scl_b,
      dio_sda_b      => dio_sda_b,
      dio_ga_o       => dio_ga_o,

      tm_time_valid_i => tm_time_valid_i,
      tm_seconds_i    => tm_seconds_i,
      tm_cycles_i     => tm_cycles_i,

      slave_i         => wb_in,
      slave_o         => wb_out
      
      -- Chipscope, debugging signals
      --TRIG0           => TRIG0,
      --TRIG1           => TRIG1,
      --TRIG2           => TRIG2,
      --TRIG3           => TRIG3,
  );
  
  wb_in.cyc  <= wb_cyc_i;
  wb_in.stb  <= wb_stb_i;
  wb_in.we   <= wb_we_i;
  wb_in.sel  <= wb_sel_i;
  wb_in.adr  <= wb_adr_i;
  wb_in.dat  <= wb_dat_i;
  wb_dat_o   <= wb_out.dat;
  wb_ack_o   <= wb_out.ack;
  wb_stall_o <= wb_out.stall;
  wb_irq_o   <= wb_out.int;  

-----------------------------------------------------------------------------------	
end rtl;



