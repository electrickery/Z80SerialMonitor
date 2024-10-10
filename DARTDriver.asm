;***************************************************************************
;  PROGRAM:			DARTDriver        
;  PURPOSE:			Subroutines for a Z80 DART
;  ASSEMBLER:		Z80asm      
;  LICENCE:			The MIT Licence
;  AUTHOR :			F.J. Kraan based on UARTDriver from MCook
;  CREATE DATE :	2020-12-25
;***************************************************************************

;The addresses of the DART in I/O space.
;Change to suit hardware.

;DRTDA:  EQU     UART_BASE   ;   060h
;DRTDB:  EQU     UART_BASE + 1
;DRTCA:  EQU     UART_BASE + 2
;DRTCB:  EQU     UART_BASE + 3

DRTDAT: EQU     UART_BASE
DRTCTL: EQU     UART_BASE + 2

; useful patterns
TXBUFEMPTY:  EQU     000000100b
RXCHARAVL:   EQU     000000001b
; unused
XOFF:   EQU     013h
XON:    EQU     015h

;***************************************************************************
;UART_INIT
;Function: Initialize the UART to 16x BAUD Rate clock, 
; 8 bits, 1 stop bit, no parity, enable Tx and Rx
;***************************************************************************
UART_INIT:
        LD      HL, DRTTB
        LD      C, DRTCTL
        LD      B, E_DRTTB - DRTTB
        OTIR                    ; write bytes from DRTTB to port DRTCB
        RET

DRTTB:                      ; alternate register select and values (not for WR0)
        DEFB   00011000b    ; DRTWR0 - Register pointer & modes. Channel reset.
        DEFB   00000100b    ; DRTWR4 - Tx/Rx misc. params & modes
        DEFB   01000100b    ;  X16+STOP1+NOPARITY
;       DEFB   00000100b    ;   X1+STOP1+NOPARITY
        DEFB   00000101b    ; DRTWR5 - Tx params & controls
        DEFB   01101000b    ;   TX8+TXEN
        DEFB   00000011b    ; DRTWR3 - Rx params & controls
        DEFB   11000001b    ;   RX8+RXEN
E_DRTTB:

;***************************************************************************
;UART_PRNT_STR:
;Function: Print out string starting at MEM location (HL) to Z80 DART
;***************************************************************************
UART_PRNT_STR:
        PUSH    AF
UARTPRNTSTRLP:
        LD      A,(HL)
        CP      EOS					;Test for end byte
        JP      Z,UART_END_PRNT_STR	;Jump if end byte is found
        CALL    UART_TX
        INC     HL					;Increment pointer to next char
        JP      UARTPRNTSTRLP	    ;Transmit loop
UART_END_PRNT_STR:
        POP     AF
        RET

;***************************************************************************
;UART_TX_READY
;Function: Check if UART is ready to transmit
;***************************************************************************
UART_TX_RDY:
WAITTXRDY:
        IN      A, (DRTCTL)		; 
        AND     TXBUFEMPTY		; Can we send the next char?
        JR      Z, WAITTXRDY	; If not, wait
        RET

;***************************************************************************
;UART_TX_SEND
;Function: Transmit character in A to DART
;***************************************************************************
TX_SEND:
        OUT     (DRTDAT), A		; Out it goes!
        RET

;***************************************************************************
; UART_TX
; Function: Blocking TX routine
;***************************************************************************
UART_TX:
        PUSH    AF
        CALL    UART_TX_RDY
        POP     AF
        CALL    TX_SEND
        RET

;***************************************************************************
;UART_RX_READY
;Function: Check if UART is ready to receive - blocking receive check
;***************************************************************************
UART_RX_RDY:
RX_NOT_RDY:
        CALL    RX_CHK
        JR      Z, RX_NOT_RDY		; If rx_ready_bit zero, wait
        RET

;***************************************************************************
; DART_RX_CHK
; Function: Non-blocking receive check		
;***************************************************************************
RX_CHK:
        IN      A, (DRTCTL)		; 
        AND     RXCHARAVL		; Mask other bits, has some char arrived?
        RET

;***************************************************************************
;UART_RX
;Function: Receive character in UART to A; wait for char
;***************************************************************************
UART_RX:
        CALL    UART_RX_RDY		; Make sure UART has received a char
        IN      A, (DRTDAT)		; Get it
        RET
