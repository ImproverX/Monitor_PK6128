	.ORG	0FDA0h
MARK:	.db 0FFh	; метка, чтобы ЕДАСМ не писал "мало памяти"
	.ORG	0FE00h
#define STEK1	0FFB0h	; для CALL 5, BIOS
#define STEK2	00000h	; для RST 7
#define STEK3	0FFB0h	; для RST 5 0FF00h
;
#include "vars.inc"
;
L_CAL5:	DI
	LXI  H,	0
	DAD  SP
	LXI SP,	STEK1
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	PUSH H
	EI
	CALL	M_0005	
	DI
	POP  H
	PUSH PSW
	XRA  A		; ОЗУ: Банк 0, Банк 1
	OUT     00Eh	; режим ОЗУ
	POP  PSW
	SPHL
	EI
	RET
;
L_RST7:	PUSH	H
	PUSH	PSW
	LXI	H,0
	DAD SP
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	LXI SP,	STEK2
	CALL	M_0038
	SPHL
	XRA  A		; ОЗУ: Банк 0, Банк 1
	OUT     00Eh	; режим ОЗУ
	POP	PSW
	POP	H
	EI
	RET
;
L_RST5: DI
	SHLD	L_R5HL+1
	POP  H		; адрес возврата
	DCX  H
	SHLD	L_R5AD+1
	PUSH PSW	; сохраняем признаки
	LXI  H, 00002h	; ?
	DAD SP
	POP  PSW
	LXI SP,	STEK3
	PUSH PSW	; =PSW
	PUSH H		; =SP
L_R5HL:	LXI  H, 0
	PUSH H		; =HL
L_R5AD:	LXI  H, 0
;;	PUSH H		; =ADR
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	JMP	M_0028
;
INIT:	DI
;	PUSH D
;	PUSH B
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	XRA  A
	JMP	BIOS01
;
BIOS:	DI
	XCHG
	XTHL		; HL:=адрес вызова, DE->стек; DE:=HL
	PUSH B		; BC->стек
	MOV  B, A
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	MOV  A, L
	SUI	3
BIOS01:	STA	BIOS02+1
	LXI  H,	0
	DAD SP
	SHLD	BIOS05+1	; SP
	LXI SP,	STEK1
	XCHG		; восстанавливаем HL
	MOV  A, B
	EI
BIOS02:	CALL	MBIOS	;<<<< изменяется
	DI
BIOS05:	LXI  SP, 0
	MOV  B, A
	MVI  A, 0	; ОЗУ: Банк 0, Банк 1
	OUT	00Eh	; режим ОЗУ
	MOV  A, B
	POP  B
	POP  D
	EI
	RET
;
RUN:	STA	Rx00+1	; <<< запуск программ G
	MVI  A, 0	; ОЗУ: Банк 0, Банк 1
	OUT	00Eh	; режим ОЗУ
Rx00:	MVI  A, 0
	EI
RxSTA:	JMP	0
;	RET
;
RUNC:	XRA  A		; ОЗУ: Банк 0, Банк 1	<<< запуск программ C
	OUT	00Eh	; режим ОЗУ
	PUSH H
	LXI  H, RRET
	XTHL		; адрес возврата в стек
	EI
	PCHL		; >> переход к подпрограмме с передачей значений BC и DE
;
RRET:	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1	<<< возврат из C
	OUT     00Eh	; режим ОЗУ
	JMP	0	; рестарт (-> L_6000)
;
INTAP:	PUSH B		; @INTAP ввод байта с магнитной ленты
	PUSH D
	MVI  C, 000h
	MOV  D, A
	IN	001h
	ANI	010h
	MOV  E, A
IT01:	IN	001h
	ANI	010h
	CMP  E
	JZ	IT01
	RLC
	RLC
	RLC
	RLC
	MOV  A, C
	RAL
	MOV  C, A
	CALL	IT10
	IN	001h
	ANI	010h
	MOV  E, A
	MOV  A, D
	ORA  A
	JP	IT04	; >> если A < 80h
	MOV  A, C
	CPI	0E6h
	JNZ	IT02
	XRA  A
	STA     ITx5+1	;D_7FFB
	JMP	IT03
;
IT02:	CPI	019h
	JNZ	IT01
	MVI  A, 0FFh
	STA     ITx5+1	;D_7FFB
IT03:	MVI  D, 009h
IT04:	DCR  D
	JNZ	IT01
ITx5:	MVI  A, 0	;LDA     D_7FFB
	XRA  C
	POP  D
	POP  B
	RET
;
IT10:
ITx10:	MVI  A, 05Bh	;LDA	D_7FF5
IT11:	DCR  A
	JNZ	IT11
	IN	001h
	ANI	040h
	JZ	INIT	; рестарт
	RET
;
	.ORG	L_CAL5+100h	;0FF00h
L_BIOS:	JMP	INIT	; +00	@INIT	-- рестарт
	CALL	BIOS	; +03	@KEY	-- ввод символа с клавиатуры,	выход: А = код
	JMP	INTAP	; +06	@INTAP	-- ввод байта с магнитной ленты, A=FF - с поиском синхробайта, =08 - без поиска, выход А = полученный байт
	CALL	BIOS	; +09	@CONOUT	-- вывод на экран символа из C
	JMP	OUTAP	; +0C	@OUTAP	-- вывод на МГ байта из A
	CALL	BIOS	; +0F	@LIST	-- вывод на принтер символа (с перекодировкой) из C
	CALL	BIOS	; +12	@CONIN	-- опрос статуса клавиатуры,	выход A=FF - клавиша нажата, =00 - не нажата
	CALL	BIOS	; +15	@DUMP	-- вывод числа в HEX из A
	CALL	BIOS	; +18	@SPIC	-- вывод строки до 00h с адреса из HL (банк 0 и 1)
	CALL	BIOS	; +1B	@INKEY	-- чтение с клавиатуры,		выход A=FF - клавиша нажата, =XX - код клавиши
;
OUTAP:	PUSH B		; ? @OUTAP << A (число) -- вывод на МГ
	PUSH PSW
	MOV  B, A
	MVI  C, 008h
OT01:	MOV  A, B
	RLC
	MOV  B, A
	MVI  A, 001h
	CALL	OT10
	MVI  A, 000h
	CALL	OT10
	DCR  C
	JNZ	OT01
	POP  PSW
	POP  B
	RET
;
OT10:	XRA  B
	ANI	001h
	OUT	000h
OTx10:	MVI  A, 03Ch	;LDA     D_7FF4
	JMP	IT11
;
FINAL:	.ORG	MARK+FreeSpace-1
	.db 0
	.END
