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
HELPMSG4: DEFB 'C - clear screen', 0Dh, 0Ah, EOS
HELPMSG5: DEFB 'D - print $FF bytes from specified location', 0Dh, 0Ah, EOS
HELPMSGa: DEFB 'E - edit bytes in memory', 0Dh, 0Ah, EOS
HELPMSG7: DEFB 'F - fill memory range with value', 0Dh, 0Ah, EOS
HELPMSG6: DEFB 'M - copy bytes in memory', 0Dh, 0Ah, EOS
HELPMSG3: DEFB 'R - monitor reset', 0Dh, 0Ah, EOS
HELPMSG8: DEFB '+ - print next block of memory', 0Dh, 0Ah, EOS
HELPMSG9: DEFB '- - print previous block of memory', 0Dh, 0Ah, EOS
HELPMSGf: DEFB 'I - upload Hex-Intel record', 0Dh, 0Ah, EOS


HELP_COMMAND:
			LD 		HL,HELPMSG1		;Print some messages
			CALL    PRINT_STRING		
			LD 		HL,HELPMSG2		
			CALL    PRINT_STRING			
			LD 		HL,HELPMSG4		
			CALL    PRINT_STRING
			LD 		HL,HELPMSG5		
			CALL    PRINT_STRING
			LD 		HL,HELPMSGa		
			CALL    PRINT_STRING
			LD 		HL,HELPMSG7		
			CALL    PRINT_STRING
			LD 		HL,HELPMSG6		
			CALL    PRINT_STRING
			LD 		HL,HELPMSG3		
			CALL    PRINT_STRING
			LD 		HL,HELPMSG8		
			CALL    PRINT_STRING
			LD 		HL,HELPMSG9		
			CALL    PRINT_STRING
			LD 		HL,HELPMSGf		
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
			LD		A, (ERRFLAG)
			CP		E_NONE
			RET		NZ
			LD		(DMPADDR), HL		;Keep address for next/prev.
			PUSH	HL					;Save HL that holds databyte location on stack
			CALL    PRINT_NEW_LINE		;Print some messages
			CALL    PRINT_NEW_LINE
			LD 		HL, MDC_3	
			CALL    PRINT_STRING

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
			LD		A, (ERRFLAG)
			CP		E_NONE
			RET		NZ
			LD		(MVADDR), HL
			CALL	PRINT_NEW_LINE
			
			LD		HL, MVC_E
			CALL	PRINT_STRING
			CALL	GETHEXWORD
			LD		A, (ERRFLAG)
			CP		E_NONE
			RET		NZ
			LD		(MVADDR+2), HL
			CALL	PRINT_NEW_LINE
			
			LD		HL, MVC_D
			CALL	PRINT_STRING
			CALL	GETHEXWORD
			LD		A, (ERRFLAG)
			CP		E_NONE
			RET		NZ
			LD		(MVADDR+4), HL
			CALL	PRINT_NEW_LINE
			
;***************************************************************************
; Adapted copy from MPF-1(B) Monitor
;***************************************************************************
			ld		hl, MVADDR
			call	GETP	; Fix BC contents from address, to size
			jp		c, MERR
			ld		de, (MVADDR+4)
			sbc		hl, de
			jr		nc, MVUP
MVDN:		ex		de, hl
			add		hl, bc
			dec		hl
			ex		de, hl
			ld		hl, (MVADDR+2)
			lddr
			inc		de
			RET
MVUP:
			add		hl,de
			ldir
			dec		de
			RET;
MERR:
			LD		A, E_PARAM
			LD		(ERRFLAG), A
			RET;

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
			
			LD		HL, MVC_S	; Start msg.
			CALL	PRINT_STRING
			CALL	GETHEXWORD
			LD		A, (ERRFLAG)
			CP		E_NONE
			RET		NZ
			LD		(MVADDR), HL	; Start val.
			CALL	PRINT_NEW_LINE
			
			LD		HL, MVC_E	; End msg.
			CALL	PRINT_STRING
			CALL	GETHEXWORD
			LD		(MVADDR+2), HL	; End val.
			LD		A, (ERRFLAG)
			CP		E_NONE
			RET		NZ
			
			LD		DE, (MVADDR)	; Start
			SBC		HL, DE		; Make sure end is past start...
			JR		C, F_ORDERR
			LD		HL, (MVADDR+2)
			CALL	PRINT_NEW_LINE
			
			LD		HL, MFC_D
			CALL	PRINT_STRING
			CALL	GETHEXBYTE
			LD		(MVADDR+4), A
			LD		A, (ERRFLAG)
			CP		E_NONE
			RET		NZ
			CALL	PRINT_NEW_LINE

			LD		DE, (MVADDR)	; Start
			LD		HL, (MVADDR+2)	; End
			SBC		HL, DE			; Size
			LD		B, H
			LD		C, L
			LD		A, (MVADDR+4)	; Fill value
			LD		HL, (MVADDR)	; First source location
			LD		(HL), A			; seed the fill block
			LD		DE, (MVADDR)	; First dest. location
			INC		DE				; 
			LDIR
			RET
			
F_ORDERR:
			LD		A, E_PARAM
			LD		(ERRFLAG), A
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

;***************************************************************************
; Edit Memory Command
; Function: Edit bytes in memory
;***************************************************************************

EDIT_COMMAND:
			LD 		HL, MVC_S	; Start msg.
			CALL    PRINT_STRING
			
			CALL	GETHEXWORD	; Get first address
			LD		A, (ERRFLAG)
			CP		E_NONE
			RET		NZ
			
EDIT_LP:	LD		A, ':'
			CALL	PRINT_CHAR
			LD		A, ' '
			CALL	PRINT_CHAR
			
			LD		A, (HL)		; Print original value
			CALL	PRINTHBYTE
			
			LD		A, '>'
			CALL	PRINT_CHAR
			LD		A, ' '
			CALL	PRINT_CHAR
			
			CALL	GETHEXBYTE
			LD		(MVADDR+4), A
			LD		A, (ERRFLAG)
			CP		E_NONE
			RET		NZ

			LD		A, (MVADDR+4)
			LD		(HL), A		; Write new value
			
			CALL	PRINT_NEW_LINE
			INC		HL
			CALL	PRINTHWORD
			JR		EDIT_LP		; Only way out is type a non-hex char...


;***************************************************************************
; Upload Hex-Intel records
; 
;***************************************************************************

UPLOAD_COMMAND:
			LD		A, 01h
			LD		(MUTE), A 		; suppress echo
			CALL	GET_CHAR
			CP		ESC
			JP		Z, I_NOERR
			CP		':'
			JR		NZ, UPLOAD_COMMAND ; Loop here until a ':' or ESC is received

; From: https://www.z80cpu.eu/mirrors/www.z80.info/zip/z80asm.zip
INTLIN_CMD:	
			LD		HL, UPLOADBUF
			LD		(MVADDR), HL
			; *** record size ***
			CALL	GETHEXBYTE		;Get record length
			LD		(ULSIZE), A
			LD		A, (ERRFLAG)
			CP		E_NONE
			JP		NZ, I_PASSERR
			LD		A, (ULSIZE)		; Check for maximum buffer size
			CP		ULBUFSIZE
			JP		NC, I_ERRBSZ
			; *** address MSB ***
			CALL	GETHEXBYTE		;Get record address hi byte
			LD		(MVADDR+5), A			;Put in move dest MSB
			LD		A, (ERRFLAG)
			CP		E_NONE
			JR		NZ, I_PASSERR
			LD		A, (MVADDR+5)
			; *** address LSB ***
			CALL	GETHEXBYTE		;Get record address lo byte
			LD		(MVADDR+4), A			;Put in move dest LSB
			LD		A, (ERRFLAG)
			CP		E_NONE
			JR		NZ, I_PASSERR
			LD		A, (MVADDR+4)
			; *** record type ***
			CALL	GETHEXBYTE		; Check record type
			LD		(IERECTYPE), A
			LD		A, (ERRFLAG)
			CP		E_NONE
			JR		NZ, I_PASSERR
			LD		A, (IERECTYPE)
			CP		HI_DATA
			JR		Z, I_ULPREP		; To data upload
			CP		HI_END
			JR		Z, I_HIEND		; Done with end record
			
			JR		I_ERRTYP
I_ULPREP:
			LD		A, (ULSIZE)
;			INC		A			; off-by-one because of decrement before test of DJNZ ?
			LD		(DEBUG), A
			LD		B, A
			LD		HL, UPLOADBUF

INTLIN_LP:
			LD		A, B
			LD		(DEBUG), A
			; *** data bytes ***
			CALL	GETHEXBYTE		;Get record data byte
			LD		(HL), A			;Save byte to memory
			LD		A, (ERRFLAG)
			CP		E_NONE
			JR		NZ, I_NOERR
			INC		HL				;Next buffer address
			LD		A, (DEBUG)
			DJNZ	INTLIN_LP		;Decrement count and jump if not finished
			; *** checksum byte ***
			CALL	GETHEXBYTE
			LD		(IECHECKSUM), A
			LD		A, (ERRFLAG)
			CP		E_NONE
			JR		NZ, I_NOERR
			; *** close ***
			LD		A, 00h
			LD		(MUTE), A 		; allow echo
			; *** checksum calculate ***
			CALL	HICHECKSUM
			
			; *** print response ***
			LD		HL, (MVADDR+4)	;print the line starting address as response
			CALL	PRINTHWORD		;
			CALL	PRINT_NEW_LINE
			
			LD		HL, UPLOADBUF
			LD		DE, (MVADDR+4)
			LD		B, 0
			LD		A, (ULSIZE)
			LD		C, A
			LDIR
;			JP		INTLIN_CMD	; next record
I_PASSERR:
I_NOERR:
			LD		A, 00h
			LD		(MUTE), A 		; allow echo
			RET

I_ERRBSZ:	LD		A, E_BUFSIZE
			LD		(ERRFLAG), A
			LD		A, 00h
			LD		(MUTE), A 		; allow echo
			RET
			
I_ERRTYP:	LD		A, E_HITYP
			LD		(ERRFLAG), A
			LD		A, 00h
			LD		(MUTE), A 		; allow echo
			RET

I_HIEND:	LD		A, E_HIEND
			LD		(ERRFLAG), A
			LD		A, 00h
			LD		(MUTE), A 		; allow echo
			CALL	GETHEXBYTE		; wait for checksum
			RET

HICHECKSUM:
			LD		A, 0FFh
			LD		HL, (ULSIZE)		; rec size
			SBC		A, (HL)
			LD		B, A
			LD		HL, (MVADDR+4)	; dest MSB
			SBC		A, (HL)
			LD		HL, (MVADDR+5)	; dest LSB
			SBC		A, (HL)
			;SBC		A, 0		; record type
			LD		HL, UPLOADBUF
I_CKSMLP:	
			SBC 	A, (HL)
			INC		HL
			DJNZ	I_CKSMLP
			LD		(IECKSMCLC), A
			RET
