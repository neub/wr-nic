target = "xilinx"
action = "synthesis"

fetchto = "../../ip_cores"

syn_device = "xc6slx45t"
syn_grade = "-3"
syn_package = "fgg484"
syn_top = "wr_nic_dio_top"
syn_project = "wr_nic_dio.xise"

modules = {"local" : 
              [ "../../top/specdio",
		"../../platform/xilinx" 
              ] 
          }
