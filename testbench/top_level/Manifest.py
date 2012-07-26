action = "simulation"
fetchto = "../../ip_cores"
vlog_opt="+incdir+../../sim +incdir+gn4124_bfm"

files = [ "main.sv" ]

modules = { "local" :  [ "../..", "../../top/spec", "./gn4124_bfm"] }

