	.286
	.MODEL TINY
ASSUME	CS:CGR,DS:CGR
CGR	GROUP	COD,DAT
COD	SEGMENT	BYTE
ORG	100H
LEN_	EQU	(ENC-SAVE+EN-LOG_+15+100H)/16
SAVE	PROC	NEAR
	MOV	SP,100H
	MOV	AX,CS
	ADD	CS:[LEAVE_SEG_],AX
	ADD	CS:[LEAVE_SEG_2_],AX
	CALL	GET_CURSOR
	LEA	SI,CREDITS_
	CALL	WRITE_WORD
	CALL	PUT_CURSOR
	MOV	SI,80H
	MOV	AX,CS
	MOV	DS,AX
	MOV	ES,AX
	MOV	AH,'/'
	CALL	READ_FILE_STRING
	JC	READ_FILE_ERROR
	PUSH	DS
	MOV	DS,CS:[LEAVE_SEG_2_]
	CALL	READ_DRIVES;c,d,..
	POP	DS
SAVE_1:
	INC	SI
	CMP	BYTE PTR DS:[SI],0
	JZ	SAVE_1
	CALL	SEEK_FILE
	PUSH	SI
	LEA	SI,FILE_
	CALL	WRITE_WORD
	POP	SI
	MOV	DX,SI
	MOV	CS:[FILE_ADRESS_],DX
	CALL	WRITE_WORD
	LEA	SI,DEFFIS_
	CALL	WRITE_WORD	
	CALL	OPEN_FILE
	JC	ERROR
	MOV	CS:[LOG_],AX
	CALL	DETECT_VIRUS
	JC	ERROR
	LEA	SI,INFECTED_
	CALL	WRITE_WORD
	LEA	SI,DEFFIS_
	CALL	WRITE_WORD
	CALL	SAVE_RESTORE
	JC	ERROR
	CALL	ERASE_VIRUS
	JC	ERROR
	LEA	SI,OK_
EXIT:
	PUSH	CS
	POP	DS
	CALL	WRITE_WORD
	MOV	DX,CS:[FILE_ADRESS_]
	MOV	BX,CS:[LOG_]
	CALL	CLOSE_FILE
	CALL	PUT_CURSOR
	MOV	AX,4C00H
	INT	21h
READ_FILE_ERROR:
	LEA	SI,CALL_FORMAT_
	JMP	SHORT	EXIT
ERROR:
	LEA	SI,DETECT_ERROR_
	CMP	AX,80H
	JAE	WRITE_ERROR
	LEA	SI,UNRECOGNIZEBLE_ERROR_
	DEC	AX
	JZ	WRITE_ERROR
	LEA	SI,FILE_NOT_FOUND_
	DEC	AX
	JZ	WRITE_ERROR
	LEA	SI,PATH_NOT_FOUND_
	DEC	AX
	JZ	WRITE_ERROR
	LEA	SI,NO_MORE_DESCRIPTORS_
	DEC	AX
	JZ	WRITE_ERROR
	LEA	SI,ACCESS_DENIED_
	DEC	AX
	JZ	WRITE_ERROR
	LEA	SI,NOT_DESCRIPTOR_
	DEC	AX
	JZ	WRITE_ERROR
	LEA	SI,UNRECOGNIZEBLE_ERROR_
WRITE_ERROR:
	JMP	SHORT	EXIT
ENDP
include	openfile.lib
include	readfile.lib
include	lseek.lib
include	writfile.lib
include	closfile.lib
include	readfstr.lib
include	readdrvr.lib
include	seekfile.lib
include	writewrd.lib
include	getcurs.lib
include	compline.lib
include	putcurs.lib
ERASE_VIRUS	PROC	NEAR
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	DS
	MOV	AL,2;FROM END
	MOV	BX,CS:[LOG_]
	MOV	CX,65535
	MOV	DX,65536-1277
	CALL	LSEEK;CX:DX=NEW_SEEK
	JC	ERASE_EXIT
	XOR	CX,CX
	MOV	BX,CS:[LOG_]
	CALL	WRITE_FILE
ERASE_EXIT:
	POP	DS
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	RET
ENDP


DETECT_VIRUS	PROC	NEAR
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	DS
	MOV	AL,2;FROM END
	MOV	BX,CS:[LOG_]
	MOV	CX,65535
	MOV	DX,65536-1277
	CALL	LSEEK;CX:DX=NEW_SEEK
	JC	DETECT_EXIT
	MOV	CX,1277
	MOV	DS,CS:[LEAVE_SEG_2_]
	XOR	DX,DX
	MOV	BX,CS:[LOG_]
	CALL	READ_FILE
	JC	DETECT_EXIT
	MOV	SI,4C7H
	LEA	DI,VIR_LINE_
	MOV	CX,5
	CALL	CMP_LINE
	JC	DETECT_ERROR
DETECT_EXIT:
	POP	DS
	POP	DX
	POP	CX
	POP	BX
	RET
DETECT_ERROR:
	MOV	AX,80H
	JMP	SHORT	DETECT_EXIT
ENDP
SAVE_RESTORE	PROC	NEAR
	PUSH	AX
	PUSH	BX
	PUSH	DS
	PUSH	ES
	MOV	DS,CS:[LEAVE_SEG_]
	MOV	ES,CS:[LEAVE_SEG_2_]
	CALL	LOAD_PARAM_FILE
	CMP	WORD PTR DS:[0],'ZM'
	JZ	SAVE_EXEC
	MOV	AX,ES:[155H]
	MOV	DS:[1],AX
	JMP	SHORT	SAVE_OK
SAVE_EXEC:
	MOV	AX,ES:[13AH]
	MOV	DS:[14H],AX
	MOV	AX,ES:[13CH]
	SUB	AX,10H
	MOV	DS:[16H],AX
	MOV	AX,ES:[13EH]
	SUB	AX,10H
	MOV	DS:[0EH],AX
	MOV	AX,ES:[140h]
	MOV	DS:[10H],AX
	MOV	AX,ES:[13AH+1EH]
	MOV	DS:[1CH],AX

	MOV	AX,DS:[2]
	MOV	BX,DS:[4]
	SUB	AX,1277-1024
	JNC	SAVE_EXEC_1
	AND	AX,1FFH
	DEC	BX
SAVE_EXEC_1:
	SUB	BX,2
	MOV	DS:[2],AX
	MOV	DS:[4],BX
SAVE_OK:	
	CALL	SAVE_PARAM_FILE
	POP	ES
	POP	DS
	POP	BX
	POP	AX
	RET
ENDP
SAVE_PARAM_FILE	PROC	NEAR
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	XOR	AL,AL
	MOV	BX,CS:[LOG_]
	XOR	CX,CX
	MOV	DX,CX
	CALL	LSEEK
	MOV	BX,CS:[LOG_]
	MOV	CX,20H
	XOR	DX,DX
	MOV	DS,CS:[LEAVE_SEG_]
	CALL	WRITE_FILE
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	RET
ENDP
LOAD_PARAM_FILE	PROC	NEAR
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	XOR	AL,AL
	MOV	BX,CS:[LOG_]
	XOR	CX,CX
	MOV	DX,CX
	CALL	LSEEK
	MOV	BX,CS:[LOG_]
	MOV	CX,20H
	XOR	DX,DX
	MOV	DS,CS:[LEAVE_SEG_]
	CALL	READ_FILE
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	RET
ENDP
ENC:
ENDS
DAT	SEGMENT	BYTE
LOG_	DW	0
FILE_ADRESS_	DW	0
LEAVE_SEG_	DW	LEN_
LEAVE_SEG_2_	DW	LEN_+2
VIR_LINE_	DB	0ABH,0A5H,0A5H,0A5H,0A5H
CREDITS_	DB	'Skrylev AntiVirus Environment (C) 1996',0dh,0ah,0
CALL_FORMAT_	DB	'USAGE: SAVE <FILENAME>',0dh,0ah,0
FILE_	DB	'File ',0
FILE_NOT_FOUND_	DB	'not found',0dh,0ah,0	
PATH_NOT_FOUND_	DB	'Path to file not found',0dh,0ah,0
NO_MORE_DESCRIPTORS_	DB	'don''t open',0dh,0ah,0
ACCESS_DENIED_	DB	'Access to file id denied',0dh,0ah,0
NOT_DESCRIPTOR_	DB	'is not be used',0dh,0ah,0
UNRECOGNIZEBLE_ERROR_	DB	'Unrecognizeble error in file',0dh,0ah,0
DETECT_ERROR_	DB	'Ok',0dh,0ah,0
INFECTED_	DB	'Infected by COMTSR-1277',0
OK_	DB	'Cured',0dh,0ah,0
DEFFIS_	DB	' - ',0
EN:
ENDS
END	SAVE
	
