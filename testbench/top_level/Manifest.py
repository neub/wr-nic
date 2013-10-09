action = "simulation"
target = "xilinx"
fetchto = "../../ip_cores"
vlog_opt="+incdir+../../sim +incdir+gn4124_bfm +incdir+../../sim/wr-hdl +incdir+../../sim/regs"

files = [ "main.sv" ]

modules = { "local" :  [ "../..", "../../top/specdio", "./gn4124_bfm"] }

