Simple Z80 serial monitor

This is a learning project for getting a serial monitor working on a modified Multitech MPF-1 Single Board Computer
based on the Z80 microprocessor. Modification so far are limited to adding a Z80 DART serial interface chip. Also part 
of the project is building a working software development and deployment environment.

The starting point for the monitor is the monitor from: https://github.com/MatthewWCook/Z80Project/tree/master/Z80%20Monitor%20Part%201/Code. Only some addresses had to be changed and the 16550 UART file replaced by Z80 DART code.

A very useful part of the project, certainly for code fragments larger than a few bytes is an upload facility. For this
An Arduino based ROM-emulator is used, which allows transferring code to a RAM chip which is part from the Z80 address
space. See https://github.com/electrickery/ROM-emulator. This is a comfortable base to extend the monitor with it's own upload functionality.

The development system is Linux based and uses the Z80 assembler from https://github.com/udo-munk/z80pack.

A small Python3 script uploads the hex-intel code to the emulated ROM.

Usage:

	sh ./asm.sh Z80Monitor.asm
	python3 'romEmuFeed.py' 'Z80Monitor.hex' 2000

The second argument of the script compensates for the target address in the hex intel file with respect to the address
in the RAM. This is different for the Arduino/RAM and the location in the Z80 address space.

The license is MIT, as the existing monitor code uses this.

fjkraan@electrickery.nl, 20201226
