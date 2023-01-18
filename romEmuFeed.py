#!/usr/bin/python3
#

import sys
import serial
import time
import argparse

port = '/dev/ttyACM0'
baud = 9600
parser = argparse.ArgumentParser(description='Send hex-intel file to ROM Emulator.')
parser.add_argument('-p', '--port', type=str, nargs='?',
                    help='Serial port to use (9600 BAUD)')
parser.add_argument('-x', '--hexFile', type=str, nargs='?',
                    help='hex-Intel file')
parser.add_argument('-o', '--offset', type=str, nargs='?',
                    help='offset to target address')               

args = parser.parse_args()

if (args.port):
    port = args.port
    
if (args.offset):
    offset = "F" + args.offset
else:
    offset = 0

if (args.hexFile):
    hexFile = args.hexFile
else:
    print("Usage: python3 romEmuFeed.py  -x HEXFILE [-p PORT] [-o OFFSET]")
    print("       default port is " + port + ", default offset is " + hex(offset))
    quit(1)









ser = serial.Serial(port, baud, timeout=2)  # open serial port
LF = "\r\n"
hexOffsetStr = ""
sendDelay = 0.05
time.sleep(sendDelay)
print(ser.readline())

#if len(sys.argv) <= 1:
#    print("Usage: python3 romEmuFeed.py hexFile [hexOffset]")
#    print("       port is " + port + " speed is " + str(baud))
#    quit()
#else:
#    hexFile = sys.argv[1]
#if len(sys.argv) > 2:
#    hexOffsetStr = "F" + sys.argv[2]

file = open(hexFile, 'r')
lines = file.readlines()
file.close()

print(ser.readline().strip())
time.sleep(sendDelay)

if hexOffsetStr:
    ser.write(str.encode(hexOffsetStr + LF))
    print(ser.readline().strip())
    time.sleep(sendDelay)

for line in lines:
    lineStrip = line.strip()
    if (lineStrip):
        print(lineStrip)
        ser.write(str.encode(lineStrip + LF))
        time.sleep(sendDelay)
        print(ser.readline().strip())
        time.sleep(sendDelay)
