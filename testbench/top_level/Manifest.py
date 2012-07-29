action = "simulation"
fetchto = "../../ip_cores"
vlog_opt="+incdir+../../sim +incdir+gn4124_bfm"

files = [ "main.sv", "../../ip_cores/wr-cores/platform/xilinx/wr_xilinx_pkg.vhd" ]

modules = { "local" :  [ "../..", "../../top/spec", "./gn4124_bfm"] }

