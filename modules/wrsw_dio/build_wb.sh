#!/bin/bash

mkdir -p doc
wbgen2 -D ./doc/dio.html -V wrsw_dio_wb.vhd --cstyle defines --lang vhdl -K ../../sim/dio_timing_regs.vh wrsw_dio.wb
# wbgen2 -D ./doc/dio.html -V wrsw_dio_wb.vhd --cstyle defines --lang vhdl -p dio_wbgen2_pkg.vhd -H record -K ../../sim/dio_timing_regs.vh wrsw_dio.wb
