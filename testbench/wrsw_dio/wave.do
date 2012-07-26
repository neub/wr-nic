onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /main/DUT/clk_sys_i
add wave -noupdate /main/DUT/clk_ref_i
add wave -noupdate /main/DUT/rst_n_i
add wave -noupdate /main/DUT/tm_time_valid_i

add wave -divider WB
add wave -noupdate /main/DUT/wb_cyc_i
add wave -noupdate /main/DUT/wb_stb_i
add wave -noupdate /main/DUT/wb_we_i
add wave -noupdate /main/DUT/wb_sel_i
add wave -noupdate /main/DUT/wb_adr_i
add wave -noupdate /main/DUT/wb_dat_i
add wave -noupdate /main/DUT/wb_dat_o
add wave -noupdate /main/DUT/wb_ack_o
add wave -noupdate /main/DUT/wb_stall_o


TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {90685000000 fs} 0}
configure wave -namecolwidth 150
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
WaveRestoreZoom {90556826170 fs} {90813173830 fs}
