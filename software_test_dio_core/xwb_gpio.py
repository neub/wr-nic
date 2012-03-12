#!/usr/bin/python

#simple driver for (x)wb_gpio_port from general-cores library

class CGPIO:
    def __init__(self, bus, base):
        self.bus =bus
        self.base = base

#returns the value on pin pin
    def inp(self, pin):
        bank=  0x20 * (pin / 32);
        r = self.bus.rd_reg(0, self.base + bank + 0xc);
        return (r >> pin) & 1;

#sets the pin "pin" to value "val"
    def outp(self, pin, val):
        bank=  0x20 * (pin >> 5);
        if(val):
            self.bus.wr_reg(0, self.base + bank + 0x4, (1<<(pin&0x1f)))
        else:
            self.bus.wr_reg(0, self.base + bank + 0x0, (1<<(pin&0x1f)))

