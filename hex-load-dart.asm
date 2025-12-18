;---------------------------------------------------------------------
; Intel hex load program that uses the Z80 Dart Driver used in my
;  ZMC-80 serial monitor for the MPF-I with the Serial_MEM_MPF_B
;  extension. The Hardware handshake is not supported. There is a line 
;  based software handshake, which the host loader program should 
;  respect. After sending a line of intel-hex, the loader waits for a 
;  <CR><LF> before sending the next line.
;
; This code is a reworking of the Intel hex loader routine in the Z80
; SBC monitor at http://www.vaxman.de/projects/tiny_z80/ by the author
; B. Ulmann
;
; The code has been tested using an SC139 Serial 68B50 Module (RC2014)
; (https://smallcomputercentral.com/sc139-serial-68b50-module-rc2014/)
; connected to the TEC-1G Z80 bus via a TEC-1G to RC2014 adapter as at
; https://github.com/turbo-gecko/TEC/tree/main/Hardware/Z80%20to%20RC%20Bus%20Adapter
;
; It has also been tested by burning an	expansion ROM for the MPF-1
; using the same hardware as described above.
;
; Requires acia.asm. To	use a different comms IC, replace the acia.asm
; library which	the device specific libray.
;
; v1.5 - 2015-12-16 modified for the ZMC-80 serial monitor
; v1.4 - 15th August 2024
;	 Change exit from rst 00h to ret to enable calling from other
;	 programs.
; v1.3 - 14th August 2024
;	 Refactored to use common serial driver.
; v1.2 - 12th April 2024
;	 Added re-enabling of RTS on exit to help flush	any spurious
;	 characters after the program has finished.
; v1.1 - 10th April 2024
;	 Added RTS signalling for HW flow control.
; v1.0 - 7th April 2024
;
; Author list:
; - B. Ulmann (http://www.vaxman.de/projects/tiny_z80/)  2011-2012
; - Gary Hammond (https://github.com/turbo-gecko/MPF/tree/main/Software/Hex%20Load)  2024
; - Fred Jan Kraan (https://github.com/electrickery/Z80SerialMonitor) 2025
;
; Last author: fjkraan@electrickery.nl, 2025-12-16
;---------------------------------------------------------------------

;        ORG     2000h   ;       temporary ORG for standalone mode testing
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
EOS             equ     00h
CR		equ	0dh
LF		equ	0ah
SPACE		equ	20h
ESC		equ	1bh

;L_ROM   EQU     0E000h

;---------------------------------------------------------------------
; Main Program
;---------------------------------------------------------------------

		;.org	00dd0h		; KS Wichit ROM
		; org	02000h		; MPF-1 Expansion ROM
		;.org	04000h		; TEC-1G User RAM
		;.org	0bd00h		; TEC-1G Expansion RAM/ROM/FRAM
		;.org	0dd00h		; KS Wichit RAM
	
HEXI_COMMAND:
;MAIN:
	call	CRLF			; Send a CR/LF to start a new line

	ld	hl,MSG_INT1		; Send intro messages...
	call	SER_TX_STRING

	ld	hl,MSG_INT2
	call	SER_TX_STRING

LOAD_LOOP:
	call	SER_RX_CHAR		; Get a single character
	cp	CR			; Don't care about CR
	jr	z,LOAD_LOOP
	cp	LF			; ...or LF
	jr	z,LOAD_LOOP
	cp	SPACE			; ...or a space
	jr	z,LOAD_LOOP
	cp	ESC			; Do care about <Esc>...
	jr	z,LOAD_QUIT		; ...as it's time to quit
	call	TO_UPPER		; Convert to upper case
	call	SER_TX_CHAR		; Echo character
	cp	':'			; Is it a colon?
	jr	nz,_LOAD_ERR  		; No - then there is an error
	call	GET_BYTE		; Yes - get record length into A
	ld	d,a			; Length is now in D
	ld	e,0			; Clear checksum
	call	LOAD_CHK		; Compute checksum
	call	GET_WORD		; Get load address into HL
	ld	a,h			; Update checksum by this address
	call	LOAD_CHK
	ld	a,l
	call	LOAD_CHK
	call	GET_BYTE		; Get the record type
	call	LOAD_CHK		; Update checksum
	cp	1			; Have we reached the EOF marker?
	jr	nz,LOAD_DATA		; No - get some data
	call	GET_BYTE		; Yes - EOF, read checksum data
	call	LOAD_CHK		; Update our own checksum
	ld	a,e
	and	a			; Is our checksum zero (as expected)?
	jr	z,LOAD_DONE		; Yes - we are all done here

_LCHK_E: 
	call	CRLF			; No - print an error message
	ld	hl,MSG_ERR2
	call	SER_TX_STRING
	jr	LOAD_EXIT		; And exit

LOAD_DATA:
	ld	a,d			; Record length is now in A
	and	a			; Did we process all bytes?
	jr	z,LOAD_EOL		; Yes - process end of line
	call	GET_BYTE		; Read two hex digits into A
	call	LOAD_CHK		; Update checksum
	ld	(hl),a			; Store byte into memory
	inc	hl			; Increment pointer
	dec	d			; Decrement remaining record length
	jr	LOAD_DATA		; Get next byte

LOAD_EOL:
	call	GET_BYTE		; Read the last byte in the line
	call	LOAD_CHK		; Update checksum
	ld	a,e
	and	a			; Is the checksum zero (as expected)?
	jr	nz,_LCHK_E
;	call	CRLF
        ld	hl, MSG_LNOK
        call	SER_TX_STRING
	jr	LOAD_LOOP		; Yes - read next line

_LOAD_ERR:
	ld	hl,MSG_ERR1
	call	SER_TX_STRING		; Print error message

LOAD_EXIT:
	call	CRLF
	
;	call	SER_RTS_LOW		; Other computer can now to send

	ret				; Return to program that called us

LOAD_QUIT:
	ld	hl,MSG_QUIT
	call	SER_TX_STRING		; Print quit message
	jr	LOAD_EXIT

LOAD_DONE:
	call	CRLF
	ld	hl,MSG_DONE
	call	SER_TX_STRING
	jr	LOAD_EXIT

LOAD_CHK:
	ld	c,a			; All in all compute E = E - A
	ld	a,e
	sub	c
	ld	e,a
	ld	a,c

	ret

;---------------------------------------------------------------------
; Send a CR/LF pair:
;---------------------------------------------------------------------
CRLF	ld	a,CR
	call	SER_TX_CHAR
	ld	a,LF
	call	SER_TX_CHAR

	ret

;---------------------------------------------------------------------
; is_hex checks a character stored in A for being a valid hexadecimal digit.
; A valid hexadecimal digit is denoted by a set C flag.
;---------------------------------------------------------------------
IS_HEX:
	cp	'F'+1			; Greater than 'F'?
	ret	nc			; Yes
	cp	'0'			; Less than '0'?
	jr	nc,IS_HEX_1		; No, continue
	ccf				; Complement carry (i.e. clear it)

	ret

IS_HEX_1:
	cp	'9'+1			; Less or equal '9*?
	ret	c			; Yes
	cp	'A'			; Less than 'A'?
	jr	nc,IS_HEX_2		; No, continue
	ccf				; Yes - clear carry and return

	ret

IS_HEX_2:
	scf				; Set carry
	
	ret

;---------------------------------------------------------------------
; nibble2val expects a hexadecimal digit (upper case!) in A and returns the
; corresponding value in A.
;---------------------------------------------------------------------
NIBBLE2VAL:
	cp	'9'	+ 1		; Is it a digit (less or equal '9')?
	jr	c, _NIBBLE2VAL		; Yes
	sub	7			; Adjust for A-F

_NIBBLE2VAL:
	sub	'0'			; Fold back to 0..15
	and	0fh			; Only return lower 4 bits

	ret

; ----------------------------------------------------------------------------
; INCLUDE libraries
; ----------------------------------------------------------------------------

;                include DARTDriver.asm

; Mapping of local names to DARTDriver labels                
SER_RX_CHAR     EQU     UART_RX
SER_TX_CHAR     EQU     UART_TX
SER_TX_STRING   EQU     PRINT_STRING
PRINT_NIBBLE    EQU     PRINTHNIB
GET_WORD        EQU     GETHEXWORD
GET_NIBBLE      EQU     GETHEXNIB
GET_BYTE        EQU     GETHEXBYTE

;     EQU     

;---------------------------------------------------------------------
; Messages
;---------------------------------------------------------------------

MSG_LNOK        db      " Ok.", CR, LF, 0
MSG_DONE	db	"Transfer complete.", CR, LF, 0
MSG_ERR1	db	" <-Syntax error!", CR, LF, 0
MSG_ERR2	db	"Checksum error!", 0
MSG_INT1	db	"Intel hex file loader v1.4", CR, LF, 0
MSG_INT2	db	"Send file when ready. Press <Esc> to quit.", CR, LF, 0
MSG_QUIT	db	"Quitting program.", CR, LF, 0

; END hex-load-dart
;		end
