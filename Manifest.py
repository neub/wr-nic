fetchto = "ip_cores"

modules =  { "local" : ["modules/wrsw_dio"],
             "git" : ["git://ohwr.org/white-rabbit/wr-switch-hdl.git",
		      "git://ohwr.org/hdl-core-lib/general-cores.git::no_coregen"],
             "svn" : "http://svn.ohwr.org/gn4124-core/trunk/hdl/gn4124core/rtl"
           }


