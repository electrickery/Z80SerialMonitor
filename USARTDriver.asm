;***************************************************************************
;  PROGRAM:			USARTDriver        
;  PURPOSE:			Subroutines for a Intel/AMD 8251A
;  ASSEMBLER:		Z80asm      
;  LICENCE:			The MIT Licence
;  AUTHOR :			F.J. Kraan based on UARTDriver from MCook
;  CREATE DATE :	2023-01-12
;***************************************************************************

; CTC channel 2 init for 9600 baud clock rate
;
; MPF xtal:  3,579545 MHz, CPU clock divided by 2: 1789772,5 MHz
; 9600 Bd, using 1x clock: 9600 Hz
; 16x prescaler value: 111860,78125 / 9600 = 11,652164714 =>> 12
;

; time constant: 111860,78125

CTC0:    EQU     CTC_BASE + 0
CTC1:    EQU     CTC_BASE + 1
CTC2:    EQU     CTC_BASE + 2
CTC3:    EQU     CTC_BASE + 3

; CTC control register:
;       7 6 5 4 3 2 1 0 B
;       | | | | | | | |
;       | | | | | | | Control Word/Vector (0=vector, 1=control word)
;       | | | | | | Reset (0=continue, 1=software reset)
;       | | | | | Constant (0=none, 1=follows, next data)
;       | | | | Trigger (0=load, 1=CLK/TRG)
;       | | | Edge (0=falling, 1=rising)
;       | | Prescaler (0=16, 1=256)
;       | Mode (0=timer, 1=counter)
;       Interrupt (0=disable, 1=enable)

; i8251A registers
URTDA:  EQU     UART_BASE + 0	;8251 UART Data Port
URTCNT: EQU     UART_BASE + 1	;8251 UART Control Port
URTSTA: EQU     UART_BASE + 1	;8251 UART Status Port

; i8251A mode instruction format control register
;		7 6 5 4 3 2 1 0 B
;       | | | | | | |/
;		| | | | |/  baud rate factor: 0 1 - 1x, 1 0 - 16x, 1 1 - 64x
;		| | | | char length: 1 1 - 8 bits
;		| | | parity enable: 0 - disable, 1 - enable
;		|/  parity gen: 0 - odd, 1 - even
;		stop bit count: 0 1 - 1 bit, 10 - 1.5 bit, 1 1 - 2 bits
;		0 1 0 0 1 1 0 1 = 4Dh ; 1 stop bit, no parity, 8 bits, 1x clock
;
; i8251A command instruction definition
;  EH  - 0 -
;  IR  - 0 -
;  RTS - 1 - set RTS line
;  ER  - 1 -
;  BRK - 0 - send BREAK
;  RE  - 1 -
;  DTR - 1 - set DTR line
;  TE  - 1 - - 00110111b - 37h
;
; i8251A status read register
;       7 6 5 4 3 2 1 0
;		| | | | | | | |
;		| | | | | | | TxRDY: 0 - not ready, 1 - ready
;		| | | | | | RxRDY: 0 - not ready, 1 - ready
;		| | | | | TxEMPTY: 0 - not empty, 1 - empty
;		| | | | PE: 1 - parity error detected
;		| | | OE: 1 - overrun error detected
;		| | FE: 1 - framing error detected
;		| SYNDET:
;		DSR:
TX_RDY:  EQU 00000001B ; just the TxRDY bit
RX_RDY:  EQU 00000010B ; just the RxRDY bit

;
XOFF:   EQU     013h
XON:    EQU     015h



;***************************************************************************
;UART_INIT
;Function:  Initialize CTC baudrate clock based on 06Ch DIPs lower nibble
;           Initialize the UART to 1x BAUD Rate clock, 
; 8 bits, 1 stop bit, no parity, enable Tx and Rx
;***************************************************************************
UART_INIT:

; CTC_INIT
        LD A, 00000011B ; int off, timer on, prescaler=16, don't care ext. TRG edge,
                        ; start timer on loading constant, no time constant follows
                        ; sw­rst active, this is a ctrl cmd
;        OUT (CTCH0), A  ; CH0 is on hold now
;        OUT (CTCH1), A  ; CH1 is on hold now
;        OUT (CTCH3), A  ; CH3 is on hold now

;CH2_INIT:
        IN		A,(SPEED)	;read baud rate switch
        AND		0FH
        LD		E,A
        CP		0101B       ;on-off-on-off
        LD		A,47H       ;channel control with
                            ;timer mode
        JR		C,HIGSPD
        LD		A,47H		;channel control with
                            ;counter mode
HIGSPD	OUT		(CTC2),A
		LD		HL,BDTAB	;baud rate table
		LD		D,0
		ADD		HL,DE
		LD		A,(HL)		;timer(counter)constant
		OUT		(CTC2),A

;P8251A_INIT:
		LD		HL,INIURT	;initialize USART
		LD		B,6
INIT	LD		C,(HL)			;PORT
		INC		HL		;(HL)=data
		OUTI
		JR		NZ,INIT
        
        ;Showing selected BAUD rate on display
        CALL    DSPBAUD
        RET

INIURT	DEFB	URTCNT
		DEFB	0			;3 null bytes reset USART
		DEFB	URTCNT
		DEFB	0
		DEFB	URTCNT
		DEFB	0
		DEFB	URTCNT
		DEFB	40H
		DEFB	URTCNT
		DEFB	8EH			;mode byte
		DEFB	URTCNT
		DEFB	37H			;command byte


MSGTSZ: EQU     00Bh            ; number of valid BAUD rate settings

; Routine to show selected BAUD rate on MPF-IPlus display.
; TODO: add a timeout, in addition to the extra key press.
;  
      
DISPBF: EQU     0FF2Ch ; Display Buffer
TEMP1:  EQU     0FEFAh ; Temporary Storage

CLEAR:  EQU     009B9H ; Clear DISPBF, reset DISP and OUTPTR.
MSG:    EQU     009CAH ; Convert ASCII from INPBF to display patterns in DISPBF, until a <CR> is found. HL is pointer.
DEC_SP: EQU     00399h ; Put FFh in (DISP) and (DISP)+1. This erases the cursor in the display buffer.
SCAN1:  EQU     0029BH ; Scan keyboard once. Set carry flag to 1 if no key is pressed. Returned key as a position code.


DSPBAUD:
        CALL    CLEAR
        CALL    WAIT4KB         ;
        IN      A, (SPEED)      ; get DIP value
        AND     00Fh            ; mask upper nibble
        CP      MSGTSZ          ; compare with highest valid value
        JR      NC, DIPNOK      ; Jump when not Ok
        PUSH    AF              ; Calculate address pointer matching the BAUD
        RLC     A               ;  multiply
        RLC     A               ;   by 4
        LD      B, 0            ;
        LD      C, A            ;
        POP     AF              ;
        ADD     A, C            ; add original value,
        LD      C, A            ;  making it a * 4 + a = a * 5
        LD      HL, BTXT        ;
        ADD     HL, BC          ;
        JR      DISPBD          ; skip the error config
        
DIPNOK:
        LD      HL, BERR        ; Point HL to 'error' BAUD rate text
        JR      DISPBD          ;
        
DISPBD:
        CALL    MSG             ; put BAUD rate in input buffer
        LD      HL, BAUD        ;
        CALL    MSG             ; put remaining config in input buffer
        CALL    DEC_SP          ; erase pointer
        
        LD      IX, DISPBF      ;
DSPWAIT:
        CALL    SCAN1           ;
        JR      C, DSPWAIT      ; wait for key here. ToDo: add timeout ~ 1 s.

ENDWAIT:
        RET                     ;
        
WAIT4KB:                        ; Wait until keyboard is free
        CALL    SCAN1           ;
        JR      NC, WAIT4KB     ; Key still pressed
        RET

;
BTXT:
B50:    DEFB    '  50', 0Dh ; 0
B75:    DEFB    '  75', 0Dh ; 1
B110:   DEFB    ' 110', 0Dh ; 2
B150:   DEFB    ' 150', 0Dh ; 3
B200:   DEFB    ' 200', 0Dh ; 4
B300:   DEFB    ' 300', 0Dh ; 5
B600:   DEFB    ' 600', 0Dh ; 6
B1k2:   DEFB    '1200', 0Dh ; 7
B2k4:   DEFB    '2400', 0Dh ; 8
B4k8:   DEFB    '4800', 0Dh ; 9
B9k6:   DEFB    '9600', 0Dh ; A
BERR:   DEFB    '????', 0Dh ; B

BAUD:   DEFB    ' BAUD, 8N1', 0Dh

BDTAB	DEFB	70			;50 BAUD (TIMER MODE)
		DEFB	47			;75 BAUD
		DEFB	32			;110 BAUD
		DEFB	23			;150 BAUD
		DEFB	18			;200 BAUD
		DEFB	93			;300 BAUD (COUNTER MODE)
		DEFB	47			;600 BAUD
		DEFB	23			;1200 BAUD
		DEFB	12			;2400 BAUD
		DEFB	6			;4800 BAUD
		DEFB	3			;9600 BAUD

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
        IN      A, (URTSTA)     ; 
        AND     TX_RDY          ; Mask other bits, not-0 means buffer free
        JR      Z, WAITTXRDY    ; If not, wait
        RET

;***************************************************************************
;UART_TX_SEND
;Function: Transmit character in A to DART
;***************************************************************************
TX_SEND:
        OUT     (URTDA), A      ; Out it goes!
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
; UART_RX_CHK
; Function: Non-blocking receive check
;***************************************************************************
RX_CHK:
        IN      A, (URTSTA)     ; 
        AND     RX_RDY          ; Mask other bits, not-0 means some char arrived
        RET
        
;***************************************************************************
;UART_RX
;Function: Receive character in UART to A; wait for char
;***************************************************************************
UART_RX:
        CALL    UART_RX_RDY     ; Make sure UART has received something
        IN      A, (URTDA)      ; Get it
        RET
        
;***************************************************************************
;UART_RX_READY
;Function: Check if UART is ready to receive - blocking receive check
;***************************************************************************
UART_RX_RDY:
RX_NOT_RDY:
        CALL    RX_CHK
        JR      Z, RX_NOT_RDY   ; If rx_ready_bit zero, wait
        RET
