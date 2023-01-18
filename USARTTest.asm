; USART test

UART_BASE:  EQU    060h         ; Base port address, P8251A/USART uses 2 ports.
CTC_BASE:   EQU    064H         ; Base port address for Z80 CTC, only CTC2 is used.
PIO_BASE:   EQU    068h         ; Pase port address for Z80 PIO, not used.
SPEED:      EQU    06Ch         ; DIP-switches for BAUD rate.

EOS:    EQU 00h

    ORG     0B000h
    
    CALL    UART_INIT
    
    LD      HL, BANNER
    CALL    UART_PRNT_STR
    
    LD      A, '>'
    
LOOP:
    CALL    UART_TX
    
    CALL    UART_RX
    
    ADD     A, 1
    
    JR      LOOP
    
    HALT
    
    INCLUDE	USARTDriver.asm

BANNER: DEFB    'Testcode for IOM-MPF-IP 8251 Usart.', 00h

    END
