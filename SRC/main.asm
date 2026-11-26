L_MON:	.EQU	08000h+04000h
	.ORG	00100h
START:	DI
	XRA  A
	OUT	010h
	OUT	011h
	MVI  A, 033h	; ОЗУ: Банк 0, Банк 2
	OUT     00Eh	; режим ОЗУ
	LXI SP,	08000h
	LXI  H, L_PAK
	LXI  D, L_MON
	CALL	UNPACK	; распаковка
	JMP	L_MON
;
	.db "-= (c) Ларин "
	.db "Юрий aka IMPROVER"
	.db " =- 25/11/2026 "
;
UNPACK:
	#include lzo28_f.asm
L_PAK:	.end
	
