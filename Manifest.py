fetchto = "ip_cores"

modules =  {"local" : 
    [ "modules/wrsw_nic",
      "modules/wrsw_txtsu",
      "modules/wrsw_dio"
       ],
    "git" : "git://ohwr.org/hdl-core-lib/wr-cores.git::wishbonized",
    "svn" : "http://svn.ohwr.org/gn4124-core/trunk/hdl/gn4124core/rtl"
    }
