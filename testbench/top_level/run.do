vlog -sv main.sv +incdir+"." +incdir+gn4124_bfm +incdir+../../sim +incdir+../../sim/wr-hdl +incdir+../../sim/regs
#make -f Makefile
vsim -t 10fs -L secureip -L unisim work.main -voptargs="+acc"
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
do wave_nic_rx.do
radix -hexadecimal
run 500us
wave zoomfull
radix -hexadecimal
