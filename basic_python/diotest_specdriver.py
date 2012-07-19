#!/usr/bin/python
#coding: utf8

from ptsexcept import *
from dio_fmc import *
import os
import sys
import kbhit

"""
Tests DIO core (GEN AND STAMPER PULSE)
"""

def pause():
   raw_input("press key\n")

GN4124_CSR = 0x0

def main(default_directory="."):
   print "(-------------STARTING TEST-----------------)"

   # Configure the FPGA using the program fpga_loader
   path_fpga_loader = './fpga_loader'
   path_firmware = '../syn/spec/wr_nic_top.bin'
   firmware_loader = os.path.join(default_directory, path_fpga_loader)
   bitstream = os.path.join(default_directory, path_firmware)
   print "Loading firmware: %s" % (firmware_loader + ' ' + bitstream)
   os.system( firmware_loader + ' ' + bitstream )

   # Load board library and open the corresponding device
   spec = rr.Gennum()
   gennum = gn4124.CGN4124(spec, GN4124_CSR)
   dio = CFmcDio(spec, 0x62000)

   print "(3 devices expected)"
   print
   print ("FMC temperature: %3.3f°C" % dio.get_temp())
   print "(expected room or computer temperature)"
   print	
   
   # Lemo output configuration
   print "(------------CONFIGURING DIO CHANNELS--------------)"
   print "Value of LEMOs with all drivers enabled and terminations disabled"
   for lemon in range(5):
      dio.set_term(lemon, 0)
      dio.set_dir(lemon, 1)  # enable output
      dio.set_in_threshold(lemon,15)
   print "Input threshold set to an intermediate level ({}).".format(dio.get_in_threshold(0))

   print
   print "(------------CONFIGURING INTERRUPTS--------------)"
 
   # DIO Interrupts
   print "(DIO Interrupts)"
   dio.set_reg(0x64, 0x1f)   # Interrupts when the fifos have datas (UTC time from the pulse stamper)
   #dio.set_reg(0x64, 0x3ff)  # fifos and pulse gen rdy interrupts
   mask_irq = dio.get_reg(0x68)
   print "MASK IRQ DIO =>", mask_irq
   status_irq = dio.get_reg(0x6c) 
   print "STATUS IRQ DIO =>", status_irq

   # VIC Interrupts
   print "(VIC Interrupts)"
   VIC = VIC_irq(spec, 0x60000)
   VIC.set_reg(0x0, 0x3)   # control register
   control_irq_vic = VIC.get_reg(0x0)
   print "CONTROL IRQ VIC =>", control_irq_vic
   VIC.set_reg(0x8, 0x7)   # enable register
   mask_irq_vic = VIC.get_reg(0x10)
   print "MASK IRQ VIC =>", mask_irq_vic
   status_irq_vic = VIC.get_reg(0x4) 
   print "STATUS VIC IRQ =>", status_irq_vic
   
   # Simulate interrupts
   #VIC.set_reg(0x18, 0x7)   # generate soft irq
   #status_irq_vic = VIC.get_reg(0x4) 
   #print "STATUS VIC IRQ AFTER SOFTWARE INTERRUPTS =>", status_irq_vic

   # Checking interrupts at pc level
   #print "Waiting irq ..."   
   #spec.irqena()   
   #gennum.set_interrupt_config()
   #a=gennum.wait_irq()
   #b=spec.irqwait()   
   #print "Is this working?", a,b

   # Read WRCORE time
   WR_CORE_AD     =0x0
   PRI_CROSSBAR_AD=0x00020000 # Second bridge
   SEC_CROSSBAR_AD=0x00000300 # PPS
   time = wrcore_time(spec, (WR_CORE_AD + PRI_CROSSBAR_AD+SEC_CROSSBAR_AD))  
   print "eso", time
   seconds= time.get_reg(0x8) # 0x00020308
   cycles = time.get_reg(0x4) # 0x00020304
   #seconds=10
   #cycles=0
   print "Time from PTP is: ", seconds, "and", cycles*8, "(cycles", cycles, ")"

   ###################################################################################
   # START LEMO OUTPUT DANCING ...
   print
   print "(------------START LEMO CONFIGURATION--------------)"
   #print "Note: The dummy time core is already running after configuring the fpga, therefore you should run this program"
   #print "before the configured trigger time below." 
   
   # BASIC GPIO FUNCTIONALITY TEST
   dio.set_reg(0x3C, 0x00)   # channels as GPIOs  
   for lemon in range(5):
     dio.set_dir(lemon, 1)  # enable output
     dio.set_out(lemon,0)
     val=dio.get_in (lemon)
     print "Set value for channel", lemon, " to 0, read: ", val
     dio.set_out(lemon,1)
     val=dio.get_in (lemon)
     print "Set value for channel", lemon, " to 1, read: ", val
   
   # Please connect channel 0 and 1 with a lemo wire for this test
   dio.set_dir(0, 0)  # enable channel 1 output and dissble channel 0
   dio.set_dir(1,1)   
   dio.set_out(1,0)
   val=dio.get_in (0)
   print "Channel 1 write 0, channel 0 read", val
   dio.set_out(1,1)
   val=dio.get_in (0)
   print "Channel 1 write 1, channel 0 read", val

   # Osciloscope test
   #dio.set_out(4,1)
   #pause() 
   #dio.set_out(4,0)
   #pause() 
   #dio.set_out(4,1)
   #pause() 
   #dio.set_out(4,0)
   #pause() 


   # TIME-LENGTH PROGRAMMABLE PULSES TESTS
   dio.set_reg(0x3C, 0x1f)   #Generate a programmable/immediate pulse of different length  
  
   # Setting pulse length
   dio.set_reg(0x48, 0x1)   
   dio.set_reg(0x4C, 0x8)   
   dio.set_reg(0x50, 0x10)   
   dio.set_reg(0x54, 0x1)   
   dio.set_reg(0x58, 0x40) 

   # Time-stamps FIFOs registers address
   adr_status_fifo = [0x7c, 0x8c, 0x9c, 0xac, 0xbc]
   adr_time        = [0x70, 0x80, 0x90, 0xa0, 0xb0] # we just take the lowest 32 bits of the seconds field
   adr_cycles      = [0x78, 0x88, 0x98, 0xa8, 0xb8]

   # Flushng fifos from previous game
   print
   for dio_pulse in range(5): # reading of pulses
     print "------Flushing fifos ", dio_pulse, ":"
     status_fifo_reg = dio.get_reg(adr_status_fifo[dio_pulse])
     cont = 0
     
     while((status_fifo_reg & 0xff) != 0x0):
       time   = dio.get_reg_long(adr_time[dio_pulse])
       cycles = dio.get_reg(adr_cycles[dio_pulse])
       print "Pulse ", cont
       print "Seconds DIO dio_pulse =>", time
       print "cycles DIO dio_pulse =>", cycles
       status_fifo_reg = dio.get_reg(adr_status_fifo[dio_pulse])
       cont = cont + 1
     print

   ###################################################################################################
   # Inmmediate output test
   print
   print "(-----------IMMEDIATE PULSE GENERATION (5 pulses for each DIO)---------------)"
   #pause()
   for num_pulses in range(5):
     dio.set_reg(0x5C, 0x1f)   #Generate a pulse of different length
   #status_irq = dio.get_reg(0x6c) 
   ##print "STATUS IRQ DIO =>", status_irq

   print "5 Immediate pulse of different length has been generated for each channel"

   print
   status_irq_vic = VIC.get_reg(0x4) 
   print "STATUS VIC IRQ =>", status_irq_vic

   status_irq = dio.get_reg(0x6c) 
   print "STATUS IRQ DIO =>", status_irq # 31 means the 5 fifos has data


   print
   for dio_pulse in range(5): # reading of pulses
     print "------Pulses from DIO ", dio_pulse, ":"
     status_fifo_reg = dio.get_reg(adr_status_fifo[dio_pulse])
     cont = 0
     
     while((status_fifo_reg & 0xff) != 0x0):
       time   = dio.get_reg_long(adr_time[dio_pulse])
       cycles = dio.get_reg(adr_cycles[dio_pulse])
       print "Pulse ", cont
       print "Seconds DIO dio_pulse =>", time
       print "cycles DIO dio_pulse =>", cycles
       status_fifo_reg = dio.get_reg(adr_status_fifo[dio_pulse])
       cont = cont + 1
     print


   print
   status_irq_vic = VIC.get_reg(0x4) 
   print "STATUS VIC IRQ =>", status_irq_vic

   status_irq = dio.get_reg(0x6c) 
   print "STATUS IRQ DIO =>", status_irq # we have read the fifo, no data to read => 0



   ############################################################################
   print
   print "Starting time-programmable test" 
   print
   print "(------------TIME-TRIGGER BASED OUTPUTS--------------)"
   # Programmable output test	
   dio_rdy = dio.get_reg(0x44)
   if dio_rdy != 0x1f:
     print "Some pulse_gen module isn't ready to accept next trigger time tag, dio_rdy:", dio_rdy
     exit()

   #TIME TRIGGERS VALUES FOR EACH CHANNEL
   dio.set_reg(0x0, 3)      #trig0 seconds_low
   dio.set_reg(0x4, 0)      #trig0 seconds_high
   dio.set_reg(0x8, 0)      #trig0 cycles

   dio.set_reg(0xc, 5)     #trig1 seconds_low
   dio.set_reg(0x10, 0)     #trig1 seconds_high
   dio.set_reg(0x14, 67)    #trig1 cycles

   dio.set_reg(0x18, 10)    #trig2 seconds_low
   dio.set_reg(0x1c, 0)     #trig2 seconds_high
   dio.set_reg(0x20, 430)   #trig2 cycles

   dio.set_reg(0x24, 12)    #trig3 seconds_low
   dio.set_reg(0x28, 0)     #trig3 seconds_high
   dio.set_reg(0x2c, 94)    #trig3 cycles

   dio.set_reg(0x30, 15)    #trig4 seconds_low
   dio.set_reg(0x34, 0)     #trig4 seconds_high
   dio.set_reg(0x38, 98)    #trig4 cycles
   
   dio.set_reg(0x40, 0x1f)  # channell x trigger strobe

   print
   for dio_pulse in range(5):
     print "Waiting pulse stamper from DIO ", dio_pulse," ...."
     status_fifo_reg = dio.get_reg(adr_status_fifo[dio_pulse])
     while((status_fifo_reg & 0xff) != 0x1): #counter = 0x1
       status_fifo_reg = dio.get_reg(adr_status_fifo[dio_pulse])
     time   = dio.get_reg_long(adr_time[dio_pulse])
     cycles = dio.get_reg(adr_cycles[dio_pulse])
     print "DIO dio_pulse seconds =>", time
     print "DIO dio_pulse cycles  =>", cycles
     print

   status_irq_vic = VIC.get_reg(0x4) 
   print "STATUS VIC IRQ =>", status_irq_vic
   print

   status_irq = dio.get_reg(0x6c) 
   print "STATUS IRQ DIO =>", status_irq


   exit()

if __name__ == "__main__":
    main(".")

