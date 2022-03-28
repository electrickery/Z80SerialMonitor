;***************************************************************************
;  PROGRAM:			MONCommands        
;  PURPOSE:			Subroutines for all monitor commands
;  ASSEMBLER:		original: TASM 3.2 , converted to z80pack/z80asm
;  LICENCE:			The MIT Licence
;  AUTHOR :			MCook
;  CREATE DATE :	06 May 15 / 2021-01-01
;***************************************************************************

HEXLINES:	EQU	17 ; FIXIT: There is a off-by-one-here

;***************************************************************************
;HELP_COMMAND
;Function: Print help dialogue box
;***************************************************************************
HLPMSG1: DEFB 'ZMC80 Monitor Command List', 0Dh, 0Ah, EOS
HLPMSG2: DEFB '? - view command list', 0Dh, 0Ah, EOS
HLPMSGc: DEFB 'C - clear screen', 0Dh, 0Ah, EOS
HLPMSGd: DEFB 'D - print 100h bytes from specified location', 0Dh, 0Ah, EOS
HLPMSGe: DEFB 'E - edit bytes in memory', 0Dh, 0Ah, EOS
HLPMSGf: DEFB 'F - fill memory range with value', 0Dh, 0Ah, EOS
HLPMSGg: DEFB 'G - jump to memory value', 0Dh, 0Ah, EOS
HLPMSGm: DEFB 'M - copy bytes in memory', 0Dh, 0Ah, EOS
HLPMSGp: DEFB 'P - print port scan (00-FF)', 0Dh, 0Ah, EOS
HLPMSGr: DEFB 'R - monitor reset', 0Dh, 0Ah, EOS
HLPMSGs: DEFB 'S - calculate checksum for memory range', 0Dh, 0Ah, EOS
HLPMSGz: DEFB 'Z - dump user registers (STEP)', 0Dh, 0Ah, EOS
HLPMSG8: DEFB '+ - print next block of memory', 0Dh, 0Ah, EOS
HLPMSG9: DEFB '- - print previous block of memory', 0Dh, 0Ah, EOS


HELP_COMMAND:
        LD      HL, HLPMSG1     ;Print some messages
        CALL    PRINT_STRING
        LD      HL, HLPMSG2
        CALL    PRINT_STRING
        LD      HL, HLPMSGc
        CALL    PRINT_STRING
        LD      HL, HLPMSGd
        CALL    PRINT_STRING
        LD      HL, HLPMSGe
        CALL    PRINT_STRING
        LD      HL, HLPMSGf
        CALL    PRINT_STRING
        LD      HL, HLPMSGg
        CALL    PRINT_STRING
        LD      HL, HLPMSGm
        CALL    PRINT_STRING
        LD      HL, HLPMSGp
        CALL    PRINT_STRING
        LD      HL, HLPMSGr
        CALL    PRINT_STRING
        LD      HL, HLPMSGs
        CALL    PRINT_STRING
        LD      HL, HLPMSGz
        CALL    PRINT_STRING
        LD      HL, HLPMSG8
        CALL    PRINT_STRING
        LD      HL, HLPMSG9
        CALL    PRINT_STRING
        LD      A, EOS          ;Load $FF into Acc so MON_COMMAND finishes
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
MVDN:	ex		de, hl
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
        
EDIT_LP:
        LD		A, ':'
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
;PORT_SCAN_COMMAND
;Function: Print $100 databytes from specified location
;***************************************************************************
PSC_1: DEFB 'Port Scan Command', 0Dh, 0Ah, EOS
PSC_3: DEFB '     0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F', 0Dh, 0Ah, EOS

PSCOMMAND:
        LD 		HL,PSC_1			;Print some messages 
        CALL    PRINT_STRING
        
        LD 		HL,PSC_3			;Print some messages 
        CALL    PRINT_STRING

        LD		BC, 0h
        XOR     A
PS_NEWPL:                   ; Start new line, start with port address
        LD      A,C
        CALL	PRINTHBYTE
        LD		A, ' '
        CALL	PRINT_CHAR  ; address - contents separator
        CALL	PRINT_CHAR
        
PS_LOOP:                    ; Print port contents
        IN		A, (C)
        CALL	PRINTHBYTE
        LD		A, ' '
        CALL	PRINT_CHAR ; inter-port-contents separator
        
        INC		BC
        XOR		A
        ADD		A, B
        JR      NZ, PS_END  ; check for all ports done
        
        LD		A, C
        AND		00Fh	; multiples of 16
        JR      NZ, PS_LOOP	; line not yet full
        
        CALL	PRINT_NEW_LINE
        JR		PS_NEWPL
        
PS_CONT:                    ; continue on same line
        LD		A, ' '
        CALL	PRINT_CHAR
        JR		PS_LOOP

        
PS_END:                     ; done all ports
        RET

;***************************************************************************
; Jump to memory Command
; Function: Execute a program at memory location
;***************************************************************************

MGo_1:	DEFB	'Excute program at a Memory Command', 0Dh, 0Ah, EOS

MGo_2:	DEFB	'Memory location: ', EOS

GO_COMMAND:
        LD		HL, MGo_1	; Print some messages
        CALL	PRINT_STRING
        LD		HL, MGo_2	; Print some messages
        CALL	PRINT_STRING
        CALL	GETHEXWORD
        LD		A, (ERRFLAG)
        CP		E_NONE
        RET		NZ

        JP       (HL)	; Jump
        
;***************************************************************************
; Checksum generator. Add memory values in a three byte counter. The last
; included location is end point - 1.
; Function: Calculate checksum for address range in three bytes
;***************************************************************************

CCKSM_1:	DEFB	'Calculate checksum for memory range Command', 0Dh, 0Ah, EOS

CCKSM_2:	DEFB	'Start location: ', EOS

CCKSM_3:	DEFB	'End location: ', EOS

CCKSM_4:    DEFB    'Checksum: ', EOS

CCKSM_COMMAND:
        LD		HL, CCKSM_1
        CALL	PRINT_STRING
        
        LD		HL, CCKSM_2	    ; start
        CALL	PRINT_STRING
        CALL	GETHEXWORD
        LD		A, (ERRFLAG)
        CP		E_NONE
        RET		NZ
        LD      (MVADDR+0), HL
        CALL	PRINT_NEW_LINE
        
        LD		HL, CCKSM_3     ; end
        CALL	PRINT_STRING
        CALL	GETHEXWORD
        LD		A, (ERRFLAG)
        CP		E_NONE
        RET		NZ
        LD      (MVADDR+2), HL
        CALL	PRINT_NEW_LINE
        
        LD      BC, (MVADDR+0)  ; starting point
        LD      DE, (MVADDR+2)  ; end point
        LD      HL, 0           ; the checksum value
        LD      A, 0
        LD      (CHKSUM_C), A   ; checksum overflow
CCSM_1:                     ; main checksum loop
        LD      A, C
        CP      E
        JR      NZ, CCSM_3      ; on no match in LSB, skip the MSB
        LD      A, B
        CP      D
        JR      Z, CCSM_4       ; MSB matches too
CCSM_3:                     ; still going, add next value to checksum
        LD      A, (BC)
        ADD     A, L
        LD      L, A
        JR      NC, CCSM_2      ; check carry in checksum LSB
        LD      A, H
        ADD     A, 1
        LD      H, A
        JR      NC, CCSM_2
        LD      A, (CHKSUM_C)
        INC     A
        LD      (CHKSUM_C), A
CCSM_2:                     ; done this value
        INC     BC
        JR      CCSM_1
        
CCSM_4:                     ; running address matches end, done
        PUSH    HL
        LD		HL, CCKSM_4     ; end
        CALL	PRINT_STRING
        LD      A, (CHKSUM_C)
        CALL    PRINTHBYTE      ; checksum overflow first
        POP     HL
        CALL    PRINTHWORD
        CALL    PRINT_NEW_LINE

        RET


;***************************************************************************
; Load hex-intel record
;
;***************************************************************************

HEXI_COMMAND:
        LD      A, 1
        LD      (MUTE), A
        LD      HL, UPLOADBUF
        LD      (RX_READ_P), HL
        LD      (RX_WRITE_P), HL
HXI_LOOP:
        CALL    UART_RX_RDY
        CALL    UART_RX
        LD      HL, (RX_WRITE_P)
        LD      (HL), A
        INC     HL
        LD      (RX_WRITE_P), HL
        AND     A
        CP      0Ah
        JR      Z, HXI_DONE
        JR      HXI_LOOP
HXI_DONE:  
        LD      A, 0
        LD      (MUTE), A
        
        LD      HL, UPLOADBUF + 2
        LD      A, (HL)
        CALL    PRINT_CHAR
        INC     HL
        LD      A, (HL)
        CALL    PRINT_CHAR
        INC     HL
        LD      A, (HL)
        CALL    PRINT_CHAR
        INC     HL
        LD      A, (HL)
        CALL    PRINT_CHAR
        CALL    PRINT_NEW_LINE
        
        LD      A, XOFF
        CALL    PRINT_CHAR
        
        CALL    PROC_SIZ
        CALL    PROC_ADDR
        
        RET

PROC_SIZ:
        LD      HL, UPLOADBUF
        LD      A, (HL)
        CALL    CHAR_ISHEX
        LD      A, C
        JR      NC, PH_NOHEX
        LD      A, (HL)
        CALL    CHAR2NIB
        RLC     A
        RLC     A
        RLC     A
        RLC     A
        LD      B, A
        INC     HL
        LD      A, (HL)
        CALL    CHAR2NIB
        ADD     A, B
        LD      A, (ULSIZE)
        JR      PH_DONE

PH_NOHEX:
        LD      A, E_NOHEX
        LD      (ERRFLAG), A
        
PH_DONE:
        RET

PROC_ADDR:

        RET
        
USERAF: EQU     01FBCh
USERBC: EQU     01FBEh
USERDE: EQU     01FC0h
USERHL: EQU     01FC2h
UAFP:   EQU     01FC4h
UBCP:   EQU     01FC6h
UDEP:   EQU     01FC8h
UHLP:   EQU     01FCAh
USERIX: EQU     01FCCh
USERIY: EQU     01FCEh
USERSP: EQU     01FD0h
USERIF: EQU     01FD2h
FLAGH:  EQU     01FD4h
FLAGL:  EQU     01FD6h
FLAGHP: EQU     01FD8h
FLAGLP: EQU     01FDAh
USERPC: EQU     01FDCh
        
RDLN_1: DEFB    ' AF   BC   DE   HL   IX   IY   AF', 027h, '  BC', 027h, '  DE', 027h, '  HL', 027h, EOS
RDLN_3: DEFB    ' SP   PC   IF   SZ-H-PNC  SZ-H-PNC', 027h  , EOS

REGDUMP_COMMAND:
        LD      HL, RDLN_1
        CALL    PRINT_STRING
        
        CALL    PRINT_NEW_LINE
        
        LD      HL, (USERAF)
        CALL    PRINTHWORD
        LD      A, ' '
        CALL    PRINT_CHAR
        
        LD      HL, (USERBC)
        CALL    PRINTHWORD
        LD      A, ' '
        CALL    PRINT_CHAR
        
        LD      HL, (USERDE)
        CALL    PRINTHWORD
        LD      A, ' '
        CALL    PRINT_CHAR
        
        LD      HL, (USERHL)
        CALL    PRINTHWORD
        LD      A, ' '
        CALL    PRINT_CHAR
        
        LD      HL, (USERIX)
        CALL    PRINTHWORD
        LD      A, ' '
        CALL    PRINT_CHAR
        
        LD      HL, (USERIY)
        CALL    PRINTHWORD
        
        LD      A, ' '
        CALL    PRINT_CHAR

        LD      HL, (UAFP)
        CALL    PRINTHWORD
        LD      A, ' '
        CALL    PRINT_CHAR
        
        LD      HL, (UBCP)
        CALL    PRINTHWORD
        LD      A, ' '
        CALL    PRINT_CHAR
        
        LD      HL, (UDEP)
        CALL    PRINTHWORD
        LD      A, ' '
        CALL    PRINT_CHAR
        
        LD      HL, (UHLP)
        CALL    PRINTHWORD
        LD      A, ' '
        CALL    PRINT_CHAR
        
        CALL    PRINT_NEW_LINE
        
        LD      HL, RDLN_3
        CALL    PRINT_STRING
        
        CALL    PRINT_NEW_LINE
        
        LD      HL, (USERSP)
        CALL    PRINTHWORD
        LD      A, ' '
        CALL    PRINT_CHAR
        
        LD      HL, (USERPC)
        CALL    PRINTHWORD
        LD      A, ' '
        CALL    PRINT_CHAR
        
        LD      HL, (USERIF)
        CALL    PRINTHWORD
        LD      A, ' '
        CALL    PRINT_CHAR
        CALL    PRINT_CHAR
        
        LD      A, (USERAF+1)
        CALL    PRT8BIT
        LD      A, ' '
        CALL    PRINT_CHAR
        LD      A, ' '
        CALL    PRINT_CHAR
        LD      A, (UAFP+1)
        CALL    PRT8BIT
        
        RET
        
REGDMPJ:
        CALL    REGDUMP_COMMAND
        JP      MPFMON  ; return to monitor
