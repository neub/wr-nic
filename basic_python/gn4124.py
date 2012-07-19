#!/usr/bin/python

import sys
import rr
import time
import csr

class CGN4124:

    # Host registers (BAR12), for DMA items storage
    HOST_BAR = 0xC
    HOST_DMA_CARRIER_START_ADDR = 0x00
    HOST_DMA_HOST_START_ADDR_L = 0x04
    HOST_DMA_HOST_START_ADDR_H = 0x08
    HOST_DMA_LENGTH = 0x0C
    HOST_DMA_NEXT_ITEM_ADDR_L = 0x10
    HOST_DMA_NEXT_ITEM_ADDR_H = 0x14
    HOST_DMA_ATTRIB = 0x18

    # GN4124 chip registers (BAR4)
    GN4124_BAR = 0x4
    R_CLK_CSR = 0x808
    R_INT_CFG0 = 0x820
    R_GPIO_DIR_MODE = 0xA04
    R_GPIO_INT_MASK_CLR = 0xA18
    R_GPIO_INT_MASK_SET = 0xA1C
    R_GPIO_INT_STATUS = 0xA20
    R_GPIO_INT_VALUE = 0xA28

    CLK_CSR_DIVOT_MASK = 0x3F0
    INT_CFG0_GPIO = 15
    GPIO_INT_SRC = 8

    # GN4124 core registers (BAR0)
    R_DMA_CTL = 0x00
    R_DMA_STA = 0x04
    R_DMA_CARRIER_START_ADDR = 0x08
    R_DMA_HOST_START_ADDR_L = 0x0C
    R_DMA_HOST_START_ADDR_H = 0x10
    R_DMA_LENGTH = 0x14
    R_DMA_NEXT_ITEM_ADDR_L = 0x18
    R_DMA_NEXT_ITEM_ADDR_H = 0x1C
    R_DMA_ATTRIB = 0x20

    DMA_CTL_START = 0
    DMA_CTL_ABORT = 1
    DMA_CTL_SWAP = 2
    DMA_STA = ['Idle','Done','Busy','Error','Aborted']
    DMA_ATTRIB_LAST = 0
    DMA_ATTRIB_DIR = 1

    def rd_reg(self, bar, addr):
        return self.bus.iread(bar, addr, 4)

    def wr_reg(self, bar, addr, value):
        self.bus.iwrite(bar, addr, 4, value)

    def __init__(self, bus, csr_addr):
        self.bus = bus
        self.dma_csr = csr.CCSR(bus, csr_addr)
        self.dma_item_cnt = 0
        # Get page list
        self.pages = self.bus.getplist()
        # Shift by 12 to get the 32-bit physical addresses
        self.pages = [addr << 12 for addr in self.pages]
        self.set_interrupt_config()
        # Enable interrupt from gn4124
        self.bus.irqena()

    # Set local bus frequency
    def set_local_bus_freq(self, freq):
        # freq in MHz
        # LCLK = (25MHz*(DIVFB+1))/(DIVOT+1)
        # DIVFB = 31
        # DIVOT = (800/LCLK)-1
        divot = int(round((800/freq)-1,0))
        #print '%d' % divot
        data = 0xe001f00c + (divot << 4)
        #print '%.8X' % data
        #print 'Set local bus freq to %dMHz' % int(round(800/(divot+1),0))
        self.wr_reg(self.GN4124_BAR, self.R_CLK_CSR, data)

    # Get local bus frequency
    #   return: frequency in MHz
    def get_local_bus_freq(self):
        reg = self.rd_reg(self.GN4124_BAR, self.R_CLK_CSR)
        divot = ((reg & self.CLK_CSR_DIVOT_MASK)>>4)
        return (800/(divot + 1))

    # Get physical addresses of the pages allocated to GN4124
    def get_physical_addr(self):
        return self.pages

    # Wait for interrupt
    def wait_irq(self):
        # Add here reading of the interrupt source (once the irq core will be present)
        return self.bus.irqwait()

    # GN4124 interrupt configuration
    def set_interrupt_config(self):
        # Set interrupt line from FPGA (GPIO8) as input
        self.wr_reg(self.GN4124_BAR, self.R_GPIO_DIR_MODE, (1<<self.GPIO_INT_SRC))
        # Set interrupt mask for all GPIO except for GPIO8
        self.wr_reg(self.GN4124_BAR, self.R_GPIO_INT_MASK_SET, ~(1<<self.GPIO_INT_SRC))
        # Make sure the interrupt mask is cleared for GPIO8
        self.wr_reg(self.GN4124_BAR, self.R_GPIO_INT_MASK_CLR, (1<<self.GPIO_INT_SRC))
        # Interrupt on rising edge of GPIO8
        self.wr_reg(self.GN4124_BAR, self.R_GPIO_INT_VALUE, (1<<self.GPIO_INT_SRC))
        # GPIO as interrupt 0 source
        self.wr_reg(self.GN4124_BAR, self.R_INT_CFG0, (1<<self.INT_CFG0_GPIO))

    # Get DMA controller status
    def get_dma_status(self):
        reg = self.dma_csr.rd_reg(self.R_DMA_STA)
        if(reg > len(self.DMA_STA)):
            print("DMA status register : %.8X") % reg
            raise Exception('Invalid DMA status')
        else:
            return self.DMA_STA[reg]

    # Configure DMA byte swapping
    #   0 = A1 B2 C3 D4 (straight)
    #   1 = B2 A1 D4 C3 (swap bytes in words)
    #   2 = C3 D4 A1 B2 (swap words)
    #   3 = D4 C3 B2 A1 (invert bytes)
    def set_dma_swap(self, swap):
        if(swap > 3):
            raise Exception('Invalid swapping configuration : %d') % swap
        else:
            self.dma_csr.wr_reg(self.R_CTL, (swap << self.DMA_CTL_SWAP))

    # Add DMA item (first item is on the board, the following in the host memory)
    #   carrier_addr, host_addr, length and next_item_addr are in bytes
    #   dma_dir  = 1 -> PCIe to carrier
    #   dma_dir  = 0 -> carrier to PCIe
    #   dma_last = 0 -> last item in the transfer
    #   dma_last = 1 -> more item in the transfer
    #   Only supports 32-bit host address
    def add_dma_item(self, carrier_addr, host_addr, length, dma_dir, last_item):
        if(0 == self.dma_item_cnt):
            # write the first DMA item in the carrier
            self.dma_csr.wr_reg(self.R_DMA_CARRIER_START_ADDR, carrier_addr)
            self.dma_csr.wr_reg(self.R_DMA_HOST_START_ADDR_L, (host_addr & 0xFFFFFFFF))
            self.dma_csr.wr_reg(self.R_DMA_HOST_START_ADDR_H, (host_addr >> 32))
            self.dma_csr.wr_reg(self.R_DMA_LENGTH, length)
            self.dma_csr.wr_reg(self.R_DMA_NEXT_ITEM_ADDR_L, (self.pages[0] & 0xFFFFFFFF))
            self.dma_csr.wr_reg(self.R_DMA_NEXT_ITEM_ADDR_H, 0x0)
            attrib = (dma_dir << self.DMA_ATTRIB_DIR) + (last_item << self.DMA_ATTRIB_LAST)
            self.dma_csr.wr_reg(self.R_DMA_ATTRIB, attrib)
        else:
            # write nexy DMA item(s) in host memory
            # uses page 0 to store DMA items
            # current and next item addresses are automatically set
            current_item_addr = (self.dma_item_cnt-1)*0x20
            next_item_addr = (self.dma_item_cnt)*0x20
            self.wr_reg(self.HOST_BAR, self.HOST_DMA_CARRIER_START_ADDR + current_item_addr, carrier_addr)
            self.wr_reg(self.HOST_BAR, self.HOST_DMA_HOST_START_ADDR_L + current_item_addr, host_addr)
            self.wr_reg(self.HOST_BAR, self.HOST_DMA_HOST_START_ADDR_H + current_item_addr, 0x0)
            self.wr_reg(self.HOST_BAR, self.HOST_DMA_LENGTH + current_item_addr, length)
            self.wr_reg(self.HOST_BAR, self.HOST_DMA_NEXT_ITEM_ADDR_L + current_item_addr,
                                self.pages[0] + next_item_addr)
            self.wr_reg(self.HOST_BAR, self.HOST_DMA_NEXT_ITEM_ADDR_H + current_item_addr, 0x0)
            attrib = (dma_dir << self.DMA_ATTRIB_DIR) + (last_item << self.DMA_ATTRIB_LAST)
            self.wr_reg(self.HOST_BAR, self.HOST_DMA_ATTRIB + current_item_addr, attrib)
        self.dma_item_cnt += 1

    # Start DMA transfer
    def start_dma(self):
        self.dma_item_cnt = 0
        self.dma_csr.wr_bit(self.R_DMA_CTL, self.DMA_CTL_START, 1)
        # The following two lines should be removed
        # when the GN4124 vhdl core will implement auto clear of start bit
        #while(('Idle' == self.get_dma_status()) or
        #      ('Busy' == self.get_dma_status())):
        #    pass
        self.dma_csr.wr_bit(self.R_DMA_CTL, self.DMA_CTL_START, 0)

    # Abort DMA transfer
    def abort_dma(self):
        self.dma_item_cnt = 0
        self.dma_csr.wr_bit(self.R_DMA_CTL, self.DMA_CTL_ABORT, 1)
        # The following two lines should be removed
        # when the GN4124 vhdl core will implement auto clear of start bit
        while('Aborted' != self.get_dma_status()):
            pass
        self.dma_csr.wr_bit(self.R_DMA_CTL, self.DMA_CTL_ABORT, 0)

    # Get memory page
    def get_memory_page(self, page_nb):
        data = []
        for i in range(2**10):
            data.append(self.rd_reg(self.HOST_BAR, (page_nb<<12)+(i<<2)))
        return data

    # Set memory page
    def set_memory_page(self, page_nb, pattern):
        for i in range(2**10):
            self.wr_reg(self.HOST_BAR, (page_nb<<12)+(i<<2), pattern)
