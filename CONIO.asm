;***************************************************************************
;  PROGRAM:			CONIO       
;  PURPOSE:			Subroutines for console I/O
;  ASSEMBLER:		original: TASM 3.2 , converted to z80pack/z80asm
;  LICENCE:			The MIT Licence
;  AUTHOR :			MCook
;  CREATE DATE :	19 May 15
;***************************************************************************

;***************************************************************************
;PRINT_STRING
;Function: Prints string to terminal program
;***************************************************************************
PRINT_STRING:
        CALL    UART_PRNT_STR
        RET
        
;***************************************************************************
;GET_CHAR
;Function: Get upper case ASCII character from user into Accumulator
;***************************************************************************			
GET_CHAR:
        CALL	UART_RX				;Get char into Acc
        CALL	TO_UPPER			;Character has to be upper case
        RET
        
;***************************************************************************
;PRINT_CHAR
;Function: Get upper case ASCII character from Accumulator to UART
;***************************************************************************			
PRINT_CHAR:
        CALL	UART_TX				;Echo character to terminal
        RET			
        
; Optional print char
OPRINTCHAR:
        LD		C, A
        LD		A, (MUTE)
        CP		MUTEON		; compare with 1=true
        JR		Z, PRTSKIP
        LD		A, C
        CALL	PRINT_CHAR

PRTSKIP:
        LD		A, C
        RET

;***************************************************************************
;TO_UPPER
;Function: Convert character in Accumulator to upper case 
;***************************************************************************
TO_UPPER:       
        CP      'a'             	; Nothing to do if not lower case
        RET     C
        CP      'z' + 1         	; > 'z'?
        RET     NC              	; Nothing to do, either
        AND     5Fh             	; Convert to upper case
        RET		
            
;***************************************************************************
;MKPRINT
;Function: Make all characters printable by replacing control-chars with '.'
;***************************************************************************
LOWPRTV:    EQU		' '
HIGPRTV:    EQU		'~'
MKPRINT:
        CP		LOWPRTV
        JR		C, ADDOT
        CP		HIGPRTV
        JR		NC, ADDOT
        RET
ADDOT:
        LD		A, '.'
        RET
        
;***************************************************************************
;PRINT_NEW_LINE
;Function: Prints carriage return and line feed
;***************************************************************************			
NEW_LINE_STRING:
        DEFB    0Dh, 0Ah ,EOS

PRINT_NEW_LINE:
        PUSH	HL
        LD 		HL,NEW_LINE_STRING			
        CALL    PRINT_STRING			
        POP		HL
        RET
        
;***************************************************************************
;CHAR_ISHEX
;Function: Checks if value in A is a hexadecimal digit, C flag set if true
;***************************************************************************		
CHAR_ISHEX:         
                                    ;Checks if Acc between '0' and 'F'
        CP      'F' + 1       		;(Acc) > 'F'? 
        RET     NC              	;Yes - Return / No - Continue
        CP      '0'             	;(Acc) < '0'?
        JP      NC,CIH1         	;Yes - Jump / No - Continue
        CCF                     	;Complement carry (clear it)
        RET
CIH1:       
                                    ;Checks if Acc below '9' and above 'A'
        CP      '9' + 1         	;(Acc) < '9' + 1?
        RET     C               	;Yes - Return / No - Continue (meaning Acc between '0' and '9')
        CP      'A'             	;(Acc) > 'A'?
        JP      NC,CIH2 	;Yes - Jump / No - Continue
        CCF                     	;Complement carry (clear it)
        RET
CIH2:        
                                    ;Only gets here if Acc between 'A' and 'F'
        SCF                     	;Set carry flag to indicate the char is a hex digit
        RET
        
;***************************************************************************
;GET_HEX_NIBBLE
;Function: Translates char to HEX nibble in bottom 4 bits of A
;***************************************************************************
GETHEXNIB:      
        CALL	GET_CHAR
        CALL    CHAR_ISHEX      	; Is it a hex digit?
        JP      NC,NONHEXNIB 	 	; Yes - Continue / No - Exit
        CALL    OPRINTCHAR

        CP      '9' + 1         	; Is it a digit less or equal '9' + 1?
        JP      C,IS_NUM 			; Yes - Jump / No - Continue
        SUB     07h             	; Adjust for A-F digits
IS_NUM:                
        SUB     '0'             	; Subtract to get nib between 0->15
        AND     0Fh             	; Only return lower 4 bits
        RET
NONHEXNIB:								; Allow exit on wrong char
        LD		A, E_NOHEX
        LD		(ERRFLAG), A		; Error flag
        RET

;***************************************************************************
;GET_HEX_BTYE
;Function: Gets HEX byte into A
;Uses: AF, D
;***************************************************************************
GETHEXBYTE:
        CALL    GETHEXNIB			; Get high nibble
        PUSH	DE
        PUSH	AF
        LD		A, (ERRFLAG)
        CP		E_NONE
        JR		NZ, GHB_ERR
        POP		AF
        RLC     A					; Rotate nibble into high nibble
        RLC     A
        RLC     A
        RLC     A
        LD      D,A					; Save upper four bits
        CALL    GETHEXNIB			; Get lower nibble
        PUSH	AF
        LD		A, (ERRFLAG)
        CP		E_NONE
        JR		NZ, GHB_ERR  
        POP		AF          
        OR      D					; Combine both nibbles
        POP		DE
        RET
GHB_ERR:
        POP		AF
        POP		DE
        RET

;***************************************************************************
;GET_HEX_WORD
;Function: Gets two HEX bytes into HL
;Uses: AF
;***************************************************************************
GETHEXWORD:
        CALL    GETHEXBYTE		;Get high byte
        PUSH	AF
        LD		A, (ERRFLAG)
        CP		E_NONE
        JR		NZ, GHW_ERR
        POP		AF
        LD		H,A
        CALL    GETHEXBYTE    	;Get low byte
        PUSH	AF
        LD		A, (ERRFLAG)
        CP		E_NONE
        JR		NZ, GHW_ERR
        POP     AF
        LD      L,A
        RET
GHW_ERR:
        POP		AF
        RET
    
;***************************************************************************
;PRINT_HEX_NIB
;Function: Prints a low nibble in hex notation from Acc to the serial line.
;***************************************************************************
PRINTHNIB:
        PUSH 	AF
        AND     0Fh             	;Only low nibble in byte
        ADD     A,'0'             	;Adjust for char offset
        CP      '9' + 1         	;Is the hex digit > 9?
        JP      C,PHN1	;Yes - Jump / No - Continue
        ADD     A,'A' - '0' - 0Ah 	;Adjust for A-F
PHN1:
        CALL	PRINT_CHAR        	;Print the nibble
        POP		AF
        RET
        
;***************************************************************************
;PRINT_HEX_BYTE
;Function: Prints a byte in hex notation from Acc to the serial line.
;***************************************************************************		
PRINTHBYTE:
        PUSH	AF					;Save registers
        PUSH	DE
        LD		D,A					;Save for low nibble
        RRCA						;Rotate high nibble into low nibble
        RRCA
        RRCA
        RRCA
        CALL    PRINTHNIB		;Print high nibble
        LD		A,D					;Restore for low nibble
        CALL    PRINTHNIB		;Print low nibble
        POP		DE
        POP		AF
        RET
        
;***************************************************************************
;PRINT_HEX_WORD
;Function: Prints the four hex digits of a word to the serial line from HL
;***************************************************************************
PRINTHWORD:     
;		PUSH 	HL
        PUSH	AF
        LD		A,H
        CALL	PRINTHBYTE		;Print high byte
        LD		A,L
        CALL    PRINTHBYTE		;Print low byte
        POP		AF
;		POP		HL
        RET			

;***************************************************************************
;CHAR TO NIBBLE
;Transforms the HEX-character in A to a value fitting in a nibble
;***************************************************************************
CHAR2NIB:
        SUB     '0'
        CP      015h
        JR      NC, C2N_DONE
        SUB     005h
c2N_DONE:
        AND     0Fh
        RET
