#!/usr/bin/python

import sys
import rr
import time


class COpenCoresOneWire:

    # OpenCores 1-wire registers description
    R_CSR = 0x0
    R_CDR = 0x4

    CSR_DAT_MSK = (1<<0)
    CSR_RST_MSK = (1<<1)
    CSR_OVD_MSK = (1<<2)
    CSR_CYC_MSK = (1<<3)
    CSR_PWR_MSK = (1<<4)
    CSR_IRQ_MSK = (1<<6)
    CSR_IEN_MSK = (1<<7)
    CSR_SEL_OFS = 8
    CSR_SEL_MSK = (0xF<<8)
    CSR_POWER_OFS = 16
    CSR_POWER_MSK = (0xFFFF<<16)

    CDR_NOR_MSK = (0xFFFF<<0)
    CDR_OVD_OFS = 16
    CDR_OVD_MSK = (0XFFFF<<16)

    def wr_reg(self, addr, val):
        self.bus.iwrite(0, self.base_addr +  addr, 4, val)

    def rd_reg(self,addr):
        return self.bus.iread(0, self.base_addr + addr, 4)

    # Function called during object creation
    #   bus = host bus (PCIe, VME, etc...)
    #   base_addr = 1-wire core base address
    #   clk_div_nor = clock divider normal operation, clk_div_nor = Fclk * 5E-6 - 1
    #   clk_div_ovd = clock divider overdrive operation, clk_div_ovd = Fclk * 1E-6 - 1
    def __init__(self, bus, base_addr, clk_div_nor, clk_div_ovd):
        self.bus = bus
        self.base_addr = base_addr
        #print('\n### Onewire class init ###')
        #print("Clock divider (normal operation): %.4X") % clk_div_nor
        #print("Clock divider (overdrive operation): %.4X") % clk_div_ovd
        data = ((clk_div_nor & self.CDR_NOR_MSK) | ((clk_div_ovd<<self.CDR_OVD_OFS) & self.CDR_OVD_MSK))
        #print('CRD register wr: %.8X') % data
        self.wr_reg(self.R_CDR, data)
        #print('CRD register rd: %.8X') % self.rd_reg(self.R_CDR)

    # return: 1 -> presence pulse detected
    #         0 -> no presence pulse detected
    def reset(self, port):
        data = ((port<<self.CSR_SEL_OFS) & self.CSR_SEL_MSK) | self.CSR_CYC_MSK | self.CSR_RST_MSK
        #print('[onewire] Sending reset command, CSR: %.8X') % data
        self.wr_reg(self.R_CSR, data)
        while(self.rd_reg(self.R_CSR) & self.CSR_CYC_MSK):
            pass
        reg = self.rd_reg(self.R_CSR)
        #print('[onewire] Reading CSR: %.8X') % reg
        return ~reg & self.CSR_DAT_MSK

    def slot(self, port, bit):
        data = ((port<<self.CSR_SEL_OFS) & self.CSR_SEL_MSK) | self.CSR_CYC_MSK | (bit & self.CSR_DAT_MSK)
        self.wr_reg(self.R_CSR, data)
        while(self.rd_reg(self.R_CSR) & self.CSR_CYC_MSK):
            pass
        reg = self.rd_reg(self.R_CSR)
        return reg & self.CSR_DAT_MSK

    def read_bit(self, port):
        return self.slot(port, 0x1)

    def write_bit(self, port, bit):
        return self.slot(port, bit)

    def read_byte(self, port):
        data = 0
        for i in range(8):
            data |= self.read_bit(port) << i
        return data

    def write_byte(self, port, byte):
        data = 0
        byte_old = byte
        for i in range(8):
            data |= self.write_bit(port, (byte & 0x1)) << i
            byte >>= 1
        if(byte_old == data):
            return 0
        else:
            return -1
    
    def write_block(self, port, block):
        if(160 < len(block)):
            return -1
        data = []
        for i in range(len(block)):
            data.append(self.write_byte(port, block[i]))
        return data

    def read_block(self, port, length):
        if(160 < length):
            return -1
        data = []
        for i in range(length):
            data.append(self.read_byte(port))
        return data
        
