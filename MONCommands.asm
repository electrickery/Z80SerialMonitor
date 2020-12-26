;***************************************************************************
;  PROGRAM:			MONCommands        
;  PURPOSE:			Subroutines for all monitor commands
;  ASSEMBLER:		TASM 3.2        
;  LICENCE:			The MIT Licence
;  AUTHOR :			MCook
;  CREATE DATE :	06 May 15
;***************************************************************************

;***************************************************************************
;HELP_COMMAND
;Function: Print help dialogue box
;***************************************************************************
HELPMSG1: DEFB 'ZMC80 Monitor Command List', 0Dh, 0Ah, EOS
HELPMSG2: DEFB '? - view command list', 0Dh, 0Ah, EOS
HELPMSG3: DEFB 'R - monitor reset', 0Dh, 0Ah, EOS
HELPMSG4: DEFB 'C - clear screen', 0Dh, 0Ah, EOS
HELPMSG5: DEFB 'D - print $80 bytes from specified location', 0Dh, 0Ah, EOS

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
			LD		A,0FFh				;Load $FF into Acc so MON_COMMAND finishes
			RET

;***************************************************************************
;MEMORY_DUMP_COMMAND
;Function: Print $80 databytes from specified location
;***************************************************************************
MDC_1: DEFB 'Memory Dump Command', 0Dh, 0Ah, EOS
MDC_2: DEFB 'Location to start in 4 digit HEX:',EOS
MDC_3: DEFB '     00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F', 0Dh, 0Ah, EOS

MDCMD:
			LD 		HL,MDC_1			;Print some messages 
			CALL    PRINT_STRING
			LD 		HL,MDC_2	
			CALL    PRINT_STRING
			CALL    GETHEXWORD		;HL now points to databyte location	
			PUSH	HL					;Save HL that holds databyte location on stack
			CALL    PRINT_NEW_LINE		;Print some messages
			CALL    PRINT_NEW_LINE
			LD 		HL,MDC_3	
			CALL    PRINT_STRING
			CALL    PRINT_NEW_LINE
			POP		HL					;Restore HL that holds databyte location on stack
			LD		C,10				;Register C holds counter of dump lines to print
MDLINE:	
			LD		B,16				;Register B holds counter of dump bytes to print
			CALL	PRINTHWORD			;Print dump line address in hex form
			LD		A,' '				;Print spacer
			CALL	PRINT_CHAR
			DEC		C					;Decrement C to keep track of number of lines printed
MDBYTES:
			LD		A,(HL)				;Load Acc with databyte HL points to
			CALL	PRINTHBYTE  		;Print databyte in HEX form 
			LD		A,' '				;Print spacer
			CALL	PRINT_CHAR	
			INC 	HL					;Increase HL to next address pointer
			DJNZ	MDBYTES				;Print 16 bytes out since B holds 16
			LD		B,C					;Load B with C to keep track of number of lines printed
			CALL    PRINT_NEW_LINE		;Get ready for next dump line
			DJNZ	MDLINE				;Print 10 line out since C holds 10 and we load B with C
			LD		A,0FFh				;Load $FF into Acc so MON_COMMAND finishes
			RET
			
