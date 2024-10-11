;***************************************************************************
;  PROGRAM:			MONCommands        
;  PURPOSE:			Subroutines for all monitor commands
;  ASSEMBLER:		original: TASM 3.2 , converted to z80pack/z80asm
;  LICENCE:			The MIT Licence
;  AUTHOR :			MCook
;  CREATE DATE :	06 May 15 / 2021-01-01
;***************************************************************************

HEXLINES:	EQU	17 ; FIXIT: There is a off-by-one-error here

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
HLPMSGk: DEFB 'K - call to memory value', 0Dh, 0Ah, EOS
HLPMSGm: DEFB 'M - copy bytes in memory', 0Dh, 0Ah, EOS
HLPMSGo: DEFB 'O - write byte to output port', 0Dh, 0Ah, EOS
HLPMSGp: DEFB 'P - print port scan (00-FF)', 0Dh, 0Ah, EOS
HLPMSGr: DEFB 'R - monitor reset', 0Dh, 0Ah, EOS
HLPMSGs: DEFB 'S - calculate checksum for memory range', 0Dh, 0Ah, EOS
HLPMSGt: DEFB 'T - test memory range', 0Dh, 0Ah, EOS
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
        LD      HL, HLPMSGk
        CALL    PRINT_STRING
        LD      HL, HLPMSGm
        CALL    PRINT_STRING
        LD      HL, HLPMSGo
        CALL    PRINT_STRING
        LD      HL, HLPMSGp
        CALL    PRINT_STRING
        LD      HL, HLPMSGr
        CALL    PRINT_STRING
        LD      HL, HLPMSGs
        CALL    PRINT_STRING
        LD      HL, HLPMSGt
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

; untested code, 2023-04-24
;***************************************************************************
; Port Write Command
; Function: Write byte to port
;***************************************************************************

MPW_1:  DEFB    'Write data to port Command', 0Dh, 0Ah
MPW_P:  DEFB    'Port & data: ', EOS

PW_COMMAND:
        LD      HL, MPW_1
        CALL    PRINT_STRING
        CALL    GETHEXBYTE
        LD      (MVADDR), A             ; Misuse Move address buffer to store port
        LD      A, (ERRFLAG)
        CP      E_NONE
        RET     NZ
        
        LD      A, ' '
        CALL    PRINT_CHAR
        CALL    GETHEXBYTE
        LD      (MVADDR+1), A
        LD      A, (ERRFLAG)
        CP      E_NONE
        RET     NZ
        
        LD      A, (MVADDR)
        LD      C, A
        LD      A, (MVADDR+1)
        OUT     (C), A
        RET

;***************************************************************************
; Jump to memory Command
; Function: Execute a program at memory location
;***************************************************************************

MGo_1:	DEFB	'Execute program in memory Command', 0Dh, 0Ah, EOS

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
; Call to memory Command
; Function: Execute a program at memory location and expect a RET
;***************************************************************************

MCl_1:	DEFB	'Call program in memory Command', 0Dh, 0Ah, EOS

CL_COMMAND:
        LD		HL, MCl_1	; Print some messages
        CALL	PRINT_STRING
        LD		HL, MGo_2	; Print some messages
        CALL	PRINT_STRING
        CALL	GETHEXWORD
        LD		A, (ERRFLAG)
        CP		E_NONE
        RET		NZ
        
        LD		DE, MON_COMMAND
        PUSH	DE			; Add a suitable return address to the stack
        
        JP	(HL)
        RET
        
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
        
; :0C 2000 00  C31820C39421C3B62AC3812A 50
;  sz addr typ data                     chk

; This part reads the record into the buffer. 
; Note the ':' is already eaten by the command interpreter.
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
        CP      LF
        JR      Z, HXI_RCVD
        JR      HXI_LOOP
        
HXI_RCVD:                               ; the record is received, echo the start address
        LD      A, 0
        LD      (MUTE), A
        
        LD      HL, UPLOADBUF + 2       ; Point to the first address char.
        LD      B, 4
HXIADRLP:
        LD      A, (HL)
        CALL    PRINT_CHAR
        INC     HL
        DJNZ    HXIADRLP
        
        LD      A, (HL)
        CALL    PRINT_CHAR
        CALL    PRINT_NEW_LINE
        
HXI_PROC:                               ; processing the record
        LD      HL, UPLOADBUF
        CALL    CHARS2BYTE              ; get record size
        LD      (ULSIZE), A             ; store it
        CALL    CHARS2BYTE              ; get record address, MSB
        LD      (IECADDR+1), A          ; 
        CALL    CHARS2BYTE              ; get record address, LSB
        LD      (IECADDR), A 
        CALL    CHARS2BYTE              ; get record type
        LD      (IERECTYPE), A
        CP      00h                     ; compare to end record
        JR      Z, HXI_ENDR
        LD      A, (ULSIZE)
        LD      B, A                    ; set up DJNZ loop
        LD      DE, (IECADDR)
HXD_LOOP:
        CALL    CHARS2BYTE              ; get data byte
        LD      (DE), A                 ; store it at target location
        INC     DE
        DJNZ    HXD_LOOP                ; repeat for all data bytes
        CALL    CHARS2BYTE              ; Get checksum

HXI_ENDR:                               ; Done
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

; RAM test
; Tssss eeee

TRC_1: DEFB 'RAM Test Command', 0Dh, 0Ah, EOS
TRC_2: DEFB 'Location to start in 4 digit HEX: ', EOS
TRC_3: DEFB 0Dh, 0Ah, 'Location to end in 4 digit HEX: ', EOS
TRC_4: DEFB 0Dh, 0Ah, 'Start address should be before End address', EOS

TRAM_COMMAND:
        LD      HL,TRC_1        ;Print some messages 
        CALL    PRINT_STRING
        LD      HL,TRC_2
        CALL    PRINT_STRING
        
        CALL    GETHEXWORD              ;HL now points to databyte location	
        LD      (MVADDR), HL
        
        LD      HL,TRC_3
        CALL    PRINT_STRING
        
        CALL    GETHEXWORD              ;HL now points to databyte location	
        LD      (MVADDR+2), HL
        
        LD      A, (MVADDR+3)   ; End MSB
        LD      HL, MVADDR+1    ; (Start MSB)
        CP      (HL)            ; A - (HL)
        JR      Z, _TC_ZERO     ; When MSBs are on same page, test LSBs
        JR      C, _TC_NEGM      ; When Start MSB > End MSB, report error, exit
_TC_POS:
        CALL    MTEST           ; When End page (MSB) is larger than Start (MSB), go to test
        JR      _TC_DONE
        
_TC_ZERO:        
        LD      A, (MVADDR+2)   ; End LSB
        LD      HL, MVADDR+0    ; (Start LSB)
        CP      (HL)            ; A - (HL)
        JR      C, _TC_NEGL      ; When Start LSB > End LSB, report error, exit
        CALL    MTEST           ; When End page (LSB) is larger than Start (LSB), go to test
        
        JR      _TC_DONE
_TC_NEGM:
_TC_NEGL:
        LD      HL, TRC_4
        CALL    PRINT_STRING
        JR      _TC_DONE
                
_TC_DONE:        
        RET
        
MTC_1: DEFB 0Dh, 0Ah, ' Phase 1: ??h to 00h ', EOS
MTC_2: DEFB 0Dh, 0Ah, ' Phase 2: 00h to 55h ', EOS
MTC_3: DEFB 0Dh, 0Ah, ' Phase 3: 55h to AAh ', EOS
MTC_4: DEFB 0Dh, 0Ah, ' Phase 4: AAh to FFh ', EOS
MTCER1: DEFB 0Dh, 0Ah, '  Error at: ', EOS
MTCER2: DEFB ' value expected: ', EOS
MTCER3: DEFB ', found: ', EOS

MTEST:
        ; Test strategy in four phases:
        ; 1. Loop through start to end and for each memory location:
        ;    Set to 00h and check new value
        ; 2. Loop through start to end and for each memory location:
        ;    Check old value (00h)
        ;    Set new value 55h
        ;    Check new value
        ; 3. Loop through start to end and for each memory location:
        ;   Check old value (55h)
        ;    Set new value AAh
        ;    Check new value 
        ; 4. Loop through start to end and for each memory location:
        ;   Check old value (AAh)
        ;    Set new value FFh
        ;    Check new value 
        ; Report start of each phase.
        ; Report address of first incorrect value and terminate
        
        ; MVADDR/MVADDR+1 : start address, MVADDR+2/MVADDR+3 : end address
        ; MVADDR+4 : actual value, MVADDR+5 : expected value
        ; D : new value, E : old value
        
        LD      IX, MVADDR
; Phase 1   ; check only new value
        LD      HL, MTC_1
        CALL    PRINT_STRING
        LD      HL, (MVADDR+0)
        LD      BC, (MVADDR+2)
        LD      D, 000h
_MTLOOP1
        ; new value write
        LD      A, D
        LD      (IX+5), A       ; expected value
        LD      (HL), A
        ; new value check
        LD      A, (HL)
        LD      (IX+4), A       ; store actual value
        CP      (IX+5)          ; compare with expected
        JR      NZ, _MTLPER2
        CALL    CPADDR
        INC     HL
        JR      NZ, _MTLOOP1
        
; Phase 2   ; check old value and new value
        LD      HL, MTC_2
        CALL    PRINT_STRING

        LD      HL, (MVADDR+0)  ; reset start address
        LD      E, 000h         ; old value
        LD      D, 055h         ; new value
        CALL    MCHECK

; Phase 3
        LD      HL, MTC_3
        CALL    PRINT_STRING

        LD      HL, (MVADDR+0)  ; reset start address
        LD      E, 055h         ; old value
        LD      D, 0AAh         ; new value
        CALL    MCHECK

; Phase 4
        LD      HL, MTC_4
        CALL    PRINT_STRING

        LD      HL, (MVADDR+0)  ; reset start address
        LD      E, 0AAh         ; old value
        LD      D, 0FFh         ; new value
        CALL    MCHECK
        
       RET

MCHECK
_MTLOOP
        ; old value check
        LD      A, E
        LD      (IX+5), A       ; store expected value
        LD      A, (HL)         ; read mem
        LD      (IX+4), A       ; store actual value
        CP      (IX+5)          ; compare with expected
        JR      NZ, _MTLPER1    ; jump to error when unequal

        ; new value write
        LD      A, D
        LD      (HL), A         ; write new value
        LD      (IX+5), A       ; store expected value
        ; new value check
        LD      A, (HL)         ; read new value
        LD      (IX+4), A       ; store actual value
        CP      (IX+5)          ; compare with expected
        JR      NZ, _MTLPER2    ; jump to error when unequal
        CALL    CPADDR          ; 
        INC     HL              ; 
        JR      NZ, _MTLOOP     ; 
        JR      _MCDONE

; Error handling
_MTLPER1
        PUSH    AF
        LD      A, '<'
        CALL    PRINT_CHAR
        POP     AF
        JR      _MTLPER
_MTLPER2
        PUSH    AF
        LD      A, '>'
        CALL    PRINT_CHAR
        POP     AF

_MTLPER:
        PUSH    HL              ; keep actual location
        LD      HL, MTCER1      ; at text
        CALL    PRINT_STRING
        POP     HL
        CALL    PRINTHWORD
        LD      HL, MTCER2      ; expected text
        CALL    PRINT_STRING
        LD      A, (MVADDR+5)   ;   expected value
        CALL    PRINTHBYTE
        LD      HL, MTCER3      ; actual found text
        CALL    PRINT_STRING
        LD      A, (MVADDR+4)   ; actual value
        CALL    PRINTHBYTE
        CALL    PRINT_NEW_LINE
        
_MCDONE        
        RET


; **********************************************************************
; CPADDR - Compare two addresses, Z-flag set when equal
;  HL contains current address, BC contains end address
;  Z-flag set when equal
; **********************************************************************
CPADDR:
        LD      A, B        ; End MSB
        CP      H           ; end MSB - current MSB : B - H
        JR      NZ, _CPDONE ; When MSBs are unequal
        LD      A, C        ; End LSB
        CP      L           ; end LSB - current LSB ; C - L

_CPDONE:
        
        RET
