#!/usr/bin/python
#coding: utf8

from ptsexcept import *
from dio_fmc import *

import rr
import os
import sys

import kbhit

"""
test01: Tests all the outputs and the FMC front panel LEDs
"""

def pause():
   raw_input("press key\n")

def print_lemos(dio):
   for lemon in range(5):
      print dio.get_in(lemon),

def osc_lemos(dio):
   while(not kbhit.kbhit()): 
      for lemon in range(5):
         dio.set_out(lemon,0)
      time.sleep(0.05)
      dio.set_out(0,1)
      time.sleep(0.05)
      for lemon in range(5):
         dio.set_out(lemon,0)
         if lemon < 5:
            dio.set_out(lemon+1,1)
         time.sleep(0.05)
      for lemon in range(5):
         dio.set_out(lemon,0)


def main(default_directory="."):
   spec = rr.Gennum()
   dio = CFmcDio(spec, 0x80000)

   #dio.set_out(0,1)
   #dio.set_dir(0, 1)
   #dio.set_term(0, 0)
   #exit()

   print "(3 devices expected)"
   print
   print "FMC temperature: {:3}°C".format(dio.get_temp())
   print "(expected room or computer temperature)"
   print
   print "Flashing board LEDs. Press key"
   while(not kbhit.kbhit()): 
      for nled in range(2):
         dio.set_led(nled,1)
      time.sleep(0.2)
      print ".",
      for nled in range(2):
         dio.set_led(nled,0)
      time.sleep(0.2)
      sys.stdout.flush()

   kbhit.getch()
   print
   print "Oscillating LEMOs without load. Press key"
   print "(2.06V-amplitude pulses expected in all ports)"
   for lemon in range(5):
      dio.set_dir(lemon, 1)
      dio.set_term(lemon, 0)
   osc_lemos(dio)

   kbhit.getch()
   print "Oscillating LEMOs with load. Press key"
   print "(1.58V-amplitude pulses expected in all ports)"
   for lemon in range(5):
      dio.set_term(lemon, 1)
   osc_lemos(dio)
   for lemon in range(5):
      dio.set_term(lemon, 0)

   kbhit.getch()
   print "Oscillating LEMOs with driver disabled. Press key"
   print "(no pulse expected in all ports)"
   for lemon in range(5):
      dio.set_dir(lemon, 0)
   osc_lemos(dio)

   kbhit.getch()
   for lemon in range(5):
      dio.set_in_threshold(lemon,10)
   print "Input threshold set to an intermediate level ({}).".format(dio.get_in_threshold(0))
   print "Value of LEMOs with all drivers and terminations disabled:",
   for lemon in range(5):
      dio.set_term(lemon, 0)
      dio.set_dir(lemon, 0)
      dio.set_out(lemon, 1)
   print_lemos(dio)
   for lemon in range(5):
      dio.set_out(lemon, 0)
   print
   print "(zero vector expected)"
   print
   print "Terminations off"
   for lemon in range(5):
      dio.set_dir(lemon, 1)
      dio.set_out(lemon, 1)
      print "driver",lemon,"on. INPUT:",
      print_lemos(dio)
      print
      dio.set_dir(lemon, 0)
      dio.set_out(lemon, 0)
   print "(identity matrix expected)"
   print
   print "Terminations on"
   for lemon in range(5):
      dio.set_dir(lemon, 1)
      dio.set_out(lemon, 1)
      dio.set_term(lemon, 1)
      print "driver",lemon,"on. INPUT:",
      print_lemos(dio)
      print
      dio.set_dir(lemon, 0)
      dio.set_out(lemon, 0)
      dio.set_term(lemon, 0)
   print "(zero matrix expected)"
   print

   print "EEPROM sequence written. DATA:",
   oldedatas=dio.eeprom.rd_data(0,20)
   time.sleep(0.1)
   dio.eeprom.wr_data(0,range(20))
   time.sleep(0.1)
   edatas=dio.eeprom.rd_data(0,20)
   for edata in edatas:
      print edata,
   print
   time.sleep(0.1)
#   oldedatas=[]
#   oldedatas.extend(255 for number in range(30))
   dio.eeprom.wr_data(0,oldedatas)
   print "(0 to 19 sequence expected)"

   print
   for lemon in range(5):
      print "Testing LEMO:",lemon
      dio.set_dir(lemon, 1)
      dio.set_out(lemon, 1)
      dio.set_term(lemon, 1)
      for odac in range(0,256,32):
         dio.set_in_threshold(lemon,odac)
         time.sleep(0.005)
         print "DAC Out: {:3} LEMOs:".format(odac),
         print_lemos(dio)
         print
      dio.set_dir(lemon, 0)
      dio.set_out(lemon, 0)
      dio.set_term(lemon, 0)
      print "(the first 4 elements in column",lemon+1,"are expected to be 1)"
      print

   exit()



"""
    	ask = ""

	## Set all LEMOS output to 2V
	lemos = 0, 1, 2, 3, 4 
	for k in lemos: 
		dio.set_out(k,1)
	ask = ""	
	while ((ask != "Y") and (ask != "N")) :
		print "-------------------------------------------------------------"
		print "\t Testing Outputs "
	    	ask = raw_input("Does the Output is 2V? [Y/N]")
		ask = ask.upper()
		print "-------------------------------------------------------------"
	if (ask == "N") :
		raise PtsError("Error loading FW through the Flash memory or there is a problem with the LEDs")
    
	## Set all LEMOS output to 0V
	for k in lemos:
		dio.set_out(k,0)
	ask = ""
	while ((ask != "Y") and (ask != "N")) :
		print "-------------------------------------------------------------"
		print "\t Testing LEDs "
	    	ask = raw_input("Does the Output is 0V? [Y/N]")
		ask = ask.upper()
		print "-------------------------------------------------------------"
	if (ask == "N") :
		raise PtsError("Error loading FW through the Flash memory or there is a problem with the LEDs")
    
"""

if __name__ == "__main__":
    main(".")

