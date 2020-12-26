;***************************************************************************
;  PROGRAM:			DARTDriver        
;  PURPOSE:			Subroutines for a Z80 DART
;  ASSEMBLER:		Z80asm      
;  LICENCE:			The MIT Licence
;  AUTHOR :			F.J. Kraan based on UARTDriver from MCook
;  CREATE DATE :	2020-12-25
;***************************************************************************

;The addresses that the CTC & DART resides in I/O space.
;Change to suit hardware.
CTCH0:    EQU     040H
CTCH1:    EQU     041H
CTCH2:    EQU     042H
CTCH3:    EQU     043H

DRTDA:   EQU     060H
DRTDB:   EQU     061H
DRTCA:   EQU     062H
DRTCB:   EQU     063H

; useful patterns
TXBUFEMPTY:     EQU     000000100b
RXCHARAVL:      EQU     000000001b		
		
;***************************************************************************
;UART_INIT
;Function: Initialize the UART to BAUD Rate 9600 (1.8432 MHz clock input)
;***************************************************************************
UART_INIT:
CTC_INIT:  LD A, 00000011B ; int off, timer on, prescaler=16, don't care ext. TRG edge,
                                ; start timer on loading constant, no time constant follows
                                ; sw­rst active, this is a ctrl cmd
           OUT (CTCH0),A     ; CH0 is on hold now
           OUT (CTCH1),A     ; CH1 is on hold now
           OUT (CTCH3),A     ; CH3 is on hold now

DARTB_INIT:
	       LD A, 00000111B ; int off, timer, prescaler=16, any edge,
                                ;  load trigger, constant following, reset, control word next
BADDRATE:  OUT (CTCH2), A
           LD A, 12        ; closest integer divider to 11.652164714
           OUT (CTCH2), A
                
DART_INIT:
INIT:   	LD      HL, DRTTB
       	 	LD      C, DRTCB
        	LD      B, 8
        	OTIR                    ; write 8 bytes from DRTTB to port DRTCB
            RET

DRTTB:
DRTWR0:            DEFB   00000000b
CHRES:             DEFB   00011100b
DRTWR4:            DEFB   00000100b
;X1+STOP1+NOPARITY: DEFB   00000100b
X1+STOP2+NOPARITY: DEFB   00001100b
DRTWR5:            DEFB   00000101b
TX8+TXEN:          DEFB   01101000b
DRTWR3:            DEFB   00000011b
RX8+RXEN:          DEFB   11000001b            
                	
;***************************************************************************
;UART_PRNT_STR:
;Function: Print out string starting at MEM location (HL) to 16550 UART
;***************************************************************************
UART_PRNT_STR:
			PUSH	AF
UARTPRNTSTRLP:
			LD		A,(HL)
            CP		EOS					;Test for end byte
            JP		Z,UART_END_PRNT_STR	;Jump if end byte is found
			CALL	UART_TX
            INC		HL					;Increment pointer to next char
            JP		UARTPRNTSTRLP	;Transmit loop
UART_END_PRNT_STR:
			POP		AF
			RET	 
			 	
;***************************************************************************
;UART_TX_READY
;Function: Check if UART is ready to transmit
;***************************************************************************
UART_TX_RDY:
WAITTXRDY:  IN      A, (DRTCB)		; 
            AND     TXBUFEMPTY		; Can we send the next char?
            JR      Z, WAITTXRDY	; If not, wait
            RET
	
;***************************************************************************
;UART_TX_SEND
;Function: Transmit character in A to UART
;***************************************************************************

TX_SEND:
			OUT     (DRTDB), A		; Out it goes!
			RET

;***************************************************************************
; UART_TX
; Function: Blocking TX routine
;***************************************************************************
UART_TX:
			PUSH	AF
			CALL	WAITTXRDY
			POP		AF
			CALL	TX_SEND
			RET

;***************************************************************************
;UART_RX_READY
;Function: Check if UART is ready to receive - blocking receive check
;***************************************************************************
UART_RX_RDY:
RX_NOT_RDY:	CALL	RX_CHK
            JR		Z, RX_NOT_RDY		; If not, wait
			RET

;***************************************************************************
; DART_RX_CHK
; Function: Non-blocking receive check		
;***************************************************************************
RX_CHK:
			IN      A, (DRTCB)		; 
            AND     RXCHARAVL		; Has some char arrived?
			RET			
	
;***************************************************************************
;UART_RX
;Function: Receive character in UART to A; wait for char
;***************************************************************************
UART_RX:
			CALL	UART_RX_RDY		; Make sure UART is ready to receive
            IN		A, (DRTDB)		; Get it
			RET			
