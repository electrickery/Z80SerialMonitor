; USART test

UART_BASE:  EQU    060h         ; Base port address, P8251A/USART uses 2 ports.
CTC_BASE:   EQU    064H         ; Base port address for Z80 CTC, only CTC2 is used.
PIO_BASE:   EQU    068h         ; Pase port address for Z80 PIO, not used.
SPEED:      EQU    06Ch         ; DIP-switches for BAUD rate.


    ORG     0B000h
    
    CALL    UART_INIT
    
    LD      A, '>'
    
LOOP:
    CALL    UART_TX
    
    CALL    UART_RX
    
    ADD     A, 1
    
    JR      LOOP
    
    HALT
    
    INCLUDE	USARTDriver.asm

    END
