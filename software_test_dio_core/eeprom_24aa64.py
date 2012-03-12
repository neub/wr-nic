#!/usr/bin/python

import sys
import rr
import time
import i2c


class C24AA64:
	def __init__(self, i2c, i2c_addr):
		self.i2c = i2c
		self.i2c_addr = i2c_addr

	def wr_data(self, mem_addr, data):
		self.i2c.start(self.i2c_addr, True)
                self.i2c.write((mem_addr >> 8), False)
                self.i2c.write((mem_addr & 0xFF), False)
                #print('24AA64:write: data lenght=%d')%(len(data))
		for i in range(len(data)-1):
                        #print('24AA64:write: i=%d')%(i)
                        self.i2c.write(data[i],False)
                i += 1
                #print('24AA64:write:last i=%d')%(i)
                self.i2c.write(data[i],True)
		return 0;

	def rd_data(self, mem_addr, size):
		self.i2c.start(self.i2c_addr, True)
		self.i2c.write((mem_addr >> 8), False)
                self.i2c.write((mem_addr & 0xFF), False)
		self.i2c.start(self.i2c_addr, False)
                data = []
                #print('24AA64:read: data lenght=%d')%(size)
                i=0
		for i in range(size-1):
                        data.append(self.i2c.read(False))
                        #print('24AA64:read: i=%d')%(i)
                i += 1
                #print('24AA64:read:last i=%d')%(i)
                data.append(self.i2c.read(True))
		return data;
