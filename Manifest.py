fetchto = "ip_cores"

modules =  {"local" : 
    [ "modules/wrsw_nic",
      "modules/wrsw_txtsu" ],
    "git" : "git://ohwr.org/hdl-core-lib/wr-cores.git::wishbonized",
    "svn" : "http://svn.ohwr.org/gn4124-core/branches/hdlmake-compliant/rtl"
    }
