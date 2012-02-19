-------------------------------------------------------------------------------
-- Title      : Mini Embedded DMA Network Interface Controller
-- Project    : WhiteRabbit Core
-------------------------------------------------------------------------------
-- File       : nic_buffer.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN BE-Co-HT
-- Created    : 2010-07-26
-- Last update: 2012-02-20
-- Platform   : FPGA-generic
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description: RAM-based packet buffer for the NIC
-------------------------------------------------------------------------------
-- Copyright (c) 2010 Tomasz Wlostowski
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2010-07-26  1.0      twlostow        Created
-- 2012-02-20  1.1      greg.d          added pipelined WB for DMA
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.genram_pkg.all;


entity nic_buffer is
  generic (
    g_memsize_log2 : integer := 14;
    g_USE_DMA      : boolean := false);
  port (
    clk_sys_i : in std_logic;
    rst_n_i   : in std_logic;

    addr_i : in  std_logic_vector(g_memsize_log2-1 downto 0);
    data_i : in  std_logic_vector(31 downto 0);
    wr_i   : in  std_logic;
    data_o : out std_logic_vector(31 downto 0);

    wb_data_i  : in  std_logic_vector(31 downto 0);
    wb_data_o  : out std_logic_vector(31 downto 0);
    wb_addr_i  : in  std_logic_vector(g_memsize_log2-1 downto 0);
    wb_sel_i   : in  std_logic_vector(3 downto 0) := x"f";
    wb_cyc_i   : in  std_logic;
    wb_stb_i   : in  std_logic;
    wb_we_i    : in  std_logic;
    wb_ack_o   : out std_logic;
    wb_stall_o : out std_logic
    );

end nic_buffer;

architecture syn of nic_buffer is

  function f_zeros(size : integer)
    return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(0, size));
  end f_zeros;

  signal host_we  : std_logic;
  signal host_ack : std_logic;
  signal host_bwe : std_logic_vector(3 downto 0);

begin  -- syn

  wb_ack_o <= host_ack;
  wb_stall_o <= '0';


  ----------------DMA----------------------
  DMA_SIGS : if(g_USE_DMA) generate
    ack_gen : process(clk_sys_i, rst_n_i)
    begin
      if rising_edge(clk_sys_i) then
        if rst_n_i = '0' then
          host_ack <= '0';
        else
          host_ack <= wb_cyc_i and wb_stb_i;                  -- pipelined WB
        end if;
      end if;
    end process;
    host_we  <= wb_we_i and wb_cyc_i and wb_stb_i;
    host_bwe <= wb_sel_i when host_we = '1' else f_zeros(4);  --Tom's hack from xwb_dpram for Xilinx ISE
  end generate;

  -------------CLASSIC---------------------
  CLASSIC_SIGS : if(not(g_USE_DMA)) generate
    ack_gen : process(clk_sys_i, rst_n_i)
    begin
      if rising_edge(clk_sys_i) then
        if rst_n_i = '0' then
          host_ack <= '0';
        else
            host_ack <= (wb_cyc_i and wb_stb_i) and (not host_ack);
        end if;
      end if;
    end process;
    host_we  <= wb_cyc_i and wb_stb_i and (wb_we_i and not host_ack);
    host_bwe <= x"f";
  end generate;


  RAM : generic_dpram
    generic map (
      g_data_width => 32,
      g_size       => 2**g_memsize_log2,
      g_dual_clock => false)
    port map (
-- host port
      rst_n_i => rst_n_i,
      clka_i  => clk_sys_i,
      clkb_i  => clk_sys_i,
      wea_i   => host_we,
      bwea_i  => host_bwe,
      aa_i    => wb_addr_i,
      da_i    => wb_data_i,
      qa_o    => wb_data_o,

      web_i  => wr_i,
      bweb_i => x"f",
      ab_i   => addr_i,
      db_i   => data_i,
      qb_o   => data_o);

end syn;
