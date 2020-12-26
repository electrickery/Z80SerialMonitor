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
;PRINT_NEW_LINE
;Function: Prints carriage return and line feed
;***************************************************************************			
NEW_LINE_STRING: 	DEFB 0Dh, 0Ah ,EOS

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
            JP      NC,CIH1 	;Yes - Jump / No - Continue
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
            CALL    CHAR_ISHEX      	;Is it a hex digit?
            JP      NC,GETHEXNIB 	 	;Yes - Jump / No - Continue
			CALL    PRINT_CHAR
			CP      '9' + 1         	;Is it a digit less or equal '9' + 1?
            JP      C,GHN1 				;Yes - Jump / No - Continue
            SUB     07h             	;Adjust for A-F digits
GHN1:                
			SUB     '0'             	;Subtract to get nib between 0->15
            AND     0Fh             	;Only return lower 4 bits
            RET	
				
;***************************************************************************
;GET_HEX_BTYE
;Function: Gets HEX byte into A
;***************************************************************************
GETHEXBYTE:
            CALL    GETHEXNIB			;Get high nibble
            RLC     A					;Rotate nibble into high nibble
            RLC     A
            RLC     A
            RLC     A
            LD      B,A					;Save upper four bits
            CALL    GETHEXNIB			;Get lower nibble
            OR      B					;Combine both nibbles
            RET				
			
;***************************************************************************
;GET_HEX_WORD
;Function: Gets two HEX bytes into HL
;***************************************************************************
GETHEXWORD:
			PUSH    AF
            CALL    GETHEXBYTE		;Get high byte
            LD		H,A
            CALL    GETHEXBYTE    	;Get low byte
            LD      L,A
            POP     AF
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
            PUSH    BC
            LD		B,A					;Save for low nibble
            RRCA						;Rotate high nibble into low nibble
			RRCA
			RRCA
			RRCA
            CALL    PRINTHNIB		;Print high nibble
            LD		A,B					;Restore for low nibble
            CALL    PRINTHNIB		;Print low nibble
            POP     BC					;Restore registers
            POP		AF
			RET
			
;***************************************************************************
;PRINT_HEX_WORD
;Function: Prints the four hex digits of a word to the serial line from HL
;***************************************************************************
PRINTHWORD:     
			PUSH 	HL
            PUSH	AF
            LD		A,H
			CALL	PRINTHBYTE		;Print high byte
            LD		A,L
            CALL    PRINTHBYTE		;Print low byte
            POP		AF
			POP		HL
            RET			
