-------------------------------------------------------------------------------
-- Title      : WhiteRabbit Network Interface Card
-- Project    : WhiteRabbit
-------------------------------------------------------------------------------
-- File       : wr_nic_top.vhd
-- Author     : Grzegorz Daniluk, Rafael Rodriguez, Javier Díaz
-- Company    : Elproma, Seven Solutions, UGR
-- Created    : 2012-02-08
-- Last update: 2012-09-19
-- Platform   : FPGA-generics
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description:
-- White Rabbit Network Interface Card (WR NIC) consists of:
-- # White Rabbit PTP Core
-- # WRSW NIC module
-- # WB Crossbar
-- # IRQ Gen (VIC core)
-- # WRSW TxTSU module
-- # GN4124 core
-- # DIO core 
-- # 
-------------------------------------------------------------------------------
-- Copyright (c) 2012 Grzegorz Daniluk, Rafael Rodriguez, Javier Díaz
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2012-02-08  1.0      greg.d          Created
-- 2012-02-20  1.1      greg.d          added GN4124 to wrsw_nic DMA connection
-- 2012-03-10  1.2      rafa.r          added dio_core
-- 2012-06-25  1.3         jdiaz                  New dio_functionality
-- 2012-07-06  1.4         jdiaz           Updating of files and integration test
-------------------------------------------------------------------------------
-- TODO:
-- testing
-- Include wb adapter

-- Memory map:
--  0x00000000: WRPC
--     0x00000: WRPC I/D Memory
--     0x20000: WRPC Peripheral interconnect
--      +0x000: WRPC Minic
--      +0x100: WRPC Endpoint
--      +0x200: WRPC Softpll
--      +0x300: WRPC PPS gen
--      +0x400: WRPC Syscon
--      +0x500: WRPC UART
--      +0x600: WRPC OneWire
--      +0x700: WRPC Auxillary space (Etherbone config, etc)
--  0x00040000: WRSW NIC
--  0x00060000: VIC  
--  0x00061000: TxTSU
--  0x00062000: DIO
--       0x000: DIO-ONEWIRE
--       0x100: DIO-I2C
--       0x200: DIO-GPIO
--       0x300: DIO-TIMING REGISTERS
--  0x00063000: SDB-BRIDGE --> MAGIC NUMBER 

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library UNISIM;
use UNISIM.vcomponents.all;

--library work;
--use work.wishbone_pkg.all;
--use work.gn4124_core_pkg.all;
--use work.gencores_pkg.all;
--use work.wrcore_pkg.all;
--use work.wr_fabric_pkg.all;
--use work.endpoint_pkg.all;
--use work.genram_pkg.all;
--use work.wr_xilinx_pkg.all;
--use work.wrnic_sdb_pkg.all;


use work.gn4124_core_pkg.all;
use work.gencores_pkg.all;
use work.wrcore_pkg.all;
use work.wr_fabric_pkg.all;
use work.wr_xilinx_pkg.all;
--use work.etherbone_pkg.all;

--library UNISIM;
--use UNISIM.vcomponents.all;

library work;
use work.wishbone_pkg.all;
use work.endpoint_pkg.all;
use work.wrnic_sdb_pkg.all;


entity wr_nic_sdb_top is
  generic
    (
      g_nic_usedma : boolean := false;
      g_simulation : integer := 0);
  port
    (
      -- Global ports
      clk_20m_vcxo_i : in std_logic;    -- 20MHz VCXO clock

      clk_125m_pllref_p_i : in std_logic;  -- 125 MHz PLL reference
      clk_125m_pllref_n_i : in std_logic;

      fpga_pll_ref_clk_101_p_i : in std_logic;  -- Dedicated clock for Xilinx GTP transceiver
      fpga_pll_ref_clk_101_n_i : in std_logic;

      -- From GN4124 Local bus
      L_CLKp : in std_logic;  -- Local bus clock (frequency set in GN4124 config registers)
      L_CLKn : in std_logic;  -- Local bus clock (frequency set in GN4124 config registers)

      L_RST_N : in std_logic;           -- Reset from GN4124 (RSTOUT18_N)

      -- General Purpose Interface
      GPIO       : inout std_logic_vector(1 downto 0);  -- GPIO[0] -> GN4124 GPIO8 -- T.B.V. datasheet write 9 
                                     -- GPIO[1] -> GN4124 GPIO9 -- T.B.V. datasheet write 9 
      -- PCIe to Local [Inbound Data] - RX
      P2L_RDY    : out   std_logic;     -- Rx Buffer Full Flag
      P2L_CLKn   : in    std_logic;     -- Receiver Source Synchronous Clock-
      P2L_CLKp   : in    std_logic;     -- Receiver Source Synchronous Clock+
      P2L_DATA   : in    std_logic_vector(15 downto 0);  -- Parallel receive data
      P2L_DFRAME : in    std_logic;     -- Receive Frame
      P2L_VALID  : in    std_logic;     -- Receive Data Valid

      -- Inbound Buffer Request/Status
      P_WR_REQ : in  std_logic_vector(1 downto 0);  -- PCIe Write Request
      P_WR_RDY : out std_logic_vector(1 downto 0);  -- PCIe Write Ready
      RX_ERROR : out std_logic;                     -- Receive Error

      -- Local to Parallel [Outbound Data] - TX
      L2P_DATA   : out std_logic_vector(15 downto 0);  -- Parallel transmit data
      L2P_DFRAME : out std_logic;       -- Transmit Data Frame
      L2P_VALID  : out std_logic;       -- Transmit Data Valid
      L2P_CLKn   : out std_logic;  -- Transmitter Source Synchronous Clock-
      L2P_CLKp   : out std_logic;  -- Transmitter Source Synchronous Clock+
      L2P_EDB    : out std_logic;       -- Packet termination and discard

      -- Outbound Buffer Status
      L2P_RDY    : in std_logic;        -- Tx Buffer Full Flag
      L_WR_RDY   : in std_logic_vector(1 downto 0);  -- Local-to-PCIe Write
      P_RD_D_RDY : in std_logic_vector(1 downto 0);  -- PCIe-to-Local Read Response Data Ready
      TX_ERROR   : in std_logic;        -- Transmit Error
      VC_RDY     : in std_logic_vector(1 downto 0);  -- Channel ready

      -- Front panel LEDs
      LED_RED   : out std_logic;
      LED_GREEN : out std_logic;

      dac_sclk_o  : out std_logic;
      dac_din_o   : out std_logic;
      dac_clr_n_o : out std_logic;      -- NOT AVAILABLE
      dac_cs1_n_o : out std_logic;
      dac_cs2_n_o : out std_logic;

      --fpga_scl_b : inout std_logic;
      --fpga_sda_b : inout std_logic;

      button1_i : in std_logic;
      button2_i : in std_logic;

      thermo_id : inout std_logic;      -- 1-Wire interface to DS18B20 on SPEC

      -------------------------------------------------------------------------
      -- SFP pins
      -------------------------------------------------------------------------

      sfp_txp_o : out std_logic;
      sfp_txn_o : out std_logic;

      sfp_rxp_i : in std_logic;
      sfp_rxn_i : in std_logic;

      sfp_mod_def0_b    : in    std_logic;  -- sfp detect
      sfp_mod_def1_b    : inout std_logic;  -- scl
      sfp_mod_def2_b    : inout std_logic;  -- sda
      sfp_rate_select_b : inout std_logic;
      sfp_tx_fault_i    : in    std_logic;
      sfp_tx_disable_o  : out   std_logic;
      sfp_los_i         : in    std_logic;


      -------------------------------------------------------------------------
      -- Digital I/O FMC Pins
      -------------------------------------------------------------------------

      dio_clk_p_i : in std_logic;
      dio_clk_n_i : in std_logic;

      dio_n_i : in std_logic_vector(4 downto 0);
      dio_p_i : in std_logic_vector(4 downto 0);

      dio_n_o : out std_logic_vector(4 downto 0);
      dio_p_o : out std_logic_vector(4 downto 0);

      dio_oe_n_o    : out std_logic_vector(4 downto 0);
      dio_term_en_o : out std_logic_vector(4 downto 0);

      dio_onewire_b  : inout std_logic;
      dio_sdn_n_o    : out   std_logic;  -- this is for ??
      dio_sdn_ck_n_o : out   std_logic;

      dio_led_top_o : out std_logic;
      dio_led_bot_o : out std_logic;

      dio_scl_b : inout std_logic;
      dio_sda_b : inout std_logic;
      -- dio_GA signals conneected to ground on SPEC board.  


      -----------------------------------------
      --UART
      -----------------------------------------
      uart_rxd_i : in  std_logic;
      uart_txd_o : out std_logic
      );

end wr_nic_sdb_top;

architecture rtl of wr_nic_sdb_top is

  ------------------------------------------------------------------------------
  -- Components declaration
  ------------------------------------------------------------------------------

  component gn4124_core is
    port(
      ---------------------------------------------------------
      -- Control and status
      rst_n_a_i : in  std_logic;        -- Asynchronous reset from GN4124
      status_o  : out std_logic_vector(31 downto 0);  -- Core status output

      ---------------------------------------------------------
      -- P2L Direction
      --
      -- Source Sync DDR related signals
      p2l_clk_p_i  : in  std_logic;     -- Receiver Source Synchronous Clock+
      p2l_clk_n_i  : in  std_logic;     -- Receiver Source Synchronous Clock-
      p2l_data_i   : in  std_logic_vector(15 downto 0);  -- Parallel receive data
      p2l_dframe_i : in  std_logic;     -- Receive Frame
      p2l_valid_i  : in  std_logic;     -- Receive Data Valid
      -- P2L Control
      p2l_rdy_o    : out std_logic;     -- Rx Buffer Full Flag
      p_wr_req_i   : in  std_logic_vector(1 downto 0);  -- PCIe Write Request
      p_wr_rdy_o   : out std_logic_vector(1 downto 0);  -- PCIe Write Ready
      rx_error_o   : out std_logic;     -- Receive Error
      vc_rdy_i     : in  std_logic_vector(1 downto 0);  -- Virtual channel ready

      ---------------------------------------------------------
      -- L2P Direction
      --
      -- Source Sync DDR related signals
      l2p_clk_p_o  : out std_logic;  -- Transmitter Source Synchronous Clock+
      l2p_clk_n_o  : out std_logic;  -- Transmitter Source Synchronous Clock-
      l2p_data_o   : out std_logic_vector(15 downto 0);  -- Parallel transmit data
      l2p_dframe_o : out std_logic;     -- Transmit Data Frame
      l2p_valid_o  : out std_logic;     -- Transmit Data Valid
      -- L2P Control
      l2p_edb_o    : out std_logic;     -- Packet termination and discard
      l2p_rdy_i    : in  std_logic;     -- Tx Buffer Full Flag
      l_wr_rdy_i   : in  std_logic_vector(1 downto 0);  -- Local-to-PCIe Write
      p_rd_d_rdy_i : in  std_logic_vector(1 downto 0);  -- PCIe-to-Local Read Response Data Ready
      tx_error_i   : in  std_logic;     -- Transmit Error

      ---------------------------------------------------------
      -- Interrupt interface
      dma_irq_o : out std_logic_vector(1 downto 0);  -- Interrupts sources to IRQ manager
      irq_p_i   : in  std_logic;  -- Interrupt request pulse from IRQ manager
      irq_p_o   : out std_logic;  -- Interrupt request pulse to GN4124 GPIO

      ---------------------------------------------------------
      -- DMA registers wishbone interface (slave classic)
      dma_reg_clk_i   : in  std_logic;
      dma_reg_adr_i   : in  std_logic_vector(31 downto 0) := x"00000000";
      dma_reg_dat_i   : in  std_logic_vector(31 downto 0) := x"00000000";
      dma_reg_sel_i   : in  std_logic_vector(3 downto 0)  := x"0";
      dma_reg_stb_i   : in  std_logic                     := '0';
      dma_reg_we_i    : in  std_logic                     := '0';
      dma_reg_cyc_i   : in  std_logic                     := '0';
      dma_reg_dat_o   : out std_logic_vector(31 downto 0);
      dma_reg_ack_o   : out std_logic;
      dma_reg_stall_o : out std_logic;

      ---------------------------------------------------------
      -- CSR wishbone interface (master pipelined)
      csr_clk_i   : in  std_logic;
      csr_adr_o   : out std_logic_vector(31 downto 0);
      csr_dat_o   : out std_logic_vector(31 downto 0);
      csr_sel_o   : out std_logic_vector(3 downto 0);
      csr_stb_o   : out std_logic;
      csr_we_o    : out std_logic;
      csr_cyc_o   : out std_logic;
      csr_dat_i   : in  std_logic_vector(31 downto 0);
      csr_ack_i   : in  std_logic;
      csr_stall_i : in  std_logic;

      ---------------------------------------------------------
      -- DMA wishbone interface (master pipelined)
      dma_clk_i   : in  std_logic;
      dma_adr_o   : out std_logic_vector(31 downto 0);
      dma_dat_o   : out std_logic_vector(31 downto 0);
      dma_sel_o   : out std_logic_vector(3 downto 0);
      dma_stb_o   : out std_logic;
      dma_we_o    : out std_logic;
      dma_cyc_o   : out std_logic;
      dma_dat_i   : in  std_logic_vector(31 downto 0) := x"00000000";
      dma_ack_i   : in  std_logic                     := '0';
      dma_stall_i : in  std_logic                     := '0'
      );
  end component;  --  gn4124_core


  -- NIC
  component xwrsw_nic
    generic
      (
        g_interface_mode      : t_wishbone_interface_mode      := CLASSIC;
        g_address_granularity : t_wishbone_address_granularity := WORD;
        g_src_cyc_on_stall    : boolean
        );
    port (
      clk_sys_i : in std_logic;
      rst_n_i   : in std_logic;

      snk_i               : in  t_wrf_sink_in;
      snk_o               : out t_wrf_sink_out;
      src_i               : in  t_wrf_source_in;
      src_o               : out t_wrf_source_out;
      -- fake RTU
      rtu_dst_port_mask_o : out std_logic_vector(31 downto 0);
      rtu_prio_o          : out std_logic_vector(2 downto 0);
      rtu_drop_o          : out std_logic;
      rtu_rsp_valid_o     : out std_logic;
      rtu_rsp_ack_i       : in  std_logic;

      wb_i : in  t_wishbone_slave_in;
      wb_o : out t_wishbone_slave_out
      --   dma_i : in  t_wishbone_slave_in;
      --  dma_o : out t_wishbone_slave_out
      );
  end component;

  component xwrsw_tx_tsu
    generic (
      g_num_ports           : integer                        := 10;
      g_interface_mode      : t_wishbone_interface_mode      := CLASSIC;
      g_address_granularity : t_wishbone_address_granularity := WORD);
    port (
      clk_sys_i        : in  std_logic;
      rst_n_i          : in  std_logic;
      timestamps_i     : in  t_txtsu_timestamp_array(g_num_ports-1 downto 0);
      timestamps_ack_o : out std_logic_vector(g_num_ports -1 downto 0);
      wb_i             : in  t_wishbone_slave_in;
      wb_o             : out t_wishbone_slave_out
      );
  end component;

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
      dio_ga_o  : out   std_logic_vector(1 downto 0);

      tm_time_valid_i : in std_logic;
      tm_seconds_i    : in std_logic_vector(39 downto 0);
      tm_cycles_i     : in std_logic_vector(27 downto 0);

      TRIG0 : out std_logic_vector(31 downto 0);
      TRIG1 : out std_logic_vector(31 downto 0);
      TRIG2 : out std_logic_vector(31 downto 0);
      TRIG3 : out std_logic_vector(31 downto 0);

      slave_i : in  t_wishbone_slave_in;
      slave_o : out t_wishbone_slave_out
      );
  end component;  --DIO core

--  -- DEBUG STUFF
--  component chipscope_ila
--    port (
--      CONTROL : inout std_logic_vector(35 downto 0);
--      CLK     : in    std_logic;
--      TRIG0   : in    std_logic_vector(31 downto 0);
--      TRIG1   : in    std_logic_vector(31 downto 0);
--      TRIG2   : in    std_logic_vector(31 downto 0);
--      TRIG3   : in    std_logic_vector(31 downto 0));
--  end component;
--
--  component chipscope_icon
--    port (
--      CONTROL0 : inout std_logic_vector (35 downto 0));
--  end component;

--  signal CONTROL : std_logic_vector(35 downto 0);
--  signal CLK     : std_logic;
--  signal TRIG0   : std_logic_vector(31 downto 0);
--  signal TRIG1   : std_logic_vector(31 downto 0);
--  signal TRIG2   : std_logic_vector(31 downto 0);
--  signal TRIG3   : std_logic_vector(31 downto 0);



  ------------------------------------------------------------------------------
  -- Constants declaration
  ------------------------------------------------------------------------------
  constant c_BAR0_APERTURE     : integer := 20;  -- 1 MB for spec card, NOT USED!
  constant c_DMA_WB_SLAVES_NB  : integer := 1;
  constant c_CSR_WB_SLAVES_NB  : integer := 1;   -- NOT IN USE
  constant c_DMA_WB_ADDR_WIDTH : integer := 26;  -- NOT IN USE

  ------------------------------------------------------------------------------
  -- Signals declaration
  ------------------------------------------------------------------------------

  -- LCLK from GN4124 used as system clock
  signal l_clk : std_logic;

  -- Dedicated clock for GTP transceiver
  signal gtp_dedicated_clk : std_logic;

  -- P2L colck PLL status
  signal p2l_pll_locked : std_logic;

  -- Reset
  signal rst : std_logic;

  -- DMA wishbone bus -- NOT IN USE
--  signal dma_adr     : std_logic_vector(31 downto 0);
--  signal dma_dat_i   : std_logic_vector((32*c_DMA_WB_SLAVES_NB)-1 downto 0);
--  signal dma_dat_o   : std_logic_vector(31 downto 0);
--  signal dma_sel     : std_logic_vector(3 downto 0);
--  signal dma_cyc     : std_logic;                      --_vector(c_DMA_WB_SLAVES_NB-1 downto 0);
--  signal dma_stb     : std_logic;
--  signal dma_we      : std_logic;
--  signal dma_ack     : std_logic;                     --_vector(c_DMA_WB_SLAVES_NB-1 downto 0);
--  signal dma_stall   : std_logic;                     --_vector(c_DMA_WB_SLAVES_NB-1 downto 0);
--  signal ram_we      : std_logic_vector(0 downto 0);  
--  signal ddr_dma_adr : std_logic_vector(29 downto 0); 

  signal irq_to_gn4124 : std_logic;

  -- SPI
  signal spi_slave_select : std_logic_vector(7 downto 0);

  signal pllout_clk_sys       : std_logic;
  signal pllout_clk_dmtd      : std_logic;
  signal pllout_clk_fb_pllref : std_logic;
  signal pllout_clk_fb_dmtd   : std_logic;

  signal clk_20m_vcxo_buf : std_logic;
  signal clk_125m_pllref  : std_logic;
  signal clk_sys          : std_logic;
  signal clk_dmtd         : std_logic;
  signal dac_rst_n        : std_logic;
  signal led_divider      : unsigned(23 downto 0);

  signal wrc_scl_o : std_logic;
  signal wrc_scl_i : std_logic;
  signal wrc_sda_o : std_logic;
  signal wrc_sda_i : std_logic;
  signal sfp_scl_o : std_logic;
  signal sfp_scl_i : std_logic;
  signal sfp_sda_o : std_logic;
  signal sfp_sda_i : std_logic;
  signal dio       : std_logic_vector(3 downto 0);

  signal dac_hpll_load_p1 : std_logic;
  signal dac_dpll_load_p1 : std_logic;
  signal dac_hpll_data    : std_logic_vector(15 downto 0);
  signal dac_dpll_data    : std_logic_vector(15 downto 0);

  signal pps : std_logic;

  signal phy_tx_data      : std_logic_vector(7 downto 0);
  signal phy_tx_k         : std_logic;
  signal phy_tx_disparity : std_logic;
  signal phy_tx_enc_err   : std_logic;
  signal phy_rx_data      : std_logic_vector(7 downto 0);
  signal phy_rx_rbclk     : std_logic;
  signal phy_rx_k         : std_logic;
  signal phy_rx_enc_err   : std_logic;
  signal phy_rx_bitslide  : std_logic_vector(3 downto 0);
  signal phy_rst          : std_logic;
  signal phy_loopen       : std_logic;

  signal dio_in  : std_logic_vector(4 downto 0);
  signal dio_out : std_logic_vector(4 downto 0);
  signal dio_clk : std_logic;

  signal local_reset_n  : std_logic;
  signal button1_synced : std_logic_vector(2 downto 0);

  signal wrc_slave_i : t_wishbone_slave_in;
  signal wrc_slave_o : t_wishbone_slave_out;

  signal owr_en : std_logic_vector(1 downto 0);
  signal owr_i  : std_logic_vector(1 downto 0);


  signal wrpc_ts_o     : t_txtsu_timestamp;
  signal wrpc_ts_ack_i : std_logic;

  -- Timecode output
  signal tm_time_valid : std_logic;
  signal tm_seconds    : std_logic_vector(39 downto 0);
  signal tm_cycles     : std_logic_vector(27 downto 0);

  -- DIO core
  --signal wb_irq_data_fifo_dio : std_logic; -- T.B.DELETED
  -------------------
  -- NIC
  -------------------
  signal nic_src_out : t_wrf_source_out;
  signal nic_src_in  : t_wrf_source_in;
  signal nic_snk_out : t_wrf_sink_out;
  signal nic_snk_in  : t_wrf_sink_in;
  signal nic_dma_in  : t_wishbone_slave_in;
  signal nic_dma_out : t_wishbone_slave_out;
  signal csr_ack     : std_logic;

  -----------------------------------------------------------------------------
  -- Top  WB Crossbar
  ---------------------------------------------------------------------------
  -- WR core & dio core layout
  constant c_wrcore_bridge_sdb : t_sdb_bridge := f_xwb_bridge_product_manual_sdb(x"0003ffff", x"00030000", c_xwr_core_sdb);
  constant c_wr_dio_bridge_sdb : t_sdb_bridge := f_xwb_bridge_product_manual_sdb(x"00000fff", x"00000400", c_xwrsw_dio_sdb);

  constant c_topbar_layout : t_sdb_record_array(4 downto 0) :=
    (0 => f_sdb_embed_bridge(c_wrcore_bridge_sdb, x"00000000"),  -- WRPC
     1 => f_sdb_embed_device(c_xwrsw_nic_sdb , x"00040000"),     -- NIC
     2 => f_sdb_embed_device(c_xwb_vic_sdb , x"00060000"),  -- VIC (IRQ gen)
     3 => f_sdb_embed_device(c_xwrsw_txtsu_sdb , x"00061000"),   -- TxTSU
     4 => f_sdb_embed_bridge(c_wr_dio_bridge_sdb, x"00062000")   -- DIO
     );

  constant c_topbar_sdb_address : t_wishbone_address := x"00063000";

  signal cbar_slave_i  : t_wishbone_slave_in;
  signal cbar_slave_o  : t_wishbone_slave_out;
  signal cbar_master_i : t_wishbone_master_in_array(4 downto 0);
  signal cbar_master_o : t_wishbone_master_out_array(4 downto 0);

  -------------------
  -- WB VIC
  -------------------
  signal vic_irq       : std_logic;
  signal vic_slave_irq : std_logic_vector(2 downto 0);

  signal cbar_slave_adr_words : std_logic_vector(31 downto 0);
  
begin

  cmp_sys_clk_pll : PLL_BASE
    generic map (
      BANDWIDTH          => "OPTIMIZED",
      CLK_FEEDBACK       => "CLKFBOUT",
      COMPENSATION       => "INTERNAL",
      DIVCLK_DIVIDE      => 1,
      CLKFBOUT_MULT      => 8,
      CLKFBOUT_PHASE     => 0.000,
      CLKOUT0_DIVIDE     => 16,         -- 62.5 MHz
      CLKOUT0_PHASE      => 0.000,
      CLKOUT0_DUTY_CYCLE => 0.500,
      CLKOUT1_DIVIDE     => 16,         -- 62,5 MHz
      CLKOUT1_PHASE      => 0.000,
      CLKOUT1_DUTY_CYCLE => 0.500,
      CLKOUT2_DIVIDE     => 16,
      CLKOUT2_PHASE      => 0.000,
      CLKOUT2_DUTY_CYCLE => 0.500,
      CLKIN_PERIOD       => 8.0,
      REF_JITTER         => 0.016)
    port map (
      CLKFBOUT => pllout_clk_fb_pllref,
      CLKOUT0  => pllout_clk_sys,
      CLKOUT1  => open,
      CLKOUT2  => open,
      CLKOUT3  => open,
      CLKOUT4  => open,
      CLKOUT5  => open,
      LOCKED   => open,
      RST      => '0',
      CLKFBIN  => pllout_clk_fb_pllref,
      CLKIN    => clk_125m_pllref);     -- 125 MHz

  cmp_dmtd_clk_pll : PLL_BASE
    generic map (
      BANDWIDTH          => "OPTIMIZED",
      CLK_FEEDBACK       => "CLKFBOUT",
      COMPENSATION       => "INTERNAL",
      DIVCLK_DIVIDE      => 1,
      CLKFBOUT_MULT      => 50,
      CLKFBOUT_PHASE     => 0.000,
      CLKOUT0_DIVIDE     => 16,         -- 62.5 MHz
      CLKOUT0_PHASE      => 0.000,
      CLKOUT0_DUTY_CYCLE => 0.500,
      CLKOUT1_DIVIDE     => 16,         -- 62.5 MHz
      CLKOUT1_PHASE      => 0.000,
      CLKOUT1_DUTY_CYCLE => 0.500,
      CLKOUT2_DIVIDE     => 8,
      CLKOUT2_PHASE      => 0.000,
      CLKOUT2_DUTY_CYCLE => 0.500,
      CLKIN_PERIOD       => 50.0,
      REF_JITTER         => 0.016)
    port map (
      CLKFBOUT => pllout_clk_fb_dmtd,
      CLKOUT0  => pllout_clk_dmtd,
      CLKOUT1  => open,
      CLKOUT2  => open,
      CLKOUT3  => open,
      CLKOUT4  => open,
      CLKOUT5  => open,
      LOCKED   => open,
      RST      => '0',
      CLKFBIN  => pllout_clk_fb_dmtd,
      CLKIN    => clk_20m_vcxo_buf);    -- 20 MHz


  local_reset_n <= L_RST_N;

  cmp_clk_sys_buf : BUFG
    port map (
      O => clk_sys,
      I => pllout_clk_sys);

  cmp_clk_dmtd_buf : BUFG
    port map (
      O => clk_dmtd,
      I => pllout_clk_dmtd);

  cmp_clk_vcxo : BUFG
    port map (
      O => clk_20m_vcxo_buf,
      I => clk_20m_vcxo_i);

  ------------------------------------------------------------------------------
  -- Local clock from gennum LCLK
  ------------------------------------------------------------------------------
  cmp_l_clk_buf : IBUFDS
    generic map (
      DIFF_TERM    => false,            -- Differential Termination
      IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD   => "DEFAULT")
    port map (
      O  => l_clk,                      -- Buffer output
      I  => L_CLKp,  -- Diff_p buffer input (connect directly to top-level port)
      IB => L_CLKn  -- Diff_n buffer input (connect directly to top-level port)
      );

  cmp_pllrefclk_buf : IBUFGDS
    generic map (
      DIFF_TERM    => true,             -- Differential Termination
      IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD   => "DEFAULT")
    port map (
      O  => clk_125m_pllref,            -- Buffer output
      I  => clk_125m_pllref_p_i,  -- Diff_p buffer input (connect directly to top-level port)
      IB => clk_125m_pllref_n_i  -- Diff_n buffer input (connect directly to top-level port)
      );


  ------------------------------------------------------------------------------
  -- Dedicated clock for GTP
  ------------------------------------------------------------------------------
  cmp_gtp_dedicated_clk_buf : IBUFGDS
    generic map(
      DIFF_TERM    => true,
      IBUF_LOW_PWR => true,
      IOSTANDARD   => "DEFAULT")
    port map (
      O  => gtp_dedicated_clk,
      I  => fpga_pll_ref_clk_101_p_i,
      IB => fpga_pll_ref_clk_101_n_i
      );

  ------------------------------------------------------------------------------
  -- WB TOP Crossbar
  ------------------------------------------------------------------------------
  WB_TOP_INTERCON : xwb_sdb_crossbar
    generic map(
      g_num_masters => 1,
      g_num_slaves  => 5,
      g_registered  => true,
      g_wraparound  => true,
      g_layout      => c_topbar_layout,
      g_sdb_addr    => c_topbar_sdb_address
      )
    port map(
      clk_sys_i  => clk_sys,
      rst_n_i    => local_reset_n,
      -- Master connections
      slave_i(0) => cbar_slave_i,
      slave_o(0) => cbar_slave_o,
      -- Slave conenctions
      master_i   => cbar_master_i,
      master_o   => cbar_master_o
      );                



  ------------------------------------------------------------------------------
  -- Gennun Core
  ------------------------------------------------------------------------------

  U_Gennum_Core : gn4124_core
    port map
    (
      ---------------------------------------------------------
      -- Control and status
      rst_n_a_i => L_RST_N,
      status_o  => open,

      ---------------------------------------------------------
      -- P2L Direction
      --
      -- Source Sync DDR related signals
      p2l_clk_p_i  => P2L_CLKp,
      p2l_clk_n_i  => P2L_CLKn,
      p2l_data_i   => P2L_DATA,
      p2l_dframe_i => P2L_DFRAME,
      p2l_valid_i  => P2L_VALID,
      -- P2L Control
      p2l_rdy_o    => P2L_RDY,
      p_wr_req_i   => P_WR_REQ,
      p_wr_rdy_o   => P_WR_RDY,
      rx_error_o   => RX_ERROR,
      vc_rdy_i     => VC_RDY,

      ---------------------------------------------------------
      -- L2P Direction
      --
      -- Source Sync DDR related signals
      l2p_clk_p_o  => L2P_CLKp,
      l2p_clk_n_o  => L2P_CLKn,
      l2p_data_o   => L2P_DATA,
      l2p_dframe_o => L2P_DFRAME,
      l2p_valid_o  => L2P_VALID,
      -- L2P Control
      l2p_edb_o    => L2P_EDB,
      l2p_rdy_i    => L2P_RDY,
      l_wr_rdy_i   => L_WR_RDY,
      p_rd_d_rdy_i => P_RD_D_RDY,
      tx_error_i   => TX_ERROR,

      ---------------------------------------------------------
      -- Interrupt interface
      dma_irq_o => open,
      irq_p_i   => vic_irq,
      irq_p_o   => GPIO(0),             -- T.B.D. Check if GPIO is 1 or 0

      ---------------------------------------------------------
      -- DMA registers wishbone interface (slave classic)
      dma_reg_clk_i => clk_sys,

      ---------------------------------------------------------
      -- CSR wishbone interface (master pipelined)
      csr_clk_i   => clk_sys,
      csr_adr_o   => cbar_slave_adr_words,
      csr_dat_o   => cbar_slave_i.dat,
      csr_sel_o   => cbar_slave_i.sel,
      csr_stb_o   => cbar_slave_i.stb,
      csr_we_o    => cbar_slave_i.we,
      csr_cyc_o   => cbar_slave_i.cyc,
      csr_dat_i   => cbar_slave_o.dat,
      csr_ack_i   => csr_ack,
      csr_stall_i => cbar_slave_o.stall,

      ---------------------------------------------------------
      -- L2P DMA Interface (Pipelined Wishbone master)
      -- Look, many signals just take default values if not used
      dma_clk_i => clk_sys
      --dma_adr_o   => dma_adr,
      --dma_dat_o   => dma_dat_o,
      --dma_sel_o   => dma_sel,
      --dma_stb_o   => dma_stb,
      --dma_we_o    => dma_we,
      --dma_cyc_o   => dma_cyc,
      --dma_dat_i   => dma_dat_i,
      --dma_ack_i   => dma_ack,
      --dma_stall_i => dma_stall
      );                

  csr_ack <= (cbar_slave_o.ack or cbar_slave_o.err);

  -- From words to bytes. TODO: change to adapter block
  cbar_slave_i.adr (18 downto 0)  <= cbar_slave_adr_words(16 downto 0) & "00";
  cbar_slave_i.adr (31 downto 19) <= (others => '0');  -- SPEC memory space is 1 MB

  ---------------------------------------------
  --   Miscelaneous stuff (i2c, onewire, etc..)
  ---------------------------------------------
  -- Be aware that connection of i2c pins are only provided to WR_CORE, no DIO_CORE   
  dio_scl_b <= '0' when wrc_scl_o = '0' else 'Z';
  dio_sda_b <= '0' when wrc_sda_o = '0' else 'Z';
  wrc_scl_i <= dio_scl_b;
  wrc_sda_i <= dio_sda_b;

  -- Comment previous lines and uncomment this one to handle i2c signals from DIO_CORE

  thermo_id <= '0' when owr_en(0) = '1' else 'Z';
  owr_i(0)  <= thermo_id;

  ---------------------------------------------
  --   SFPs
  ---------------------------------------------

  sfp_mod_def1_b   <= '0' when sfp_scl_o = '0' else 'Z';
  sfp_mod_def2_b   <= '0' when sfp_sda_o = '0' else 'Z';
  sfp_scl_i        <= sfp_mod_def1_b;
  sfp_sda_i        <= sfp_mod_def2_b;
  sfp_tx_disable_o <= '0';

  -------------------------------------
  -- WR PTP Core
  -------------------------------------
  U_WR_CORE : xwr_core
    generic map (
      g_simulation                => g_simulation,
      g_phys_uart                 => true,
      g_virtual_uart              => true,
      g_with_external_clock_input => true,
      g_aux_clks                  => 1,
      g_ep_rxbuf_size             => 1024,
      g_dpram_initf               => "wrc.ram",  --Path to the lm32 file (wrc.ram) of the wrpc_sw repository
      g_dpram_size                => 90112/4,  -- 20480, it is the old value, it does not fit anymore 
      g_interface_mode            => PIPELINED,
      g_address_granularity       => BYTE)
    port map (
      clk_sys_i  => clk_sys,
      clk_dmtd_i => clk_dmtd,
      clk_ref_i  => clk_125m_pllref,
      clk_aux_i  => (others => '0'),
      clk_ext_i  => dio_clk,            -- It correspond to dio_in(4)
      pps_ext_i  => dio_in(3),          -- It need to be documented
      rst_n_i    => local_reset_n,

      dac_hpll_load_p1_o => dac_hpll_load_p1,
      dac_hpll_data_o    => dac_hpll_data,
      dac_dpll_load_p1_o => dac_dpll_load_p1,
      dac_dpll_data_o    => dac_dpll_data,

      phy_ref_clk_i      => clk_125m_pllref,
      phy_tx_data_o      => phy_tx_data,
      phy_tx_k_o         => phy_tx_k,
      phy_tx_disparity_i => phy_tx_disparity,
      phy_tx_enc_err_i   => phy_tx_enc_err,
      phy_rx_data_i      => phy_rx_data,
      phy_rx_rbclk_i     => phy_rx_rbclk,
      phy_rx_k_i         => phy_rx_k,
      phy_rx_enc_err_i   => phy_rx_enc_err,
      phy_rx_bitslide_i  => phy_rx_bitslide,
      phy_rst_o          => phy_rst,
      phy_loopen_o       => phy_loopen,

      led_act_o  => LED_RED,
      led_link_o => LED_GREEN,
      scl_o      => wrc_scl_o,
      scl_i      => wrc_scl_i,
      sda_o      => wrc_sda_o,
      sda_i      => wrc_sda_i,
      sfp_scl_o  => sfp_scl_o,
      sfp_scl_i  => sfp_scl_i,
      sfp_sda_o  => sfp_sda_o,
      sfp_sda_i  => sfp_sda_i,
      sfp_det_i  => sfp_mod_def0_b,
      btn1_i     => button1_i,
      btn2_i     => button2_i,

      uart_rxd_i => uart_rxd_i,
      uart_txd_o => uart_txd_o,

      owr_en_o => owr_en,
      owr_i    => owr_i,

      slave_i => cbar_master_o(0),  --cbar_slave_i, --
      slave_o => cbar_master_i(0),  --cbar_slave_o, --

      wrf_src_o => nic_snk_in,
      wrf_src_i => nic_snk_out,
      wrf_snk_o => nic_src_in,
      wrf_snk_i => nic_src_out,

      timestamps_o     => wrpc_ts_o,
      timestamps_ack_i => wrpc_ts_ack_i,

      tm_dac_value_o       => open,
      tm_dac_wr_o          => open,
      tm_clk_aux_lock_en_i => '0',
      tm_clk_aux_locked_o  => open,
      tm_time_valid_o      => tm_time_valid,
      tm_tai_o             => tm_seconds,
      tm_cycles_o          => tm_cycles,
      pps_p_o              => pps,

      dio_o       => open,
      rst_aux_n_o => open
      );

  -------------------------------------
  -- NIC
  -------------------------------------
  U_NIC : xwrsw_nic
    generic map(
      g_interface_mode      => PIPELINED,
      g_address_granularity => BYTE,
      g_src_cyc_on_stall    => true)
    port map(
      clk_sys_i => clk_sys,
      rst_n_i   => local_reset_n,

      snk_i => nic_snk_in,
      snk_o => nic_snk_out,
      src_i => nic_src_in,
      src_o => nic_src_out,

      rtu_dst_port_mask_o => open,
      rtu_prio_o          => open,
      rtu_drop_o          => open,
      rtu_rsp_valid_o     => open,
      rtu_rsp_ack_i       => '1',

      wb_i => cbar_master_o(1),
      wb_o => cbar_master_i(1)
      --dma_i => nic_dma_in,
      --dma_o => nic_dma_out
      );

--  GEN_DMA : if(g_nic_usedma) generate
--      nic_dma_in.cyc <= dma_cyc;
--      nic_dma_in.stb <= dma_stb;
--      nic_dma_in.we  <= dma_we;
--      nic_dma_in.adr <= dma_adr;
--      nic_dma_in.sel <= dma_sel;
--      nic_dma_in.dat <= dma_dat_o;
--
--      dma_dat_i(31 downto 0) <= nic_dma_out.dat;
--      dma_ack                <= nic_dma_out.ack;
--      dma_stall              <= nic_dma_out.stall;
--  end generate;
--
--  GEN_PIPELINED : if(not(g_nic_usedma)) generate
--      nic_dma_in <= cc_dummy_slave_in;
--      dma_ack    <= '0';
--      dma_stall  <= '0';
--  end generate;

  -------------------------------------
  -- VIC 
  -------------------------------------
  U_VIC : xwb_vic
    generic map(
      g_interface_mode      => PIPELINED,
      g_address_granularity => BYTE,
      g_num_interrupts      => 3)
    port map(
      clk_sys_i    => clk_sys,
      rst_n_i      => local_reset_n,
      slave_i      => cbar_master_o(2),
      slave_o      => cbar_master_i(2),
      irqs_i       => vic_slave_irq,
      irq_master_o => vic_irq
      );

  vic_slave_irq(0) <= cbar_master_i(3).int;  -- wrpc, txtsu
  vic_slave_irq(1) <= cbar_master_i(1).int;  -- wrsw-nic
  vic_slave_irq(2) <= cbar_master_i(4).int;  -- DIO core


  -------------------------------------
  -- WRSW TXTSU
  -------------------------------------
  U_TXTSU : xwrsw_tx_tsu
    generic map(
      g_num_ports           => 1,
      g_interface_mode      => PIPELINED,
      g_address_granularity => BYTE)
    port map(
      clk_sys_i           => clk_sys,
      rst_n_i             => local_reset_n,
      timestamps_i(0)     => wrpc_ts_o,
      timestamps_ack_o(0) => wrpc_ts_ack_i,
      wb_i                => cbar_master_o(3),
      wb_o                => cbar_master_i(3)
      );

  ---------------------
  -- GTP
  ---------------------

  U_GTP : wr_gtp_phy_spartan6
    generic map (
      g_simulation => g_simulation)
    port map (
      gtp_clk_i => gtp_dedicated_clk,

      ch0_ref_clk_i      => clk_125m_pllref,
      ch0_tx_data_i      => x"00",
      ch0_tx_k_i         => '0',
      ch0_tx_disparity_o => open,
      ch0_tx_enc_err_o   => open,
      ch0_rx_rbclk_o     => open,
      ch0_rx_data_o      => open,
      ch0_rx_k_o         => open,
      ch0_rx_enc_err_o   => open,
      ch0_rx_bitslide_o  => open,
      ch0_rst_i          => '1',
      ch0_loopen_i       => '0',

      ch1_ref_clk_i      => clk_125m_pllref,
      ch1_tx_data_i      => phy_tx_data,
      ch1_tx_k_i         => phy_tx_k,
      ch1_tx_disparity_o => phy_tx_disparity,
      ch1_tx_enc_err_o   => phy_tx_enc_err,
      ch1_rx_data_o      => phy_rx_data,
      ch1_rx_rbclk_o     => phy_rx_rbclk,
      ch1_rx_k_o         => phy_rx_k,
      ch1_rx_enc_err_o   => phy_rx_enc_err,
      ch1_rx_bitslide_o  => phy_rx_bitslide,
      ch1_rst_i          => phy_rst,
      ch1_loopen_i       => phy_loopen,
      pad_txn0_o         => open,
      pad_txp0_o         => open,
      pad_rxn0_i         => '0',
      pad_rxp0_i         => '0',
      pad_txn1_o         => sfp_txn_o,
      pad_txp1_o         => sfp_txp_o,
      pad_rxn1_i         => sfp_rxn_i,
      pad_rxp1_i         => sfp_rxp_i);

  
  U_DAC_ARB : spec_serial_dac_arb
    generic map (
      g_invert_sclk    => false,
      g_num_extra_bits => 8)

    port map (
      clk_i   => clk_sys,
      rst_n_i => local_reset_n,

      val1_i  => dac_dpll_data,
      load1_i => dac_dpll_load_p1,

      val2_i  => dac_hpll_data,
      load2_i => dac_hpll_load_p1,

      dac_cs_n_o(0) => dac_cs1_n_o,
      dac_cs_n_o(1) => dac_cs2_n_o,
      dac_clr_n_o   => dac_clr_n_o,
      dac_sclk_o    => dac_sclk_o,
      dac_din_o     => dac_din_o);


-----------------------------------
--   DIO core
-----------------------------------
  U_DIO_CORE : xwrsw_dio
    generic map (
      g_interface_mode      => PIPELINED,
      g_address_granularity => BYTE)

    port map(
      clk_sys_i => clk_sys,
      clk_ref_i => clk_125m_pllref,
      rst_n_i   => local_reset_n,

      dio_clk_i     => dio_clk,
      dio_in_i      => dio_in,
      dio_out_o     => dio_out,
      dio_oe_n_o    => dio_oe_n_o,
      dio_term_en_o => dio_term_en_o,

      dio_onewire_b  => dio_onewire_b,
      dio_sdn_n_o    => dio_sdn_n_o,
      dio_sdn_ck_n_o => dio_sdn_ck_n_o,
      dio_led_top_o  => dio_led_top_o,
      dio_led_bot_o  => dio_led_bot_o,

      --  dio_scl_b => dio_scl_b,
      --  dio_sda_b => dio_sda_b,
      dio_ga_o => open,

      tm_time_valid_i => tm_time_valid,
      tm_seconds_i    => tm_seconds,
      tm_cycles_i     => tm_cycles,

      slave_i => cbar_master_o(4),
      slave_o => cbar_master_i(4)

      -- Chipscope, debugging signals
--      TRIG0           => TRIG0,
--      TRIG1           => TRIG1
--      TRIG2           => TRIG2,
--      TRIG3           => TRIG3,               
      );

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


-- .............................................
-- ............... DEBUGGING ...................
-- .............................................
--
--  chipscope_ila_1 : chipscope_ila
--    port map (
--      CONTROL => CONTROL,
--      CLK     => clk_sys,
--      TRIG0   => TRIG0,
--      TRIG1   => TRIG1,
--      TRIG2   => TRIG2,
--      TRIG3   => TRIG3);
--
--  chipscope_icon_1 : chipscope_icon
--    port map (
--      CONTROL0 => CONTROL
--      );
--
--  -- Genumm wb bus
--  TRIG2(18 downto 0)  <= cbar_slave_i.adr (18 downto  0);
--  TRIG2(19)           <= cbar_slave_i.stb; 
--  --TRIG2(20)           <= cbar_slave_i.dat;
--  TRIG2(21)           <= cbar_slave_i.cyc;
--  TRIG2(22)           <= cbar_slave_i.we;
--  TRIG2(26 downto 23) <= cbar_slave_i.sel;
--  TRIG2(27)           <= cbar_slave_o.ack;
--  TRIG2(28)           <= cbar_slave_o.stall; 
--  
--  -- Global interrupts
--  TRIG2(30 downto 29) <= GPIO(1 downto 0);
--  TRIG2(31)           <= vic_irq;
--  
--  -- crossbar slaves wb bus (0 wrpc, 4 dio, ...)
--  TRIG3(18 downto 0)  <= cbar_master_o(0).adr (18 downto  0);
--  TRIG3(19)           <= cbar_master_o(0).stb; 
--  --TRIG3(20)           <= cbar_master_o(4).dat;
--  TRIG3(21)           <= cbar_master_o(0).cyc;
--  TRIG3(22)           <= cbar_master_o(0).we;
--  TRIG3(26 downto 23) <= cbar_master_o(0).sel;
--  TRIG3(27)           <= cbar_master_i(0).ack;
--  TRIG3(28)           <= cbar_master_i(0).stall;
--
--  -- Peripherals interrupts
--  TRIG3(29)           <= vic_slave_irq(0);
--  TRIG3(30)           <= vic_slave_irq(1);
--  TRIG3(31)           <= vic_slave_irq(2);

end rtl;


