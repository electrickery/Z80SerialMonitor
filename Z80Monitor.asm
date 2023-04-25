;***************************************************************************
;  PROGRAM:			Z80 Monitor        
;  PURPOSE:			ROM Monitor Program
;  ASSEMBLER:		original: TASM 3.2 , converted to z80pack/z80asm
;  LICENCE:			The MIT Licence
;  AUTHOR :			MCook. Extended MPF-I version: F.J. Kraan
;  CREATE DATE :	05 May 15 / 2022-03-28
;***************************************************************************

VERSMYR:    EQU     '0'
VERSMIN:    EQU     '8'

            INCLUDE CONSTANTS.asm ; copy or edit one of the 
                                  ; CONSTANTS-aaaa-pp.asm files to
                                  ; CONSTANTS.asm

;ROM_BOTTOM:  EQU    0F000h		; Bottom address of ROM
ROM_TOP:     EQU    ROM_BOTTOM + 00FFFh		; Top address of ROM

;RAM_BOTTOM:  EQU    01800h		; Bottom address of RAM
RAM_TOP:     EQU    RAM_BOTTOM + 0FFh		; Top address of RAM	

;UART_BASE:  EQU     0E0h        ; Base port address, DART uses 4 ports

MPFMON:     EQU    0000h
ASCDMPBUF:  EQU    RAM_BOTTOM + 0h	    	;Buffer to construct ASCII part of memory dump
ASCDMPEND:  EQU    RAM_BOTTOM + 10h		;End of buffer, fill with EOS
DMPADDR:    EQU    RAM_BOTTOM + 11h		;Last dump address
MVADDR:     EQU    RAM_BOTTOM + 12h 		; 6 bytes: start-address, end-address, dest-address or fill-value (23, 24, 25, 26, 27, 28)
ERRFLAG:    EQU    RAM_BOTTOM + 18h		; Location to store 
MUTE:       EQU    RAM_BOTTOM + 19h		; 0 - print received chars, 1 - do not print received chars
ULSIZE:     EQU    RAM_BOTTOM + 1Ah		; actual size of current/last hex-intel message
IECHECKSUM: EQU    RAM_BOTTOM + 1Bh        ; hex-intel record checksum
IECKSMCLC:  EQU    RAM_BOTTOM + 1Ch        ; hex-intel record
IERECTYPE:  EQU    RAM_BOTTOM + 1Dh        ; hex-intel record type
DEBUG:      EQU    RAM_BOTTOM + 1Eh
RX_READ_P:  EQU    RAM_BOTTOM + 20h     ; read pointer
RX_WRITE_P: EQU    RAM_BOTTOM + 22h     ; write pointer
CHKSUM_C:   EQU    RAM_BOTTOM + 24h     ; uses 3 bytes
CF_SECCNT:  EQU    RAM_BOTTOM + 27h 
CF_LBA0:    EQU    RAM_BOTTOM + 28h
CF_LBA1:    EQU    RAM_BOTTOM + 29h
CF_LBA2:    EQU    RAM_BOTTOM + 2Ah
CF_LBA3:    EQU    RAM_BOTTOM + 2Bh
UPLOADBUF:  EQU    RAM_BOTTOM + 2Ch     ; Buffer for hex-intel upload. Allows up to 32 bytes (20h) per line.
ULBUFSIZE:  EQU    50h                  ; a 20h byte hex-intel record use 75 bytes...
ULBEND:     EQU    UPLOADBUF + ULBUFSIZE
MSGBUF:     EQU    UPLOADBUF

; Error codes intel Hex record
E_NONE:     EQU    00h
E_NOHEX:    EQU    01h			; input char not 0-9, A-F
E_PARAM:    EQU    02h			; inconsistent range; start > end
E_BUFSIZE:  EQU    03h			; size larger than buffer
E_HITYP:    EQU    04h			; unsupported hex-intel record type
E_HICKSM:   EQU    05h			; hex-intel record checksum error
E_HIEND:    EQU    06h			; hex-intel end record type found

HI_DATA:    EQU    00h
HI_END:     EQU    01h

ESC:        EQU    01Bh		; 
EOS:        EQU    000h		; End of string
MUTEON:     EQU    001h

; Elaborate logic/arithmetic to calculate ROM & UART base address digits
            IFEQ (ROM_BOTTOM & 0C000h), 0C000h
ROMB1:      EQU    (ROM_BOTTOM & 0F000h) / 1000h + '7'
            ELSE
            IFEQ (ROM_BOTTOM & 0A000h), 0A000h
ROMB1:      EQU    (ROM_BOTTOM & 0F000h) / 1000h + '7'
            ELSE
ROMB1:      EQU    (ROM_BOTTOM & 0F000h) / 1000h + '0'
            ENDIF
            ENDIF
             
            IFEQ (ROM_BOTTOM & 0C00h), 0C00h
ROMB2:      EQU    (ROM_BOTTOM & 00F00h) / 100h  + '7'
            ELSE
            IFEQ (ROM_BOTTOM & 0A0h), 0A00h
ROMB2:      EQU    (ROM_BOTTOM & 00F00h) / 100h  + '7'
            ELSE
ROMB2:      EQU    (ROM_BOTTOM & 00F00h) / 100h  + '0'
            ENDIF
            ENDIF

            IFEQ (ROM_BOTTOM & 0C0h), 0C0h
ROMB3:      EQU    (ROM_BOTTOM & 000F0h) / 10h   + '7'
            ELSE
            IFEQ (ROM_BOTTOM & 0A0h), 0A0h
ROMB3:      EQU    (ROM_BOTTOM & 000F0h) / 10h   + '7'
            ELSE
ROMB3:      EQU    (ROM_BOTTOM & 000F0h) / 10h   + '0'
            ENDIF
            ENDIF
             
            IFEQ (ROM_BOTTOM & 0Ch), 0Ch
ROMB4:      EQU    (ROM_BOTTOM & 0000Fh) / 1h + '7'
            ELSE
            IFEQ (ROM_BOTTOM & 0Ah), 0Ah
ROMB4:      EQU    (ROM_BOTTOM & 0000Fh) / 1h + '7'
            ELSE
ROMB4:      EQU    (ROM_BOTTOM & 0000Fh) / 1h + '0'
            ENDIF
            ENDIF
            
            IFEQ (UART_BASE & 0C0h), 0C0h
UART1:      EQU    (UART_BASE & 0F0h) / 10h   + '7'
            ELSE
            IFEQ (UART_BASE & 0A0h), 0A0h
UART1:      EQU    (UART_BASE & 0F0h) / 10h   + '7'
            ELSE
UART1:      EQU    (UART_BASE & 0F0h) / 10h   + '0'
            ENDIF
            ENDIF
             
            IFEQ (UART_BASE & 0Ch), 0Ch
UART2:      EQU    (UART_BASE & 00Fh) / 1h   + '7'
            ELSE
            IFEQ (UART_BASE & 0Ah), 0Ah
UART2:      EQU    (UART_BASE & 00Fh) / 1h   + '7'
            ELSE
UART2:      EQU    (UART_BASE & 00Fh) / 1h   + '0'
            ENDIF
            ENDIF

			ORG ROM_BOTTOM
ROUTINES:
R_MAIN:         JP      MAIN            ; init DART and starts command loop
R_U_INIT:       JP      UART_INIT       ; configures DARTchannel B 
R_PRT_NL:       JP      PRINT_NEW_LINE  ; sends a CR LF
R_PRT_STR:      JP      PRINT_STRING    ; sends a NULL terminated string
                DEFS    3
                DEFS    3
                DEFS    3
                DEFS    3
            
            ORG ROM_BOTTOM + 24     ; room for eight routine entries
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
			JP		MPFMON				;Jumps to 0000 (MPF-1 monitor re-entry)	
			
;***************************************************************************
;PRINT_MON_HDR
;Function: Print out program header info
;***************************************************************************
MNMSG1:     DEFB    0DH, 0Ah, 'ZMC80 Computer', 09h, 09h, 09h, '2015 MCook', EOS
MNMSG2:     DEFB    0DH, 0Ah, ' adaptation to MPF-1 / Z80 DART', 09h, '2022 F.J.Kraan', 0Dh, 0Ah, EOS
MNMSG3:     DEFB    'Monitor v', VERSMYR, '.', VERSMIN, 
            DEFB    ' ROM: ', ROMB1, ROMB2, ROMB3, ROMB4
            DEFB    'h DART: ', UART1, UART2, 'h', 0Dh, 0AH, 0Dh, 0AH, EOS
MONHLP:     DEFB    09h,' Input ? for command list', 0Dh, 0AH, EOS
MONERR:     DEFB    0Dh, 0AH, 'Error in params: ', EOS

PRINT_MON_HDR:
        CALL    CLEAR_SCREEN        ;Clear the terminal screen
        LD      HL, MNMSG1          ;Print some messages
        CALL    PRINT_STRING
        LD      HL, MNMSG2          ;Print some extra message
        CALL    PRINT_STRING
        LD      HL, MNMSG3
        CALL    PRINT_STRING
        LD      HL, MONHLP
        CALL    PRINT_STRING
        RET

;***************************************************************************
;MON_PROMPT
;Function: Prompt user for input
;***************************************************************************			
MON_PROMPT: DEFB '>', EOS

MON_PRMPT_LOOP:
        LD      A, 00h
        LD      (MUTE), A			; Enables echo of received chars
        LD      HL,MON_PROMPT		;Print monitor prompt
        CALL    PRINT_STRING		
        CALL    GET_CHAR			;Get a character from user into Acc
        CALL    PRINT_CHAR
        CALL    PRINT_NEW_LINE		;Print a new line
        CALL    MON_COMMAND			;Respond to user input
        CALL    PRINT_NEW_LINE		;Print a new line	
        JR      MON_PRMPT_LOOP

;***************************************************************************
;MON_COMMAND
;Function: User input in accumulator to respond to 
;***************************************************************************
MON_COMMAND:    ; Inserted ERROR_CHK for all commands requiring input
        CALL    CLEAR_ERROR
        CP      '?'
        CALL    Z,HELP_COMMAND
        CP      'D'
        CALL    Z,MDCMD
        CP      'C'
        CALL    Z,CLEAR_SCREEN
        CP      'O'
        CALL    Z,PW_COMMAND
        CP      'P'
        CALL    Z,PSCOMMAND
        CP      'R'
        CALL    Z,RESET_COMMAND
        CP      'M'
        CALL    Z,MOVE_COMMAND
        CP      'F'
        CALL    Z,FILL_COMMAND
        CP      'G'
        CALL    Z,GO_COMMAND
        CP      'K'
        CALL    Z,CL_COMMAND
        CP      '+'
        CALL    Z,NEXTP_COMMAND
        CP      '-'
        CALL    Z,PREVP_COMMAND
        CP      'E'
        CALL    Z,EDIT_COMMAND
        CP      ':'
        CALL    Z,HEXI_COMMAND
        CP      'S'
        CALL    Z,CCKSM_COMMAND
        CP      'Z'
        CALL    Z,REGDUMP_COMMAND
        CALL    ERROR_CHK
        RET

ERROR_CHK:
        LD      A, (ERRFLAG)
        CP      E_NONE
        RET     Z
        LD      HL, MONERR
        CALL    PRINT_STRING
        LD      A, (ERRFLAG)
        CALL    PRINTHBYTE
        CALL    PRINT_NEW_LINE
CLEAR_ERROR:
        PUSH    AF
        LD      A, E_NONE
        LD      (ERRFLAG), A
        POP     AF
        RET
        
        INCLUDE	DARTDriver.asm
        INCLUDE	MONCommands.asm
        INCLUDE	CONIO.asm
        INCLUDE CFDriver.asm

        END
