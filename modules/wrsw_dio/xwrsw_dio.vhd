-------------------------------------------------------------------------------
-- Title      : DIO Core
-- Project    : White Rabbit Network Interface
-------------------------------------------------------------------------------
-- File       : xwrsw_dio.vhd
-- Author     : Rafael Rodriguez, Javier Díaz
-- Company    : Seven Solutions
-- Created    : 2012-03-03
-- Last update: 2013-08-07
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
-- TODO: Include wb adapter
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2012-03-03  0.1      Rafa.r          Created
-- 2012-03-08  0.1      JDiaz           Added wrsw_dio_wb
-- 2012-07-05  0.2      JDiaz           Modified wrsw_dio_wb, modified interface
-- 2012-07-20  0.2      JDiaz           Include sdb support
-------------------------------------------------------------------------------
--     Memory map:
--       0x000: DIO-ONEWIRE
--       0x100: DIO-I2C
--       0x200: DIO-GPIO
--       0x300: DIO-TIMING REGISTERS
--       0x400: SDB-BRIDGE --> MAGIC NUMBER

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.wishbone_pkg.all;
use work.wrnic_sdb_pkg.all;

entity xwrsw_dio is
  generic (
    g_interface_mode      : t_wishbone_interface_mode      := CLASSIC;
    g_address_granularity : t_wishbone_address_granularity := WORD
  );
  port (
    clk_sys_i        : in  std_logic;
    clk_ref_i        : in  std_logic;
    rst_n_i          : in  std_logic;
		
    dio_clk_i        : in std_logic;
	--dio_pps_i        : in std_logic;
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
		
    slave_i            : in  t_wishbone_slave_in;
    slave_o            : out t_wishbone_slave_out;
   
	-- Debug signals for chipscope
    TRIG0            : out std_logic_vector(31 downto 0);
    TRIG1            : out std_logic_vector(31 downto 0);
    TRIG2            : out std_logic_vector(31 downto 0);
    TRIG3            : out std_logic_vector(31 downto 0)	 	 	 
  );
  end xwrsw_dio; 


architecture rtl of xwrsw_dio is

  -------------------------------------------------------------------------------
  -- Component only for debugging (in order to generate seconds time) 
  -------------------------------------------------------------------------------
  component dummy_time is
    port(
      clk_sys       : in std_logic;
      rst_n         : in std_logic; 
      tm_utc        : out std_logic_vector(39 downto 0);
      tm_cycles     : out std_logic_vector(27 downto 0));
  end component;	
  
  -------------------------------------------------------------------------------
  -- PULSE GENERATOR which produces a 1-tick-long pulse in its
  -- output when the seconds time passed to it through a vector equals a
  -- pre-programmed seconds time.
  -------------------------------------------------------------------------------
  component pulse_gen_pl  is
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
      trig_valid_p1_i : in std_logic;
      pulse_length_i  : in std_logic_vector(27 downto 0)
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
      tm_tai_i        : in std_logic_vector(39 downto 0);
      -- number of clk_ref_i cycles
      tm_cycles_i     : in std_logic_vector(27 downto 0);

      ---------------------------------------------------------------------------
      -- Time tag output (clk_sys_i domain)
      ---------------------------------------------------------------------------
      tag_tai_o    : out std_logic_vector(39 downto 0);
      tag_cycles_o : out std_logic_vector(27 downto 0);
      -- single-cycle pulse: strobe tag on tag_seconds_o and tag_cycles_o
      tag_valid_o  : out std_logic
    );
  end component;

  component immed_pulse_counter is
    generic (
    -- reference clock frequency
    pulse_length_width : integer := 28
    );

    port (
      clk_i          : in std_logic;    
      rst_n_i        : in std_logic;      -- asynchronous system reset
    
      pulse_start_i  : in std_logic;      -- strobe for pulse generation
      pulse_length_i : in std_logic_vector(pulse_length_width-1 downto 0);
  
      pulse_output_o : out std_logic
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
    dio_tsf0_tag_seconds_i                   : in     std_logic_vector(31 downto 0);
    dio_tsf0_tag_secondsh_i                  : in     std_logic_vector(7 downto 0);
    dio_tsf0_tag_cycles_i                    : in     std_logic_vector(27 downto 0);
    irq_nempty_0_i                           : in     std_logic;
-- FIFO write request
    dio_tsf1_wr_req_i                        : in     std_logic;
-- FIFO full flag
    dio_tsf1_wr_full_o                       : out    std_logic;
-- FIFO empty flag
    dio_tsf1_wr_empty_o                      : out    std_logic;
    dio_tsf1_tag_seconds_i                   : in     std_logic_vector(31 downto 0);
    dio_tsf1_tag_secondsh_i                  : in     std_logic_vector(7 downto 0);
    dio_tsf1_tag_cycles_i                    : in     std_logic_vector(27 downto 0);
    irq_nempty_1_i                           : in     std_logic;
-- FIFO write request
    dio_tsf2_wr_req_i                        : in     std_logic;
-- FIFO full flag
    dio_tsf2_wr_full_o                       : out    std_logic;
-- FIFO empty flag
    dio_tsf2_wr_empty_o                      : out    std_logic;
    dio_tsf2_tag_seconds_i                   : in     std_logic_vector(31 downto 0);
    dio_tsf2_tag_secondsh_i                  : in     std_logic_vector(7 downto 0);
    dio_tsf2_tag_cycles_i                    : in     std_logic_vector(27 downto 0);
    irq_nempty_2_i                           : in     std_logic;
-- FIFO write request
    dio_tsf3_wr_req_i                        : in     std_logic;
-- FIFO full flag
    dio_tsf3_wr_full_o                       : out    std_logic;
-- FIFO empty flag
    dio_tsf3_wr_empty_o                      : out    std_logic;
    dio_tsf3_tag_seconds_i                   : in     std_logic_vector(31 downto 0);
    dio_tsf3_tag_secondsh_i                  : in     std_logic_vector(7 downto 0);
    dio_tsf3_tag_cycles_i                    : in     std_logic_vector(27 downto 0);
    irq_nempty_3_i                           : in     std_logic;
-- FIFO write request
    dio_tsf4_wr_req_i                        : in     std_logic;
-- FIFO full flag
    dio_tsf4_wr_full_o                       : out    std_logic;
-- FIFO empty flag
    dio_tsf4_wr_empty_o                      : out    std_logic;
    dio_tsf4_tag_seconds_i                   : in     std_logic_vector(31 downto 0);
    dio_tsf4_tag_secondsh_i                  : in     std_logic_vector(7 downto 0);
    dio_tsf4_tag_cycles_i                    : in     std_logic_vector(27 downto 0);
    irq_nempty_4_i                           : in     std_logic;
-- Port for std_logic_vector field: 'seconds field' in reg: 'fmc-dio 0 seconds-based trigger for pulse generation'
    dio_trig0_seconds_o                      : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'seconds field' in reg: 'fmc-dio 0 seconds-based trigger for pulse generation'
    dio_trigh0_seconds_o                     : out    std_logic_vector(7 downto 0);
-- Port for std_logic_vector field: 'cycles field' in reg: 'fmc-dio 0 cycles to  trigger a pulse generation'
    dio_cyc0_cyc_o                           : out    std_logic_vector(27 downto 0);
-- Port for std_logic_vector field: 'seconds field' in reg: 'fmc-dio 1 seconds-based trigger for pulse generation'
    dio_trig1_seconds_o                      : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'seconds field' in reg: 'fmc-dio 1 seconds-based trigger for pulse generation'
    dio_trigh1_seconds_o                     : out    std_logic_vector(7 downto 0);
-- Port for std_logic_vector field: 'cycles field' in reg: 'fmc-dio 1 cycles to  trigger a pulse generation'
    dio_cyc1_cyc_o                           : out    std_logic_vector(27 downto 0);
-- Port for std_logic_vector field: 'seconds field' in reg: 'fmc-dio 2 seconds-based trigger for pulse generation'
    dio_trig2_seconds_o                      : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'seconds field' in reg: 'fmc-dio 2 seconds-based trigger for pulse generation'
    dio_trigh2_seconds_o                     : out    std_logic_vector(7 downto 0);
-- Port for std_logic_vector field: 'cycles field' in reg: 'fmc-dio 2 cycles to  trigger a pulse generation'
    dio_cyc2_cyc_o                           : out    std_logic_vector(27 downto 0);
-- Port for std_logic_vector field: 'seconds field' in reg: 'fmc-dio 3 seconds-based trigger for pulse generation'
    dio_trig3_seconds_o                      : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'seconds field' in reg: 'fmc-dio 3 seconds-based trigger for pulse generation'
    dio_trigh3_seconds_o                     : out    std_logic_vector(7 downto 0);
-- Port for std_logic_vector field: 'cycles field' in reg: 'fmc-dio 3 cycles to  trigger a pulse generation'
    dio_cyc3_cyc_o                           : out    std_logic_vector(27 downto 0);
-- Port for std_logic_vector field: 'seconds field' in reg: 'fmc-dio 4 seconds-based trigger for pulse generation'
    dio_trig4_seconds_o                      : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'seconds field' in reg: 'fmc-dio 4 seconds-based trigger for pulse generation'
    dio_trigh4_seconds_o                     : out    std_logic_vector(7 downto 0);
-- Port for std_logic_vector field: 'cycles field' in reg: 'fmc-dio 4 cycles to  trigger a pulse generation'
    dio_cyc4_cyc_o                           : out    std_logic_vector(27 downto 0);
-- Port for unsigned field: 'channel' in reg: 'FMC-DIO input/output configuration register. '
    dio_iomode_ch0_o                         : out    std_logic_vector(3 downto 0);
    dio_iomode_ch0_i                         : in     std_logic_vector(3 downto 0);
    dio_iomode_ch0_load_o                    : out    std_logic;
-- Port for unsigned field: 'channel1' in reg: 'FMC-DIO input/output configuration register. '
    dio_iomode_ch1_o                         : out    std_logic_vector(3 downto 0);
    dio_iomode_ch1_i                         : in     std_logic_vector(3 downto 0);
    dio_iomode_ch1_load_o                    : out    std_logic;
-- Port for unsigned field: 'channel2' in reg: 'FMC-DIO input/output configuration register. '
    dio_iomode_ch2_o                         : out    std_logic_vector(3 downto 0);
    dio_iomode_ch2_i                         : in     std_logic_vector(3 downto 0);
    dio_iomode_ch2_load_o                    : out    std_logic;
-- Port for unsigned field: 'channel3' in reg: 'FMC-DIO input/output configuration register. '
    dio_iomode_ch3_o                         : out    std_logic_vector(3 downto 0);
    dio_iomode_ch3_i                         : in     std_logic_vector(3 downto 0);
    dio_iomode_ch3_load_o                    : out    std_logic;
-- Port for unsigned field: 'channel4' in reg: 'FMC-DIO input/output configuration register. '
    dio_iomode_ch4_o                         : out    std_logic_vector(3 downto 0);
    dio_iomode_ch4_i                         : in     std_logic_vector(3 downto 0);
    dio_iomode_ch4_load_o                    : out    std_logic;
-- Port for MONOSTABLE field: 'Sincle-cycle strobe' in reg: 'Time-programmable output strobe signal'
    dio_latch_time_ch0_o                     : out    std_logic;
-- Port for MONOSTABLE field: 'Sincle-cycle strobe' in reg: 'Time-programmable output strobe signal'
    dio_latch_time_ch1_o                     : out    std_logic;
-- Port for MONOSTABLE field: 'Sincle-cycle strobe' in reg: 'Time-programmable output strobe signal'
    dio_latch_time_ch2_o                     : out    std_logic;
-- Port for MONOSTABLE field: 'Sincle-cycle strobe' in reg: 'Time-programmable output strobe signal'
    dio_latch_time_ch3_o                     : out    std_logic;
-- Port for MONOSTABLE field: 'Sincle-cycle strobe' in reg: 'Time-programmable output strobe signal'
    dio_latch_time_ch4_o                     : out    std_logic;
-- Port for std_logic_vector field: 'trig_rdy field' in reg: 'FMC-DIO time trigger is ready to accept a new trigger generation request'
    dio_trig_rdy_i                           : in     std_logic_vector(4 downto 0);
    irq_trigger_ready_0_i                    : in     std_logic;
    irq_trigger_ready_1_i                    : in     std_logic;
    irq_trigger_ready_2_i                    : in     std_logic;
    irq_trigger_ready_3_i                    : in     std_logic;
    irq_trigger_ready_4_i                    : in     std_logic;
-- Port for std_logic_vector field: 'number of ticks field for channel 0' in reg: 'fmc-dio channel 0 Programmable/immediate output pulse length'
    dio_prog0_pulse_length_o                 : out    std_logic_vector(27 downto 0);
-- Port for std_logic_vector field: 'number of ticks field for channel 1' in reg: 'fmc-dio channel 1 Programmable/immediate output pulse length'
    dio_prog1_pulse_length_o                 : out    std_logic_vector(27 downto 0);
-- Port for std_logic_vector field: 'number of ticks field for channel 2' in reg: 'fmc-dio channel 2 Programmable/immediate output pulse length'
    dio_prog2_pulse_length_o                 : out    std_logic_vector(27 downto 0);
-- Port for std_logic_vector field: 'number of ticks field for channel 3' in reg: 'fmc-dio channel 3 Programmable/immediate output pulse length'
    dio_prog3_pulse_length_o                 : out    std_logic_vector(27 downto 0);
-- Port for std_logic_vector field: 'number of ticks field for channel 4' in reg: 'fmc-dio channel 4 Programmable/immediate output pulse length'
    dio_prog4_pulse_length_o                 : out    std_logic_vector(27 downto 0);
-- Port for asynchronous (clock: clk_asyn_i) MONOSTABLE field: 'pulse_gen_now_0' in reg: 'Pulse generate immediately'
    dio_pulse_imm_0_o                        : out    std_logic;
-- Port for asynchronous (clock: clk_asyn_i) MONOSTABLE field: 'pulse_gen_now_1' in reg: 'Pulse generate immediately'
    dio_pulse_imm_1_o                        : out    std_logic;
-- Port for asynchronous (clock: clk_asyn_i) MONOSTABLE field: 'pulse_gen_now_2' in reg: 'Pulse generate immediately'
    dio_pulse_imm_2_o                        : out    std_logic;
-- Port for asynchronous (clock: clk_asyn_i) MONOSTABLE field: 'pulse_gen_now_3' in reg: 'Pulse generate immediately'
    dio_pulse_imm_3_o                        : out    std_logic;
-- Port for asynchronous (clock: clk_asyn_i) MONOSTABLE field: 'pulse_gen_now_4' in reg: 'Pulse generate immediately'
    dio_pulse_imm_4_o                        : out    std_logic
	 );
  end component;


  ------------------------------------------------------------------------------
  -- Constants declaration
  ------------------------------------------------------------------------------

  constant c_WB_SLAVES_DIO  : integer := 4;	-- Number of WB slaves in DIO
  constant c_IOMODE_NB : integer := 4;			-- Number of bit per channel for iomode reg

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
  type t_seconds_array     is array (4 downto 0) of std_logic_vector (39 downto 0);
  type t_cycles_array      is array (4 downto 0) of std_logic_vector (27 downto 0);
  type t_pulselength_array is array (4 downto 0) of std_logic_vector (27 downto 0);
  
  signal trig_seconds   : t_seconds_array;
  signal trig_cycles    : t_cycles_array;
  signal trig_valid_p1 	: std_logic_vector (4 downto 0);
  
  signal trig_ready     : std_logic_vector (4 downto 0);
  
  signal tag_seconds    : t_seconds_array;
  signal tag_cycles     : t_cycles_array;
  signal tag_valid_p1   : std_logic_vector (4 downto 0);
  signal pulse_length   : t_pulselength_array; 

  -- FIFO signals
  signal dio_tsf_wr_req      : std_logic_vector (4 downto 0);
  signal dio_tsf_wr_full     : std_logic_vector (4 downto 0);
  signal dio_tsf_wr_empty    : std_logic_vector (4 downto 0);
  signal dio_tsf_tag_seconds : t_seconds_array;
  signal dio_tsf_tag_cycles  : t_cycles_array;
  
  -- Fifos no-empty interrupts
  signal irq_nempty          : std_logic_vector (4 downto 0);

  -- DEBUG SIGNALS FOR USING seconds time values from dummy_time instead WRPC
  signal tm_seconds             : std_logic_vector (39 downto 0);
  signal tm_cycles              : std_logic_vector (27 downto 0);
	
  -- WB SDB Crossbar
  constant c_diobar_layout : t_sdb_record_array(3 downto 0) :=
    (0 => f_sdb_embed_device(c_xwb_onewire_master_sdb ,   x"00000000"), -- ONEWIRE
     1 => f_sdb_embed_device(c_xwb_i2c_master_sdb     ,   x"00000100"), -- I2C
     2 => f_sdb_embed_device(c_xwb_gpio_port_sdb      ,   x"00000200"), -- GPIO
     3 => f_sdb_embed_device(c_xwrsw_dio_wb_sdb       ,   x"00000300")  -- DIO REGISTERS
     );	  
  constant c_diobar_sdb_address : t_wishbone_address := x"00000400";	  

  signal cbar_master_in   : t_wishbone_master_in_array(c_WB_SLAVES_DIO-1 downto 0);
  signal cbar_master_out  : t_wishbone_master_out_array(c_WB_SLAVES_DIO-1 downto 0);

  signal slave_bypass_i   : t_wishbone_slave_in;
  signal slave_bypass_o   : t_wishbone_slave_out;

  signal wb_dio_slave_in   : t_wishbone_slave_in;
  signal wb_dio_slave_out  : t_wishbone_slave_out;

  -- DIO related signals
  signal dio_pulse           : std_logic_vector(4 downto 0);
  signal dio_pulse_prog      : std_logic_vector(4 downto 0);
  signal dio_pulse_immed     : std_logic_vector(4 downto 0);
  signal dio_pulse_immed_stb : std_logic_vector(4 downto 0);
  signal dio_iomode_reg   	  : std_logic_vector(19 downto 0);
  signal dio_iomode_o   	  : std_logic_vector(19 downto 0);
  signal dio_iomode_load_o	  : std_logic_vector(4 downto 0);
  signal wb_dio_irq          : std_logic;
  
-------------------------------------------------------------------------------
-- rtl
-------------------------------------------------------------------------------
begin  

  -- Dummy counter for simulationg WRPC seconds time
--  U_dummy: dummy_time
--    port map(
--      clk_sys     => clk_ref_i,
--      rst_n       => rst_n_i, 
--      tm_utc      => tm_seconds, 
--      tm_cycles   => tm_cycles
--    );	
	
  ------------------------------------------------------------------------------
  -- GEN AND STAMPER
  ------------------------------------------------------------------------------    
  gen_pulse_modules : for i in 0 to 4 generate
    U_pulse_gen : pulse_gen_pl
      port map(
        clk_ref_i        => clk_ref_i,
        clk_sys_i        => clk_sys_i,
        rst_n_i          => rst_n_i,

        pulse_o          => dio_pulse_prog(i),
        -- DEBUG
--        tm_time_valid_i  => '1',--tm_time_valid_i,
--        tm_utc_i         => tm_seconds,--tm_utc_i, 
--        tm_cycles_i      => tm_cycles, --tm_cycles_i, 
        tm_time_valid_i  => tm_time_valid_i,
        tm_utc_i         => tm_seconds_i, 
        tm_cycles_i      => tm_cycles_i, 
		
        trig_ready_o     => trig_ready(i),

        trig_utc_i       => trig_seconds(i), 
        trig_cycles_i    => trig_cycles(i), 
        trig_valid_p1_i  => trig_valid_p1(i),
		  pulse_length_i   => pulse_length(i)
		  );
	 

    U_PULSE_STAMPER : pulse_stamper
      port map(
        clk_ref_i       => clk_ref_i,
        clk_sys_i       => clk_sys_i,
        rst_n_i         => rst_n_i,

        pulse_a_i       => dio_in_i(i),
        
		  -- DEBUG
--        tm_time_valid_i => '1',
--        tm_utc_i        => tm_seconds,  
--        tm_cycles_i     => tm_cycles, 
        tm_time_valid_i => tm_time_valid_i,
        tm_tai_i        => tm_seconds_i, 
        tm_cycles_i     => tm_cycles_i, 

        tag_tai_o    => tag_seconds(i), 
        tag_cycles_o => tag_cycles(i), 
        tag_valid_o  => tag_valid_p1(i));

  end generate gen_pulse_modules;       

  ------------------------------------------------------------------------------
  -- WB ONEWIRE MASTER
  ------------------------------------------------------------------------------    
  U_ONEWIRE : xwb_onewire_master
    generic map (
      g_interface_mode => g_interface_mode,
      g_address_granularity => g_address_granularity,
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
  -- i2c core does not handle extra signals. 
--  cbar_master_in(1).err<='0';
--  cbar_master_in(1).rty<='0';
  
  U_I2C : xwb_i2c_master
    generic map (
      g_interface_mode => g_interface_mode,
      g_address_granularity => g_address_granularity
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
      g_interface_mode         => g_interface_mode,
      g_address_granularity => g_address_granularity,
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
 WB_DIO_INTERCON : xwb_sdb_crossbar
    generic map(
      g_num_masters => 1,
      g_num_slaves  => 4,
      g_registered  => true,
      g_wraparound  => true,
      g_layout      => c_diobar_layout,
      g_sdb_addr    => c_diobar_sdb_address
      )
    port map(
      clk_sys_i  => clk_sys_i,
      rst_n_i    => rst_n_i,
      -- Master connections
      slave_i(0)    => slave_bypass_i,
      slave_o(0)    => slave_bypass_o,
      -- Slave conenctions
      master_i      => cbar_master_in,
      master_o      => cbar_master_out
      );				

  -- Irq form one slave is bypassed to the Master connection 
  slave_bypass_i.cyc <= slave_i.cyc;
  slave_bypass_i.stb <= slave_i.stb;
  slave_bypass_i.adr <= slave_i.adr;
  slave_bypass_i.sel <= slave_i.sel;
  slave_bypass_i.dat <= slave_i.dat;	
  slave_bypass_i.we  <= slave_i.we;	

  slave_o.ack        <= slave_bypass_o.ack;		
  slave_o.stall      <= slave_bypass_o.stall;
  slave_o.int        <= wb_dio_irq;
  slave_o.dat        <= slave_bypass_o.dat;	 
  slave_o.err        <= slave_bypass_o.err;
  slave_o.rty        <= slave_bypass_o.rty;

  immediate_output_with_pulse_length: for i in 0 to 4 generate
    immediate_output_component: immed_pulse_counter
    generic map (
      pulse_length_width => 28
    )
    port map(
      clk_i          => clk_ref_i,
      rst_n_i        => rst_n_i,
      pulse_start_i  => dio_pulse_immed_stb(i),
      pulse_length_i => pulse_length(i),
      pulse_output_o => dio_pulse_immed(i)
    );
  end generate immediate_output_with_pulse_length;

  gen_pio_assignment: for i in 0 to 4 generate
    gpio_in(c_IOMODE_NB*i)     <= dio_in_i(i);
    dio_pulse(i) <= '1' when dio_pulse_immed(i) = '1' else dio_pulse_prog(i);
    dio_oe_n_o(i)    <= dio_iomode_reg(c_IOMODE_NB*i+2);
    dio_term_en_o(i) <= dio_iomode_reg(c_IOMODE_NB*i+3);
    dio_out_o(i) <= gpio_out(c_IOMODE_NB*i) when dio_iomode_reg(c_IOMODE_NB*i+1 downto c_IOMODE_NB*i)="00" else dio_pulse(i);
    
    --with dio_iomode_reg(c_IOMODE_NB*i+1 downto c_IOMODE_NB*i)
	 --select dio_out_o(i) <=
	--	gpio_out(c_IOMODE_NB*i) when "00", --GPIO out as also 4 bits per channel
	--	dio_pulse(i) when "01",
	--	--dio_pps_i when "10",
	--	'1' when others;	--Error output will stay at one (similar as GPIO set to one)

  end generate gen_pio_assignment;

  dio_led_bot_o  <=  dio_iomode_reg(c_IOMODE_NB*0+3) OR 
							dio_iomode_reg(c_IOMODE_NB*1+3) OR
							dio_iomode_reg(c_IOMODE_NB*2+3) OR
							dio_iomode_reg(c_IOMODE_NB*3+3) OR
							dio_iomode_reg(c_IOMODE_NB*4+3);
  dio_led_top_o  <= gpio_out(27);
  
  --gpio_in(29)    <= dio_clk_i;
  dio_sdn_ck_n_o <= gpio_out(30);
  dio_sdn_n_o    <= gpio_out(31);

  -- Adapter of wbgen2 salve signals to top wb mode and granularity
  U_Adapter : wb_slave_adapter
    generic map (
      g_master_use_struct  => true,
      g_master_mode        => PIPELINED,
      g_master_granularity => WORD, -- only word acesses are available for wbgen2 slaves
      g_slave_use_struct   => true,
      g_slave_mode         => g_interface_mode,
      g_slave_granularity  => g_address_granularity)
    port map (
      clk_sys_i => clk_sys_i,
      rst_n_i   => rst_n_i,
      slave_i   => cbar_master_out(3),
      slave_o   => cbar_master_in (3),
      master_i  => wb_dio_slave_out,
      master_o  => wb_dio_slave_in);
 
  ------------------------------------------------------------------------------
  -- WB DIO control registers
  ------------------------------------------------------------------------------  
  wb_dio_slave_out.err<='0';
  wb_dio_slave_out.rty<='0';
  wb_dio_slave_out.int<='0'; -- Real signal we bypass to crossbar
  
  -- SUPPORTING PIPELINE WBGEN2 SLAVES
  U_DIO_REGISTERS : wrsw_dio_wb 
    port map(
      rst_n_i     => rst_n_i,
      clk_sys_i   => clk_sys_i,
      wb_adr_i    => wb_dio_slave_in.adr(5 downto 0), 
      wb_dat_i    => wb_dio_slave_in.dat,
      wb_dat_o    => wb_dio_slave_out.dat,
      wb_cyc_i    => wb_dio_slave_in.cyc, 
      wb_sel_i    => wb_dio_slave_in.sel, 
      wb_stb_i    => wb_dio_slave_in.stb, 
      wb_we_i     => wb_dio_slave_in.we,  
      wb_ack_o    => wb_dio_slave_out.ack,
      wb_stall_o  => wb_dio_slave_out.stall,
		-- Crossbar could not propagate interrupt lines of several slaves  => signal bypass
      wb_int_o    => wb_dio_irq, 
      clk_asyn_i  => clk_ref_i,

      dio_tsf0_wr_req_i       => dio_tsf_wr_req(0),
      dio_tsf0_wr_full_o      => dio_tsf_wr_full(0),
      dio_tsf0_wr_empty_o     => dio_tsf_wr_empty(0),
      dio_tsf0_tag_seconds_i  => dio_tsf_tag_seconds(0)(31 downto 0),
      dio_tsf0_tag_secondsh_i => dio_tsf_tag_seconds(0)(39 downto 32),
      dio_tsf0_tag_cycles_i   => dio_tsf_tag_cycles(0),
      irq_nempty_0_i          => irq_nempty(0),

      dio_tsf1_wr_req_i       => dio_tsf_wr_req(1),
      dio_tsf1_wr_full_o      => dio_tsf_wr_full(1),
      dio_tsf1_wr_empty_o     => dio_tsf_wr_empty(1),
      dio_tsf1_tag_seconds_i  => dio_tsf_tag_seconds(1)(31 downto 0),
      dio_tsf1_tag_secondsh_i => dio_tsf_tag_seconds(1)(39 downto 32),
      dio_tsf1_tag_cycles_i   => dio_tsf_tag_cycles(1),
      irq_nempty_1_i          => irq_nempty(1),

      dio_tsf2_wr_req_i       => dio_tsf_wr_req(2),
      dio_tsf2_wr_full_o      => dio_tsf_wr_full(2),
      dio_tsf2_wr_empty_o     => dio_tsf_wr_empty(2),
      dio_tsf2_tag_seconds_i  => dio_tsf_tag_seconds(2)(31 downto 0),
      dio_tsf2_tag_secondsh_i => dio_tsf_tag_seconds(2)(39 downto 32),
      dio_tsf2_tag_cycles_i   => dio_tsf_tag_cycles(2),
      irq_nempty_2_i          => irq_nempty(2),

      dio_tsf3_wr_req_i       => dio_tsf_wr_req(3),
      dio_tsf3_wr_full_o      => dio_tsf_wr_full(3),
      dio_tsf3_wr_empty_o     => dio_tsf_wr_empty(3),
      dio_tsf3_tag_seconds_i  => dio_tsf_tag_seconds(3)(31 downto 0),
      dio_tsf3_tag_secondsh_i => dio_tsf_tag_seconds(3)(39 downto 32),
      dio_tsf3_tag_cycles_i   => dio_tsf_tag_cycles(3),
      irq_nempty_3_i          => irq_nempty(3),

      dio_tsf4_wr_req_i       => dio_tsf_wr_req(4),
      dio_tsf4_wr_full_o      => dio_tsf_wr_full(4),
      dio_tsf4_wr_empty_o     => dio_tsf_wr_empty(4),
      dio_tsf4_tag_seconds_i  => dio_tsf_tag_seconds(4)(31 downto 0),
      dio_tsf4_tag_secondsh_i => dio_tsf_tag_seconds(4)(39 downto 32),
      dio_tsf4_tag_cycles_i   => dio_tsf_tag_cycles(4),
      irq_nempty_4_i          => irq_nempty(4),

      dio_trig0_seconds_o 	   => trig_seconds(0)(31 downto 0), 
      dio_trigh0_seconds_o	   => trig_seconds(0)(39 downto 32),
      dio_cyc0_cyc_o          => trig_cycles(0),

      dio_trig1_seconds_o     => trig_seconds(1)(31 downto 0), 
      dio_trigh1_seconds_o    => trig_seconds(1)(39 downto 32),
      dio_cyc1_cyc_o          => trig_cycles(1),

      dio_trig2_seconds_o     => trig_seconds(2)(31 downto 0), 
      dio_trigh2_seconds_o    => trig_seconds(2)(39 downto 32),
      dio_cyc2_cyc_o          => trig_cycles(2),

      dio_trig3_seconds_o     => trig_seconds(3)(31 downto 0), 
      dio_trigh3_seconds_o    => trig_seconds(3)(39 downto 32),
      dio_cyc3_cyc_o          => trig_cycles(3),

      dio_trig4_seconds_o     => trig_seconds(4)(31 downto 0), 
      dio_trigh4_seconds_o    => trig_seconds(4)(39 downto 32),
      dio_cyc4_cyc_o          => trig_cycles(4),

	  dio_iomode_ch0_i        => dio_iomode_reg(3  downto 0),
	  dio_iomode_ch1_i        => dio_iomode_reg(7  downto 4),
	  dio_iomode_ch2_i        => dio_iomode_reg(11 downto 8),
	  dio_iomode_ch3_i        => dio_iomode_reg(15 downto 12),
	  dio_iomode_ch4_i        => dio_iomode_reg(19 downto 16),

	  dio_iomode_ch0_o        => dio_iomode_o(3 downto 0),
	  dio_iomode_ch1_o        => dio_iomode_o(7 downto 4),
	  dio_iomode_ch2_o        => dio_iomode_o(11 downto 8),
	  dio_iomode_ch3_o        => dio_iomode_o(15 downto 12),
	  dio_iomode_ch4_o        => dio_iomode_o(19 downto 16),

	  dio_iomode_ch0_load_o   => dio_iomode_load_o(0),
	  dio_iomode_ch1_load_o   => dio_iomode_load_o(1),
	  dio_iomode_ch2_load_o   => dio_iomode_load_o(2),
	  dio_iomode_ch3_load_o   => dio_iomode_load_o(3),
	  dio_iomode_ch4_load_o   => dio_iomode_load_o(4),

      dio_latch_time_ch0_o    => trig_valid_p1(0),
      dio_latch_time_ch1_o    => trig_valid_p1(1),
      dio_latch_time_ch2_o    => trig_valid_p1(2),
      dio_latch_time_ch3_o    => trig_valid_p1(3),
      dio_latch_time_ch4_o    => trig_valid_p1(4),

      dio_trig_rdy_i          => trig_ready,

      irq_trigger_ready_0_i   => trig_ready(0),
      irq_trigger_ready_1_i   => trig_ready(1),
      irq_trigger_ready_2_i   => trig_ready(2),
      irq_trigger_ready_3_i   => trig_ready(3),
      irq_trigger_ready_4_i   => trig_ready(4),      

      dio_prog0_pulse_length_o=> pulse_length(0),
      dio_prog1_pulse_length_o=> pulse_length(1),
      dio_prog2_pulse_length_o=> pulse_length(2),
      dio_prog3_pulse_length_o=> pulse_length(3),
      dio_prog4_pulse_length_o=> pulse_length(4),

      dio_pulse_imm_0_o       => dio_pulse_immed_stb(0),
      dio_pulse_imm_1_o       => dio_pulse_immed_stb(1),
      dio_pulse_imm_2_o       => dio_pulse_immed_stb(2),
      dio_pulse_imm_3_o       => dio_pulse_immed_stb(3),
      dio_pulse_imm_4_o       => dio_pulse_immed_stb(4)
   );

  -- seconds timestamped FIFO-no-empty interrupts
	irq_nempty(0)     <= not dio_tsf_wr_empty(0);
	irq_nempty(1)     <= not dio_tsf_wr_empty(1);
	irq_nempty(2)    <= not dio_tsf_wr_empty(2);
	irq_nempty(3)     <= not dio_tsf_wr_empty(3);

	--disable interrupts when setup in clock mode.
	irq_nempty(4)     <= not dio_tsf_wr_empty(4) when (dio_iomode_reg(18 downto 16) /= "110");

  irq_fifos : for i in 0 to 4 generate
    process(clk_sys_i)
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

	process(clk_sys_i)
	begin
		if rising_edge(clk_sys_i) then
			-- Set default configuration for each channel at reset
			if rst_n_i = '0' then
				dio_iomode_reg(0*c_IOMODE_NB+3 downto 0*c_IOMODE_NB) <= "0000"; -- mode 0 0
				dio_iomode_reg(3*c_IOMODE_NB+3 downto 3*c_IOMODE_NB) <= "0100"; -- mode 3 i
				dio_iomode_reg(4*c_IOMODE_NB+3 downto 4*c_IOMODE_NB) <= "0110"; -- mode 4 C
			else
			-- Set up register iomode for each channel
				for i in 0 to 4 loop
					if (dio_iomode_load_o(i) = '1') then
					dio_iomode_reg(c_IOMODE_NB*i+3 downto c_IOMODE_NB*i) <= dio_iomode_o(c_IOMODE_NB*i+3 downto c_IOMODE_NB*i);
					end if;
				end loop;
			end if;
		end if;
	end process;

-----------------------------------------------------------------------------------
------ signals for debugging
-----------------------------------------------------------------------------------
     TRIG0(21 downto 0 ) <= tag_seconds(0)(21 downto 0);
	  TRIG0(22)           <= irq_nempty(0);
	  TRIG0(23)           <= tm_time_valid_i;
	  TRIG0(31 downto 24) <= pulse_length(0)(7 downto 0);
     TRIG1(27 downto 0)  <= tag_cycles(0)(27 downto 0);
     TRIG1(28)  <= slave_bypass_o.int;
     TRIG1(29)  <= slave_bypass_o.ack;
	  TRIG1(30)  <= dio_pulse(0);
	  TRIG1(31)  <= gpio_out(0);     
     --TRIG3(2 downto 0)   <= 
     --TRIG3(4 downto 0)  <= 
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------	
end rtl;



