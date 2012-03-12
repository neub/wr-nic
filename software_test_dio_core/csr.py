#!/usr/bin/python

import sys
import rr
import time


class CCSR:

	def __init__(self, bus, base_addr):
		self.base_addr = base_addr;
		self.bus = bus;

	def wr_reg(self, addr, val):
		#print("                wr:%.8X reg:%.8X")%(val,(self.base_addr+addr))
		self.bus.iwrite(0, self.base_addr +  addr, 4, val)

	def rd_reg(self, addr):
		reg = self.bus.iread(0, self.base_addr + addr, 4)
		#print("                reg:%.8X value:%.8X")%((self.base_addr+addr), reg)
		return reg

	def wr_bit(self, addr, bit, value):
		reg = self.rd_reg(addr)
		if(0==value):
			reg &= ~(1<<bit)
		else:
			reg |= (1<<bit)
		self.wr_reg(addr, reg)


	def rd_bit(self, addr, bit):
		if(self.rd_reg(addr) & (1<<bit)):
			return 1
		else:
			return 0
