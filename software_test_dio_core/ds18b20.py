#!/usr/bin/python

import sys
import rr
import time
import onewire


class CDS18B20:

    # ROM commands
    ROM_SEARCH = 0xF0
    ROM_READ = 0x33
    ROM_MATCH = 0x55
    ROM_SKIP = 0xCC
    ROM_ALARM_SEARCH = 0xEC

    # DS18B20 fonctions commands
    CONVERT_TEMP = 0x44
    WRITE_SCRATCHPAD = 0x4E
    READ_SCRATCHPAD = 0xBE
    COPY_SCRATCHPAD = 0x48
    RECALL_EEPROM = 0xB8
    READ_POWER_SUPPLY = 0xB4

    # Thermometer resolution configuration
    RES = {'9-bit':0x0, '10-bit':0x1, '11-bit':0x2, '12-bit':0x3}

    def __init__(self, onewire, port):
        self.onewire = onewire
        self.port = port

    def read_serial_number(self):
        #print('[DS18B20] Reading serial number')
        if(1 != self.onewire.reset(self.port)):
            print('[DS18B20] No presence pulse detected')
            return None
        else:
            #print('[DS18B20] Write ROM command %.2X') % self.ROM_READ
            err = self.onewire.write_byte(self.port, self.ROM_READ)
            if(err != 0):
                print('[DS18B20] Write error')
                return None
            family_code = self.onewire.read_byte(self.port)
            serial_number = 0
            for i in range(6):
                serial_number |= self.onewire.read_byte(self.port) << (i*8)
            crc = self.onewire.read_byte(self.port)
            #print('[DS18B20] Family code  : %.2X') % family_code
            #print('[DS18B20] Serial number: %.12X') % serial_number
            #print('[DS18B20] CRC          : %.2X') % crc
        return ((crc<<56) | (serial_number<<8) | family_code)

    def access(self, serial_number):
        #print('[DS18B20] Accessing device')
        if(1 != self.onewire.reset(self.port)):
            print('[DS18B20] No presence pulse detected')
            return -1
        else:
            #print('[DS18B20] Write ROM command %.2X') % self.ROM_MATCH
            err = self.onewire.write_byte(self.port, self.ROM_MATCH)
            #print serial_number
            block = []
            for i in range(8):
                block.append(serial_number & 0xFF)
                serial_number >>= 8
            #print block
            self.onewire.write_block(self.port, block)
            return 0

    def read_temp(self, serial_number):
        #print('[DS18B20] Reading temperature')
        err = self.access(serial_number)
        #print('[DS18B20] Write function command %.2X') % self.CONVERT_TEMP
        err = self.onewire.write_byte(self.port, self.CONVERT_TEMP)
        time.sleep(1)
        err = self.access(serial_number)
        #print('[DS18B20] Write function command %.2X') % self.READ_SCRATCHPAD
        err = self.onewire.write_byte(self.port, self.READ_SCRATCHPAD)
        data = self.onewire.read_block(self.port, 9)
        #for i in range(9):
        #    print('Scratchpad data[%1d]: %.2X') % (i, data[i])
        temp = (data[1] << 8) | (data[0])
        if(temp & 0x1000):
            temp = -0x10000 + temp
        temp = temp/16.0
        return temp

    # Set temperature thresholds

    # Configure thermometer resolution
