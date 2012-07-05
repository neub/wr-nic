-------------------------------------------------------------------------------
-- Title      : DIO Core
-- Project    : White Rabbit Network Interface
-------------------------------------------------------------------------------
-- File       : wrsw_dio.vhd
-- Author     : Rafael Rodriguez, Javier Díaz
-- Company    : Seven Solutions
-- Created    : 2012-03-03
-- Last update: 2012-03-20
-- Platform   : FPGA-generic
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description: The DIO core allows configuration of each one of the 5 channels of 
-- the DIO mezzanine as input or output. For inputs, it provides an accurate seconds 
-- time stamp (using seconds from the WRPC, not shown in the diagram) and  
-- a host (PCIe) interrupt via the IRQ Gen block. For outputs, it allows the user 
-- to schedule the generation of a pulse at a given future seconds time, or to generate 
-- it immediately. 
-------------------------------------------------------------------------------
-- TODO:
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2012-03-03  0.1      Rafa.r          Created
-- 2012-03-08  0.2      Javier.d        Added wrsw_dio_wb
-- 2012-07-05  0.3		Javier.d        Midified wrsw_dio_wb, modified interface
-------------------------------------------------------------------------------

-- WARNING: only pipelined mode is supported (Intercon is pipelined only) - T.W.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.wishbone_pkg.all;


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
    dio_ga_o	     : out std_logic_vector(1 downto 0); 
	 
    tm_time_valid_i  : in std_logic;
    tm_seconds_i         : in std_logic_vector(39 downto 0);
    tm_cycles_i      : in std_logic_vector(27 downto 0);

    -- Debug signals for chipscope
    TRIG0            : out std_logic_vector(31 downto 0);
    TRIG1            : out std_logic_vector(31 downto 0);
    TRIG2            : out std_logic_vector(31 downto 0);
    TRIG3            : out std_logic_vector(31 downto 0);
		
    slave_i            : in  t_wishbone_slave_in;
    slave_o            : out t_wishbone_slave_out
  --  wb_irq_data_fifo_o : out std_logic  -- T.B.DELETED
  );
  end wrsw_dio; 


architecture rtl of wrsw_dio is

  -------------------------------------------------------------------------------
  -- Component only for debugging (in order to generate seconds time) 
  -------------------------------------------------------------------------------
--  component dummy_time is
--    port(
--      clk_sys       : in std_logic;
--      rst_n         : in std_logic; 
--      tm_utc        : out std_logic_vector(39 downto 0);
--      tm_cycles     : out std_logic_vector(27 downto 0));
--  end component;	
  
  -------------------------------------------------------------------------------
  -- PULSE GENERATOR which produces a 1-tick-long pulse in its
  -- output when the seconds time passed to it through a vector equals a
  -- pre-programmed seconds time.
  -------------------------------------------------------------------------------
  component pulse_gen is
    generic (
      g_ref_clk_rate : integer := 125000000
    );
    port (
      clk_ref_i : in std_logic;           -- timing reference clock
      clk_sys_i : in std_logic;           -- data output reference clock
      rst_n_i   : in std_logic;           -- system reset
      pulse_o   : out std_logic;          -- pulse output
		
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
      trig_ready_o    : out std_logic;
      -- time at which the pulse will be produced + a single-cycle strobe to
      -- latch it in
      trig_utc_i      : in std_logic_vector(39 downto 0);
      trig_cycles_i   : in std_logic_vector(27 downto 0);
      trig_valid_p1_i : in std_logic
    );
  end component;
  
  -------------------------------------------------------------------------------
  -- PULSE STAMPER which associates a time-tag with an asyncrhonous
  -- input pulse.
  -------------------------------------------------------------------------------
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
      -- 1: time given on tm_seconds_i and tm_cycles_i is valid (otherwise, don't timestamp)
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
      -- single-cycle pulse: strobe tag on tag_seconds_o and tag_cycles_o
      tag_valid_p1_o : out std_logic
    );
  end component;

  component wrsw_dio_wb is
    port (
    rst_n_i                                  : in     std_logic;
    clk_sys_i                                : in     std_logic;
    wb_adr_i                                 : in     std_logic_vector(5 downto 0);
    wb_dat_i                                 : in     std_logic_vector(31 downto 0);
    wb_dat_o                                 : out    std_logic_vector(31 downto 0);
    wb_cyc_i                                 : in     std_logic;
    wb_sel_i                                 : in     std_logic_vector(3 downto 0);
    wb_stb_i                                 : in     std_logic;
    wb_we_i                                  : in     std_logic;
    wb_ack_o                                 : out    std_logic;
    wb_stall_o                               : out    std_logic;
    wb_int_o                                 : out    std_logic;
    clk_asyn_i                               : in     std_logic;
    -- FIFO write request
    dio_tsf0_wr_req_i                        : in     std_logic;
    -- FIFO full flag
    dio_tsf0_wr_full_o                       : out    std_logic;
    -- FIFO empty flag
    dio_tsf0_wr_empty_o                      : out    std_logic;
    dio_tsf0_tag_seconds_i                       : in     std_logic_vector(31 downto 0);
    dio_tsf0_tag_secondsh_i                      : in     std_logic_vector(7 downto 0);
    dio_tsf0_tag_cycles_i                    : in     std_logic_vector(27 downto 0);
    irq_nempty_0_i                           : in     std_logic;
    -- FIFO write request
    dio_tsf1_wr_req_i                        : in     std_logic;
    -- FIFO full flag
    dio_tsf1_wr_full_o                       : out    std_logic;
    -- FIFO empty flag
    dio_tsf1_wr_empty_o                      : out    std_logic;
    dio_tsf1_tag_seconds_i                       : in     std_logic_vector(31 downto 0);
    dio_tsf1_tag_secondsh_i                      : in     std_logic_vector(7 downto 0);
    dio_tsf1_tag_cycles_i                    : in     std_logic_vector(27 downto 0);
    irq_nempty_1_i                           : in     std_logic;
    -- FIFO write request
    dio_tsf2_wr_req_i                        : in     std_logic;
    -- FIFO full flag
    dio_tsf2_wr_full_o                       : out    std_logic;
    -- FIFO empty flag
    dio_tsf2_wr_empty_o                      : out    std_logic;
    dio_tsf2_tag_seconds_i                       : in     std_logic_vector(31 downto 0);
    dio_tsf2_tag_secondsh_i                      : in     std_logic_vector(7 downto 0);
    dio_tsf2_tag_cycles_i                    : in     std_logic_vector(27 downto 0);
    irq_nempty_2_i                           : in     std_logic;
    -- FIFO write request
    dio_tsf3_wr_req_i                        : in     std_logic;
    -- FIFO full flag
    dio_tsf3_wr_full_o                       : out    std_logic;
    -- FIFO empty flag
    dio_tsf3_wr_empty_o                      : out    std_logic;
    dio_tsf3_tag_seconds_i                       : in     std_logic_vector(31 downto 0);
    dio_tsf3_tag_secondsh_i                      : in     std_logic_vector(7 downto 0);
    dio_tsf3_tag_cycles_i                    : in     std_logic_vector(27 downto 0);
    irq_nempty_3_i                           : in     std_logic;
    -- FIFO write request
    dio_tsf4_wr_req_i                        : in     std_logic;
    -- FIFO full flag
    dio_tsf4_wr_full_o                       : out    std_logic;
    -- FIFO empty flag
    dio_tsf4_wr_empty_o                      : out    std_logic;
    dio_tsf4_tag_seconds_i                       : in     std_logic_vector(31 downto 0);
    dio_tsf4_tag_secondsh_i                      : in     std_logic_vector(7 downto 0);
    dio_tsf4_tag_cycles_i                    : in     std_logic_vector(27 downto 0);
    irq_nempty_4_i                           : in     std_logic;
    -- Port for std_logic_vector field: 'seconds field' in reg: 'fmc-dio 0 seconds-based trigger for pulse generation'
    dio_trig0_seconds_o                          : out    std_logic_vector(31 downto 0);
    -- Port for std_logic_vector field: 'seconds field' in reg: 'fmc-dio 0 seconds-based trigger for pulse generation'
    dio_trigh0_seconds_o                         : out    std_logic_vector(7 downto 0);
    -- Port for std_logic_vector field: 'cycles field' in reg: 'fmc-dio 0 cycles to  trigger a pulse generation'
    dio_cyc0_cyc_o                           : out    std_logic_vector(27 downto 0);
    -- Port for std_logic_vector field: 'seconds field' in reg: 'fmc-dio 1 seconds-based trigger for pulse generation'
    dio_trig1_seconds_o                          : out    std_logic_vector(31 downto 0);
    -- Port for std_logic_vector field: 'seconds field' in reg: 'fmc-dio 1 seconds-based trigger for pulse generation'
    dio_trigh1_seconds_o                         : out    std_logic_vector(7 downto 0);
    -- Port for std_logic_vector field: 'cycles field' in reg: 'fmc-dio 1 cycles to  trigger a pulse generation'
    dio_cyc1_cyc_o                           : out    std_logic_vector(27 downto 0);
    -- Port for std_logic_vector field: 'seconds field' in reg: 'fmc-dio 2 seconds-based trigger for pulse generation'
    dio_trig2_seconds_o                          : out    std_logic_vector(31 downto 0);
    -- Port for std_logic_vector field: 'seconds field' in reg: 'fmc-dio 2 seconds-based trigger for pulse generation'
    dio_trigh2_seconds_o                         : out    std_logic_vector(7 downto 0);
    -- Port for std_logic_vector field: 'cycles field' in reg: 'fmc-dio 2 cycles to  trigger a pulse generation'
    dio_cyc2_cyc_o                           : out    std_logic_vector(27 downto 0);
    -- Port for std_logic_vector field: 'seconds field' in reg: 'fmc-dio 3 seconds-based trigger for pulse generation'
    dio_trig3_seconds_o                          : out    std_logic_vector(31 downto 0);
    -- Port for std_logic_vector field: 'seconds field' in reg: 'fmc-dio 3 seconds-based trigger for pulse generation'
    dio_trigh3_seconds_o                         : out    std_logic_vector(7 downto 0);
    -- Port for std_logic_vector field: 'cycles field' in reg: 'fmc-dio 3 cycles to  trigger a pulse generation'
    dio_cyc3_cyc_o                           : out    std_logic_vector(27 downto 0);
    -- Port for std_logic_vector field: 'seconds field' in reg: 'fmc-dio 4 seconds-based trigger for pulse generation'
    dio_trig4_seconds_o                          : out    std_logic_vector(31 downto 0);
    -- Port for std_logic_vector field: 'seconds field' in reg: 'fmc-dio 4 seconds-based trigger for pulse generation'
    dio_trigh4_seconds_o                         : out    std_logic_vector(7 downto 0);
    -- Port for std_logic_vector field: 'cycles field' in reg: 'fmc-dio 4 cycles to  trigger a pulse generation'
    dio_cyc4_cyc_o                           : out    std_logic_vector(27 downto 0);
-- Port for std_logic_vector field: 'outmode' in reg: 'FMC-DIO output configuration register. '
    dio_out_mode_o                           : out    std_logic_vector(4 downto 0);
-- Port for MONOSTABLE field: 'Sincle-cycle strobe' in reg: 'Time-programmable output strobe signal'
    dio_latch_time_ch0_o                : out    std_logic;
-- Port for MONOSTABLE field: 'Sincle-cycle strobe' in reg: 'Time-programmable output strobe signal'
    dio_latch_time_ch1_o                : out    std_logic;
-- Port for MONOSTABLE field: 'Sincle-cycle strobe' in reg: 'Time-programmable output strobe signal'
    dio_latch_time_ch2_o                : out    std_logic;
-- Port for MONOSTABLE field: 'Sincle-cycle strobe' in reg: 'Time-programmable output strobe signal'
    dio_latch_time_ch3_o                : out    std_logic;
-- Port for MONOSTABLE field: 'Sincle-cycle strobe' in reg: 'Time-programmable output strobe signal'
    dio_latch_time_ch4_o                : out    std_logic;
-- Port for std_logic_vector field: 'trig_rdy field' in reg: 'FMC-DIO seconds-based trigger is ready to accept a new trigger generation request'
    dio_trig_rdy_i                           : in     std_logic_vector(4 downto 0);
    -- Port for asynchronous (clock: clk_asyn_i) MONOSTABLE field: 'pulse_gen_now_0' in reg: 'Pulse generate immediately'
    dio_puls_inmed_pul_inm_0_o               : out    std_logic;
    -- Port for asynchronous (clock: clk_asyn_i) MONOSTABLE field: 'pulse_gen_now_1' in reg: 'Pulse generate immediately'
    dio_puls_inmed_pul_inm_1_o               : out    std_logic;
    -- Port for asynchronous (clock: clk_asyn_i) MONOSTABLE field: 'pulse_gen_now_2' in reg: 'Pulse generate immediately'
    dio_puls_inmed_pul_inm_2_o               : out    std_logic;
    -- Port for asynchronous (clock: clk_asyn_i) MONOSTABLE field: 'pulse_gen_now_3' in reg: 'Pulse generate immediately'
    dio_puls_inmed_pul_inm_3_o               : out    std_logic;
    -- Port for asynchronous (clock: clk_asyn_i) MONOSTABLE field: 'pulse_gen_now_4' in reg: 'Pulse generate immediately'
    dio_puls_inmed_pul_inm_4_o               : out    std_logic
  );
  end component;


  ------------------------------------------------------------------------------
  -- Constants declaration
  ------------------------------------------------------------------------------

  constant c_WB_SLAVES_DIO  : integer := 4;

  ------------------------------------------------------------------------------
  -- Signals declaration
  ------------------------------------------------------------------------------
  signal gpio_out : std_logic_vector(31 downto 0);
  signal gpio_in  : std_logic_vector(31 downto 0);
  signal gpio_oen : std_logic_vector(31 downto 0);

  signal onewire_en                           : std_logic;
  signal onewire_pwren                        : std_logic;
  signal scl_pad_in, scl_pad_out, scl_pad_oen : std_logic;
  signal sda_pad_in, sda_pad_out, sda_pad_oen : std_logic;

  -- Pulse generator trigger registers signals
  type t_seconds_array is array (4 downto 0) of std_logic_vector (39 downto 0);
  type t_cycles_array is array (4 downto 0) of std_logic_vector (27 downto 0);
  
  signal trig_seconds       : t_seconds_array;
  signal trig_cycles    : t_cycles_array;
  signal trig_valid_p1 	: std_logic_vector (4 downto 0);
  
  signal trig_ready     : std_logic_vector (4 downto 0);

  signal tag_seconds        : t_seconds_array;
  signal tag_cycles     : t_cycles_array;
  signal tag_valid_p1   : std_logic_vector (4 downto 0);

  -- FIFO signals
  signal dio_tsf_wr_req      : std_logic_vector (4 downto 0);
  signal dio_tsf_wr_full     : std_logic_vector (4 downto 0);
  signal dio_tsf_wr_empty    : std_logic_vector (4 downto 0);
  signal dio_tsf_tag_seconds     : t_seconds_array;
  signal dio_tsf_tag_cycles  : t_cycles_array;
  
  -- Fifos no-empty interrupts
  signal irq_nempty          : std_logic_vector (4 downto 0);


  -- DEBUG SIGNALS FOR USING seconds time values from dummy_time instead WRPC
  signal tm_seconds                 : std_logic_vector (39 downto 0);
  signal tm_cycles              : std_logic_vector (27 downto 0);
	
  -- WB Crossbar
  constant c_cfg_base_addr : t_wishbone_address_array(3 downto 0) :=
    (0 => x"00000000",  -- ONEWIRE                
     1 => x"00000100",  -- I2C                
     2 => x"00000200",  -- GPIO                 
     3 => x"00000300"); -- PULSE GEN & STAMPER                 

  constant c_cfg_base_mask : t_wishbone_address_array(3 downto 0) :=
    (0 => x"00000f00",
     1 => x"00000f00",
     2 => x"00000f00",
     3 => x"00000f00");

  signal cbar_master_in   : t_wishbone_master_in_array(c_WB_SLAVES_DIO-1 downto 0);
  signal cbar_master_out  : t_wishbone_master_out_array(c_WB_SLAVES_DIO-1 downto 0);

  -- DIO related signals
  signal dio_monost        : std_logic_vector(4 downto 0);
  signal dio_prog          : std_logic_vector(4 downto 0);
  signal dio_puls_inmed    : std_logic_vector(4 downto 0);
  signal dio_out_mode      : std_logic_vector(4 downto 0);
  
-------------------------------------------------------------------------------
-- rtl
-------------------------------------------------------------------------------
begin  

  -- Dummy counter for simulationg WRPC seconds time
--  U_dummy: dummy_time
--    port map(
--      clk_sys     => clk_ref_i,
--      rst_n       => rst_n_i, 
--      tm_utc      => tm_utc, 
--      tm_cycles   => tm_cycles
--    );	
	
  ------------------------------------------------------------------------------
  -- GEN AND STAMPER
  ------------------------------------------------------------------------------    
  gen_pulse_modules : for i in 0 to 4 generate
    U_pulse_gen : pulse_gen
      port map(
        clk_ref_i        => clk_ref_i,
        clk_sys_i        => clk_sys_i,
        rst_n_i          => rst_n_i,

        pulse_o          => dio_prog(i),
        -- DEBUG
--        tm_time_valid_i  => '1',--tm_time_valid_i,
--        tm_utc_i         => tm_utc,--tm_utc_i, 
--        tm_cycles_i      => tm_cycles, --tm_cycles_i, 
        tm_time_valid_i  => tm_time_valid_i,
        tm_utc_i         => tm_seconds_i, 
        tm_cycles_i      => tm_cycles_i, 
		
        trig_ready_o     => trig_ready(i),

        trig_utc_i       => trig_seconds(i), 
        trig_cycles_i    => trig_cycles(i), 
        trig_valid_p1_i  => trig_valid_p1(i));
	 

    U_pulse_stamper : pulse_stamper
      port map(
        clk_ref_i       => clk_ref_i,
        clk_sys_i       => clk_sys_i,
        rst_n_i         => rst_n_i,

        pulse_a_i       => dio_in_i(i),
 
--        tm_time_valid_i => '1',--tm_time_valid_i,
--        tm_utc_i        => tm_utc, --tm_utc_i, 
--        tm_cycles_i     => tm_cycles, --tm_cycles_i, 
        tm_time_valid_i => tm_time_valid_i,
        tm_utc_i        => tm_seconds_i, 
        tm_cycles_i     => tm_cycles_i, 

        tag_utc_o       => tag_seconds(i), 
        tag_cycles_o    => tag_cycles(i), 
        tag_valid_p1_o  => tag_valid_p1(i));

  end generate gen_pulse_modules;       

  ------------------------------------------------------------------------------
  -- WB ONEWIRE MASTER
  ------------------------------------------------------------------------------    
  U_Onewire : xwb_onewire_master
    generic map (
      g_interface_mode => PIPELINED,
      g_address_granularity => BYTE,
      g_num_ports      => 1)
    port map (
      clk_sys_i        => clk_sys_i,
      rst_n_i          => rst_n_i,
      slave_i          => cbar_master_out(0),
      slave_o          => cbar_master_in(0),
      desc_o           => open,
      owr_pwren_o(0)   => onewire_pwren,
      owr_en_o(0)      => onewire_en,
      owr_i(0)         => dio_onewire_b);

  dio_onewire_b <= '0' when onewire_en = '1' else 'Z';

  ------------------------------------------------------------------------------
  -- WB I2C MASTER
  ------------------------------------------------------------------------------    
  U_I2C : xwb_i2c_master
    generic map (
      g_interface_mode => PIPELINED,
      g_address_granularity => BYTE
      )
    
    port map (
      clk_sys_i    => clk_sys_i,
      rst_n_i      => rst_n_i,
      slave_i      => cbar_master_out(1),
      slave_o      => cbar_master_in(1),
      desc_o       => open,
      scl_pad_i    => scl_pad_in,
      scl_pad_o    => scl_pad_out,
      scl_padoen_o => scl_pad_oen,
      sda_pad_i    => sda_pad_in,
      sda_pad_o    => sda_pad_out,
      sda_padoen_o => sda_pad_oen);

		
  dio_scl_b <= scl_pad_out when scl_pad_oen = '0' else 'Z';
  dio_sda_b <= sda_pad_out when sda_pad_oen = '0' else 'Z';

  scl_pad_in <= dio_scl_b;
  sda_pad_in <= dio_sda_b;		
  dio_ga_o<="00"; -- Innused because SPEC boards have these fmc signals to ground

  ------------------------------------------------------------------------------
  -- WB GPIO PORT
  ------------------------------------------------------------------------------  
  U_GPIO : xwb_gpio_port
    generic map (
      g_interface_mode         => PIPELINED,
      g_address_granularity => BYTE,
      g_num_pins               => 32,
      g_with_builtin_tristates => false)
    port map (
      clk_sys_i  => clk_sys_i,
      rst_n_i    => rst_n_i,
      slave_i    => cbar_master_out(2),
      slave_o    => cbar_master_in(2),
      desc_o     => open,
      gpio_b     => open,
      gpio_out_o => gpio_out,
      gpio_in_i  => gpio_in,
      gpio_oen_o => gpio_oen);

  ------------------------------------------------------------------------------
  -- WB Crossbar
  ------------------------------------------------------------------------------
  WB_INTERCON : xwb_crossbar
    generic map(
      g_num_masters => 1,
      g_num_slaves  => 4,
      g_registered  => true,
      -- Address of the slaves connected
      g_address     => c_cfg_base_addr,
      g_mask        => c_cfg_base_mask
      )
    port map(
      clk_sys_i     => clk_sys_i,
      rst_n_i       => rst_n_i,
      -- Master connections
      slave_i(0)    => slave_i,
      slave_o(0)    => slave_o,
      -- Slave conenctions
      master_i      => cbar_master_in,
      master_o      => cbar_master_out
      );

  gen_pio_assignment: for i in 0 to 4 generate
    gpio_in(4*i)     <= dio_in_i(i);
	 
    dio_monost(i) <= '1' when dio_puls_inmed(i) = '1' else dio_prog(i);
    dio_out_o(i) <= dio_monost(i) when dio_out_mode(i) ='1' else gpio_out(4*i);
    dio_oe_n_o(i)    <= gpio_out(4*i+1);
    dio_term_en_o(i) <= gpio_out(4*i+2);
  end generate gen_pio_assignment;

  dio_led_bot_o  <= gpio_out(28);
  dio_led_top_o  <= gpio_out(27);
  
  gpio_in(29)    <= dio_clk_i;
  dio_sdn_ck_n_o <= gpio_out(30);
  dio_sdn_n_o    <= gpio_out(31);
  
  ------------------------------------------------------------------------------
  -- WB seconds-BASED PULSE GENERATION & INPUT STAMPING
  ------------------------------------------------------------------------------  
  U_seconds_wbslave : wrsw_dio_wb 
    port map(
      rst_n_i     => rst_n_i,
      clk_sys_i   => clk_sys_i,
      wb_adr_i    => cbar_master_out(3).adr(7 downto 2), -- only word acesses are available
      wb_dat_i    => cbar_master_out(3).dat,
      wb_dat_o    => cbar_master_in(3).dat,
      wb_cyc_i    => cbar_master_out(3).cyc, 
      wb_sel_i    => cbar_master_out(3).sel, 
      wb_stb_i    => cbar_master_out(3).stb, 
      wb_we_i     => cbar_master_out(3).we,  
      wb_ack_o    => cbar_master_in(3).ack,
      wb_stall_o  => cbar_master_in(3).stall,
      wb_int_o    => cbar_master_in(3).int,--wb_irq_data_fifo_o, --slave_o.int,
      clk_asyn_i  => clk_ref_i,

      dio_tsf0_wr_req_i     => dio_tsf_wr_req(0),
      dio_tsf0_wr_full_o    => dio_tsf_wr_full(0),
      dio_tsf0_wr_empty_o   => dio_tsf_wr_empty(0),
      dio_tsf0_tag_seconds_i    => dio_tsf_tag_seconds(0)(31 downto 0),
      dio_tsf0_tag_secondsh_i   => dio_tsf_tag_seconds(0)(39 downto 32),
      dio_tsf0_tag_cycles_i => dio_tsf_tag_cycles(0),
      irq_nempty_0_i        => irq_nempty(0),

      dio_tsf1_wr_req_i     => dio_tsf_wr_req(1),
      dio_tsf1_wr_full_o    => dio_tsf_wr_full(1),
      dio_tsf1_wr_empty_o   => dio_tsf_wr_empty(1),
      dio_tsf1_tag_seconds_i    => dio_tsf_tag_seconds(1)(31 downto 0),
      dio_tsf1_tag_secondsh_i   => dio_tsf_tag_seconds(1)(39 downto 32),
      dio_tsf1_tag_cycles_i => dio_tsf_tag_cycles(1),
      irq_nempty_1_i        => irq_nempty(1),

      dio_tsf2_wr_req_i     => dio_tsf_wr_req(2),
      dio_tsf2_wr_full_o    => dio_tsf_wr_full(2),
      dio_tsf2_wr_empty_o   => dio_tsf_wr_empty(2),
      dio_tsf2_tag_seconds_i    => dio_tsf_tag_seconds(2)(31 downto 0),
      dio_tsf2_tag_secondsh_i   => dio_tsf_tag_seconds(2)(39 downto 32),
      dio_tsf2_tag_cycles_i => dio_tsf_tag_cycles(2),
      irq_nempty_2_i        => irq_nempty(2),

      dio_tsf3_wr_req_i     => dio_tsf_wr_req(3),
      dio_tsf3_wr_full_o    => dio_tsf_wr_full(3),
      dio_tsf3_wr_empty_o   => dio_tsf_wr_empty(3),
      dio_tsf3_tag_seconds_i    => dio_tsf_tag_seconds(3)(31 downto 0),
      dio_tsf3_tag_secondsh_i   => dio_tsf_tag_seconds(3)(39 downto 32),
      dio_tsf3_tag_cycles_i => dio_tsf_tag_cycles(3),
      irq_nempty_3_i        => irq_nempty(3),

      dio_tsf4_wr_req_i     => dio_tsf_wr_req(4),
      dio_tsf4_wr_full_o    => dio_tsf_wr_full(4),
      dio_tsf4_wr_empty_o   => dio_tsf_wr_empty(4),
      dio_tsf4_tag_seconds_i    => dio_tsf_tag_seconds(4)(31 downto 0),
      dio_tsf4_tag_secondsh_i   => dio_tsf_tag_seconds(4)(39 downto 32),
      dio_tsf4_tag_cycles_i => dio_tsf_tag_cycles(4),
      irq_nempty_4_i        => irq_nempty(4),

      dio_trig0_seconds_o 	    => trig_seconds(0)(31 downto 0), 
      dio_trigh0_seconds_o	    => trig_seconds(0)(39 downto 32),
      dio_cyc0_cyc_o        => trig_cycles(0),

      dio_trig1_seconds_o       => trig_seconds(1)(31 downto 0), 
      dio_trigh1_seconds_o      => trig_seconds(1)(39 downto 32),
      dio_cyc1_cyc_o        => trig_cycles(1),

      dio_trig2_seconds_o       => trig_seconds(2)(31 downto 0), 
      dio_trigh2_seconds_o      => trig_seconds(2)(39 downto 32),
      dio_cyc2_cyc_o        => trig_cycles(2),

      dio_trig3_seconds_o       => trig_seconds(3)(31 downto 0), 
      dio_trigh3_seconds_o      => trig_seconds(3)(39 downto 32),
      dio_cyc3_cyc_o        => trig_cycles(3),

      dio_trig4_seconds_o       => trig_seconds(4)(31 downto 0), 
      dio_trigh4_seconds_o      => trig_seconds(4)(39 downto 32),
      dio_cyc4_cyc_o        => trig_cycles(4),

      dio_out_mode_o                           => dio_out_mode,

      dio_latch_time_ch0_o                => trig_valid_p1(0),
      dio_latch_time_ch1_o                => trig_valid_p1(1),
      dio_latch_time_ch2_o                => trig_valid_p1(2),
      dio_latch_time_ch3_o                => trig_valid_p1(3),
      dio_latch_time_ch4_o                => trig_valid_p1(4),

      dio_trig_rdy_i          => trig_ready,

      dio_puls_inmed_pul_inm_0_o  =>   dio_puls_inmed(0),		
      dio_puls_inmed_pul_inm_1_o  =>   dio_puls_inmed(1),		
      dio_puls_inmed_pul_inm_2_o  =>   dio_puls_inmed(2),		
      dio_puls_inmed_pul_inm_3_o  =>   dio_puls_inmed(3),		
      dio_puls_inmed_pul_inm_4_o  =>   dio_puls_inmed(4)
   );

  -- seconds timestamped FIFO-no-empty interrupts
  irq_fifos : for i in 0 to 4 generate
    irq_nempty(i)     <= not dio_tsf_wr_empty(i);

    process(clk_sys_i, rst_n_i) 
      begin
        if rising_edge(clk_sys_i) then
          if rst_n_i = '0' then
            dio_tsf_wr_req(i)        <= '0';
            dio_tsf_tag_seconds(i)   <= (others => '0');
            dio_tsf_tag_cycles(i)	 <= (others => '0');        
          else
            if ((tag_valid_p1(i) = '1') AND (dio_tsf_wr_full(i)='0')) then
              dio_tsf_wr_req(i)      <='1';
              dio_tsf_tag_seconds(i) <=tag_seconds(i);
              dio_tsf_tag_cycles(i)  <=tag_cycles(i);
            else
              dio_tsf_wr_req(i)      <='0';				
            end if;
          end if; 
        end if; 
      end process; 
    end generate irq_fifos;

-----------------------------------------------------------------------------------
------ signals for debugging
-----------------------------------------------------------------------------------
--     TRIG0               <= tag_utc(0)(31 downto 0);
--     TRIG1(27 downto 0)  <= tag_cycles(0)(27 downto 0);
--     TRIG1(0)  <= cbar_master_in(3).int;
--     TRIG2               <= tm_utc(31 downto 0);
    -- TRIG3(2 downto 0)   <= dio_in_i(0) & dio_out(0) & dio_puls_inmed(0);
    --TRIG3(4 downto 0)  <= dio_tsf_wr_req(0) & tag_valid_p1(0) & gpio_out(1) & dio_in_i(0) & dio_out(0);
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------	
end rtl;



