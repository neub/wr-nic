onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /main/U_wrf_source/clk_i
add wave -noupdate /main/U_wrf_source/rst_n_i
add wave -noupdate -expand -group EP_STIM /main/U_wrf_source/adr
add wave -noupdate -expand -group EP_STIM /main/U_wrf_source/dat_o
add wave -noupdate -expand -group EP_STIM /main/U_wrf_source/ack
add wave -noupdate -expand -group EP_STIM /main/U_wrf_source/stall
add wave -noupdate -group RX_PCS /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_RX_PCS/d_is_k
add wave -noupdate -group RX_PCS /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_RX_PCS/d_err
add wave -noupdate -group RX_PCS /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_RX_PCS/d_is_comma
add wave -noupdate -group RX_PCS /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_RX_PCS/d_is_epd
add wave -noupdate -group RX_PCS /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_RX_PCS/d_is_spd
add wave -noupdate -group RX_PCS /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_RX_PCS/d_is_extend
add wave -noupdate -group RX_PCS /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_RX_PCS/d_is_idle
add wave -noupdate -group RX_PCS /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_RX_PCS/d_is_lcr
add wave -noupdate -group RX_PCS /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_RX_PCS/d_is_sfd_char
add wave -noupdate -group RX_PCS /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_RX_PCS/d_is_preamble_char
add wave -noupdate -group RX_PCS /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_RX_PCS/d_data
add wave -noupdate -group RX_PCS /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_RX_PCS/d_is_even
add wave -noupdate -group RX_PCS /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_RX_PCS/d_is_cal
add wave -noupdate /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/rxpcs_fab_o
add wave -noupdate -expand -group pfilter /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_Rx_Path/pfilter_pclass
add wave -noupdate -expand -group pfilter /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_Rx_Path/pfilter_drop
add wave -noupdate -expand -group pfilter /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_Rx_Path/pfilter_done
add wave -noupdate -group mbuf /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_Rx_Path/mbuf_rd
add wave -noupdate -group mbuf /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_Rx_Path/mbuf_valid
add wave -noupdate -group mbuf /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_Rx_Path/mbuf_we
add wave -noupdate -group mbuf /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_Rx_Path/mbuf_pf_drop
add wave -noupdate -group mbuf /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_Rx_Path/mbuf_is_hp
add wave -noupdate -group mbuf /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_Rx_Path/mbuf_is_pause
add wave -noupdate -group mbuf /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_Rx_Path/mbuf_full
add wave -noupdate -group mbuf /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_Rx_Path/mbuf_we_d0
add wave -noupdate -group mbuf /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_Rx_Path/mbuf_we_d1
add wave -noupdate -group mbuf /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_Rx_Path/mbuf_pf_class
add wave -noupdate -group RX_PATH -expand -subitemconfig {/main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_Rx_Path/fab_pipe(8) -expand} /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_Rx_Path/fab_pipe
add wave -noupdate -group RX_PATH -expand /main/DUT/U_WR_CORE/WRPC/U_Endpoint/U_Wrapped_Endpoint/U_Rx_Path/dreq_pipe
add wave -noupdate -group WRF_MUX -height 16 /main/DUT/U_WR_CORE/WRPC/U_WBP_Mux/demux
add wave -noupdate -group WRF_MUX /main/DUT/U_WR_CORE/WRPC/U_WBP_Mux/dmux_sel
add wave -noupdate -group EP_FABRIC -expand /main/DUT/U_WR_CORE/WRPC/U_Endpoint/src_o
add wave -noupdate -group EP_FABRIC /main/DUT/U_WR_CORE/WRPC/U_Endpoint/src_i
add wave -noupdate -expand -group EXT_FABRIC -expand /main/DUT/U_WR_CORE/wrf_src_o
add wave -noupdate -expand -group EXT_FABRIC /main/DUT/U_WR_CORE/wrf_src_i
add wave -noupdate -group MINIC_FABRIC /main/DUT/U_WR_CORE/WRPC/MINI_NIC/snk_o
add wave -noupdate -group MINIC_FABRIC -expand /main/DUT/U_WR_CORE/WRPC/MINI_NIC/snk_i
add wave -noupdate -expand -group NIC -height 16 /main/DUT/U_NIC/U_RX_FSM/state
add wave -noupdate -expand -group NIC /main/DUT/U_NIC/rxdesc_request_next
add wave -noupdate -expand -group NIC /main/DUT/U_NIC/rxdesc_grant
add wave -noupdate -expand -group NIC -expand /main/DUT/U_NIC/rxdesc_current
add wave -noupdate -expand -group NIC -expand /main/DUT/U_NIC/rxdesc_new
add wave -noupdate -expand -group NIC /main/DUT/U_NIC/rxdesc_write
add wave -noupdate -expand -group NIC /main/DUT/U_NIC/rxdesc_write_done
add wave -noupdate -expand -group NIC -height 16 /main/DUT/U_NIC/U_RX_DESC_MANAGER/state
add wave -noupdate -expand -group NIC /main/DUT/U_NIC/nic_drx_addr
add wave -noupdate -expand -group NIC /main/DUT/U_NIC/nic_drx_wr_data
add wave -noupdate -expand -group NIC /main/DUT/U_NIC/nic_drx_rd
add wave -noupdate -expand -group NIC /main/DUT/U_NIC/nic_drx_rd_data
add wave -noupdate -expand -group NIC /main/DUT/U_NIC/nic_drx_wr
add wave -noupdate -expand -group NIC -expand -group RXD_RAM /main/DUT/U_NIC/U_WB_SLAVE/nic_drx_raminst/wrapped_dpram/gen_single_clk/U_RAM_SC/ram(0)
add wave -noupdate -expand -group NIC -expand -group RXD_RAM /main/DUT/U_NIC/U_WB_SLAVE/nic_drx_raminst/wrapped_dpram/gen_single_clk/U_RAM_SC/ram(1)
add wave -noupdate -expand -group NIC -expand -group RXD_RAM /main/DUT/U_NIC/U_WB_SLAVE/nic_drx_raminst/wrapped_dpram/gen_single_clk/U_RAM_SC/ram(2)
add wave -noupdate -expand -group NIC -expand -group RXD_RAM /main/DUT/U_NIC/U_WB_SLAVE/nic_drx_raminst/wrapped_dpram/gen_single_clk/U_RAM_SC/ram(3)
add wave -noupdate -expand -group NIC -expand -group RXD_RAM /main/DUT/U_NIC/U_WB_SLAVE/nic_drx_raminst/wrapped_dpram/gen_single_clk/U_RAM_SC/ram(4)
add wave -noupdate -expand -group NIC -expand -group RXD_RAM /main/DUT/U_NIC/U_WB_SLAVE/nic_drx_raminst/wrapped_dpram/gen_single_clk/U_RAM_SC/ram(5)
add wave -noupdate -expand -group NIC -expand -group RXD_RAM /main/DUT/U_NIC/U_WB_SLAVE/nic_drx_raminst/wrapped_dpram/gen_single_clk/U_RAM_SC/ram(6)
add wave -noupdate -expand -group NIC -expand -group RXD_RAM /main/DUT/U_NIC/U_WB_SLAVE/nic_drx_raminst/wrapped_dpram/gen_single_clk/U_RAM_SC/ram(7)
add wave -noupdate -expand -group NIC -expand -group RXD_RAM /main/DUT/U_NIC/U_WB_SLAVE/nic_drx_raminst/wrapped_dpram/gen_single_clk/U_RAM_SC/ram(8)
add wave -noupdate -expand -group NIC -expand -group RXD_RAM /main/DUT/U_NIC/U_WB_SLAVE/nic_drx_raminst/wrapped_dpram/gen_single_clk/U_RAM_SC/ram(9)
add wave -noupdate -expand -group NIC -expand -group RXD_RAM /main/DUT/U_NIC/U_WB_SLAVE/nic_drx_raminst/wrapped_dpram/gen_single_clk/U_RAM_SC/ram(10)
add wave -noupdate -expand -group NIC -expand /main/DUT/U_NIC/U_RX_DESC_MANAGER/granted_desc_rx
add wave -noupdate -expand -group nic_buffer /main/DUT/U_NIC/U_BUFFER/addr_i
add wave -noupdate -expand -group nic_buffer /main/DUT/U_NIC/U_BUFFER/data_i
add wave -noupdate -expand -group nic_buffer /main/DUT/U_NIC/U_BUFFER/wr_i
add wave -noupdate -expand -group nic_buffer /main/DUT/U_NIC/U_BUFFER/data_o
add wave -noupdate -expand -group nic_buffer /main/DUT/U_NIC/U_RX_FSM/rx_rdreg_toggle
add wave -noupdate -expand -group nic_buffer /main/DUT/U_NIC/U_RX_FSM/fab_in.data
add wave -noupdate -expand -group nic_buffer -height 16 /main/DUT/U_NIC/U_RX_FSM/state
add wave -noupdate -expand -group CBAR /main/DUT/cbar_slave_i
add wave -noupdate -expand -group CBAR /main/DUT/cbar_slave_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {379266620970 fs} 0} {{Cursor 2} {313309014010 fs} 0}
configure wave -namecolwidth 207
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 fs} {525 us}
