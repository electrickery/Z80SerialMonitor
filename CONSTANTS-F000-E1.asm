; Constants, extracted to make the versioned file hardware agnostic

ROM_BOTTOM: EQU    0F000h       ; Bottom address of ROM

RAM_BOTTOM: EQU    01800h       ; Bottom address of RAM

UART_1DAT:  EQU    0E1h         ; 1st channel data port
UART_1CTL:  EQU    0E3h         ; 1st channel control port
UART_2DAT:  EQU    0E0h         ; 2nd channel data port
UART_2CTL:  EQU    0E2h         ; 2nd channel control port


; Calculated values for version and locations line in startup banner and help text.
; Processing it and assemble-time reduces monitor code size.

    IF  (ROM_BOTTOM / 1000h LE 9)
ROMB1:      EQU     (ROM_BOTTOM / 1000h) + '0'
    ELSE
ROMB1:      EQU     (ROM_BOTTOM / 1000h) + 55  
    ENDIF
    
    IF  (((ROM_BOTTOM / 100h) & 0Fh) LE 9)
ROMB2:      EQU     ((ROM_BOTTOM / 100h) & 0Fh) + '0'
    ELSE
ROMB2:      EQU     ((ROM_BOTTOM / 100h) & 0Fh) + 55  
    ENDIF
    
    IF  ((ROM_BOTTOM / 10h) & 0Fh) LE 9
ROMB3:      EQU     ((ROM_BOTTOM / 10h) & 0Fh) + '0'
    ELSE
ROMB3:      EQU     ((ROM_BOTTOM / 10h) & 0Fh) + 55
    ENDIF
    
    IF  ((ROM_BOTTOM & 0Fh) & 0Fh) LE 9
ROMB4:      EQU     (ROM_BOTTOM & 0Fh)    + '0'
    ELSE
ROMB4:      EQU     (ROM_BOTTOM & 0Fh)    + 55
    ENDIF
    
    IF  RAM_BOTTOM / 1000h LE 9
RAMB1:      EQU     (RAM_BOTTOM / 1000h) + '0'
    ELSE
RAMB1:      EQU     (RAM_BOTTOM / 1000h) + 55
    ENDIF

    IF  ((RAM_BOTTOM / 100h) & 0Fh) LE 9
RAMB2:      EQU     ((RAM_BOTTOM / 100h) & 0Fh) + '0'
    ELSE
RAMB2:      EQU     ((RAM_BOTTOM / 100h) & 0Fh) + 55
    ENDIF

    IF  ((RAM_BOTTOM / 10h) & 0Fh) LE 9
RAMB3:      EQU     ((RAM_BOTTOM / 10h) & 0Fh) + '0'
    ELSE
RAMB3:      EQU     ((RAM_BOTTOM / 10h) & 0Fh) + 55
    ENDIF

    IF  (RAM_BOTTOM & 0Fh) LE 9
RAMB4:      EQU     (RAM_BOTTOM & 0Fh)  + '0'
    ELSE
RAMB4:      EQU     (RAM_BOTTOM & 0Fh)  + 55
    ENDIF

    IF  ((UART_BASE / 10h) & 0Fh) LE 9
UARTB1:     EQU     ((UART_BASE / 10h) & 0Fh) + '0'
    ELSE
UARTB1:     EQU     ((UART_BASE / 10h) & 0Fh) + 55
    ENDIF

    IF  (UART_BASE & 0Fh) LE 9
UARTB2:     EQU     (UART_BASE & 0Fh) + '0'
    ELSE
UARTB2:     EQU     (UART_BASE & 0Fh) + 55
    ENDIF
