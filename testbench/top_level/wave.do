onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /main/DUT/U_VIC/g_interface_mode
add wave -noupdate /main/DUT/U_VIC/g_address_granularity
add wave -noupdate /main/DUT/U_VIC/g_num_interrupts
add wave -noupdate /main/DUT/U_VIC/clk_sys_i
add wave -noupdate /main/DUT/U_VIC/rst_n_i
add wave -noupdate /main/DUT/U_VIC/slave_i
add wave -noupdate /main/DUT/U_VIC/slave_o
add wave -noupdate /main/DUT/U_VIC/irqs_i
add wave -noupdate /main/DUT/U_VIC/irq_master_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2367015 ps} 0}
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
WaveRestoreZoom {0 ps} {26250 ns}
