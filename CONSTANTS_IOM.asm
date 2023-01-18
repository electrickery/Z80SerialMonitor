; Constants, extracted to make the versioned file hardware agnostic

ROM_BOTTOM: EQU    0B000h       ; Bottom address of ROM

RAM_BOTTOM: EQU    0E000H       ; Bottom address of RAM

;IOM-MPF-IP ports:
UART_BASE:  EQU    060h         ; Base port address, P8251A/USART uses 2 ports.
CTC_BASE:   EQU    064H         ; Base port address for Z80 CTC, only CTC2 is used.
PIO_BASE:   EQU    068h         ; Pase port address for Z80 PIO, not used.
SPEED:      EQU    06Ch         ; DIP-switches for BAUD rate.
