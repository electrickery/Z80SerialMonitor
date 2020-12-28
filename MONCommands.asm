;***************************************************************************
;  PROGRAM:			MONCommands        
;  PURPOSE:			Subroutines for all monitor commands
;  ASSEMBLER:		original: TASM 3.2 , converted to z80pack/z80asm
;  LICENCE:			The MIT Licence
;  AUTHOR :			MCook
;  CREATE DATE :	06 May 15
;***************************************************************************

HEXLINES:	EQU	17 ; FIXIT: There is a off-by-one-here

;***************************************************************************
;HELP_COMMAND
;Function: Print help dialogue box
;***************************************************************************
HELPMSG1: DEFB 'ZMC80 Monitor Command List', 0Dh, 0Ah, EOS
HELPMSG2: DEFB '? - view command list', 0Dh, 0Ah, EOS
HELPMSG3: DEFB 'R - monitor reset', 0Dh, 0Ah, EOS
HELPMSG4: DEFB 'C - clear screen', 0Dh, 0Ah, EOS
HELPMSG5: DEFB 'D - print $FF bytes from specified location', 0Dh, 0Ah, EOS
HELPMSG6: DEFB 'M - copy bytes in memory', 0Dh, 0Ah, EOS
HELPMSG7: DEFB 'F - fill memory range with value', 0Dh, 0Ah, EOS
HELPMSG8: DEFB '+ - print next block of memory', 0Dh, 0Ah, EOS
HELPMSG9: DEFB '- - print previous block of memory', 0Dh, 0Ah, EOS


HELP_COMMAND:
			LD 		HL,HELPMSG1		;Print some messages
			CALL    PRINT_STRING		
			LD 		HL,HELPMSG2		
			CALL    PRINT_STRING			
			LD 		HL,HELPMSG3		
			CALL    PRINT_STRING
			LD 		HL,HELPMSG4		
			CALL    PRINT_STRING
			LD 		HL,HELPMSG5		
			CALL    PRINT_STRING
			LD 		HL,HELPMSG6		
			CALL    PRINT_STRING
			LD 		HL,HELPMSG7		
			CALL    PRINT_STRING
			LD 		HL,HELPMSG8		
			CALL    PRINT_STRING
			LD 		HL,HELPMSG9		
			CALL    PRINT_STRING
			LD		A, EOS				;Load $FF into Acc so MON_COMMAND finishes
			RET

;***************************************************************************
;MEMORY_DUMP_COMMAND
;Function: Print $80 databytes from specified location
;***************************************************************************
MDC_1: DEFB 'Memory Dump Command', 0Dh, 0Ah, EOS
MDC_2: DEFB 'Location to start in 4 digit HEX: ',EOS
MDC_3: DEFB '      0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F', 0Dh, 0Ah, EOS

MDCMD:
			LD 		HL,MDC_1			;Print some messages 
			CALL    PRINT_STRING
			LD 		HL,MDC_2	
			CALL    PRINT_STRING
			
			CALL    GETHEXWORD			;HL now points to databyte location	
			LD		(DMPADDR), HL		;Keep address for next/prev.
			PUSH	HL					;Save HL that holds databyte location on stack
			CALL    PRINT_NEW_LINE		;Print some messages
			CALL    PRINT_NEW_LINE
			LD 		HL,MDC_3	
			CALL    PRINT_STRING
;			CALL    PRINT_NEW_LINE
			POP		HL					;Restore HL that holds databyte location on stack
MDNXTPR:	LD		C,HEXLINES			;Register C holds counter of dump lines to print
MDLINE:	
			LD		DE,	ASCDMPBUF
			LD		B,16				;Register B holds counter of dump bytes to print
			CALL	PRINTHWORD			;Print dump line address in hex form
			LD		A,' '				;Print spacer
			CALL	PRINT_CHAR
			DEC		C					;Decrement C to keep track of number of lines printed
MDBYTES:
			LD		A,(HL)				;Load Acc with databyte HL points to
			CALL	PRINTHBYTE  		;Print databyte in HEX form 
			CALL	CHAR2BUF			;Store ASCII char
			LD		A,' '				;Print spacer
			CALL	PRINT_CHAR	
			INC 	HL					;Increase HL to next address pointer
			DJNZ	MDBYTES				;Print 16 bytes out since B holds 16
			
			LD		A,' '				;Print spacer
			CALL	PRINT_CHAR			;
			LD		A, EOS
			LD		(ASCDMPEND), A		;Make sure there is a EOS

			PUSH	HL
			LD		HL, ASCDMPBUF		;Point HL to ASCII buffer
			CALL    PRINT_STRING		;Print buffer
			POP		HL
			
			LD		B,C					;Load B with C to keep track of number of lines printed
			CALL    PRINT_NEW_LINE		;Get ready for next dump line
			DJNZ	MDLINE				;Print 16 line out since C holds 16 and we load B with C
			LD		A,EOS				;Load $FF into Acc so MON_COMMAND finishes

			RET

CHAR2BUF:
			CALL	MKPRINT
			LD		(DE), A
			INC		DE
			RET

;***************************************************************************
;MEMORY_MOVE_COMMAND
;Function: Copy data blocks in memory
;***************************************************************************
MVC_1:	DEFB	'Move Data Command', 0Dh, 0Ah, EOS
MVC_S:	DEFB	'Start Location: ', EOS
MVC_E:	DEFB	'End Location: ', EOS
MVC_D:	DEFB	'Destination Location: ', EOS

MOVE_COMMAND:
			LD		HL, MVC_1	; Print some messages
			CALL	PRINT_STRING
			
			LD		HL, MVC_S
			CALL	PRINT_STRING
			CALL	GETHEXWORD
			LD		(MVADDR), HL
			CALL	PRINT_NEW_LINE
			
			LD		HL, MVC_E
			CALL	PRINT_STRING
			CALL	GETHEXWORD
			LD		(MVADDR+2), HL
			CALL	PRINT_NEW_LINE
			
			LD		HL, MVC_D
			CALL	PRINT_STRING
			CALL	GETHEXWORD
			LD		(MVADDR+4), HL
			CALL	PRINT_NEW_LINE
			
;***************************************************************************
; Adapted copy from MPF-1(B) Monitor
;***************************************************************************
			ld		hl, MVADDR
			call	GETP	; Fix BC contents from address, to size
			jp		c, ERROR
			ld		de, (MVADDR+4)
			sbc		hl, de
			jr		nc, MVUP
			ex		de, hl
			add		hl, bc
			dec		hl
			ex		de, hl
			ld		hl, (MVADDR+2)
			lddr
			inc		de
			jp		MON_PRMPT_LOOP
MVUP:
			add		hl,de
			ldir
			dec		de
			jp		MON_PRMPT_LOOP
			
			
GETP:
			ld		e, (hl) ; MVADDR
			inc		hl
			ld		d, (hl) ; MVADDR+1
			inc		hl
			ld		c, (hl) ; MVADDR+2
			inc		hl
			ld		h, (hl) ; MVADDR+3
			ld		l, c
			or		a
			sbc		hl, de
			ld		c, l
			ld		b, h
			inc		bc
			ex		de, hl
			ret	
;***************************************************************************
; End copy from MPF-1(B) Monitor
;***************************************************************************

;***************************************************************************
; Memory Fill Command
; Function: Fill a memory block
;***************************************************************************

MFC_1:	DEFB	'Fill Memory Command', 0Dh, 0Ah, EOS
MFC_D:	DEFB	'Data value (one byte): ', EOS

FILL_COMMAND:
			LD		HL, MFC_1	; Print some messages
			CALL	PRINT_STRING
			
			LD		HL, MVC_S
			CALL	PRINT_STRING
			CALL	GETHEXWORD
			LD		(MVADDR), HL
			CALL	PRINT_NEW_LINE
			
			LD		HL, MVC_E
			CALL	PRINT_STRING
			CALL	GETHEXWORD
			LD		(MVADDR+2), HL
			CALL	PRINT_NEW_LINE
			
			LD		HL, MFC_D
			CALL	PRINT_STRING
			CALL	GETHEXBYTE
			LD		(MVADDR+4), A
			CALL	PRINT_NEW_LINE

			LD		DE, (MVADDR)
			LD		HL, (MVADDR+2)
			SBC		HL, DE
			LD		B, H
			LD		C, L
			LD		A, (MVADDR+4)
			LD		HL, (MVADDR)
			LD		(HL), A
			LD		DE, (MVADDR)
			INC		DE
			LDIR
			RET

;***************************************************************************
; Next Page Memory Dump Command
; Function: Print the next block of memory
;***************************************************************************

NEXTP_COMMAND:
			LD 		HL,MDC_3	
			CALL    PRINT_STRING
			LD		HL, (DMPADDR)
			INC		H
			LD		(DMPADDR), HL
			JP		MDNXTPR

;***************************************************************************
; Previous Page Memory Dump Command
; Function: Print the previous block of memory
;***************************************************************************

PREVP_COMMAND:
			LD 		HL,MDC_3	
			CALL    PRINT_STRING
			LD		HL, (DMPADDR)
			DEC		H
			LD		(DMPADDR), HL
			JP		MDNXTPR

