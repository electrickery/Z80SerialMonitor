; Constants, extracted to make the versioned file hardware agnostic

ROM_BOTTOM: EQU    02000h       ; Bottom address of ROM

RAM_BOTTOM: EQU    01800h       ; Bottom address of RAM

UART_BASE:  EQU    0E1h         ; Base port address, DART uses 4 ports , E0h+E2h is A, E1h+E3h is B
