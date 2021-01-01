;***************************************************************************
;  PROGRAM:			Z80 Monitor        
;  PURPOSE:			ROM Monitor Program
;  ASSEMBLER:		original: TASM 3.2 , converted to z80pack/z80asm
;  LICENCE:			The MIT Licence
;  AUTHOR :			MCook
;  CREATE DATE :	05 May 15
;***************************************************************************

ROM_BOTTOM:  EQU    0000h		;Bottom address of ROM
ROM_TOP:     EQU    07FFh		;Top address of ROM

RAM_BOTTOM:  EQU    1800h		;Bottom address of RAM
RAM_TOP:     EQU    19FFh		;Top address of RAM	

MPFMON:      EQU    0030h
ASCDMPBUF:   EQU    1810h		;Buffer to construct ASCII part of memory dump
ASCDMPEND:   EQU    1820h		;End of buffer, fill with EOS
DMPADDR:     EQU    1821h		;Last dump address
MVADDR:      EQU    1823h 		; 6 bytes: start-address, end-address, dest-address or fill-value (23, 24, 25, 26, 27, 28)
ERRFLAG:     EQU    1829h		; Location to store 
MUTE:        EQU    182Ah		; 0 - print received chars, 1 - do not print received chars
ULSIZE:      EQU    182Bh		; actual size of current/last hex-intel message
IECHECKSUM:  EQU    182Ch
DEBUG:       EQU    182Fh
UPLOADBUF:   EQU    1830h		; Buffer for hex-intel upload. Allows up to 32 bytes (20h) per line.
ULBEND:      EQU    1850h
ULBUFSIZE:   EQU    ULBEND-UPLOADBUF+1

E_NONE:      EQU    00h
E_NOHEX:     EQU    01h			; input char not 0-9, A-F
E_PARAM:     EQU    02h			; inconsistent range; start > end
E_BUFSIZE:   EQU    03h			; size larger than buffer
E_HITYP:     EQU    04h			; unsupported hex-intel record type
E_HIEND:     EQU    05h			; hex-intel end record type found

HI_DATA:     EQU    00h
HI_END:      EQU    01h

ESC:         EQU    01Bh		; 
EOS:         EQU    0FFh		; End of string

;			ORG 0000h

START:
;			DI							;Disable interrupts
;			JP 		MAIN  				;Jump to the MAIN routine
;			
;			ORG 0038h

;INT_CATCH:
;			JP 		INT_CATCH			;INF loop to catch interrupts (not enabled)
;			
;			ORG 0066h

;NMI_CATCH:
;			JP		NMI_CATCH			;INF loop to catch interrupts (not enabled)
;			
			ORG 2000h
;***************************************************************************
;MAIN
;Function: Entrance to user program
;***************************************************************************
MAIN:
			LD		SP,RAM_TOP			;Load the stack pointer for stack operations.
			CALL	UART_INIT			;Initialize UART
			CALL	PRINT_MON_HDR		;Print the monitor header info
			LD		A, 00h
			LD		(DMPADDR), A
			LD		A, 0FFh				; FF00h and next should result in 0000h
			LD		(DMPADDR+1), A
			CALL	CLEAR_ERROR
			CALL    MON_PROMPT_LOOP		;Monitor user prompt loop
			HALT

;***************************************************************************
;CLEAR_SCREEN
;Function: Clears terminal screen
;***************************************************************************
MON_CLS: DEFB 0Ch, EOS  				;Escape sequence for CLS. (aka form feed) 
		
CLEAR_SCREEN:
			LD 		HL,MON_CLS
			CALL    PRINT_STRING
			RET
			
;***************************************************************************
;RESET_COMMAND
;Function: Software Reset to $0000
;***************************************************************************
RESET_COMMAND:
			JP		MPFMON				;Jumps to $0030 (MPF-1 monitor re-entry)	
			
;***************************************************************************
;PRINT_MON_HDR
;Function: Print out program header info
;***************************************************************************
MON_MSG:	DEFB	0DH, 0Ah, 'ZMC80 Computer', 09h, 09h, 09h, '2015 MCook', EOS
MONMSG2:	DEFB	0DH, 0Ah, ' adaptation to MPF-1 / Z80 DART', 09h, '2020 F.J.Kraan', 0Dh, 0Ah, EOS
MON_VER:	DEFB	'ROM Monitor v0.2', 0Dh, 0AH, 0Dh, 0AH, EOS
MON_HLP:	DEFB	09h,' Input ? for command list', 0Dh, 0AH, EOS
MON_ERR:	DEFB	0Dh, 0AH, 'Error in params: ', EOS

PRINT_MON_HDR:
			CALL	CLEAR_SCREEN		;Clear the terminal screen
			LD 		HL,MON_MSG			;Print some messages
			CALL    PRINT_STRING	
			LD 		HL,MONMSG2			;Print some extra message
			CALL    PRINT_STRING	
			LD 		HL,MON_VER
			CALL    PRINT_STRING
			LD 		HL,MON_HLP
			CALL    PRINT_STRING
			RET
			
;***************************************************************************
;MON_PROMPT
;Function: Prompt user for input
;***************************************************************************			
MON_PROMPT: DEFB '>',EOS

MON_PRMPT_LOOP:
			LD		A, 00h
			LD		(MUTE), A			; Enables echo of received chars
			LD 		HL,MON_PROMPT		;Print monitor prompt
			CALL    PRINT_STRING		
			CALL	GET_CHAR			;Get a character from user into Acc
			CALL 	PRINT_CHAR
			CALL    PRINT_NEW_LINE		;Print a new line
			CALL	MON_COMMAND			;Respond to user input
			CALL 	PRINT_NEW_LINE		;Print a new line	
			JP		MON_PRMPT_LOOP

;***************************************************************************
;MON_COMMAND
;Function: User input in accumulator to respond to 
;***************************************************************************
MON_COMMAND:	; Inserted ERROR_CHK for all commands requiring input
			CALL	CLEAR_ERROR
			CP		'?'					
			CALL  	Z,HELP_COMMAND
			CP		'D'
			CALL  	Z,MDCMD
			CP		'C'
			CALL  	Z,CLEAR_SCREEN
			CP		'R'
			CALL	Z,RESET_COMMAND
			CP		'M'
			CALL	Z,MOVE_COMMAND
			CP		'F'
			CALL	Z,FILL_COMMAND
			CP		'+'
			CALL	Z,NEXTP_COMMAND
			CP		'-'
			CALL	Z,PREVP_COMMAND
			CP		'E'
			CALL	Z,EDIT_COMMAND
			CP		'I'
			CALL	Z,UPLOAD_COMMAND
			CALL	ERROR_CHK
			RET
			
ERROR_CHK:
			LD		A, (ERRFLAG)
			CP		E_NONE
			RET		Z
			LD		HL, MON_ERR
			CALL    PRINT_STRING
			LD		A, (ERRFLAG)
			CALL	PRINTHBYTE
			CALL	PRINT_NEW_LINE
CLEAR_ERROR:
			PUSH	AF
			LD		A, E_NONE
			LD		(ERRFLAG), A
			POP		AF
			RET
			
			INCLUDE	DARTDriver.asm
			INCLUDE	MONCommands.asm
			INCLUDE	CONIO.asm

			END
