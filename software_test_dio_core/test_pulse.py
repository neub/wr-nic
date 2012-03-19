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
   print "Value of LEMOs with all drivers enabled and terminations disabled"
   for lemon in range(5):
      dio.set_term(lemon, 0)
      dio.set_dir(lemon, 1)
      dio.set_in_threshold(lemon,15)

   print "Input threshold set to an intermediate level ({}).".format(dio.get_in_threshold(0))

   print
   print "(------------CONFIGURING INTERRUPTS--------------)"
   print "(DIO Interrupts)"
   # DIO Interrupts
   dio.set_reg(0x64, 0x1f)   # Interrupts when the fifos have datas (UTC time from the pulse stamper)
   mask_irq = dio.get_reg(0x68)
   print "MASK IRQ DIO =>", mask_irq
   status_irq = dio.get_reg(0x6c) 
   print "STATUS IRQ DIO =>", status_irq

   # VIC Interrupts
   print "(VIC Interrupts)"
   VIC = VIC_irq(spec, 0x40000)
   VIC.set_reg(0x0, 0x3)   # control register
   control_irq_vic = VIC.get_reg(0x0)
   print "CONTROL IRQ VIC =>", control_irq_vic
   VIC.set_reg(0x8, 0x7)   # enable register
   mask_irq_vic = VIC.get_reg(0x10)
   print "MASK IRQ VIC =>", mask_irq_vic
   #VIC.set_reg(0x18, 0x7)   # generate soft irq

   print
   print "(------------CONFIGURING TRIG UTC TIME FOR EACH LEMO--------------)"
   print "Note: The dummy time core is already running after configuring the fpga, therefore you should run this program"
   print "before the configured trigger time below." 
   dio_rdy = dio.get_reg(0x40)
   if dio_rdy != 0x1f:
     print "Some pulse_gen module isn't ready to accept next trigger time tag, dio_rdy:", dio_rdy
     exit()

   #TIME TRIGGERS
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
   
   adr_status_fifo = [0x7c, 0x8c, 0x9c, 0xac, 0xbc]
   adr_time = [0x70, 0x80, 0x90, 0xa0, 0xb0]
   adr_cycles = [0x78, 0x88, 0x98, 0xa8, 0xb8]
   for dio_pulse in range(5):
     print "Waiting pulse stamper from DIO ", dio_pulse," ...."
     status_fifo_reg = dio.get_reg(adr_status_fifo[dio_pulse])
     while((status_fifo_reg & 0xff) != 0x1): #counter = 0x1
       status_fifo_reg = dio.get_reg(adr_status_fifo[dio_pulse])
     time   = dio.get_reg_long(adr_time[dio_pulse])
     cycles = dio.get_reg(adr_cycles[dio_pulse])
     print "UTC DIO dio_pulse =>", time
     print "cycles DIO dio_pulse =>", cycles
     print

   status_irq_vic = VIC.get_reg(0x4) 
   print "STATUS VIC IRQ =>", status_irq_vic
   print

   status_irq = dio.get_reg(0x6c) 
   print "STATUS IRQ DIO =>", status_irq

   print
   print "(-----------IMMEDIATE PULSE GENERATION (5 pulses for each DIO)---------------)"
   for num_pulses in range(5):
     dio.set_reg(0x44, 0x1f) # To generate 5 pulses for each DIO

   print
   status_irq_vic = VIC.get_reg(0x4) 
   print "STATUS VIC IRQ =>", status_irq_vic

   status_irq = dio.get_reg(0x6c) 
   print "STATUS IRQ DIO =>", status_irq


   print
   for dio_pulse in range(5): # reading of pulses
     print "------Pulses from DIO ", dio_pulse, ":"
     status_fifo_reg = dio.get_reg(adr_status_fifo[dio_pulse])
     cont = 0
     while((status_fifo_reg & 0xff) != 0x0):
       time   = dio.get_reg_long(adr_time[dio_pulse])
       cycles = dio.get_reg(adr_cycles[dio_pulse])
       print "Pulse ", cont
       print "UTC DIO dio_pulse =>", time
       print "cycles DIO dio_pulse =>", cycles
       status_fifo_reg = dio.get_reg(adr_status_fifo[dio_pulse])
       cont = cont + 1
     print


   print
   status_irq_vic = VIC.get_reg(0x4) 
   print "STATUS VIC IRQ =>", status_irq_vic

   status_irq = dio.get_reg(0x6c) 
   print "STATUS IRQ DIO =>", status_irq


#   print "Waiting irq ..."
#   gennum.wait_irq()




   exit()


if __name__ == "__main__":
    main(".")

