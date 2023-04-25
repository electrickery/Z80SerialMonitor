;***************************************************************************
;  PROGRAM:			CFDriver        
;  PURPOSE:			Subroutines for a CF Card
;  ASSEMBLER:		TASM 3.2        
;  LICENCE:			The MIT Licence
;  AUTHOR :			MCook
;  CREATE DATE :	19 June 15
;***************************************************************************


CFBASE:		EQU		0F8h
CFSECT_BUFF:EQU     RAM_BOTTOM + 0100h
CFSECT_END:	EQU		CFSECT_BUFF + 0200h
;EOS:		EQU		00h
;CF_PROMPT:	


;PRINT_STRING:EQU	0F000h

;The addresses that the CF Card resides in I/O space.
;Change to suit hardware.
CFDATA:		EQU	CFBASE + 00h		; Data (R/W)
CFERR:		EQU	CFBASE + 01h		; Error register (R)
CFFEAT:		EQU	CFBASE + 01h		; Features (W)
CFSECCO:	EQU	CFBASE + 02h		; Sector count (R/W)
CFLBA0:		EQU	CFBASE + 03h		; LBA bits 0-7 (R/W, LBA mode)
CFLBA1:		EQU	CFBASE + 04h		; LBA bits 8-15 (R/W, LBA mode)
CFLBA2:		EQU	CFBASE + 05h		; LBA bits 16-23 (R/W, LBA mode)
CFLBA3:		EQU	CFBASE + 06h		; LBA bits 24-27 (R/W, LBA mode)
CFSTAT:		EQU	CFBASE + 07h		; Status (R)
CFCMD:		EQU	CFBASE + 07h		; Command (W)


;***************************************************************************
;CF_INIT
;Function: Initialize CF to 8 bit data transfer mode
;***************************************************************************	
CF_MSG_i: DEFB 0Dh, 0Ah, 'CF Card Initialized', 0Dh, 0Ah, EOS
CF_INIT:
	CALL	CF_LP_BUSY
	LD		A,01h						;LD features register to enable 8 bit
	OUT		(CFFEAT),A
	CALL	CF_LP_BUSY
	LD		A,0EFh						;Send set features command
	OUT		(CFCMD),A
	CALL	CF_LP_BUSY
	LD		A, 00h
	LD		(CF_LBA0), A
	LD		(CF_LBA1), A
	LD		(CF_LBA2), A
	LD		(CF_LBA3), A
	INC		A
	LD		(CF_SECCNT), A
	LD 		HL,CF_MSG_i					;Print some messages 
	CALL    PRINT_STRING
	RET

;***************************************************************************
;LOOP_BUSY
;Function: Loops until status register bit 7 (busy) is 0
;***************************************************************************	
CF_LP_BUSY:
	IN		A, (CFSTAT)					;Read status
	AND		010000000b					;Mask busy bit
	JP		NZ,CF_LP_BUSY				;Loop until busy(7) is 0
	RET

;***************************************************************************
;LOOP_CMD_RDY
;Function: Loops until status register bit 7 (busy) is 0 and drvrdy(6) is 1
;***************************************************************************	
CF_LP_CMD_RDY:
	IN		A,(CFSTAT)					;Read status
	AND		011000000b					;mask off busy and rdy bits
	XOR		001000000b					;we want busy(7) to be 0 and drvrdy(6) to be 1
	JP		NZ,CF_LP_CMD_RDY
	RET

;***************************************************************************
;LOOP_DAT_RDY
;Function: Loops until status register bit 7 (busy) is 0 and drq(3) is 1
;***************************************************************************		
CF_LP_DAT_RDY:
	IN		A,(CFSTAT)					;Read status
	AND		010001000b					;mask off busy and drq bits
	XOR		000001000b					;we want busy(7) to be 0 and drq(3) to be 1
	JP		NZ,CF_LP_DAT_RDY
	RET
	
;***************************************************************************
;CF_RD_CMD
;Function: Gets a sector (512 bytes) into RAM buffer.
;***************************************************************************			
CF_RD_CMD:
	CALL	CF_LP_CMD_RDY				;Make sure drive is ready for command
	LD		A,020h						;Prepare read command
	OUT		(CFCMD),A					;Send read command
	CALL	CF_LP_DAT_RDY				;Wait until data is ready to be read
	IN		A,(CFSTAT)					;Read status
	AND		000000001b					;mask off error bit
	JP		NZ,CF_RD_CMD				;Try again if error
	LD 		HL,CFSECT_BUFF
	LD 		B,0							;read 256 words (512 bytes per sector)
CF_RD_SECT:
	CALL	CF_LP_DAT_RDY	
	IN 		A,(CFDATA)					;get byte of ide data	
	LD 		(HL),A
	INC 	HL
	CALL	CF_LP_DAT_RDY
	IN 		A,(CFDATA)					;get byte of ide data	
	LD 		(HL),A
	INC 	HL
	DJNZ 	CF_RD_SECT
	RET
	
;***************************************************************************
;CF_READ
;Function: Read sector 0 into RAM buffer.
;***************************************************************************	
CF_MSG1:  DEFB 0Dh, 0Ah, 'CF Card Read', 0Dh, 0Ah, EOS

CF_MSG21: DEFB 'Reading sector '
CF_MSG2h: DEFB '00000000'
CF_MSG22: DEFB 'h into RAM buffer...', 0Dh, 0Ah, EOS
CF_MSG2E: 

CF_MSG31: DEFB 'Sector '
CF_MSG3h: DEFB '00000000'
CF_MSG32: DEFB  'h read...', 0Dh, 0Ah, EOS
CF_MSG3E:

CF_READ:
	LD 		HL, CF_MSG1					;Print some messages 
	CALL    PRINT_STRING
	CALL	CF_MKMS2
	LD		HL, MSGBUF
	CALL    PRINT_STRING
	CALL 	CF_LP_BUSY
	LD 		A,(CF_SECCNT)
	OUT 	(CFSECCO),A					;Number of sectors at a time (512 bytes)
	CALL 	CF_LP_BUSY
	LD      A,(CF_LBA0)
	OUT		(CFLBA0),A					;LBA 0:7
	CALL 	CF_LP_BUSY
	LD      A,(CF_LBA1)
	OUT		(CFLBA1),A					;LBA 8:15
	CALL 	CF_LP_BUSY
	LD      A,(CF_LBA2)
	OUT 	(CFLBA2),A					;LBA 16:23
	CALL 	CF_LP_BUSY
	LD      A,(CF_LBA3)
	AND		00Fh						; Only LBA 24:27
	OR		0E0h						;Selects CF as master
	OUT 	(CFLBA3),A					;LBA 24:27 + DRV 0 selected + bits 5:7=111
	CALL	CF_RD_CMD
	CALL	CF_MKMS3
	LD		HL, MSGBUF
	CALL    PRINT_STRING
	RET
	
CF_PROMPT: DEFB	'CF> ', EOS

CF_CLMSB:
; clear message buffer
	LD		A, ' '
	LD		HL, MSGBUF
	LD		(HL), A
	LD		DE, MSGBUF
	INC		DE
	LD		B, 0
	LD		C, ULBUFSIZE
	DEC		C
	LDIR
	RET
	
;CF_MKMSG2
; Function: Construct CF message before reading in MSGBUF
CF_MKMS3:
	CALL	CF_CLMSB
	LD		HL, CF_MSG31
	LD		DE, MSGBUF
	LD		BC, CF_MSG3E - CF_MSG31
	LDIR
	LD		HL, MSGBUF + (CF_MSG3h - CF_MSG31)	; first digit position for CF_MSG31 in MSGBUF
	CALL	CFSECDG
	RET
	
;CF_MKMSG3
; Function: Construct CF message after reading in MSGBUF
CF_MKMS2:
	CALL	CF_CLMSB
	LD		HL, CF_MSG21
	LD		DE, MSGBUF
	LD		BC, CF_MSG2E - CF_MSG21
	LDIR
	LD		HL, MSGBUF + (CF_MSG2h - CF_MSG21)	; first digit position for CF_MSG21 in MSGBUF
	CALL    CFSECDG
	
	RET

	
CFSECDG:
	LD		A,(CF_LBA3)
	PUSH	AF
	CALL	SHFTNIB
	CALL	NIB2CHAR
	LD		(HL), A
	INC		HL
	POP		AF
	CALL	NIB2CHAR
	LD		(HL), A
	INC		HL
	
	LD		A,(CF_LBA2)
	PUSH	AF
	CALL	SHFTNIB
	CALL	NIB2CHAR
	LD		(HL), A
	INC		HL
	POP		AF
	CALL	NIB2CHAR
	LD		(HL), A
	INC		HL
	
	LD		A,(CF_LBA1)
	PUSH	AF
	CALL	SHFTNIB
	CALL	NIB2CHAR
	LD		(HL), A
	INC		HL
	POP		AF
	CALL	NIB2CHAR
	LD		(HL), A
	INC		HL
	
	LD		A,(CF_LBA0)
	PUSH	AF
	CALL	SHFTNIB
	CALL	NIB2CHAR
	LD		(HL), A
	INC		HL
	POP		AF
	CALL	NIB2CHAR
	LD		(HL), A
	
	RET
	

;***************************************************************************
;CF_ID_CMD
;Function: Issue the Identify Drive command and read the response into the data buffer
;***************************************************************************
CF_MSGID:	DEFB 0Dh, 0Ah, 'CF Card Identify Drive', 0Dh, 0Ah, EOS

CF_ID_CMD:
	LD		HL, CF_MSGID
	CALL    PRINT_STRING
	CALL 	CF_LP_BUSY
	CALL	CF_LP_CMD_RDY				;Make sure drive is ready for command
	LD		A,0ECh						;Prepare ID drive command
	OUT		(CFCMD),A					;Send ID drive command
	CALL	CF_LP_DAT_RDY				;Wait until data is ready to be read
	IN		A,(CFSTAT)					;Read status
	AND		000000001b					;mask off error bit
	JP		NZ,CF_ID_CMD				;Try again if error
	LD 		HL,CFSECT_BUFF
	LD 		B,0							;read 256 words (512 bytes per sector)
CF_ID1:
	CALL	CF_LP_DAT_RDY	
	IN 		A,(CFDATA)					;get byte of ide data	
	LD 		(HL),A
	INC 	HL
	CALL	CF_LP_DAT_RDY
	IN 		A,(CFDATA)					;get byte of ide data	
	LD 		(HL),A
	INC 	HL
	DJNZ 	CF_ID1
	RET


;***************************************************************************
;CF_WR_CMD
;Function: Puts a sector (512 bytes) from RAM buffer disk buffer and to the disk.
;***************************************************************************			
CF_WR_CMD:
	CALL	CF_LP_CMD_RDY				;Make sure drive is ready for command
	LD		A,0E8h						;Prepare fill buffer command
	OUT		(CFCMD),A					;Send write buffer command
;...	
	
	CALL	CF_LP_CMD_RDY				;Make sure drive is ready for command
	LD		A,030h						;Prepare write command
	OUT		(CFCMD),A					;Send write buffer command
	CALL	CF_LP_DAT_RDY				;Wait until drive is ready to be written
	IN		A,(CFSTAT)					;Read status
	AND		000000001b					;mask off error bit
	JP		NZ,CF_WR_CMD				;Try again if error
	
	
