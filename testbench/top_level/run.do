vlog -sv main.sv +incdir+"." +incdir+gn4124_bfm +incdir+../../sim
#make -f Makefile
vsim -t 10fs -L secureip -L unisim work.main -voptargs="+acc"
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
do wave.do
radix -hexadecimal
run 25us
wave zoomfull
radix -hexadecimal
