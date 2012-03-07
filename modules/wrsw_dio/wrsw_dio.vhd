-------------------------------------------------------------------------------
-- Title      : DIO Core
-- Project    : White Rabbit Network Interface
-------------------------------------------------------------------------------
-- File       : wrsw_dio.vhd
-- Author     : Rafael Rodriguez
-- Company    : Seven Solutions
-- Created    : 2012-03-03
-- Last update: 2012-03-07
-- Platform   : FPGA-generic
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description: The DIO core allows configuration of each one of the 5 channels of 
-- the DIO mezzanine as input or output. For inputs, it provides an accurate UTC 
-- time stamp (using UTC from the WRPC, not shown in the diagram) and optionally 
-- a host (PCIe) interrupt via the IRQ Gen block. For outputs, it allows the user 
-- to schedule the generation of a pulse at a given future UTC time, or to generate it immediately. 
-------------------------------------------------------------------------------
-- TODO:
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2012-03-03  0.1      R.Rodriguez     Created
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

--use work._pkg.all;
--use work._pkg.all;

entity wrsw_dio is
  generic (
    g_interface_mode      : t_wishbone_interface_mode      := CLASSIC;
    g_address_granularity : t_wishbone_address_granularity := WORD
  );
  port (
    clk_sys_i      : in  std_logic;
    rst_n_i        : in  std_logic;
		
    dio_clk_p_i    : in std_logic;
    dio_clk_n_i    : in std_logic;
    dio_n_i        : in std_logic_vector(4 downto 0);
    dio_p_i        : in std_logic_vector(4 downto 0);
    dio_n_o        : out std_logic_vector(4 downto 0);
    dio_p_o        : out std_logic_vector(4 downto 0);
    dio_oe_n_o     : out std_logic_vector(4 downto 0);
    dio_term_en_o  : out std_logic_vector(4 downto 0);
    dio_onewire_b  : inout std_logic;
    dio_sdn_n_o    : out std_logic;
    dio_sdn_ck_n_o : out std_logic;
    dio_led_top_o  : out std_logic;
    dio_led_bot_o  : out std_logic;		

    tm_time_valid_i : in std_logic;
    tm_utc_i        : in std_logic_vector(39 downto 0);
    tm_cycles_i     : in std_logic_vector(27 downto 0);
		
    slave_i         : in  t_wishbone_slave_in;
    slave_o         : out t_wishbone_slave_out
  );
  end wrsw_dio; 


architecture rtl of wrsw_dio is

  component pulse_gen is
    generic (
      g_ref_clk_rate : integer := 125000000
    );
    port (
      clk_ref_i : in std_logic;           -- timing reference clock
      clk_sys_i : in std_logic;           -- data output reference clock
      rst_n_i   : in std_logic;           -- system reset
      pulse_o : out std_logic;            -- pulse output
		
      -------------------------------------------------------------------------------
      -- Timing input (from WRPC), clk_ref_i domain
      ------------------------------------------------------------------------------
      -- 1: time given on tm_utc_i and tm_cycles_i is valid (otherwise, don't
      -- produce pulses and keep trig_ready_o line permamaently active)
      tm_time_valid_i : in std_logic;
      -- number of seconds
      tm_utc_i        : in std_logic_vector(39 downto 0);
      -- number of clk_ref_i cycles
      tm_cycles_i     : in std_logic_vector(27 downto 0);

      ---------------------------------------------------------------------------
      -- Time tag output (clk_sys_i domain)
      ---------------------------------------------------------------------------
      -- 1: input is ready to accept next trigger time tag
      trig_ready_o : out std_logic;
      -- time at which the pulse will be produced + a single-cycle strobe to
      -- latch it in
      trig_utc_i      : in std_logic_vector(39 downto 0);
      trig_cycles_i   : in std_logic_vector(27 downto 0);
      trig_valid_p1_i : in std_logic
    );
  end component;

  component pulse_stamper is
    generic (
      -- reference clock frequency
      g_ref_clk_rate : integer := 125000000
    );
    port(
      clk_ref_i : in std_logic;           -- timing reference clock
      clk_sys_i : in std_logic;           -- data output reference clock
      rst_n_i   : in std_logic;           -- system reset

      pulse_a_i : in std_logic;           -- pulses to be stamped

      -------------------------------------------------------------------------------
      -- Timing input (from WRPC), clk_ref_i domain
      ------------------------------------------------------------------------------
      -- 1: time given on tm_utc_i and tm_cycles_i is valid (otherwise, don't timestamp)
      tm_time_valid_i : in std_logic;
      -- number of seconds
      tm_utc_i        : in std_logic_vector(39 downto 0);
      -- number of clk_ref_i cycles
      tm_cycles_i     : in std_logic_vector(27 downto 0);

      ---------------------------------------------------------------------------
      -- Time tag output (clk_sys_i domain)
      ---------------------------------------------------------------------------
      tag_utc_o      : out std_logic_vector(39 downto 0);
      tag_cycles_o   : out std_logic_vector(27 downto 0);
      -- single-cycle pulse: strobe tag on tag_utc_o and tag_cycles_o
      tag_valid_p1_o : out std_logic
    );
  end component;


  
begin  -- rtl

  gen_dio_iobufs : for i in 0 to 4 generate
    U_ibuf : IBUFDS
      generic map (
        DIFF_TERM => true)
      port map (
        O  => dio_in(i),
        I  => dio_p_i(i),
        IB => dio_n_i(i)
        );

    U_obuf : OBUFDS
      port map (
        I  => dio_out(i),
        O  => dio_p_o(i),
        OB => dio_n_o(i)
        );
  end generate gen_dio_iobufs;

  U_input_buffer : IBUFDS
    generic map (
      DIFF_TERM => true)
    port map (
      O  => dio_clk,
      I  => dio_clk_p_i,
      IB => dio_clk_n_i
      );
  
  U_Onewire : xwb_onewire_master
    generic map (
      g_interface_mode => CLASSIC,
      g_num_ports      => 1)
    port map (
      clk_sys_i      => clk_sys,
      rst_n_i        => l_rst_n,
      slave_i        => cnx_out(0),
      slave_o        => cnx_in(0),
      desc_o         => open,
      owr_pwren_o(0) => onewire_pwren,
      owr_en_o(0)    => onewire_en,
      owr_i(0)       => dio_onewire_b);

  dio_onewire_b <= '0' when onewire_en = '1' else 'Z';
  
  U_I2C : xwb_i2c_master
    generic map (
      g_interface_mode => CLASSIC)
    
    port map (
      clk_sys_i    => clk_sys,
      rst_n_i      => l_rst_n,
      slave_i      => cnx_out(1),
      slave_o      => cnx_in(1),
      desc_o       => open,
      scl_pad_i    => scl_pad_in,
      scl_pad_o    => scl_pad_out,
      scl_padoen_o => scl_pad_oen,
      sda_pad_i    => sda_pad_in,
      sda_pad_o    => sda_pad_out,
      sda_padoen_o => sda_pad_oen);
  
  U_GPIO : xwb_gpio_port
    generic map (
      g_interface_mode         => CLASSIC,
      g_num_pins               => 32,
      g_with_builtin_tristates => false)
    port map (
      clk_sys_i  => clk_sys,
      rst_n_i    => l_rst_n,
      slave_i    => cnx_out(2),
      slave_o    => cnx_in(2),
      desc_o     => open,
      gpio_b     => open,
      gpio_out_o => gpio_out,
      gpio_in_i  => gpio_in,
      gpio_oen_o => gpio_oen);

  U_Fanout: xwb_bus_fanout
    generic map (
      g_num_outputs    => c_NUM_WISHBONE_DEVS,
      g_bits_per_slave => 6)
    port map (
      clk_sys_i => clk_sys,
      rst_n_i   => l_rst_n,
      slave_i   => cnx_slave_in,
      slave_o   => cnx_slave_out,
      master_i  => cnx_in,
      master_o  => cnx_out);

  
  gen_pio_assignment: for i in 0 to 4 generate
    gpio_in(4*i) <= dio_in(i);
    dio_out(i) <= gpio_out(4*i);
    dio_oe_n_o(i) <= gpio_out(4*i+1);
    dio_term_en_o(i) <= gpio_out(4*i+2);
  end generate gen_pio_assignment;

  dio_led_bot_o <= gpio_out(28);
  dio_led_top_o <= gpio_out(27);
  
  gpio_in(29) <= dio_clk;
  dio_sdn_ck_n_o <= gpio_out(30);
  dio_sdn_n_o <= gpio_out(31);
  gpio_in(30) <= prsnt_m2c_l;


  fmc_scl_b <= scl_pad_out when scl_pad_oen = '0' else 'Z';
  fmc_sda_b <= sda_pad_out when sda_pad_oen = '0' else 'Z';

  scl_pad_in <= fmc_scl_b;
  sda_pad_in <= fmc_sda_b;






















 
--  U_WB_SLAVE : wrsw_txtsu_wb
--    port map (
--      rst_n_i              => rst_n_i,
--      wb_clk_i             => clk_sys_i,
--      wb_addr_i            => wb_in.adr(2 downto 0),
--      wb_data_i            => wb_in.dat,
--      wb_data_o            => wb_out.dat,
--      wb_cyc_i             => wb_in.cyc,
--      wb_sel_i             => wb_in.sel,
--      wb_stb_i             => wb_in.stb,
--      wb_we_i              => wb_in.we,
--      wb_ack_o             => wb_out.ack,
--      wb_irq_o             => wb_out.int,
--      txtsu_tsf_wr_req_i   => txtsu_tsf_wr_req,
--      txtsu_tsf_wr_full_o  => txtsu_tsf_wr_full,
--      txtsu_tsf_wr_empty_o => txtsu_tsf_wr_empty,
--      txtsu_tsf_val_r_i    => txtsu_tsf_val_r,
--      txtsu_tsf_val_f_i    => txtsu_tsf_val_f,
--      txtsu_tsf_pid_i      => txtsu_tsf_pid,
--      txtsu_tsf_fid_i      => txtsu_tsf_fid,
--      irq_nempty_i         => irq_nempty);
--
--  irq_nempty <= not txtsu_tsf_wr_empty;
  
end rtl;
