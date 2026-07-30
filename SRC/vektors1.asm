	.ORG	0FDA0h
MARK:	.db 0FFh	; метка, чтобы ЕДАСМ не писал "мало памяти"
	.ORG	0FE00h
#define STEK1	0FFA0h	; для CALL 5, BIOS
#define STEK2	00000h	; для RST 7
#define STEK3	0FFA0h	; для RST 5 0FF00h
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
	XRA  A
	JMP	BIOS00
;
BIOS:	DI
	SHLD	BIOS03+1
	STA	BIOS04+1
	POP	H
	MOV	A,L
	SUI	3
BIOS00:	STA	BIOS02+1
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	JNZ	BIOS01	; >> не INIT
	MVI  A, 0C3h	; JMP ...
	STA     M_0000	;
	STA     M_0005	;
	STA     M_0038	;
	LXI  H, MBIOS	; рестарт
	SHLD	M_0000+1	; ... MBIOS
	LXI  H, CALL5L
	SHLD	M_0005+1	; ... CALL5L
	LXI  H, RST7L
	SHLD	M_0038+1	; ... RST7L
BIOS01:	LXI  H,	0
	DAD SP
	SHLD	BIOS05+1	; SP
	LXI SP,	STEK1
BIOS03:	LXI  H, 0
BIOS04: MVI  A, 0
	EI
BIOS02:	CALL	MBIOS	;<<<< изменяется
	DI
BIOS05:	LXI  SP, 0
	STA	BIOS06+1
	MVI  A, 0	; ОЗУ: Банк 0, Банк 1
	OUT	00Eh	; режим ОЗУ
BIOS06:	MVI  A, 0	; =========================
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
	.ORG	L_CAL5+100h	;0FF00h
L_BIOS:	JMP	INIT	; +00	@INIT	-- рестарт
	CALL	BIOS	; +03	@KEY	-- ввод символа с клавиатуры,	выход: А = код
	CALL	BIOS	; +06	@INTAP	-- ввод байта с магнитной ленты, A=FF - с поиском синхробайта, =08 - без поиска, выход А = полученный байт
	CALL	BIOS	; +09	@CONOUT	-- вывод на экран символа из C
	CALL	BIOS	; +0C	@OUTAP	-- вывод на МГ байта из C
	CALL	BIOS	; +0F	@LIST	-- вывод на принтер символа (с перекодировкой) из C
	CALL	BIOS	; +12	@CONIN	-- опрос статуса клавиатуры,	выход A=FF - клавиша нажата, =00 - не нажата
	CALL	BIOS	; +15	@DUMP	-- вывод числа в HEX из A
	CALL	BIOS	; +18	@SPIC	-- вывод строки до 00h с адреса из HL (банк 0 и 1)
	CALL	BIOS	; +1B	@INKEY	-- чтение с клавиатуры,		выход A=FF - клавиша нажата, =XX - код клавиши
;
FINAL:	.ORG	MARK+FreeSpace-1
	.db 0
	.END
