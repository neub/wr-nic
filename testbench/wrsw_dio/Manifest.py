action = "simulation"
target = "xilinx"
fetchto = "../../ip_cores"
vlog_opt="+incdir+../../sim"

files = [ "main.sv" ]

modules = { "local" :  "../.." }

