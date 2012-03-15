#!/usr/bin/python
#coding: utf8

from ptsexcept import *
from dio_fmc import *

import rr
import os
import sys
import gn4124
import kbhit

"""
Tests DIO core (GEN AND STAMPER PULSE)
"""

def pause():
   raw_input("press key\n")

GN4124_CSR = 0x0

def main(default_directory="."):
   print "(-------------STARTING TEST-----------------)"
   spec = rr.Gennum()
   gennum = gn4124.CGN4124(spec, GN4124_CSR)
   dio = CFmcDio(spec, 0x60000)

   print "(3 devices expected)"
   print
   print ("FMC temperature: %3.3f°C" % dio.get_temp())
   print "(expected room or computer temperature)"
   print

   print "(------------CONFIGURING DIO CHANNELS--------------)"
   print "Value of LEMOs with all drivers enabled and terminations disabled",
   for lemon in range(5):
      dio.set_term(lemon, 0)
      dio.set_dir(lemon, 1)
      dio.set_in_threshold(lemon,30)
   print "Input threshold set to an intermediate level ({}).".format(dio.get_in_threshold(0))

   print "(------------CONFIGURING INTERRUPTS--------------)"
   print "(DIO Interrupts)"
   # DIO Interrupts
   dio.set_reg(0x64, 0x1f)   # Interrupts when the fifos have datas (UTC time from the pulse stamper)
   mask_irq = dio.get_reg(0x68)
   print "mask_irq =>", mask_irq
   status_irq = dio.get_reg(0x6c) 
   print "STATUS IRQ =>", status_irq


   # DIO Interrupts
   print "(VIC Interrupts)"
   VIC = VIC_irq(spec, 0x40000)
   VIC.set_reg(0x0, 0x3)   # control register
   control_irq_vic = VIC.get_reg(0x0)
   print "control_irq_vic =>", control_irq_vic
   VIC.set_reg(0x8, 0x3)   # enable register
   mask_irq_vic = VIC.get_reg(0x10)
   print "mask_irq_vic =>", mask_irq_vic


   print
   print "(------------CONFIGURING TRIG UTC TIME FOR EACH LEMO--------------)"
   print "Note: The dummy time core is already running after configuring the fpga"
   dio_rdy = dio.get_reg(0x40)
#   if dio_rdy != 0x1f:
#      print "Some pulse_gen module isn't ready to accept next trigger time tag, dio_rdy:", dio_rdy
#      exit()

   dio.set_reg(0x0, 20)     #trig0 UTC_low
   dio.set_reg(0x4, 0)    #trig0 UTC_high
   dio.set_reg(0x8, 0)    #trig0 cycles

   dio.set_reg(0xc, 25)     #trig1 UTC_low
   dio.set_reg(0x10, 0)   #trig1 UTC_high
   dio.set_reg(0x14, 67)  #trig1 cycles

   dio.set_reg(0x18, 31)    #trig2 UTC_low
   dio.set_reg(0x1c, 0)   #trig2 UTC_high
   dio.set_reg(0x20, 430) #trig2 cycles

   dio.set_reg(0x24, 40)    #trig3 UTC_low
   dio.set_reg(0x28, 0)   #trig3 UTC_high
   dio.set_reg(0x2c, 94)  #trig3 cycles

   dio.set_reg(0x30, 42)    #trig4 UTC_low
   dio.set_reg(0x34, 0)   #trig4 UTC_high
   dio.set_reg(0x38, 98)  #trig4 cycles

   dio.set_reg(0x3c, 0x1f)   #all trigX Enabled


   print
   print "Waiting pulse stamper from DIO 0...."
   status_fifo_reg_0 = dio.get_reg(0x7c)
   while(status_fifo_reg_0 != 0x1): #counter = 0x1
     status_fifo_reg_0 = dio.get_reg(0x7c)

   time   = dio.get_reg_long(0x70)
   cycles = dio.get_reg_long(0x78)

   print "UTC DIO 0 =>", time
   print "cycles DIO 0 =>", cycles
   print


   print
   print "Waiting pulse stamper from DIO 1...."
   status_fifo_reg_0 = dio.get_reg(0x8c)
   while(status_fifo_reg_0 != 0x1):  #counter = 0x1
     status_fifo_reg_0 = dio.get_reg(0x8c)

   time   = dio.get_reg_long(0x80)
   cycles = dio.get_reg_long(0x88)

   print "UTC DIO 1 =>", time
   print "cycles DIO 1 =>", cycles
   print


   print
   print "Waiting pulse stamper from DIO 2...."
   status_fifo_reg_0 = dio.get_reg(0x9c)
   while(status_fifo_reg_0 != 0x1):  #counter = 0x1
     status_fifo_reg_0 = dio.get_reg(0x9c)

   time   = dio.get_reg_long(0x90)
   cycles = dio.get_reg_long(0x98)

   print "UTC DIO 2 =>", time
   print "cycles DIO 2 =>", cycles
   print


   print
   print "Waiting pulse stamper from DIO 3...."
   status_fifo_reg_0 = dio.get_reg(0xac)
   while(status_fifo_reg_0 != 0x1):  #counter = 0x1
     status_fifo_reg_0 = dio.get_reg(0xac)

   time   = dio.get_reg_long(0xa0)
   cycles = dio.get_reg_long(0xa8)

   print "UTC DIO 3 =>", time
   print "cycles DIO 3 =>", cycles
   print


   print
   print "Waiting pulse stamper from DIO 4...."
   status_fifo_reg_0 = dio.get_reg(0xbc)
   while(status_fifo_reg_0 != 0x1):  #counter = 0x1
     status_fifo_reg_0 = dio.get_reg(0xbc)

   time   = dio.get_reg_long(0xb0)
   cycles = dio.get_reg_long(0xb8)

   print "UTC DIO 4 =>", time
   print "cycles DIO 4 =>", cycles
   print

   status_irq_vic = dio.get_reg(0x4) 
   print "STATUS VIC IRQ =>", status_irq_vic


#   print "Waiting irq ..."
#   gennum.wait_irq()




   exit()


if __name__ == "__main__":
    main(".")

