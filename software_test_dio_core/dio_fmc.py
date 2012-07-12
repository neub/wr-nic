#!/usr/bin/python

import rr
import struct
import time
import sys

from xwb_gpio import *
from i2c import *
from eeprom_24aa64 import *
from onewire import *
from ds18b20 import *

class VIC_irq:

    def __init__(self, bus, base):
	self.bus = bus;
	self.base = base;

    def set_reg(self, adr, value):        
        self.bus.iwrite(0, self.base + adr, 4, value)

    def get_reg(self, adr):        
        return self.bus.iread(0, self.base + adr, 4)

class wrcore_time:

    def __init__(self, bus, base):
	self.bus = bus;
	self.base = base;

    def set_reg(self, adr, value):        
        self.bus.iwrite(0, self.base + adr, 4, value)

    def get_reg(self, adr):        
        return self.bus.iread(0, self.base + adr, 4)

class CDAC5578:

	CMD_POWER_ON = 0x40
	CMD_WRITE_CH = 0x30
	CMD_SW_RESET = 0x70
	CMD_LDAC_CTRL = 0x60
	CMD_READ_REG = 0x10
	 
	def __init__(self, bus, addr):
		self.bus = bus;
		self.addr = addr;
		self.cmd_out(self.CMD_SW_RESET,  0);
		self.cmd_out(self.CMD_LDAC_CTRL, 0xff); # ignore LDAC pins
		self.cmd_out(self.CMD_POWER_ON, 0x1f, 0xe0);

			

	def cmd_out(self, cmd, data, data2 = 0):
		self.bus.start(self.addr, True);
		self.bus.write(cmd, False)
		self.bus.write(data, False)
		self.bus.write(data2, True)

	def cmd_in(self, cmd):
		self.bus.start(self.addr, True)
		self.bus.write(cmd, False)
		self.bus.start(self.addr, False)
		reg_val=self.bus.read(False)
		self.bus.read(True)
		return(reg_val)

	def out(self, channel, data):
		self.cmd_out(self.CMD_WRITE_CH | channel, data)

	def rd_out(self, channel):
		return(self.cmd_in(self.CMD_READ_REG | channel))

class CFmcDio:

    BASE_ONEWIRE = 0x0
    BASE_I2C = 0x100
    BASE_GPIO = 0x200
    BASE_REGS = 0x300
    
    I2C_ADDR_DAC = 0x48
    I2C_ADDR_EEPROM = 0x50

    I2C_PRESCALER = 400

    PIN_PRSNT = 30

    GPIO_LED_TOP = 27
    GPIO_LED_BOTTOM = 28

    DAC_CHANNEL_CORRESP=[0,1,2,7,4,5]

    def __init__(self, bus, base):
        self.bus = bus;
        self.gpio = CGPIO(bus, base + self.BASE_GPIO)
        if(not self.fmc_present()):
            raise DeviceNotFound("FMC", 0x60000)
        self.i2c = COpenCoresI2C(bus, base + self.BASE_I2C, self.I2C_PRESCALER)
        self.onewire = COpenCoresOneWire(self.bus, base + self.BASE_ONEWIRE, 624/2, 124/2)
        self.eeprom = C24AA64(self.i2c, self.I2C_ADDR_EEPROM);
        self.dac = CDAC5578(self.i2c, self.I2C_ADDR_DAC);
        self.ds1820 = CDS18B20(self.onewire, 0);
        self.i2c.scan()		

    def fmc_present(self):
        return not self.gpio.inp(self.PIN_PRSNT);

    def set_dir(self, port, d):
        self.gpio.outp(port * 4 + 1, not d)

    def set_out(self, port, d):
        self.gpio.outp(port * 4, d)

    def set_term(self, port, d):
        self.gpio.outp(port * 4 + 2, d)

    def get_in(self, port):
        return self.gpio.inp(port * 4)

    def power(self, ins, clock):
        pass

    def set_led(self, led, state):
        gpio_leds=[self.GPIO_LED_TOP, self.GPIO_LED_BOTTOM]
        self.gpio.outp(gpio_leds[led],state)
        #print "LED", gpio_leds[led], "set to", state     

    def get_unique_id(self):
        return self.ds1820.read_serial_number()

    def set_in_threshold(self, port, threshold):        
        self.dac.out(self.DAC_CHANNEL_CORRESP[port], threshold)

    def get_in_threshold(self, port):        
        return(self.dac.rd_out(self.DAC_CHANNEL_CORRESP[port]))

    def get_temp(self):
        serial_number = self.ds1820.read_serial_number()
        if(serial_number == -1):
            return -1
        else:
            return self.ds1820.read_temp(serial_number)

    def set_reg(self, adr, value):        
        self.bus.iwrite(0, 0x62000 + self.BASE_REGS + adr, 4, value)

    def get_reg(self, adr):        
        return self.bus.iread(0, 0x62000 + self.BASE_REGS + adr, 4)

    def get_reg_long(self, adr):        
        return self.bus.iread(0, 0x62000 + self.BASE_REGS + adr, 8)

    def wait_irq_spec(self):
        return self.bus.irqwait()



#spec = rr.Gennum()

#dio= CFmcDio(spec, 0x80000);
            
#print("S/N: %x" % dio.get_unique_id())
#print("Board temp: %d degC" % dio.get_temp());
