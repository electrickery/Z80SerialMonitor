#!/bin/sh
#
FILE=$1
NOEXT=${FILE%%.*}; echo "$NOEXT"
~/kryten/Programming/c/z80pack/z80asm/z80asm -v -fh -o$NOEXT -l $FILE
