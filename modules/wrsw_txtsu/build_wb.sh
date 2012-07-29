#!/bin/bash

mkdir -p doc
wbgen2 -D ./doc/txtsu.htm -V wrsw_txtsu_wb.vhd --cstyle defines --lang vhdl -K ../../sim/tx_tstsu_regs.vh wrsw_txtsu.wb

