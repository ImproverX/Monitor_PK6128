#include "vars.inc"
;
	.ORG    CALL5L	; 04C80h
;
MSTEK:	.EQU	$-100h	; стек рабочий
KSTEK:	.EQU	$-80h	; стек при показе курсора
DSTEK:	.EQU	$	; стек при выводе символов
HSTEK:	.EQU	CALL5V-10h	;0FDF0h	; стек в верхней памяти для G и С (вар.1)
M_E000:	.EQU    0E000h	; конец экрана
;
L_5400:	MOV  A, C
	CPI	00Ch
	LXI  H, L_5431	; L_5430
	PUSH H
	RNC
	MVI  H, 000h
	MOV  L, C
	DAD  H
	LXI  B, D_5418
	DAD  B
	MOV  C, M
	INX  H
	MOV  H, M
	MOV  L, C
	PCHL
;
D_5418:	.dw L_5431	; 0 - сброс
	.dw L_5432	; 1 - ввод символа с клавиатуры
	.dw L_5439	; 2 - вывод на экран
	.dw L_5431	; 3 - RET
	.dw L_5431	; 4 - RET
	.dw L_5431	; 5 - RET
	.dw L_543D	; 6 - непосредственный ввод-вывод с консоли
	.dw L_5431	; 7 - RET
	.dw L_5431	; 8 - RET
	.dw L_544F	; 9 - печать строки до "$" (Банк 0, 1)
	.dw L_545C	;10 - ввод данных в буфер (Банк 0, 1)
	.dw L_54F2	;11 - статус клавиатуры
;
;L_5430:	RET
;
L_5431:	RET
;
L_5432:	CALL	L_54F5
	MOV  C, A
	JMP	L_7809	; вывод на экран символа A
;
L_5439:	MOV  C, E
	JMP	L_7809	; вывод на экран символа E
;
L_543D:	MOV  A, E
	CPI	0FFh
	JZ	L_5447
	MOV  C, E
	JMP	L_7809	; вывод на экран символа
;
L_5447:	CALL	L_7812	; опрос статуса клавиатуры
	ORA  A
	RZ
	JMP	L_54F5
;
L_544F:	XCHG
L_5450:	CALL	RBYTE	; чтение байта с адреса HL (банк 0 и банк 1)
;	MOV  A, M
	INX  H
	MOV  C, A
	CPI	024h
	RZ
	CALL	L_7809	; вывод на экран символа
	JMP	L_5450
;
L_545C:	XCHG		; << 10 - ввод данных в буфер
	SHLD	D_65FD	; адрес буфера ввода
	CALL	RBYTE	; чтение байта с адреса HL (банк 0 и банк 1)
	MOV  D, A	; размер буфера ввода
L_5460:	LXI  H, D_664C	; буфер ввода монитора
	MVI  M, 00Dh
	MVI  B, 000h
	MOV  E, B
L_5468:	PUSH H
	LXI  H, L_5468
	XTHL		; адрес возврата в стек
	CALL	L_54F5	; чтение с клавиатуры
	MOV  C, A
	CPI	008h
	JNZ	L_547E
	MOV  A, E
	ORA  A
	RZ		; -> L_5468
	DCR  E
	DCX  H
;L_547B:
	JMP	L_7809	; вывод на экран символа с возвратом на L_5468
;
L_547E:	CPI	018h
	JNZ	L_548B
	MOV  A, B
	CMP  E
	RZ
	INR  E
	INX  H
	JMP	L_7809	; вывод на экран символа с возвратом на L_5468 //L_547B
;
L_548B:	CPI	07Fh
	JNZ	L_54BA
	MOV  A, E
	ORA  A
	RZ
	DCR  E
	INR  D
	PUSH H
	MVI  C, 008h
L_5498:	CALL	L_7809	; вывод на экран символа
	MOV  A, M
	DCX  H
	MOV  M, A
	CPI	00Dh
	INX  H
	INX  H
	MOV  C, A
	JNZ	L_5498
	MVI  C, 020h
	CALL	L_7809	; вывод на экран символа
	MOV  A, B
	SUB  E
L_54AD:	MVI  C, 008h
	CALL	L_7809	; вывод на экран символа
	DCR  A
	JNZ	L_54AD
	DCR  B
	POP  H
	DCX  H
	RET
;
L_54BA:	CPI	00Dh
	JNZ	L_54C6
L_54BF:	POP  H		; подчистка стека
	LXI  H, D_664B
	MOV  M, B	; сохраняем длину строки -- сколько
	XCHG		; DE -- откуда
	LHLD	D_65FD	; адрес буфера ввода -- куда
	MOV  A, H
	ORA  L
	RZ		; был задан буфер 0000 -- внутренний буфер монитора
	INR  B
	INR  B
	DI
	MVI  A, B_MONW	; ОЗУ: {Банк 2 R | Банк 0 W}, Банк 1
	OUT     00Eh	; режим ОЗУ
L_54BZ:	INX  H
	LDAX D
	MOV  M, A
	INX  D
	DCR  B
	JNZ	L_54BZ	; цикл переноса буфера
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	EI
	RET
;
L_54C6:	CPI	020h
	RC		; >> возврат на L_5468
	INR  B
	INR  E
	PUSH H
L_54CC:	CALL	L_7809	; вывод на экран символа
	MOV  A, M
	MOV  M, C
	MOV  C, A
	INX  H
	CPI	00Dh
	JNZ	L_54CC
	DCR  D		; размер буфера -1
	JNZ	L_54E0
	POP  H		; цикл до конца буфера
	JMP	L_54BF
;
L_54E0:	MOV  M, C
	MOV  A, B
	SUB  E
	JZ	L_54EF
L_54E6:	MVI  C, 008h
	CALL	L_7809	; вывод на экран символа
	DCR  A
	JNZ	L_54E6
L_54EF:	POP  H
	INX  H
	RET		; возврат на L_5468
;
L_54F2:	JMP	L_7812	; опрос статуса клавиатуры
;
L_54F5:	CALL	L_7803	; ? @KEY
	CPI	003h
	RNZ
	MVI  A, 0C3h
	STA     M_0000	; ?
	LXI  H, L_7800
	SHLD	M_0001	; ?
	JMP	M_0000	; ?
;
L_5509:	XRA  A		; <<< G
	STA     D_6626
	LDA     D_662C	; = 0 (норм.)/ FF (запуск с минусом)
	ORA  A
	JZ	L_550Z
	XRA  A		; переключить на экран 1
	OUT     00Dh	; Номер банка Экрана
L_550Z:	CALL	L_64A8
	STA     D_6627
	CALL	L_62AF
	SHLD	D_662A
	XCHG
	SHLD	D_6628
	XCHG
	PUSH B
	XTHL
	POP  B
	JMP	L_552B
;
L_5524:	PUSH H
	LXI  H, D_6626
	MVI  M, 0FFh
	POP  H
L_552B:	DI
	JZ	L_5547
	JC	L_5535
	SHLD	D_66F8
L_5535:	ANI	07Fh
	DCR  A
	JZ	L_5547
	CALL	L_55A6	; установка RST5
	DCR  A
	JZ	L_5547
	MOV  E, C
	MOV  D, B
	CALL	L_55A6	; установка RST5
L_5547:	LXI  H, D_6605
	MVI  C, 008h
L_554C:	PUSH H
	MOV  A, M
	ORA  A
	JZ	L_5581
	INX  H
	MOV  E, M
	INX  H
	MOV  D, M
	PUSH H
	LDA     D_6626
	ORA  A
	JZ	L_557A	; >> запуск G
	LHLD	D_66F8
	MOV  A, E
	CMP  L
	JNZ	L_557A
	MOV  A, D
	CMP  H
	JNZ	L_557A
	POP  H
	POP  H
	SHLD	D_6602
	PUSH H
	MOV  A, M
	MVI  M, 000h
	STA     D_6601
	JMP	L_5581
;
L_557A:	POP  H
	INX  H
	LDAX D
	MOV  M, A
	XCHG
	MVI  M, 0EFh
L_5581:	POP  H
	LXI  D, 00004h	; ?
	DAD  D
	DCR  C
	JNZ	L_554C
	LXI  H,	M_0028
	MVI  M, 0C3h	; JMP ...
	MVI  A, B_MONW	; ОЗУ: {Банк 2 R | Банк 0 W}, Банк 1
	OUT     00Eh	; режим ОЗУ
	MVI  M, 0C3h	; JMP ...
VxR51:	LXI  H, RST5V
	SHLD	M_0029	; ... RST5V
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	LXI  H, L_5D5A
	SHLD	M_0029	; ... L_5D5A
	LXI  SP,D_66EE
	POP  D
	POP  B
	POP  PSW
	POP  H		; SP
	SPHL
	LHLD	D_66F8	; PS
VxRS1:	SHLD	RxSTAV+1	; адрес запуска
	LHLD	D_66F6	; HL
VxRN1:	JMP	RUNV
;	EI
;	RET
;
L_55A6:	PUSH PSW
	PUSH B
	LXI  H, D_6634
	MOV  A, M
	INR  M
	ORA  A
	JZ	L_55C1
	INX  H		; D_6634+1
	MOV  A, M
	INX  H		; D_6634+2
	MOV  B, M
	INX  H		; D_6634+3
	CMP  E
	JNZ	L_55C1
	MOV  A, B
	CMP  D
	JNZ	L_55C1
	DI
	MVI  A, B_MONW	; ОЗУ: {Банк 2 R | Банк 0 W}, Банк 1
	OUT     00Eh	; режим ОЗУ
	MOV  A, M
	STAX D
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	EI	
L_55C1:	INX  H
	MOV  M, E
	INX  H
	MOV  M, D
	INX  H
;	LDAX D
	XCHG
	CALL	RBYTE	; чтение байта с адреса HL (банк 0 и банк 1)
	XCHG
	MOV  M, A
	DI
	MVI  A, B_MONW	; ОЗУ: {Банк 2 R | Банк 0 W}, Банк 1
	OUT     00Eh	; режим ОЗУ
	MVI  A, 0EFh	; = 'RST 5'
	STAX D
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	EI	
	POP  B
	POP  PSW
	RET
;
L_55CE:	CALL	L_630D
	JZ	L_6318	; >> Ошибка
	CALL	L_63C7
	DCR  A
	JZ	L_55FE
	DCR  A
	JNZ	L_6318	; >> Ошибка
	PUSH H
	CALL	L_63C7
	POP  D
	PUSH H
	CALL	L_6382	; вывод 0Dh,0Ah
	DAD  D
	CALL	L_6398	; вывод HL в HEX
	CALL	L_6335	; вывод пробела
	POP  H
	XRA  A
	SUB  L
	MOV  L, A
	MVI  A, 000h
	SBB  H
	MOV  H, A
	DAD  D
	CALL	L_6398	; вывод HL в HEX
	JMP	L_6000	; рестарт
;
L_55FE:	XCHG
	CALL	L_6382	; вывод 0Dh,0Ah
	PUSH D
	PUSH D
	CALL	L_6392	; вывод DE в HEX
	CALL	L_6335	; вывод пробела
	MVI  A, 023h	; '#'
	CALL	L_6337	; вывод символа из A
	MVI  B, 085h
	LXI  H, D_66FA	; перевод в десятичное значение
L_5614:	MOV  E, M
	INX  H
	MOV  D, M
	INX  H
	XTHL
	MVI  C, 030h
L_561B:	MOV  A, L
	SUB  E
	MOV  L, A
	MOV  A, H
	SBB  D
	MOV  H, A
	JC	L_5628
	INR  C
	JMP	L_561B
;
L_5628:	DAD  D
	MOV  A, B
	ORA  A
	JP	L_563F
	PUSH PSW
	MOV  A, C
	CPI	030h
	JZ	L_5646
	CALL	L_6337	; вывод символа из A
	POP  PSW
	ANI	07Fh
	MOV  B, A
	JMP	L_5652
;
L_563F:	MOV  A, C
	CALL	L_6337	; вывод символа из A
	JMP	L_5652
;
L_5646:	POP  PSW
	ANI	07Fh
	CPI	001h
	JNZ	L_5652
	MOV  B, A
	JMP	L_563F
;
L_5652:	XTHL
	DCR  B
	JNZ	L_5614
	POP  D
	POP  D
	MOV  A, D
	ORA  A
	JNZ	L_6000	; рестарт
	MOV  A, E
	ANI	07Fh
	CPI	020h
	JC	L_6000	; рестарт
	INR  A
	JZ	L_6000	; рестарт
	CALL	L_6335	; вывод пробела
	MVI  A, 027h
	CALL	L_6337	; вывод символа из A
	MOV  A, E
	ANI	07Fh
	CALL	L_6337	; вывод символа из A
	MVI  A, 027h
	CALL	L_6337	; вывод символа из A
	JMP	L_6000	; рестарт
;
L_5680:	LXI  H, D_669B
	MVI  C, 008h
	LDA     D_662C	; = 0 (норм.)/ FF (запуск с минусом)
	ORA  A
	JZ	L_569C
	CALL	L_56EF
	MVI  A, 02Eh
	CALL	L_6337	; вывод символа из A
	MVI  C, 003h
	CALL	L_56EF
	JMP	L_6000	; рестарт
;
L_569C:	MVI  C, 008h
	CALL	L_56C3
	MVI  C, 003h
	CALL	L_56C3
	JMP	L_6000	; рестарт
;
L_56A9:	LXI  H, D_667E	; имя по команде I
	MVI  C, 00Bh
	LDA     D_662C	; = 0 (норм.)/ FF (запуск с минусом)
	ORA  A
	JZ	L_56BB
	CALL	L_56EF
	JMP	L_6000	; рестарт
;
L_56BB:	MVI  C, 00Bh
	CALL	L_56C3
	JMP	L_6000	; рестарт
;
L_56C3:	CALL	L_634A
	CPI	00Dh
	JZ	L_56E6
	CPI	02Eh
	JZ	L_56E6
	CPI	02Ah
	JNZ	L_56DA
	MVI  A, 03Fh
	JMP	L_56E8
;
L_56DA:	CPI	021h
	JC	L_56C3
	MOV  M, A
	INX  H
	DCR  C
	JNZ	L_56C3
	RET
;
L_56E6:	MVI  A, 020h
L_56E8:	MOV  M, A
	INX  H
	DCR  C
	JNZ	L_56E8
	RET
;
L_56EF:	CALL	L_6335	; вывод пробела
L_56F2:	MOV  A, M
	INX  H
	CALL	L_6337	; вывод символа из A
	DCR  C
	JNZ	L_56F2
	RET
;
L_56FC:	CALL	L_630D
	JNZ	L_6318	; >> Ошибка
L_5702:	CALL	L_54F5
	CPI	003h
	JZ	L_6000	; рестарт
	CALL	L_6337	; вывод символа из A
	JMP	L_5702
;
L_5710:	DI
	JMP	L_789B	; вывод на МГ
;
L_5A22:	MVI  A, 008h
L_5714:	DI
	JMP	L_7840	; ввод байта с магнитной ленты
;
L_5718:	LXI  H, L_57EC	; <<< O
	SHLD	X_57BC+1
	LDA     D_664D
	CPI	03Eh	; '>'
	JZ	L_5731
	CPI	025h	; '%' -- однократный вывод блоков
	JNZ	L_5680
	LXI  H, L_57D4
	SHLD	X_57BC+1
L_5731:	CALL	L_633E
	CALL	L_64A8
	CALL	L_62AA
	MOV  A, B
	ORA  D
	ORA  H
	JNZ	L_6318	; >> Ошибка
	CMP  E
	JZ	L_6318	; >> Ошибка
	MOV  A, L	; C - начальный блок, E - количество блоков, L - смещение
	LXI  H, D_66A8
	MOV  M, C
	INX  H
	MOV  M, E
	INX  H
	MOV  M, A
	LXI  H, D_668D	; "NODISK..."
	CALL	L_575A
	ORA  A
	JNZ	L_6318	; >> Ошибка
	JMP	L_6000	; рестарт
;
L_575A:	PUSH B
	PUSH D
	PUSH H
	MVI  E, 000h
	MVI  B, 019h
L_5761:	MOV  A, M
	ADD  E
	MOV  E, A
	INX  H
	DCR  B
	JNZ	L_5761
	MOV  A, M
	CPI	003h
	JNC	L_57DA
	ADD  E
	MOV  E, A
	INX  H
	MOV  A, M
	CPI	010h
	JNC	L_57DA
	ADD  E
	MOV  E, A
	INX  H
	MOV  B, M
	INX  H
	ADD  M
	MOV  E, A
	MOV  C, M
	INX  H
	MOV  D, M
	MOV  A, B
	ADD  D
	DCX  H
	DCX  H
	MOV  M, A
	ADD  E
	STA     D_668A
;	MOV  D, C
;	MOV  H, B
	CALL	L_57E0	; подсчёт КС блока
	STA     D_668B
	MVI  H, 004h
L_5795:	MVI  L, 019h
L_5797:	XRA  A
	CALL	L_5710
	DCR  L
	JNZ	L_5797
	MVI  L, 019h
L_57A1:	MVI  A, 055h
	CALL	L_5710
	DCR  L
	JNZ	L_57A1
	DCR  H
	JNZ	L_5795
	POP  H
	PUSH B
	MOV  D, B
	MVI  E, 000h
L_57B3:	MVI  B, 080h
	CALL	L_57EC
	MVI  E, 000h
	MVI  B, 088h
X_57BC:	CALL	L_57EC
	INR  D
	DCR  C
	JNZ	L_57B3
	POP  B
;	MOV  D, C
;	MOV  H, B
	CALL	L_57E0	; подсчёт КС блока
	MOV  B, A
	LDA     D_668B
	SUB  B
	JNZ	L_57D5
L_57D2:	POP  D
	POP  B
L_57D4:	RET
;
L_57D5:	MVI  A, 002h
	JMP	L_57D2
;
L_57DA:	MVI  A, 00Ah
	POP  H
	JMP	L_57D2
;
L_57E0:	XRA  A		; подсчёт КС
	MOV  L, A
	MOV  D, C
	MOV  H, B
	MOV  A, B
	RAL
	JC	L_57E2	; BC >= 8000h
	STC
	RAR
	MOV  H, A
	DI
	MVI  A, B_PRG0	; ОЗУ: Банк 2, Банк 0
	OUT     00Eh	; режим ОЗУ
L_57E2:	ADD  M
	INR  L
	JNZ	L_57E2
	DCR  D
	JNZ	L_57E2
	MOV  H, A
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	EI
	MOV  A, H
	RET
;
L_57EC:	PUSH B
	PUSH H
	PUSH D
	MVI  D, 010h
	XRA  A
	CALL	L_5858
	MVI  D, 004h
	MVI  A, 055h
	CALL	L_5858
	MVI  A, 0E6h
	CALL	L_5710
	XRA  A
	MVI  D, 004h
	CALL	L_5858
	MVI  D, 01Dh
L_5809:	MOV  A, M
	CALL	L_5710
	INX  H
	DCR  D
	JNZ	L_5809
	MOV  A, C
	CALL	L_5710
	LDA     D_668A
	ADD  C
	CALL	L_5710
	STA     D_668C
	POP  D
	PUSH D
	MOV  A, D
	RAL
	JC	L_5821	; DE >= 8000h
	STC
	RAR
	MOV  D, A
	MVI  A, B_PRG0	; ОЗУ: Банк 2, Банк 0
	OUT     00Eh	; режим ОЗУ
L_5821:	MVI  H, 008h
L_5823:	MVI  L, 020h
	PUSH D
	XRA  A
	MVI  D, 004h
	CALL	L_5858
	POP  D
	MVI  A, 0E6h
	CALL	L_5710
	LDA     D_668C
	ADD  B
	MOV  C, A
	MOV  A, B
	CALL	L_5710
	LDA     D_668C
	CALL	L_5710
L_5841:	LDAX D		; mem
	INR  E
	CALL	L_5710
	ADD  C
	MOV  C, A
	DCR  L
	JNZ	L_5841	; цикл вывода блока
	MOV  A, C
	CALL	L_5710
	INR  B
	DCR  H
	JNZ	L_5823
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	POP  D
	POP  H
	POP  B
	RET
;
L_5858:	CALL	L_5710
	DCR  D
	JNZ	L_5858
	RET
;
L_5860:	CALL	L_6314	; <<< P
	JZ	L_58D3
	CALL	L_63C7
	PUSH H
	LXI  H, M_0001	; ?
	DCR  A
	LDA     D_662C	; = 0 (норм.)/ FF (запуск с минусом)
	JZ	L_587E
	ORA  A
	JNZ	L_6318	; >> Ошибка
	CALL	L_63C7
	JMP	L_5888
;
L_587E:	LXI  H, M_0000	; ?
	ORA  A
	JNZ	L_5888
	LXI  H, M_0001	; ?
L_5888:	MOV  A, H
	ORA  A
	JNZ	L_6318	; >> Ошибка
	SHLD	D_66C6
	LXI  H, D_6605
	LXI  B, 0FF08h	; счётчик
L_5896:	PUSH H
	MOV  A, M
	ORA  A
	JNZ	L_58A0
	SHLD	D_66AE
	INR  B
L_58A0:	INX  H
	MOV  A, M
	INX  H
	MOV  D, M
	POP  H
	XTHL
	CMP  L
	JNZ	L_58B7
	MOV  A, D
	CMP  H
	JNZ	L_58B7
	XTHL
	LDA     D_66C6
	MOV  M, A
	JMP	L_6000	; рестарт
;
L_58B7:	XTHL
	LXI  D, 00004h	; ?
	DAD  D
	DCR  C
	JNZ	L_5896
	INR  B
	JZ	L_6318	; >> Ошибка
	LHLD	D_66AE
	LDA     D_66C6
	MOV  M, A
	INX  H
	POP  D
	MOV  M, E
	INX  H
	MOV  M, D
	JMP	L_6000	; рестарт
;
L_58D3:	LXI  H, D_6605
	MVI  C, 008h
L_58D8:	PUSH H
	MOV  A, M
	ORA  A
	JZ	L_58FC
	LDA     D_662C	; = 0 (норм.)/ FF (запуск с минусом)
	ORA  A
	JZ	L_58EA
	MVI  M, 000h
	JMP	L_58FC
;
L_58EA:	PUSH B
	CALL	L_6382	; вывод 0Dh,0Ah
	CALL	L_637B	; вывод числа из adr[HL] в HEX
	CALL	L_6335	; вывод пробела
	INX  H
	MOV  E, M
	INX  H
	MOV  D, M
	CALL	L_6392	; вывод DE в HEX
	POP  B
L_58FC:	POP  H
	LXI  D, 00004h	; ?
	DAD  D
	DCR  C
	JNZ	L_58D8
	JMP	L_6000	; рестарт
;
L_5908:	LXI  H,	Lx59DZ	; <<< R
	MVI  M, 0CDh	; = CALL ...
L_591A:	CALL	L_6499	; << вызов из V
	LXI  H, M_0000	; ?
	JC	L_6318	; >> Ошибка
	JZ	L_592D
	DCR  A
	JNZ	L_6318	; >> Ошибка
	CALL	L_63C7
L_592D:	SHLD	D_667C
	CALL	L_6DDC
	LDA     D_662C	; = 0 (норм.)/ FF (запуск с минусом)
	ORA  A
	JNZ	L_59C8
	MVI  C, 00Bh
	LXI  H, D_664C
	CALL	L_56E6
	LXI  H, D_6742	; "Поиск:"
	CALL	L_7833	; вывод строки до 00h
	LDA     D_662D	; наличие "W"
	ORA  A
	JNZ	L_5957
	MVI  C, 00Bh
	LXI  H, D_667E
	CALL	L_56EF
L_5957:	CALL	L_6DDC
L_595A:	MVI  B, 004h
	MVI  A, 0FFh
L_595E:	CALL	L_5714
	CPI	0D2h
	JNZ	L_595A
	MVI  A, 008h
	DCR  B
	JNZ	L_595E
	MVI  B, 00Bh
	CALL	L_5A22
	LXI  H, D_664C
L_5974:	ORA  A
	JZ	L_5988
	MOV  M, A
	INX  H
	CALL	L_5A22
	DCR  B
	JNZ	L_5974
L_5981:	CALL	L_5A22
	ORA  A
	JNZ	L_5981
L_5988:	MVI  B, 002h
L_598A:	CALL	L_5A22
	ORA  A
	JNZ	L_595A
	DCR  B
	JNZ	L_598A
	LXI  H, D_6750
	CALL	L_7833	; вывод строки до 00h
	MVI  C, 00Bh
	LXI  H, D_664C
	CALL	L_56EF
	CALL	L_6335	; вывод пробела
	CALL	L_6DDC
	LDA     D_662D	; наличие "W"
	ORA  A
	JNZ	L_59C8
	LXI  H, D_664C
	LXI  D, D_667E
	MVI  B, 00Bh
L_59B8:	LDAX D
	CMP  M
	INX  H
	INX  D
	JZ	L_59C4
	CPI	03Fh
	JNZ	L_595A
L_59C4:	DCR  B
	JNZ	L_59B8
L_59C8:	MVI  A, 0FFh
	CALL	L_5714
	MOV  D, A
	LHLD	D_667C
	CALL	L_5A22
	MOV  E, A
	XCHG
	DAD  D
	CALL	L_5A22
	PUSH H
	MOV  H, A
	CALL	L_5A22
	MOV  L, A
	DAD  D
	XCHG
	POP  H
	SHLD	D_66C6	;----
Lx59DZ:	CALL	L_5A22	; <- меняется на RET (V2)
	MOV  B, A	; контрольная сумма
	MVI  A, B_MONW	; ОЗУ: {Банк 2 R | Банк 0 W}, Банк 1
	OUT     00Eh	; режим ОЗУ
	MOV  M, B
L_59EB:	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	CALL	L_6301	; сравнение HL и DE
	INX  H
	JZ	L_5A06	; >>
;	CALL	L_5A22
	MVI  A, 008h
	CALL	L_7840	; ввод байта с магнитной ленты	
	MOV  C, A
	ADD  B
	MOV  B, A
	MVI  A, B_MONW	; ОЗУ: {Банк 2 R | Банк 0 W}, Банк 1
	OUT     00Eh	; режим ОЗУ
	MOV  M, C
	JMP	L_59EB
;
L_5A06:	CALL	L_5A22
	MOV  C, A
L_5A0A:	LXI  H, D_675E	; "загружено..."
	CALL	L_7833	; вывод строки до 00h
	LHLD	D_66C6
	CALL	L_6307	; вывод HL в HEX и пробел
	XCHG
	CALL	L_6307	; вывод HL в HEX и пробел
	MOV  A, B
	CMP  C
	JNZ	L_6318	; >> Ошибка
	JMP	L_6000	; рестарт
;
L_5A27:	CALL	L_6499	; <<< S
	DCR  A
	JNZ	L_6318	; >> Ошибка
	LDA     D_662C	; = 0 (норм.)/ FF (запуск с минусом)
	ORA  A
	JNZ	L_6318	; >> Ошибка
	CALL	L_63C7
L_5A38:	CALL	L_6382	; вывод 0Dh,0Ah
	PUSH H
	CALL	L_6398	; вывод HL в HEX
	CALL	L_6335	; вывод пробела
	POP  H
	PUSH H
	LDA     D_662D	; наличие "W"
	ORA  A
	JZ	L_5A55
	CALL	RWORD	; чтение двух байт в DE с адреса HL (банк 0 и банк 1)
;	MOV  E, M
;	INX  H
;	MOV  D, M
	DCX  H
	XCHG
	CALL	L_6398	; вывод HL в HEX
	JMP	L_5A58
;
L_5A55:	CALL	RBYTE	; чтение байта с адреса HL (банк 0 и банк 1)
	CALL	L_637C	; вывод числа A в HEX
;	CALL	L_637B	; вывод числа из adr[HL] в HEX
L_5A58:	CALL	L_6335	; вывод пробела
	CALL	L_6321	; ввод данных в буфер (D_664A)
	CALL	L_633E
	POP  H
	CPI	00Dh
	JZ	L_5AA2
	CPI	02Eh
	JZ	L_6000	; рестарт
	CPI	022h
	PUSH H
	JNZ	L_5A81
L_5A72:	CALL	L_634A
	POP  H
	CPI	00Dh
	JZ	L_5A38
	MOV  M, A
	INX  H
	PUSH H
	JMP	L_5A72
;
L_5A81:	CALL	L_64AB
	DCR  A
	JNZ	L_6318	; >> Ошибка
	CALL	L_63C7
	LDA     D_662D	; наличие "W"
	ORA  A
	JZ	L_5A9B
	XCHG
	POP  H
	DI
	MVI  A, B_MONW	; ОЗУ: (Банк 2 R / Банк 0 W), Банк 1
	OUT     00Eh	; режим ОЗУ
	MOV  M, E
	INX  H
	MOV  M, D
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	EI
	INX  H
	JMP	L_5A38
;
L_5A9B:	ORA  A
	JNZ	L_6318	; >> Ошибка
	DI
	MVI  A, B_MONW	; ОЗУ: (Банк 2 R / Банк 0 W), Банк 1
	OUT     00Eh	; режим ОЗУ
	MOV  A, L
	POP  H
	MOV  M, A
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	EI
L_5AA2:	INX  H
	LDA     D_662D	; наличие "W"
	ORA  A
	JZ	L_5A38
	INX  H
	JMP	L_5A38
;
L_5AAE:	MVI  A, 001h	; <<< U
	JMP	L_5AB5
;
L_5AB3:	MVI  A, 002h	; <<< T
L_5AB5:	STA     D_662F
	CALL	L_6499	; разбор параметров строки 
	LXI  H, M_0000	; ?
	SHLD	D_6632
	INX  H
	JZ	L_5AE5
	CALL	L_63C7
	JNC	L_5ACE
	INX  H
	ANI	07Fh
L_5ACE:	PUSH H
	PUSH PSW
	MOV  A, L
	ORA  H
	JZ	L_6318	; >> Ошибка
	POP  PSW
	DCR  A
	JZ	L_5AE4
	DCR  A
	JNZ	L_6318	; >> Ошибка
	CALL	L_63C7
	SHLD	D_6632
L_5AE4:	POP  H
L_5AE5:	SHLD	D_6630
	XRA  A
	STA     D_6627
	CALL	L_655F	; вывод значений регистров
	JMP	L_5524
;
L_5AF2:	LXI  H, Lx59DZ	; <<< V
	MVI  M, 0C9h	; = RET
	CALL	L_591A	; >> вызов модифицированного чтения
	MOV  A, H	; << чтение байта с адреса HL (банк 0 и банк 1)
	MOV  B, H
	RAL
	JC	L_5AFX	; HL >= 8000h
	STC
	RAR
	MOV  H, A
;	DI
	MVI  A, B_PRG0	; ОЗУ: Банк 2, Банк 0
	OUT     00Eh	; режим ОЗУ
L_5AFX:	CALL	L_5A22
	CMP  M
	MOV  H, B
	MOV  B, A
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
;	EI
	JNZ	L_5AFY
L_5AFZ:	CALL	L_6301	; сравнение HL и DE
	INX  H
	JZ	L_5AFY
	MOV  A, H	; << чтение байта с адреса HL (банк 0 и банк 1)
	MOV  B, H
	RAL
	JC	L_5AFV	; HL >= 8000h
	STC
	RAR
	MOV  H, A
;	DI
	MVI  A, B_PRG0	; ОЗУ: Банк 2, Банк 0
	OUT     00Eh	; режим ОЗУ
L_5AFV:;	CALL	L_5A22
	MVI  A, 008h
	CALL	L_7840	; ввод байта с магнитной ленты	
	CMP  M
	MOV  H, B
	MOV  B, A
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
;	EI
	JNZ	L_5AFY
	JMP	L_5AFZ
;	
L_5AFY:	MOV  A, B
	MOV  B, C
	JZ	L_5A0A	; >> всё нормально
	MOV  D, A
	CALL	L_6307	; вывод HL в HEX и пробел
	MOV  A, D
	CALL	L_637C	; вывод числа A в HEX
	CALL	L_6B9D	; вывод двух пробелов
;	CALL	L_637B	; вывод числа из adr[HL] в HEX
	CALL	RBYTE	; чтение байта с адреса HL (банк 0 и банк 1)
	CALL	L_637C	; вывод числа A в HEX
	JMP	L_6318	; >> Ошибка
;
L_5B19:	MOV  A, H
	CALL	L_5710
	MOV  A, L
	JMP	L_5710
;
L_5B21:	CALL	L_5710
	DCR  B
	JNZ	L_5B21
	RET
;
L_5B29:	CALL	L_6314
	SUI	002h
	JC	L_6318	; >> Ошибка
	CALL	L_62AF
	PUSH B
	PUSH D
	PUSH B
	XTHL
	POP  B
	DCR  A
	JNZ	L_5B41
	DAD  B
	XCHG
	DAD  B
	XCHG
L_5B41:	CALL	L_6DDC
	CALL	L_6DE3
	LDA     D_662C	; = 0 (норм.)/ FF (запуск с минусом)
	ORA  A
	JNZ	L_5B9B
	PUSH H
	XRA  A
	MOV  B, A
	CALL	L_5B21
	MVI  A, 0E6h
	CALL	L_5710
	MVI  A, 0D2h
	MVI  B, 004h
	CALL	L_5B21
	LXI  H, D_667E
	MVI  B, 00Bh
L_5B65:	MOV  A, M
	CPI	021h
	JC	L_5B94
	CPI	03Fh
	JNZ	L_5B8C
	LXI  H, D_5B79
	CALL	L_7833	; вывод строки до 00h
	JMP	L_6000	; рестарт
;
D_5B79:	.db " # neqwnoe imq (?)"
	.db 000h
;
L_5B8C:	CALL	L_5710
	INX  H
	DCR  B
	JNZ	L_5B65
L_5B94:	XRA  A
	MVI  B, 003h
	CALL	L_5B21
	POP  H
L_5B9B:	XRA  A
	MOV  B, A
	CALL	L_5B21
	MVI  A, 0E6h
	CALL	L_5710
	CALL	L_5B19
	XCHG
	CALL	L_5B19
	XCHG
	POP  D
	POP  H
L_5BAF:	MOV  A, H	; << чтение байта с адреса HL (банк 0 и банк 1)
	MOV  C, H
	RAL
	JC	L_5BAZ	; HL >= 8000h
	STC
	RAR
	MOV  H, A
	DI
	MVI  A, B_PRG0	; ОЗУ: Банк 2, Банк 0
	OUT     00Eh	; режим ОЗУ
L_5BAZ:	MOV  A, M
	CALL	L_5710
	ADD  B
	MOV  B, A
	MOV  H, C
	CALL	L_6301	; сравнение HL и DE
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	EI
	INX  H
	JNZ	L_5BAF
	MOV  A, B
	CALL	L_5710
	JMP	L_6000	; рестарт
;
L_5BC3:	CALL	L_633E
	CPI	00Dh
	JNZ	L_5BD1
	CALL	L_655F
	JMP	L_6000	; рестарт
;
L_5BD1:	LXI  B, 0000Bh	; счётчик
	LXI  H, D_6704
L_5BD7:	CMP  M
	JZ	L_5BE4
	INX  H
	INR  B
	DCR  C
	JNZ	L_5BD7
	JMP	L_6318	; >> Ошибка
;
L_5BE4:	CALL	L_633E
	CPI	00Dh
	JNZ	L_6318	; >> Ошибка
	PUSH B
	CALL	L_6382	; вывод 0Dh,0Ah
	CALL	L_6532
	CALL	L_6335	; вывод пробела
	CALL	L_6321	; ввод данных в буфер (D_664A)
	CALL	L_6314
	ORA  A
	JZ	L_6000	; рестарт
	DCR  A
	JNZ	L_6318	; >> Ошибка
	CALL	L_63C7
	POP  B
	MOV  A, B
	CPI	005h
	JNC	L_5C35
	MOV  A, H
	ORA  A
	JNZ	L_6318	; >> Ошибка
	MOV  A, L
	CPI	002h
	JNC	L_6318	; >> Ошибка
	CALL	L_64FB
	MOV  H, A
	MOV  B, C
	MVI  A, 0FEh
	CALL	L_5C2F
	ANA  H
	MOV  B, C
	MOV  H, A
	MOV  A, L
	CALL	L_5C2F
	ORA  H
	STAX D
	JMP	L_6000	; рестарт
;
L_5C2F:	DCR  B
	RZ
	RLC
	JMP	L_5C2F
;
L_5C35:	JNZ	L_5C45
	MOV  A, H
	ORA  A
	JNZ	L_6318	; >> Ошибка
	MOV  A, L
	LXI  H, D_66F3
	MOV  M, A
	JMP	L_6000	; рестарт
;
L_5C45:	PUSH H
	CALL	L_6519
	POP  D
	MOV  M, E
	INX  H
	MOV  M, D
	JMP	L_6000	; рестарт
;
L_5C50:	CALL	L_6499	; проверка параметров <<< D
	JZ	L_5C6F	; > нет параметров
	CALL	L_63C7
	JC	L_5C5F
	SHLD	D_6642
L_5C5F:	ANI	07Fh
	DCR  A
	JZ	L_5C6F
	CALL	L_63C7
	DCR  A
	JNZ	L_6318	; >> Ошибка
	JMP	L_5C7A
;
L_5C6F:	LHLD	D_6642	; начальный адрес
	MOV  A, L
	ANI	0F0h
	MOV  L, A
	LXI  D, 000AFh	; = 11 строк
	DAD  D
	JNC	L_5C7A	; <= FFFFh
	LXI  H, 0FFFFh
L_5C7A:	SHLD	D_6644	; конечный адрес
L_5C7D:	CALL	L_6382	; вывод 0Dh,0Ah
	CALL	L_638C
	JNZ	L_6000	; рестарт
	LHLD	D_6642
	SHLD	D_6646
	CALL	L_6398	; вывод HL в HEX
	MVI  A, 03Ah	; ':'
	CALL	L_6337	; вывод символа из A
	LDA     D_662D	; наличие "W"
	ORA  A
	JZ	L_5CB4	; -> побайтный вывод
	MVI  C, 008h	; вывод словами (двухбайтный)
L_5C9D:	CALL	L_6335	; пробел
	CALL	RWORD	; чтение двух байт в DE с адреса HL (банк 0 и банк 1)
;	MOV  E, M
;	INX  H
;	MOV  D, M
;	INX  H
	CALL	L_6392	; вывод DE в HEX
	CALL	L_63A0	; HL > adr[D_6644] ?
	JC	L_5CD9
	MOV  A, H
	ORA  L
	ANI	0FEh
	JZ	L_5CDZ	; HL = 0..1 ?
	DCR  C
	JNZ	L_5C9D
	JMP	L_5CD9
;
L_5CDZ: MVI  L, 0
	JMP	L_5CD9
;
L_5CB4:	PUSH H		; дополнение пробелами
L_5CB5:	MOV  A, L
	ANI	00Fh
	JZ	L_5CC8
	CALL	L_6335	; пробел
	CALL	L_6335
	CALL	L_6335
	DCX  H
	JMP	L_5CB5
;
L_5CC8:	POP  H		; вывод строки байт
L_5CC9:	CALL	L_6335	; пробел
	CALL	RBYTE	; чтение байта с адреса HL (банк 0 и банк 1)
	CALL	L_637C	; вывод числа A в HEX
;;	CALL	L_62D0	; вывод пробела и байта в HEX из adr[HL]
	INX  H
	CALL	L_63A0	; HL > adr[D_6644] ?
	JC	L_5CD9
	MOV  A, H
	ORA  L
	JZ	L_5CD9	; HL = 0 ?
	MOV  A, L
	ANI	00Fh
	JNZ	L_5CC9	; цикл до HL = 0xxx0h
L_5CD9:	SHLD	D_6642
	LDA     D_662C	; = 0 (норм.)/ FF (запуск с минусом)
	ORA  A
	JNZ	L_5D21
	LHLD	D_6646
	PUSH H
L_5CE7:	MOV  A, L
	ANI	00Fh
	JZ	L_5CF4
	CALL	L_6335	; вывод пробела
	DCX  H
	JMP	L_5CE7
;
L_5CF4:	LHLD	D_6642	; адрес конца строки
	XCHG
	POP  H
	CALL	L_6335	; пробел
L_5CF9:	CALL	RBYTE	; чтение байта с адреса HL (банк 0 и банк 1)
	CPI	0FFh
	JNC	L_5D0E
	CPI	0A0h
	JNC	L_5D10
	CPI	07Fh
	JNC	L_5D0E
	CPI	020h
	JNC	L_5D10
L_5D0E:	MVI  A, 02Eh	; '.'
L_5D10:	CALL	L_6337	; вывод символа из A
	INX  H
	MOV  A, L
	SUB  E
	JNZ	L_5CF9
	MOV  A, H
	SUB  D
	JNZ	L_5CF9
L_5D21:	LHLD	D_6642
	CALL	L_63A0	; HL > adr[D_6644] ?
	JC	L_6000	; рестарт
	MOV  A, H
	ORA  L
	JZ	L_6000	; HL = 0 ?
	JMP	L_5C7D
;
L_5D2D:	CALL	L_630D	; <<< L
	JZ	L_5D4B
	CALL	L_63C7
	SHLD	D_65EE
	DCR  A
	JZ	L_5D4B
	CALL	L_63C7
	SHLD	D_65F0
	DCR  A
	JNZ	L_6318	; >> Ошибка
	XRA  A
	JMP	L_5D4D
;
L_5D4B:	MVI  A, 00Ch
L_5D4D:	STA     D_65F2
	XRA  A
	STA     D_6625
	CALL	L_6BC3	;L_68D4
	JMP	L_6000	; рестарт
;
L_5D5A:;	DI		; <<< RST5
;	SHLD	D_66F6
;	POP  H		; адрес возврата
;	DCX  H
;	SHLD	D_66F8
;	PUSH PSW
;	LXI  H, 00002h	; ?
;	DAD  SP
;	POP  PSW
;;	POP  H
	SHLD	D_66F8	; = адрес возврата
	POP  H
	SHLD	D_66F6	; = HL
	POP  H		; = SP
	POP  PSW	; = PSW
	LXI  SP,D_66F6
	PUSH H		; = SP
	PUSH PSW
	PUSH B
	PUSH D
	EI
	LHLD	D_66F8	; адрес возврата
;	MOV  A, M
	CALL	RBYTE	; чтение байта с адреса HL (банк 0 и банк 1)
	CPI	0EFh
	PUSH PSW
	PUSH H
	LDA     D_6601
	STA     D_6626
	LXI  H, D_6621
	MVI  C, 008h
L_5D84:	PUSH H
	MOV  A, M
	ORA  A
	JZ	L_5D91
	INX  H
	MOV  E, M
	INX  H
	MOV  D, M
	INX  H
	MOV  A, M
	STAX D
L_5D91:	POP  H
	LXI  D, 0FFFCh	; = -4
	DAD  D
	DCR  C
	JNZ	L_5D84
	CALL	L_5E81
	LXI  H, D_6634
	MOV  A, M
	MVI  M, 000h
L_5DA3:	ORA  A
	JZ	L_5DB4
	DCR  A
	MOV  B, A
	INX  H
	MOV  E, M
	INX  H
	MOV  D, M
	INX  H
	DI
	MVI  A, B_MONW	; ОЗУ: {Банк 2 R | Банк 0 W}, Банк 1
	OUT     00Eh	; режим ОЗУ
	MOV  A, M
	STAX D
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	EI	
	MOV  A, B
	JMP	L_5DA3
;
L_5DB4:	POP  H
	POP  PSW
	JZ	L_5DBE
	INX  H
	SHLD	D_66F8
	XCHG
L_5DBE:	LDA     D_6604
	ORA  A
	JNZ	L_5E45
	LXI  H, D_6605
	MVI  C, 008h
L_5DCA:	PUSH H
	MOV  A, M
	ORA  A
	JZ	L_5E0E
	INX  H
	MOV  A, M
	INX  H
	MOV  D, M
	LHLD	D_66F8
	CMP  L
	JNZ	L_5E0E
	MOV  A, D
	CMP  H
	JNZ	L_5E0E
	POP  H
	MOV  A, M
	DCR  A
	JNZ	L_5E06
	PUSH PSW
	DCR  A
	STA     D_6604
L_5DEB:	CALL	L_6382	; вывод 0Dh,0Ah
	POP  PSW
	INR  A
	CALL	L_637C	; вывод числа A в HEX
	LXI  H, D_6739
	CALL	L_7833	; вывод строки до 00h
	LHLD	D_66F8
	XCHG
	CALL	L_6392	; вывод DE в HEX
L_5E00:	CALL	L_655F
	JMP	L_5524
;
L_5E06:	MOV  M, A
	PUSH PSW
	CALL	L_5E65
	JMP	L_5DEB
;
L_5E0E:	POP  H
	LXI  D, 00004h	; ?
	DAD  D
	DCR  C
	JNZ	L_5DCA
	CALL	L_638C
	JNZ	L_5E45
	CALL	L_5E65
	JZ	L_5E2D
	DCR  A
	JNZ	L_5E00
	CALL	L_5E8F
	JMP	L_5524
;
L_5E2D:	LDA     D_6626
	ORA  A
	JZ	L_5E45
	LHLD	D_662A
	MOV  C, L
	MOV  B, H
	LHLD	D_6628
	XCHG
	LDA     D_6627
	ORA  A
	STC
	JMP	L_5524
;
L_5E45:	CALL	L_6382	; вывод 0Dh,0Ah
	CALL	L_5E81
	CALL	L_65E3
	SHLD	D_6632
	STA     D_6604
	MVI  A, 02Ah
	CALL	L_6337	; вывод символа из A
	LHLD	D_66F8
	SHLD	D_65EE
	CALL	L_6398	; вывод HL в HEX
	JMP	L_6000	; рестарт
;
L_5E65:	LXI  H, D_662F
	MOV  A, M
	ORA  A
	RZ
	PUSH H
	LHLD	D_6630
	DCX  H
	SHLD	D_6630
	MOV  A, H
	ORA  L
	POP  H
	JNZ	L_5E7E
	MOV  M, A
	DCR  A
	STA     D_6604
L_5E7E:	MOV  A, M
	ORA  A
	RET
;
L_5E81:	LDA     D_6601
	ORA  A
	RZ
	LHLD	D_6602
	MOV  M, A
	XRA  A
	STA     D_6601
	RET
;
L_5E8F:	LHLD	D_66F8	; текущий адрес
	CALL	RBYTE	; чтение байта с адреса HL (банк 0 и банк 1)
;	MOV  B, M
	MOV  B, A
	INX  H
	PUSH H
	LXI  D, 0000Dh	; счётчик
	LXI  H, D_671F
L_5E9B:	MOV  A, M	; << поиск команд на 2-3 байта
	ANA  B
	INX  H
	CMP  M
	INX  H
	JZ	L_5EA8
	INR  D
	DCR  E
	JNZ	L_5E9B
L_5EA8:	MOV  E, D
	MVI  D, 000h
	LXI  H, D_662E
	MOV  M, E
	LXI  H, D_5EB9
	DAD  D
	DAD  D
	MOV  E, M
	INX  H
	MOV  D, M
	XCHG
	PCHL
;
D_5EB9:	.dw L_5ED5	; команда JMP
	.dw L_5EEA	; J*
	.dw L_5EE1	; CALL
	.dw L_5EEA	; C*
	.dw L_5EDB	; RET
	.dw L_5EFC	; R*
	.dw L_5F1D	; PCHL
	.dw L_5F06	; RST *
	.dw L_5F2F	; LXI *, ...
	.dw L_5F2F	; LHLD, LDA, SHLD, STA
	.dw L_5F32	; MVI *, ...
	.dw L_5F32	; ADI, SUI, ANI, ORI, ACI, SBI, XRI, CPI
	.dw L_5F32	; IN, OUT
	.dw L_5F2A	; прочее
;
L_5ED5:	CALL	L_5FB1
	JNZ	L_5F35
L_5EDB:	CALL	L_5FD2	; чтение в DE двух байт из стека программы, адрес в D_66F4
	JMP	L_5F35
;
L_5EE1:	CALL	L_5FB1
	JNZ	L_5F35
	JMP	L_5EF7
;
L_5EEA:	CALL	L_5FB1
	JZ	L_5EF7
	POP  B
	PUSH B
	MVI  A, 002h
	JMP	L_5F37
;
L_5EF7:	POP  D
	PUSH D
	JMP	L_5F35
;
L_5EFC:	CALL	L_5FD2	; чтение в DE двух байт из стека программы, адрес в D_66F4
	POP  B
	PUSH B
	MVI  A, 002h
	JMP	L_5F37
;
L_5F06:	MOV  A, B
	CPI	0FFh
	JZ	L_6318	; >> Ошибка
	CPI	0EFh
	JNZ	L_5F15
	XRA  A
	JMP	L_5F39
;
L_5F15:	ANI	038h
	MOV  E, A
	MVI  D, 000h
	JMP	L_5F35
;
L_5F1D:	LHLD	D_66F6
	XCHG
	CALL	L_5FB9
	JNZ	L_5F35
	JMP	L_5EDB
;
L_5F2A:	POP  D
	PUSH D
	JMP	L_5F35
;
L_5F2F:	POP  D
	INX  D
	PUSH D
L_5F32:	POP  D
	INX  D
	PUSH D
L_5F35:	MVI  A, 001h
L_5F37:	INR  A
	STC
L_5F39:	PUSH PSW
	LHLD	D_6632
	MOV  A, H
	ORA  L
	JZ	L_5F5D
	PUSH D
	PUSH B
	PUSH H
	LHLD	D_66F8
	XCHG
	LXI  H, L_5F4E
	XTHL
	PCHL
;
L_5F4E:	POP  B
	POP  D
	POP  PSW
	PUSH PSW
	JNZ	L_5F5D
	MVI  A, 023h	; '#'
	CALL	L_6337	; вывод символа из A
	JMP	L_5E45
;
L_5F5D:	LDA     D_662F
	LXI  H, D_662D	; наличие "W"
	ANA  M
	JZ	L_5F72
	CALL	L_5F9F
	JC	L_5F72
	POP  PSW
	MVI  A, 002h
	POP  H
	RET
;
L_5F72:	POP  PSW
	PUSH PSW
	ORA  A
	JZ	L_5F9C
	DCR  A
L_5F79:	XCHG
	MOV  E, A
	MOV  A, H	; << чтение байта с адреса HL (банк 0 и банк 1)
	PUSH H
	DI
	RAL
	JC	L_5F7Z	; HL >= 8000h
	STC
	RAR
	MOV  H, A
	MVI  A, B_PRG0	; ОЗУ: Банк 2, Банк 0
	OUT     00Eh	; режим ОЗУ
L_5F7Z:	MOV  A, M
	CMA
	MOV  M, A
	CMP  M
	CMA
	MOV  M, A
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	EI
	POP  H
	MOV  A, E
	XCHG
	PUSH PSW
	JZ	L_5F90
	CALL	L_5F9F
	JNC	L_5F90
	CALL	L_5FD2	; чтение в DE двух байт из стека программы, адрес в D_66F4
L_5F90:	POP  PSW
	DCR  A
	JZ	L_5F9C
	PUSH D
	MOV  E, C
	MOV  D, B
	POP  B
	JMP	L_5F79
;
L_5F9C:	POP  PSW
	POP  H
	RET
;
L_5F9F:	LDA     D_662E
	CPI	002h
	RC
	CPI	004h
	CMC
	RC
	LHLD	D_66F8
	INX  H
	INX  H
	INX  H
	XCHG
	RET
;
L_5FB1:	POP  B
	POP  H
	CALL	RWORD	; чтение двух байт в DE с адреса HL (банк 0 и банк 1)
;	MOV  E, M
;	INX  H
;	MOV  D, M
;	INX  H
	PUSH H
	PUSH B
L_5FB9:	MVI  A, 000h		; L_5400%0100h -- адрес вызова заканчивается на 0?
	CMP  E
	JNZ	L_5FC3
VxC51:	MVI  A, CALL5V/0100h	; (0FEh)
	CMP  D
	RZ			; Z (= 0FE00h)
L_5FC3:	MVI  A, MBIOSV/0100h	; (0FFh)
	CMP  D
	RNZ			;	JNZ	L_5FDX		; (<> 0FFxxh)
L_5FCZ:	MOV  A, E
	CPI	01Eh
	MVI  A, 000h
	JC	L_5FD0		; -> адрес меньше L_781E / MBIOSV+1Eh
	CMA
L_5FD0:	ORA  A
	RET
;
L_5FD2:	LHLD	D_66F4	; SP программы
	CALL	RWORD	; чтение двух байт в DE с адреса HL (банк 0 и банк 1)
;	MOV  E, M
;	INX  H
;	MOV  D, M
	RET
;
M_DCF0:	.EQU    0DCF0h	;+
M_DED0:	.EQU    0DED0h	;+
M_DEF1:	.EQU    0DEF1h	;+
M_DEF4:	.EQU    0DEF4h	; инверсия сигнала
M_DEF6:	.EQU    0DEF6h	; скорость чтения (задержка)
;
L_9100:	LDA     D_664D	; <<< B, BM
	CPI	04Dh
	JNZ	L_9110	; >> B
	MVI  A, 004h	; ='INR  B'
	LXI  H, D_92E9	; "& MOVE"
	JMP	L_9115
;
L_9110:	MVI  A, 000h	; ='NOP'
	LXI  H, D_92F4	; "BOOT"
L_9115:	STA     Lx91C2	; (для BM)
	CALL	L_7833	; вывод строки до 00h
	DI
	MVI  A, 088h
	OUT	000h
	LDA	D_7FDE	;MVI  A, 0FFh
	OUT	003h
	MVI  A, 010h	; установка режима экрана
	OUT     002h	; 512*256
	LXI  H, 00000h
	DAD  SP	
	SHLD	Lx916Z+1
	MVI  A, B_MONW	; ОЗУ: (Банк 2 R / Банк 0 W), Банк 1
	OUT     00Eh	; режим ОЗУ
	LXI  SP,0E000h
	LXI  B, 01000h	; счётчик
	LXI  H, 00000h
L_CLRM:	PUSH H
	DCR  C
	JNZ     L_CLRM
	DCR  B
	JNZ     L_CLRM	; циклы очистки экрана 1
	MVI  A, 011h
	STA     M_DEF6	; начальная скорость чтения ROM
	LXI  SP,M_DCF0	; ?
	LXI  D, 00009h	; ?
L_9169:	MOV  H, B
	MOV  L, D
	CALL	L_921E
	DCR  L
	MVI  M, 0FFh
	DAD  D
	MVI  M, 0FFh
	INR  L
	MVI  M, 081h
	INR  B
	JNZ	L_9169	; рисуем загрузочную таблицу
	CALL	L_9182	; чтение
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
Lx916Z:	LXI SP, 00000h
	EI
	MVI  C, 007h	; "пик"
	CALL	L_7809	; вывод на экран символа
	JMP	L_6000	; рестарт // M_0000
;
L_9182:	CALL	L_9252
L_9185:	MOV  D, A
	ORA  A
	RAR
	MOV  E, A
	ADD  D
	MOV  H, A	; H = A * 1.5
	CALL    L_9252
	CMP  H
	JC      L_9185	; ждём, пока не станет больше, чем в 1,5 раза
	ADD  D		; = одинарный + двойной промежутки
	ADI	00Bh	; 006h	поправка для ПК-6128ц
L_9194:	STA     M_DEF6	; скорость чтения
	XRA  A		; переключить на экран 1
	OUT     00Dh	; Номер банка Экрана
	MVI  E, 00Ch
L_9199:	MVI  A, 008h
	CALL	L_92A8	; PP1 >>>
	CPI	055h
	JZ	L_91A7
	CPI	0AAh
	JNZ	L_9182	; PP2 >>>
L_91A7:	MVI  A, 0FFh
	OUT	003h
	DCR  E
	JNZ	L_9199	; цикл заголовка ROM
L_91A8:	CALL	L_9286
	MOV  E, A
	MOV  A, M
	ORA  A		; cpi	000H
	JNZ	L_91A8
	LXI  H, M_DEF1	; ?
	MOV  A, M
	DCX  H
	CMP  M
	JNZ	L_9182	; >>>
	MOV  D, A
	DCX  H
	MOV  B, M
Lx91C2:	NOP		; = NOP / INR B
L_91C3:	CALL	L_9286	; << начало цикла загрузки блоков
	PUSH PSW
	MOV  A, M
	ORA  A		; cpi	000H
	JZ	L_91FC
	ADD  A
	ADD  A
	ADD  A
	ADD  A
	ADD  A
	MOV  C, A
	POP  PSW
	INX  H
	MOV  A, M
	CMP  E
	JNZ     L_91C3
	PUSH D
	PUSH B
	INX  H
	LXI  D, 0207Eh	; 7Е -- чёрточка блока, 20 -- счётчик
L_91DB:	MOV  A, M
	STAX B
	LDAX B
	XRA  M
	MOV  M, A
	INX  H
	INR  C
	DCR  D
	JNZ	L_91DB
	POP  B
	MOV  L, C
	MOV  H, B
	CALL	L_921E	; вычисление координат загрузочной таблицы
	MOV  M, E
	POP  D
	CALL	L_920D	; блок загружен?
	JZ	L_91C3	; >> нет
	MOV  A, D
	CPI	001h	; последний блок?
	JNZ	L_91C3	; >> нет
	XRA  A
	RET		; >>>>> загрузка окончена
;
L_91FC:	POP  PSW
	SUB  E
	JZ	L_91C3
	INR  A
	RNZ
	CALL	L_920D
	RZ
	DCR  E
	DCR  D
	INR  B
	JMP	L_91C3
;
L_920D:	MVI  L, 000h	; ПП проверки заполнения блока
	MOV  H, B
	CALL	L_921E	; вычисление координат загрузочной таблицы
L_9213:	MOV  A, M
	ANA  A
	RZ
	INX  H
	CPI	081h
	JNZ	L_9213
	ANA  A
	RET
;
L_921E:	PUSH D
	MOV  A, L
	RLC
	RLC
	RLC
	MOV  L, A
	MOV  A, H
	RAR
	ANI	070h
	MOV  D, A
	RAR
	ADD  D
	ADD  L
	ADI	018h
	MOV  L, A
	MOV  A, H
	ANI	01Fh
	ADI	0C0h
	MOV  H, A
	POP  D
	RET
;
L_9237:	PUSH D
;rst7 -- ожидание DEF6 циклов
	IN      001h
	ANI     010h
	MOV  E, A
L_9239:	IN      001h
	ANI     010h
	CMP  E
	JZ      L_9239	; ожидание сигнала
	MOV  E, A
	MVI  D, 001h
L_9244:	IN      001h
	ANI     010h
	INR  D
	CMP  E
	JZ      L_9244
	MOV  A, D
	ADD  A
	ADD  A
	POP  D
	RET
;
L_9252:	PUSH H
	PUSH D
L_9254:	CALL    L_9237
	MOV  B, A
	ORA  A
	RAR
	MOV  C, A
	LXI  H, 00000h
	MVI  D, 020h
L_9265:	CALL    L_9237
	PUSH D
	MVI  D, 000h
	MOV  E, A
	DAD  D
	POP  D
	MOV  E, A
	SUB  B
	JNC     L_9273
	MOV  A, B
	SUB  E
L_9273:	CMP  C
	JNC     L_9254
	DCR  D
	JNZ     L_9265
	DAD  H
	MOV  A, H
	POP  D
	POP  H
	RET
;
L_9286:	PUSH B
	PUSH D
	LXI  H, M_DED0	; ?
L_928A:	PUSH H
	LXI  B, 00023h	; B - контр. сумма; C - счётчик
	MVI  A, 0FFh
L_9290:	CALL	L_92A8	; PP1 >>>
	MOV  M, A
	INX  H
	ADD  B
	MOV  B, A
	MVI  A, 008h
	DCR  C
	JNZ	L_9290	; цикл по строке
	DCX  H
	MOV  A, B
	SUB  M
	SUB  M
	MOV  A, M
	POP  H
	JNZ	L_928A
	POP  D
	POP  B
	RET
;
L_92A8:	PUSH B		; << PP1
	PUSH D
	MVI  C, 000h
	MOV  D, A
L_92BX:	IN      001h
	ANI     010h
	MOV  E, A
L_92B0:	IN	001h
	ANI	010h
	CMP  E
	JZ	L_92B0
	RLC
	RLC
	RLC
	RLC
	MOV  A, C
	RAL
	MOV  C, A
	LDA     M_DEF6	; скорость чтения
L_92BZ: DCR  A
	JNZ     L_92BZ
	MOV  A, D
	ORA  A
	JP	L_92DE
	MOV  A, C
	CPI	0E6h	; синхробайт
	JNZ	L_92D2
	XRA  A
	STA     M_DEF4	; выкл. инвертирование сигнала
	JMP	L_92DC
;
L_92D2:	CPI	019h	; синхробайт в инверсии
	JNZ	L_92BX
	MVI  A, 0FFh
	STA     M_DEF4	; вкл. инвертирование сигнала
L_92DC:	MVI  D, 009h
L_92DE:	DCR  D
	JNZ	L_92BX
	LDA     M_DEF4	; ?
	XRA  C
	PUSH PSW
	POP  PSW	; задержка между байтами, для выравнивания скорости с Вектором
	POP  D
	POP  B
	RET
;
L_9330:	MVI  C, 01Fh	; <<< J
	CALL	L_7809	; вывод на экран символа
	JMP	L_6000	; рестарт
;
L_9350:	LXI  H, D_6742	;D_93A0	; <<< Y
	CALL	L_7833	; вывод строки до 00h
	DI
	MVI  A, 011h
	STA     M_DEF6	; ?
	MVI  A, 0C9h	; "RET"
	STA     L_9194
	CALL	L_9182
	STA     Lx93ZZ+1	; полученная константа
	MVI  A, 032h	; "STA ..."
	STA     L_9194	; ???
	LXI  H, D_9387
	CALL	L_7833	; вывод строки до 00h
Lx93ZZ:	MVI  A, 000h	;LDA     M_00FF	; ?
	CALL	L_7815	; вывод числа в HEX
	JMP	L_6000	; рестарт
;
L_9400:	LXI  H,	D_7FDE	; <<< Z
	MOV  A, M
	STA	Lx9405+1	; сохраняем значение сдвига экрана
	MVI  M, 0FFh
	XRA  A		; переключить временно на экран 1
	OUT     00Dh	; Номер банка Экрана
L_9404:	CALL	L_7812	; опрос статуса клавиатуры
;	ORA  A
	JZ	L_9404	; ожидание нажатия клавиши
Lx9405:	MVI  M, 0FFh
	JMP	L_6000	; рестарт
;
D_92E9:;	.db 01Bh, 059h, 021h, 026h	; координата 021h/026h
	.db 00Dh
	.db 00Ah
	.db "    ~tenie ROM so sdwigom"
	.db 000h
;	.db "MOVE & "
D_92F4:;	.db 01Bh, 059h, 021h, 021h	; координата 021h/021h
	.db 00Dh
	.db 00Ah
	.db "    ~tenie ROM"
	.db 000h
;	.db "BOOT"
;	.db 000h
D_9387:	.db "    konstanta ~teniq: "
	.db 000h
;
L_6000:	LXI  SP,MSTEK	;D_66EE	; ? @INIT рестарт =========================================================================
	CALL	L_6382	; вывод 0Dh,0Ah
	CALL	L_638C
	CNZ	L_54F5
	MVI  A, 023h	; '#'
	CALL	L_6337	; вывод символа из A
	CALL	L_6321	; ввод данных в буфер (D_664A)
	CALL	L_633E
	CPI	00Dh
	JZ	L_6000	; рестарт
	LXI  H, D_662C	; = 0 (норм.)/ FF (запуск с минусом)
	MVI  M, 000h
	CPI	02Dh
	JNZ	L_602A
	DCR  M
	CALL	L_633E
L_602A:	SUI	041h
	JC	L_6318	; >> Ошибка
	CPI	01Ah
	JNC	L_6318	; >> Ошибка
	MOV  E, A
	MVI  D, 000h
	LXI  H, D_6041
	DAD  D
	DAD  D
	MOV  E, M
	INX  H
	MOV  D, M
	XCHG
	PCHL
;
D_6041:	.dw L_6075	; A
	.dw L_9100	; B, BM +++
	.dw L_6090	; C
	.dw L_5C50	; D
	.dw L_60B3	; E
	.dw L_60E9	; F
	.dw L_5509	; G +'-G'(с переключением на экран 1)
	.dw L_55CE	; H
	.dw L_56A9	; I
	.dw L_9330	; J +++
	.dw L_56FC	; K
	.dw L_5D2D	; L
	.dw L_6104	; M
	.dw L_6137	; N
	.dw L_5718	; O
	.dw L_5860	; P
	.dw L_61C5	; Q
	.dw L_5908	; R
	.dw L_5A27	; S
	.dw L_5AB3	; T
	.dw L_5AAE	; U
	.dw L_5AF2	; V
	.dw L_5B29	; W
	.dw L_5BC3	; X
	.dw L_9350	; Y +++
	.dw L_9400	; Z + показать экран 1
;
L_6075:	CALL	L_630D	; разбор параметров	; <<< A
	ORA  A
	JZ	L_6086	; нет переметров
	DCR  A
	JNZ	L_6318	; >> ошибка, параметров больше 1
	CALL	L_63C7
	SHLD	D_65EE
L_6086:	XRA  A
	STA     D_6625
	CALL	L_6D94	;L_68D7
	JMP	L_6000	; рестарт
;
L_6090:	CALL	L_630D	; <<< C
	CALL	L_62AF
	JZ	L_6318	; >> Ошибка
	PUSH B
	PUSH D
	POP  B
	POP  D
	XCHG
	DI
VxHS1:	LXI SP, HSTEK
	DCR  A
	JZ	L_60AC
	DCR  A
	JZ	L_60AF
VxRN2:	JMP	RUNCV
;	PCHL		; >> переход к подпрограмме с передачей значений BC и DE
;
L_60AC:	LXI  B, M_0000	;
L_60AF:	LXI  D, M_0000	;
VxRN3:	JMP	RUNCV
;	PCHL		; >> переход к подпрограмме без передачи значений ВС и/или DE
;
L_60B3:	CALL	L_62A7	; <<< E
	CALL	L_62BD	; сравнение BC и DE
	JC	L_6318	; >> Ошибка	; BC..DE -- что, HL -- с чем сравнивать
	XCHG
	PUSH B
	PUSH H
	POP  B
	POP  H		; HL..BC -- что, DE -- с чем сравнивать
	INX  B
	DSUB		; HL = HL - BC
L_60BE:	DAD  B
	PUSH B
	MOV  A, H	; << чтение байта с адреса HL (банк 0 и банк 1)
	STA	Lx60BZ+1
	DI
	RAL
	JC	L_60BY	; HL >= 8000h
	STC
	RAR
	MOV  H, A
	MVI  A, B_PRG0	; ОЗУ: Банк 2, Банк 0
	OUT     00Eh	; режим ОЗУ
L_60BY:	MOV  B, M
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
Lx60BZ:	MVI  H, 0
	MOV  A, D	; << чтение байта с адреса DE (банк 0 и банк 1)
	STA	Lx60CZ+1
	RAL
	JC	L_60CX	; DE >= 8000h
	STC
	RAR
	MOV  D, A
	MVI  A, B_PRG0	; ОЗУ: Банк 2, Банк 0
	OUT     00Eh	; режим ОЗУ
L_60CX:	LDAX D
	MOV  C, A
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	EI
Lx60CZ:	MVI  D, 0
	MOV  A, B
	CMP  C
	POP  B
	JNZ	L_60D4	; вывод различия
L_60DZ:	INX  D
	INX  H
	DSUB		; HL = HL - BC
	JNZ	L_60BE
	JMP	L_6000	; рестарт
;
L_60D4:	CALL	L_6382	; вывод 0Dh,0Ah
	CALL	L_62CA	; вывод HL в HEX, два пробела и число из adr[HL] в HEX
	MVI  A, 009h
	CALL	L_6337	; вывод символа из A
	XCHG
	CALL	L_62CA	; вывод HL в HEX, два пробела и число из adr[HL] в HEX
	XCHG
	CALL	L_638C	; проверка статуса клавиатуры
	JNZ	L_6000	; рестарт
	JMP	L_60DZ
;
L_62CA:	CALL	L_6398	; вывод HL в HEX
	CALL	L_6335	; вывод пробела
	CALL	L_6335	; вывод пробела
	CALL	RBYTE	; чтение байта с адреса HL (банк 0 и банк 1)
	JMP	L_637C	; вывод числа A в HEX
;
L_60E9:	CALL	L_62A7	; <<< F
	MOV  A, H
	ORA  A
	JNZ	L_6318	; >> Ошибка
	CALL	L_62BD	; сравнение BC и DE
	JC	L_6318	; >> Ошибка
	DI
	MVI  A, B_MONW	; ОЗУ: (Банк 2 R / Банк 0 W), Банк 1
	OUT     00Eh	; режим ОЗУ
	MOV  A, L
	XCHG
	INX  H		; HL - конечный адрес
	DSUB		; HL = HL - BC
L_60F8:	DAD  B
	STAX B
	INX  B
;	CALL	L_62BD	; сравнение BC и DE
	DSUB		; HL = HL - BC
	JNZ	L_60F8
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	JMP	L_6000	; рестарт
;
L_6104:	CALL	L_62A7	; <<< M
	CALL	L_62BD	; сравнение BC и DE
	JC	L_6318	; >> Ошибка	; BC - начальный адрес, DE - конечный, HL - куда
	XCHG
	CALL	L_62BD	; сравнение BC и DE
	XCHG
	JNC	L_6123	; >> начальный адрес меньше адреса назначения
L_6116:	MOV  A, B	; << чтение байта с адреса BC (банк 0 и банк 1)
	STA	Lx611Z+1
	DI
	RAL
	JC	RBBB1	; BC >= 8000h
	STC
	RAR
	MOV  B, A
	MVI  A, B_PRG0	; ОЗУ: Банк 2, Банк 0
	OUT     00Eh	; режим ОЗУ
RBBB1:	LDAX B
	MOV  B, A
	MVI  A, B_MONW	; ОЗУ: {Банк 2 R | Банк 0 W}, Банк 1
	OUT     00Eh	; режим ОЗУ
	MOV  M, B
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	EI
Lx611Z:	MVI  B, 0
	INX  B
	INX  H
	CALL	L_62BD	; сравнение BC и DE
	JC	L_6000	; рестарт
	JMP	L_6116
;
L_6123:	DAD  D
	DSUB		; HL = HL - BC
	INX  B
L_612A:	MOV  A, D	; << чтение байта с адреса DE (банк 0 и банк 1)
	STA	Lx612Z+1
	DI
	RAL
	JC	RBDB3	; DE >= 8000h
	STC
	RAR
	MOV  D, A
	MVI  A, B_PRG0	; ОЗУ: Банк 2, Банк 0
	OUT     00Eh	; режим ОЗУ
RBDB3:	LDAX D
	MOV  D, A
	MVI  A, B_MONW	; ОЗУ: {Банк 2 R | Банк 0 W}, Банк 1
	OUT     00Eh	; режим ОЗУ
	MOV  M, D
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	EI
Lx612Z:	MVI  D, 0
	CALL	L_62BD	; сравнение BC и DE
	JC	L_6000	; рестарт
	DCX  D
	DCX  H
	JMP	L_612A
;
L_6137:	CALL	L_633E
	PUSH PSW
	CALL	L_630D
	JZ	L_617B
	DCR  A
	CALL	L_63C7
	ORA  H
	JNZ	L_6318	; >> Ошибка
	MOV  B, L
	LXI  D, D_7FF4
	LXI  H, D_6719
	POP  PSW
	MVI  C, 004h
L_6153:	CMP  M
	JZ	L_6176
	INX  H
	INX  D
	DCR  C
	JNZ	L_6153
	CMP  M
	JNZ	L_616A
	MOV  A, B
	CPI	003h
	JNC	L_6318	; >> Ошибка
	JMP	L_6176
;
L_616A:	INX  H
	INX  D
	CMP  M
	JNZ	L_6318	; >> Ошибка
	MOV  A, B
	CPI	002h
	JNC	L_6318	; >> Ошибка
L_6176:	MOV  A, B
	STAX D
	JMP	L_6000	; рестарт
;
L_617B:	POP  PSW
	CPI	00Dh
	JNZ	L_6318	; >> Ошибка
	LXI  H, D_7FF4
	LXI  D, D_6719
	MVI  B, 004h
L_6189:	CALL	L_62D6
	CALL	L_637B	; вывод числа из adr[HL] в HEX
	INX  H
	INX  D
	DCR  B
	JNZ	L_6189
	MOV  A, M
	PUSH H
	LXI  H, D_6777
	ORA  A
	JZ	L_61A8
	LXI  H, D_677D
	DCR  A
	JZ	L_61A8
	LXI  H, D_6784
L_61A8:	CALL	L_62D6
	CALL	L_7833	; вывод строки до 00h
	POP  H
	INX  H
	INX  D
	MOV  A, M
	LXI  H, D_678B
	ORA  A
	JZ	L_61BC
	LXI  H, D_6795
L_61BC:	CALL	L_62D6
	CALL	L_7833	; вывод строки до 00h
	JMP	L_6000	; рестарт
;
L_61C5:	CALL	L_630D	; <<< Q
	CPI	002h
	JNZ	L_6318	; >> Ошибка
	CALL	L_62AF
	CALL	L_62BD	; сравнение BC и DE
	JC	L_6318	; >> Ошибка
	CALL	L_6382	; вывод 0Dh,0Ah
	MVI  A, 03Ah	; ":"
	CALL	L_6337	; вывод символа из A
	PUSH B
	PUSH D
	CALL	L_6321	; ввод данных в буфер (D_664A)
	CALL	L_634A
	CPI	00Dh
	JZ	L_6000	; рестарт
	CPI	022h	; '"'
	JNZ	L_6238
	LXI  H, D_664B
	MOV  A, M
	INX  H
	INX  H
	POP  D
	POP  B
L_61F8:	PUSH H
	PUSH PSW
	STA     D_66AC
	PUSH B
L_61FE:	CALL	L_62BD	; сравнение BC и DE
	JC	L_6000	; рестарт
	CALL	L_638C
	JNZ	L_6000	; рестарт
;	LDAX B
	MOV  A, B	; чтение байта с адреса BC (банк 0 и банк 1)
	RAL
	JC	L_61FZ	; BC >= 8000h
	STC
	RAR
	PUSH H
	MOV  H, A
	DI
	MVI  A, B_PRG0	; ОЗУ: Банк 2, Банк 0
	OUT     00Eh	; режим ОЗУ
	MOV  L, C
	MOV  H, M
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	EI
	MOV  A, H
	POP  H
L_61FY:	CMP  M
	JNZ	L_6231
	LDA     D_66AC
	DCR  A
	STA     D_66AC
	INX  H
	INX  B
	JNZ	L_61FE
	POP  H
	POP  H
	PUSH H
	MOV  A, C
	SUB  H
	MOV  L, A
	MOV  A, B
	SBI	000h
	MOV  H, A
	CALL	L_6382	; вывод 0Dh,0Ah
	MVI  A, 02Ah
	CALL	L_6337	; вывод символа из A
	CALL	L_6398	; вывод HL в HEX
	PUSH B
L_6231:	POP  B
	INX  B
	POP  PSW
	POP  H
	JMP	L_61F8
;
L_61FZ:	LDAX B
	JMP	L_61FY
;
L_6238:	CPI	027h	; "'"
	JNZ	L_6262
	STA     D_6625
	CALL	L_6360
	LXI  H, D_66AE
	SHLD	D_65F3
L_6249:	CALL	L_6A00
	LDA     D_664B
	ORA  A
	JNZ	L_6249
	LHLD	D_65F3
L_6256:	LXI  D, D_66AE
	CALL	L_63A4
	MOV  A, E
	POP  D
	POP  B
	JMP	L_61F8
;
L_6262:	CPI	03Dh	; "="
	JNZ	L_626B
	XRA  A
	JMP	L_6272
;
L_626B:	CPI	023h	; "#"
	JNZ	L_6318	; >> Ошибка
	MVI  A, 001h
L_6272:	STA     D_66AD
	LXI  D, D_66AE
L_6278:	MVI  C, 000h
L_627A:	CALL	L_634A
	CALL	L_63AB
	JZ	L_6298
	MOV  H, A
	LDA     D_66AD
	ANA  A
	MOV  A, H
	JZ	L_6292
	CALL	L_62EE
	JMP	L_627A
;
L_6292:	CALL	L_62E0
	JMP	L_627A
;
L_6298:	MOV  A, C
	STAX D
	INX  D
	LXI  H, D_664B
	MOV  A, M
	ANA  A
	JNZ	L_6278
	XCHG
	JMP	L_6256
;
L_62A7:	CALL	L_630D
L_62AA:	CPI	003h
	JNZ	L_6318	; >> Ошибка
L_62AF:	CALL	L_63C7
	PUSH H
	CALL	L_63C7
	PUSH H
	CALL	L_63C7	; HL - параметр 1
	POP  D		; параметр 3
	POP  B		; параметр 2
	RET
;
L_62BD:	MOV  A, B	; << сравнение BC и DE
	ANA  C
	INR  A
	JNZ	L_62C5	; >> BC < FFFFh
	STC
	RET
;
L_62C5:	MOV  A, E	; DE > BC ?
	SUB  C
	MOV  A, D
	SBB  B
	RET		; [C] -- DE < BC
;
L_62D6:	CALL	L_6B9D	; вывод двух пробелов
	LDAX D
	CALL	L_6337	; вывод символа из A
	JMP	L_6330
;
L_62E0:	CALL	L_63BA
	MOV  B, A
	MOV  A, C
	RAL
	RAL
	RAL
	RAL
	ANI	0F0h
	ADD  B
	MOV  C, A
	RET
;
L_62EE:	SUI	030h
	CPI	00Ah
	JNC	L_6318	; >> Ошибка
	PUSH PSW
	MOV  A, C
	ADD  A
	MOV  B, A
	ADD  A
	ADD  A
	ADD  B
	MOV  B, A
	POP  PSW
	ADD  B
	MOV  C, A
	RET
;
L_6301:	MOV  A, H	; << сравнение HL и DE
	CMP  D
	RNZ
	MOV  A, L
	CMP  E
L_6306:	RET
;
L_6307:	CALL	L_6398	; вывод HL в HEX
	JMP	L_6335	; вывод пробела
;
L_630D:	LDA     D_662C	; = 0 (норм.)/ FF (запуск с минусом)	; << разбор параметров
	ORA  A
	JNZ	L_6318	; >> Ошибка
L_6314:	CALL	L_64A8
	RNC
L_6318:	LXI  H, D_676A	; "Ошибка"
	CALL	L_7833	; вывод строки до 00h
	JMP	L_6000	; рестарт
;
L_6321:	LXI  H, 0	; << ввод данных в буфер (D_664A)
	SHLD	D_65FD	; обнуляем адрес буфера ввода -- используем внутренний буфер монитора
	MVI  D, 030h	; размер буфера
;	MVI  C, 00Ah
;	LXI  D, D_664A
	CALL	L_5460	;L_5400	; ввод данных в буфер {L_545C}
	LXI  H, D_664C
	SHLD	D_6648
	RET
;
L_6330:	MVI  A, 03Dh	; '='
	JMP	L_6337	; вывод символа из A
;
L_6335:	MVI  A, 020h
L_6337:	PUSH B
	MOV  C, A
	CALL	L_7809	; вывод на экран символа
	POP  B
	RET
;
L_633E:	CALL	L_634A
	CPI	07Fh
	RZ
	CPI	061h
	RC
	ANI	05Fh
	RET
;
L_634A:	PUSH H
	LXI  H, D_664B
	MOV  A, M
	ORA  A
	MVI  A, 00Dh
	JZ	L_635E
	DCR  M
	LHLD	D_6648
	MOV  A, M
	INX  H
	SHLD	D_6648
L_635E:	POP  H
	RET
;
L_6360:	LXI  D, D_664B
	LHLD	D_6648
	LDAX D
	INX  D
	STAX D
L_6369:	LDAX D
	DCR  A
	STAX D
	RZ
	MVI  A, 021h
	CMP  M
	INX  H
	JNZ	L_6369
	DCX  H
	MVI  M, 00Dh
	INX  H
	JMP	L_6369
;
L_637B:	MOV  A, M	; << вывод числа из adr[HL] в HEX
L_637C:	PUSH B
	CALL	L_7815	; вывод числа в HEX
	POP  B
	RET
;
L_6382:	MVI  A, 00Dh	; << вывод 0Dh,0Ah
	CALL	L_6337	; вывод символа из A
	MVI  A, 00Ah
	JMP	L_6337	; вывод символа из A
;
L_638C:	CALL	L_7812	; опрос статуса клавиатуры
	ANI	001h
	RET
;
L_6392:	XCHG		; << вывод DE в HEX
	CALL	L_6398	; вывод HL в HEX
	XCHG
	RET
;
L_6398:	MOV  A, H	; << вывод HL в HEX
	CALL	L_637C	; вывод числа A в HEX
	MOV  A, L
	JMP	L_637C	; вывод числа A в HEX
;
L_63A0:	XCHG		; << HL >= adr[D_6644]
	LHLD	D_6644
L_63A4:	MOV  A, L
	SUB  E
	MOV  L, A
	MOV  A, H
	SBB  D
	XCHG
	RET
;
L_63AB:	CPI	02Bh	; '+'
	RZ
	CPI	02Dh	; '-'
	RZ
	CPI	00Dh	; '<ВК>'
	RZ
	CPI	02Ch	; ','
	RZ
	CPI	020h	; ' '
	RET
;
L_63BA:	SUI	030h
	CPI	00Ah
	RC
	ADI	0F9h
	CPI	010h
	RC
	JMP	L_6318	; >> Ошибка
;
L_63C7:	XCHG
	MOV  E, M
	INX  H
	MOV  D, M
	INX  H
	XCHG
	RET
;
L_63CE:	XCHG
	LXI  H, M_0000	; ?
	CPI	027h
	JNZ	L_63F6
	XCHG
L_63D8:	CALL	L_634A
	CPI	020h
	JC	L_6318	; >> Ошибка
	CPI	027h
	JNZ	L_63F1
	CALL	L_634A
	CALL	L_63AB
	RZ
	CPI	027h
	JNZ	L_6318	; >> Ошибка
L_63F1:	MOV  D, E
	MOV  E, A
	JMP	L_63D8
;
L_63F6:	CPI	023h
	JNZ	L_641A
L_63FB:	CALL	L_633E
	CALL	L_63AB
	JZ	L_6418
	SUI	030h
	CPI	00Ah
	JNC	L_6318	; >> Ошибка
	DAD  H
	MOV  B, H
	MOV  C, L
	DAD  H
	DAD  H
	DAD  B
	MOV  C, A
	MVI  B, 000h
	DAD  B
	JMP	L_63FB
;
L_6418:	XCHG
	RET
;
L_641A:	CPI	05Eh
	JNZ	L_6431
	PUSH D
	LHLD	D_66F4
L_6423:	MOV  E, M
	INX  H
	MOV  D, M
	INX  H
	CALL	L_633E
	CPI	05Eh
	JZ	L_6423
	POP  H
	RET
;
L_6431:	CALL	L_63BA
	DAD  H
	DAD  H
	DAD  H
	DAD  H
	ORA  L
	MOV  L, A
	CALL	L_633E
	CALL	L_63AB
	JNZ	L_6431
	XCHG
	RET
;
L_6445:	XCHG
	SHLD	D_65FF
	XCHG
	MOV  M, E
	INX  H
	MOV  M, D
	INX  H
	PUSH H
	LXI  H, D_663B
	INR  M
	POP  H
	RET
;
L_6455:	CPI	02Dh
	JNZ	L_6460
	LXI  D, M_0000	; ?
	JMP	L_6486
;
L_6460:	CPI	02Bh
	JNZ	L_646D
	XCHG
	LHLD	D_65FF
	XCHG
	JMP	L_6475
;
L_646D:	CALL	L_63CE
L_6470:	CPI	02Bh
	JNZ	L_6483
L_6475:	PUSH D
	CALL	L_633E
	CALL	L_63CE
	POP  B
	XCHG
	DAD  B
	XCHG
	JMP	L_6470
;
L_6483:	CPI	02Dh
	RNZ
L_6486:	CALL	L_633E
	PUSH D
	CALL	L_63CE
	POP  B
	PUSH PSW
	MOV  A, C
	SUB  E
	MOV  E, A
	MOV  A, B
	SBB  D
	MOV  D, A
	POP  PSW
	JMP	L_6470
;
L_6499:	CALL	L_633E
	LXI  H, D_662D
	MVI  M, 000h
	CPI	057h	; "W"
	JNZ	L_64AB
	MVI  M, 0FFh
L_64A8:	CALL	L_633E
L_64AB:	LXI  H, D_663B
	MVI  M, 000h
	INX  H
	CPI	00Dh
	JZ	L_64ED
	CPI	02Ch	; ","
	JNZ	L_64C6
	MVI  A, 080h
	STA     D_663B
	LXI  D, M_0000	; ?
	JMP	L_64C9
;
L_64C6:	CALL	L_6455
L_64C9:	CALL	L_6445
	CPI	00Dh
	JZ	L_64ED
	CALL	L_633E
	CALL	L_6455
	CALL	L_6445
	CPI	00Dh
	JZ	L_64ED
	CALL	L_633E
	CALL	L_6455
	CALL	L_6445
	CPI	00Dh
	JNZ	L_6318	; >> Ошибка
L_64ED:	LXI  D, D_663B
	LDAX D
	CPI	081h
	JZ	L_6318	; >> Ошибка
	INX  D
	ORA  A
	RLC
	RRC
	RET
;
L_64FB:	PUSH H
	LXI  H, D_6714
	MOV  E, B
	MVI  D, 000h
	DAD  D
	MOV  C, M
	LXI  H, D_66F2
	MOV  A, M
	XCHG
	POP  H
	RET
;
L_650B:	CALL	L_64FB
L_650E:	DCR  C
	JZ	L_6516
	RAR
	JMP	L_650E
;
L_6516:	ANI	001h
	RET
;
L_6519:	SUI	006h
	LXI  H, D_670F
	MOV  E, A
	MVI  D, 000h
	DAD  D
	MOV  E, M
	MVI  D, 0FFh
	LXI  H, D_66FA
	DAD  D
	RET
;
L_652A:	CALL	L_6519
	MOV  E, M
	INX  H
	MOV  D, M
	XCHG
	RET
;
L_6532:	MOV  A, B
	CPI	005h
	JNC	L_6545
	CALL	L_650B
	ORA  A
	MVI  A, 02Dh
	JZ	L_6337	; вывод символа из A
	MOV  A, M
	JMP	L_6337	; вывод символа из A
;
L_6545:	PUSH PSW
	MOV  A, M
	CALL	L_6337	; вывод символа из A
	CALL	L_6330
	POP  PSW
	JNZ	L_6558
	LXI  H, D_66F3
	CALL	L_637B	; вывод числа из adr[HL] в HEX
	RET
;
L_6558:	CALL	L_652A
	CALL	L_6398	; вывод HL в HEX
	RET
;
L_655F:	CALL	L_6382	; вывод 0Dh,0Ah		<<< вывод значений регистров
	LDA     D_662C	; = 0 (норм.)/ FF (запуск с минусом)
	ORA  A
	JNZ	L_658A
	MVI  B, 001h
	LHLD	D_66F4	; = SP
L_656E:	CALL	RWORD	; чтение двух байт в DE с адреса HL (банк 0 и банк 1)
;	MOV  E, M
;	INX  H
;	MOV  D, M
;	INX  H
	PUSH B
L_6573:	MVI  A, 05Eh	; '^'
	CALL	L_6337	; вывод символа из A
	DCR  B
	JNZ	L_6573
	POP  B
	CALL	L_6330	; '='
	CALL	L_6392	; вывод DE в HEX
	INR  B
	MOV  A, B
	CPI	004h
	JNZ	L_656E
L_658A:	CALL	L_6335	; вывод пробела
	LXI  H, D_6704
	MVI  B, 000h
L_6592:	PUSH B
	PUSH H
	CALL	L_6532
	POP  H
	POP  B
	INR  B
	INX  H
	MOV  A, B
	CPI	00Bh
	JNC	L_65AC
	CPI	005h
	JC	L_6592
	CALL	L_6335	; вывод пробела
	JMP	L_6592
;
L_65AC:	CALL	L_6335	; вывод пробела
	CALL	L_5E8F
	PUSH PSW
	PUSH D
	PUSH B
	LHLD	D_66F8
	SHLD	D_65EE
	LXI  H, D_65F2
	MVI  M, 0FFh
	CALL	L_6BC3	;L_68D4
	LHLD	D_66F8
	CALL	RBYTE	; чтение байта с адреса HL (банк 0 и банк 1)
;	MOV  A, M
	ANI	0C7h
	CPI	086h
	JZ	L_65D6
	CALL	RBYTE	; чтение байта с адреса HL (банк 0 и банк 1)
;	MOV  A, M
	ANI	0FEh
	CPI	034h
	JNZ	L_65DF
L_65D6:	CALL	L_6330
	LHLD	D_66F6
	CALL	L_637B	; вывод числа из adr[HL] в HEX
L_65DF:	POP  B
	POP  D
	POP  PSW
	RET
;
L_65E3:	LXI  H, M_0000	; ?
	SHLD	D_6630
	XRA  A
	STA     D_662F
	RET
;
D_65EE:	.dw 00100h	; адрес старта вывода по команде L, A...
D_65F0:	.dw 0FFFFh	;
D_65F2:	.db 000h	;
D_65F3:	.dw 00000h	;
D_65F5:	.dw 03FFEh	;
D_65F7:	.db 000h	;
D_65F8:	.db 000h	;
	.db 000h	;
	.db 000h	;
	.db 000h	; "_" - |        | (adr. 65FBh)
	.db 000h	; "_" - |        | (adr. 65FCh)
D_65FD:	.dw 00000h	; адрес буфера ввода
D_65FF:	.dw 00000h	;
D_6601:	.db 000h	;
D_6602:	.dw 00000h	;
D_6604:	.db 000h	;
D_6605:	.db 000h	;
	.db 000h	;
	.db 000h	;
	.db 000h	;
	.db 000h	;
	.db 000h	;
	.db 000h	;
	.db 000h	;
	.db 000h	; "_" - |        | (adr. 660Dh)
	.db 000h	; "_" - |        | (adr. 660Eh)
	.db 000h	; "_" - |        | (adr. 660Fh)
	.db 000h	; "_" - |        | (adr. 6610h)
	.db 000h	; "_" - |        | (adr. 6611h)
	.db 000h	; "_" - |        | (adr. 6612h)
	.db 000h	; "_" - |        | (adr. 6613h)
	.db 000h	; "_" - |        | (adr. 6614h)
	.db 000h	; "_" - |        | (adr. 6615h)
	.db 000h	; "_" - |        | (adr. 6616h)
	.db 000h	; "_" - |        | (adr. 6617h)
	.db 000h	; "_" - |        | (adr. 6618h)
	.db 000h	; "_" - |        | (adr. 6619h)
	.db 000h	; "_" - |        | (adr. 661Ah)
	.db 000h	; "_" - |        | (adr. 661Bh)
	.db 000h	; "_" - |        | (adr. 661Ch)
	.db 000h	; "_" - |        | (adr. 661Dh)
	.db 000h	; "_" - |        | (adr. 661Eh)
	.db 000h	; "_" - |        | (adr. 661Fh)
	.db 000h	; "_" - |        | (adr. 6620h)
D_6621:	.db 000h	;
	.db 000h	; "_" - |        | (adr. 6622h)
	.db 000h	; "_" - |        | (adr. 6623h)
	.db 000h	; "_" - |        | (adr. 6624h)
D_6625:	.db 000h	; "_" - |        | (adr. 6625h)
D_6626:	.db 000h	; = 0 (G)/ FF (T,U, ...)
D_6627:	.db 000h	; "_" - |        | (adr. 6627h)
D_6628:	.dw 00000h	;
D_662A:	.dw 00000h	;
D_662C:	.db 000h	; = 0 (норм.) / FF (запуск с минусом)
D_662D:	.db 000h	; = 0 (без "W") / FF (с "W")
D_662E:	.db 000h	; "_" - |        | (adr. 662Eh)
D_662F:	.db 000h	; "_" - |        | (adr. 662Fh)
D_6630:	.dw 00001h	;
D_6632:	.dw 00000h	;
D_6634:	.db 000h	;
	.db 000h	;
	.db 000h	;
	.db 000h	;
	.db 000h	; "_" - |        | (adr. 6638h)
	.db 000h	; "_" - |        | (adr. 6639h)
	.db 000h	; "_" - |        | (adr. 663Ah)
D_663B:	.db 000h	; количество параметров
	.dw 00000h	; параметр 1
	.dw 00000h	; параметр 2
	.dw 00000h	; параметр 3
D_6642:	.dw 00100h	; адрес старта вывода по команде D
D_6644:	.dw 00000h	;
D_6646:	.dw 00000h	;
D_6648:	.dw 00000h	;
D_664A:	.db 030h	; буфер строки ввода -- размер буфера
D_664B:	.db 000h	; длина строки
D_664C:	.db 00Dh	; строка текущей команды
D_664D:	.ds 254
D_667C:	.dw 00000h	;
D_667E:	.db "???????????"	; имя по команде I
	.db 000h
D_668A:	.db 000h	; "_" - |        | (adr. 668Ah)
D_668B:	.db 000h	; КС блока
D_668C:	.db 000h	; "_" - |        | (adr. 668Ch)
D_668D:	.db "NODISC00100788"
D_669B:	.db "SMONSTR5SYS"	; имя по команде O
	.db 000h
	.db 000h	; "_" - |        | (adr. 66A7h)
D_66A8:	.db 001h	; начальный блок ROM
	.db 001h	; количество блоков ROM
	.db 000h	; смещение
	.db 000h	; "_" - |        | (adr. 66ABh)
D_66AC:	.db 000h	; "_" - |        | (adr. 66ACh)
D_66AD:	.db 000h	; "_" - |        | (adr. 66ADh)
D_66AE:	.db 000h	; "_" - |        | (adr. 66AEh)
	.db 000h	; "_" - |        | (adr. 66AFh)
	.db 000h	; "_" - |        | (adr. 66B0h)
	.db 000h	; "_" - |        | (adr. 66B1h)
	.db 000h	; "_" - |        | (adr. 66B2h)
	.db 000h	; "_" - |        | (adr. 66B3h)
	.db 000h	; "_" - |        | (adr. 66B4h)
	.db 000h	; "_" - |        | (adr. 66B5h)
	.db 000h	; "_" - |        | (adr. 66B6h)
	.db 000h	; "_" - |        | (adr. 66B7h)
	.db 000h	; "_" - |        | (adr. 66B8h)
	.db 000h	; "_" - |        | (adr. 66B9h)
	.db 000h	; "_" - |        | (adr. 66BAh)
	.db 000h	; "_" - |        | (adr. 66BBh)
	.db 000h	; "_" - |        | (adr. 66BCh)
	.db 000h	; "_" - |        | (adr. 66BDh)
	.db 000h	; "_" - |        | (adr. 66BEh)
	.db 000h	; "_" - |        | (adr. 66BFh)
	.db 000h	; "_" - |        | (adr. 66C0h)
	.db 000h	; "_" - |        | (adr. 66C1h)
	.db 000h	; "_" - |        | (adr. 66C2h)
	.db 000h	; "_" - |        | (adr. 66C3h)
	.db 000h	; "_" - |        | (adr. 66C4h)
	.db 000h	; "_" - |        | (adr. 66C5h)
D_66C6:	.db 000h	; 
	.db 000h	; "_" - |        | (adr. 66C7h)
;
;;	.ds 37
;
D_66EE:	.dw 00000h	; DE	чтение через стек при RST5
	.dw 00000h	; BC
D_66F2:	.db 002h	; PSW признаки
D_66F3:	.db 000h	; PSW A
D_66F4:	.dw HSTEK	;05000h	; SP	запись через стек
D_66F6:	.dw 00000h	; HL
;
D_66F8:	.dw 00100h	; адрес запуска по G / адрес возврата при RST5 -1
;
D_66FA:	.dw 02710h	; = 10000
	.dw 003E8h	; = 1000
	.dw 00064h	; = 100
	.dw 0000Ah	; = 10
	.dw 00001h	; = 1
;
D_6704:	.db 043h	; "C" - | ■    ■■| (adr. 6704h)
	.db 05Ah	; "Z" - | ■ ■■ ■ | (adr. 6705h)
	.db 04Dh	; "M" - | ■  ■■ ■| (adr. 6706h)
	.db 045h	; "E" - | ■   ■ ■| (adr. 6707h)
	.db 049h	; "I" - | ■  ■  ■| (adr. 6708h)
	.db 041h	; "A" - | ■     ■| (adr. 6709h)
	.db 042h	; "B" - | ■    ■ | (adr. 670Ah)
	.db 044h	; "D" - | ■   ■  | (adr. 670Bh)
	.db 048h	; "H" - | ■  ■   | (adr. 670Ch)
	.db 053h	; "S" - | ■ ■  ■■| (adr. 670Dh)
	.db 050h	; "P" - | ■ ■    | (adr. 670Eh)
;
D_670F:	.db 0F6h	; "Ў" - |■■■■ ■■ | (adr. 670Fh)
	.db 0F4h	; "Ї" - |■■■■ ■  | (adr. 6710h)
	.db 0FCh	; "№" - |■■■■■■  | (adr. 6711h)
	.db 0FAh	; "·" - |■■■■■ ■ | (adr. 6712h)
	.db 0FEh	; "■" - |■■■■■■■ | (adr. 6713h)
D_6714:	.db 001h	; "_" - |       ■| (adr. 6714h)
	.db 007h	; "_" - |     ■■■| (adr. 6715h)
	.db 008h	; "_" - |    ■   | (adr. 6716h)
	.db 003h	; "_" - |      ■■| (adr. 6717h)
	.db 005h	; "_" - |     ■ ■| (adr. 6718h)
;
D_6719:	.db 057h	; "W" - аргументы команды N
	.db 052h	; "R"
	.db 046h	; "F"
	.db 043h	; "C"
	.db 050h	; "P"
	.db 04Bh	; "K"
;
D_671F:	.db 0FFh	; маска
	.db 0C3h	; команда JMP
	.db 0C7h	;
	.db 0C2h	; J*
	.db 0FFh	;
	.db 0CDh	; CALL
	.db 0C7h	;
	.db 0C4h	; C*
	.db 0FFh	;
	.db 0C9h	; RET
	.db 0C7h	;
	.db 0C0h	; R*
	.db 0FFh	;
	.db 0E9h	; PCHL
	.db 0C7h	;
	.db 0C7h	; RST *
	.db 0CFh	;
	.db 001h	; LXI *, ...
	.db 0E7h	;
	.db 022h	; LHLD, LDA, SHLD, STA
	.db 0C7h	;
	.db 006h	; MVI *, ...
	.db 0C7h	;
	.db 0C6h	; ADI, SUI, ANI, ORI, ACI, SBI, XRI, CPI
	.db 0F7h	;
	.db 0D3h	; IN, OUT
;
D_6739:	.db " prohod "
	.db 000h
D_6742:	.db 00Dh
	.db 00Ah
	.db "    poisk: "
	.db 000h
D_6750:	.db 00Dh, 00Ah
	.db "programma: "
	.db 000h
D_675E:	.db "zagruveno: "
	.db 000h
D_676A:	.db "  <- o{ibka"
	.db 007h, 000h
D_6777:	.db 022h, "ROB", 022h
	.db 000h
D_677D:	.db 022h, "EPS1", 022h
	.db 000h
D_6784:	.db 022h, "EPS2", 022h
	.db 000h
D_678B:	.db 022h, "JCUKEN", 022h
	.db 007h, 000h
D_6795:	.db 022h, "QWERTY", 022h
	.db 007h, 000h
;	
D_679F:	.db 000h	; 19 11 NOP
	.db 007h	; 18 10 RLC
	.db 00Fh	; 17 0F RRC
	.db 017h	; 16 0E RAL
	.db 01Fh	; 15 0D RAR
	.db 027h	; 14 0C DAA
	.db 02Fh	; 13 0B CMA
	.db 037h	; 12 0A STC
	.db 03Fh	; 11 09 CMC
	.db 076h	; 10 08 HLT
	.db 0C9h	; 0F 07 RET
	.db 0E3h	; 0E 06 XTHL
	.db 0E9h	; 0D 05 PCHL
	.db 0EBh	; 0C 04 XCHG
	.db 0F3h	; 0B 03 DI
	.db 0F9h	; 0A 02 SPHL
	.db 0FBh	; 09 01 EI
	.db 008h	; 08 ++ DSUB
	.db 010h	; 07 ++ ARHL
	.db 018h	; 06 ++ RDEL
	.db 020h	; 05 ++ RIM
	.db 030h	; 04 ++ SIM
	.db 0CBh	; 03 ++ RSTV
	.db 0D9h	; 02 ++ SHLX
	.db 0EDh	; 01 ++ LHLX
;	
	.db 0C6h	; 0C 0A ADI
	.db 0CEh	; 0B 09 ACI
	.db 0D3h	; 0A 08 OUT
	.db 0D6h	; 09 07 SUI
	.db 0DBh	; 08 06 IN
	.db 0DEh	; 07 05 SBI
	.db 0E6h	; 06 04 ANI
	.db 0EEh	; 05 03 XRI
	.db 0F6h	; 04 02 ORI
	.db 0FEh	; 03 01 CPI
	.db 028h	; 02 ++ LDHI
	.db 038h	; 01 ++ LDSI
;
	.db 022h	; 06 SHLD
	.db 02Ah	; 05 LHLD
	.db 032h	; 04 STA
	.db 03Ah	; 03 LDA
	.db 0C3h	; 02 JMP
	.db 0CDh	; 01 CALL
;
D_67C0:	.db "LHLX"
	.db "SHLX"
	.db "RSTV"
	.db "SIM "
	.db "RIM "
	.db "RDEL"
	.db "ARHL"
	.db "DSUB"
	.db "EI  "
	.db "SPHL"
	.db "DI  "
	.db "XCHG"
	.db "PCHL"
	.db "XTHL"
	.db "RET "
	.db "HLT "
	.db "CMC "
	.db "STC "
	.db "CMA "
	.db "DAA "
	.db "RAR "
	.db "RAL "
	.db "RRC "
	.db "RLC "
D_6800:	.db "NOP "
;
D_6804:	.db "LDSI"
	.db "LDHI"
	.db "CPI "
	.db "ORI "
	.db "XRI "
	.db "ANI "
	.db "SBI "
	.db "IN  "
	.db "SUI "
	.db "OUT "
	.db "ACI "
D_6828:	.db "ADI "
;
D_682C:	.db "CALL"
	.db "JMP "
	.db "LDA "
	.db "STA "
	.db "LHLD"
D_6840:	.db "SHLD"
;
D_6844:	.db "MOV "
D_6848:	.db "ADD "
	.db "ADC "
	.db "SUB "
	.db "SBB "
	.db "ANA "
	.db "XRA "
	.db "ORA "
D_6864:	.db "CMP "
D_6868:	.db "INR "
D_686C:	.db "DCR "
D_6870:	.db "MVI "
D_6874:	.db "LXI "
	.db "STAX"
	.db "INX "
	.db "DAD "
	.db "LDAX"
D_6888:	.db "DCX "
D_688C:	.db "RST "
D_6890:	.db "PSW "
;
D_6894:	.db "POP "
D_6898:	.db "PUSH"
;
D_689C:	.db "NZ"	; 1 00
	.db "Z "	; 2 08
	.db "NC"	; 3 10
	.db "C "	; 4 18
	.db "PO"	; 5 20
	.db "PE"	; 6 28
	.db "P "	; 7 30
D_68AA:	.db "M "	; 8 38
	.db "NK"	; 9 1D
D_68AE:	.db "K "	; A 3D
;
	.db "B "	; 1
	.db "C "	; 2
	.db "D "	; 3
	.db "E "	; 4
	.db "H "	; 5
	.db "L "	; 6
	.db "M "	; 7
D_68BA:	.db "A "	; 8
;
	.db "B   "	; 1
	.db "D   "	; 2
	.db "H   "	; 3
	.db "SP  "	; 4
D_68CC:	.db "PSW "	; 5
;
D_68D0:	.db "??= "	; наверно, это уже не нужно...
;
;L_68D4:	JMP	L_6BC3
;
;L_68D7:	JMP	L_6D94
;
L_68DA:	CPI	020h
	RZ
	CPI	009h
	RZ
	CPI	02Ch
	RZ
	CPI	00Dh
	RZ
	CPI	07Fh
	JZ	L_6D94
	RET
;
L_68EC:	CALL	L_633E
L_68EF:	CPI	00Dh
	JZ	L_6D81
	CALL	L_68DA
	JZ	L_68EC
	MVI  C, 004h
	LXI  H, D_65F7
L_68FF:	MVI  M, 020h
	INX  H
	DCR  C
	JNZ	L_68FF
	MVI  C, 005h
	LXI  H, D_65F7
L_690B:	MOV  M, A
	CALL	L_633E
	CALL	L_68DA
	JZ	L_691D
	INX  H
	DCR  C
	JZ	L_6D81
	JMP	L_690B
;
L_691D:	LDA     D_65F7
	CPI	020h
	RET
;
L_6923:	CALL	L_64A8
	DCR  A
	JNZ	L_6D81
	XCHG
	MOV  C, M
	INX  H
	MOV  B, M
	MOV  A, C
	DCR  B
	INR  B
	RET
;
L_6932:	CALL	L_6923
	JNZ	L_6D81
	RET
;
L_6939:	RAL
	RAL
	RAL
	ANI	038h
	RET
;
L_693F:	RAL
	RAL
	RAL
	RAL
	ANI	030h
	RET
;
L_6946:	XCHG
	LHLD	D_65F7
	XCHG
L_694B:	MOV  A, E
	CMP  M
	JNZ	L_6955
	INX  H
	MOV  A, D
	CMP  M
	RZ
	DCX  H
L_6955:	DCX  H
	DCX  H
	DCR  C
	JNZ	L_694B
	DCR  C
	RET
;
L_695D:	MVI  B, 004h	; << поиск 4 байт adr[D_65F7] в таблице с adr[HL], С-счётчик записей, DE-код
	PUSH D
	LXI  D, D_65F7
L_6963:	LDAX D
	CMP  M
	JNZ	L_6970
	INX  H
	INX  D
	DCR  B
	JNZ	L_6963
	POP  D
	RET
;
L_6970:	INX  H
	DCR  B
	JNZ	L_6970
	LXI  D, 0FFF8h	; = -8
	DAD  D
	POP  D
	INX  D
	DCR  C
	JNZ	L_695D
	DCR  C
	RET
;
L_6981:	PUSH B
	CALL	L_68EC
	JZ	L_6D81
	MVI  C, 008h
	LXI  H, D_68BA	; список регистров
	CALL	L_6946
	JNZ	L_6D81
	DCR  C
	MOV  A, C
	POP  B
	RET
;
L_6997:	PUSH B
	CALL	L_68EC
	JZ	L_6D81
	MVI  C, 005h
	LXI  H, D_68CC
	CALL	L_695D	; поиск
	JNZ	L_6D81
	DCR  C
	MOV  A, C
	POP  B
	RET
;
L_69AD:	CALL	L_6997
	CPI	004h
	JZ	L_6D81
	RET
;
L_69B6:	CALL	L_6997
	CPI	003h
	JZ	L_6D81
	CPI	004h
	RNZ
	DCR  A
	RET
;
L_69C3:	LXI  H, D_65F7
	LXI  D, D_65F8
	MVI  C, 002h
L_69CB:	LDAX D
	MOV  M, A
	INX  H
	INX  D
	DCR  C
	JNZ	L_69CB
	LDAX D
	CPI	020h
	JNZ	L_6D81	; >> ошибка
	MOV  M, A
	LXI  H, D_68AA
	MVI  C, 008h
	CALL	L_6946
	JNZ	L_69CX	;L_6D81	; >> ошибка
	DCR  C
	MOV  A, C
	CALL	L_6939	; A=A*8 & 38h
	ORI	0C0h
	RET
;
L_69CX:	LXI  H, D_68AE	; поиск K, NK
	MVI  C, 002h
	CALL	L_6946	; C=2 (K) / 1 (NK)
	JNZ	L_6D81	; >> ошибка
	MVI  A, 0DDh	; "JNK"
	DCR  C
	RZ
	MVI  A, 0FDh	; "JK"
	DCR  C		; уст.признак Z
	RET
;
L_69EB:	CALL	L_69C3
	PUSH PSW
	CALL	L_6923	; проверка строки далее
	POP  PSW
;	ORI	0C0h
	RET
;
L_69F6:	LDAX D
L_69F7:	MOV  H, A
	DI
	MVI  A, B_MONW	; ОЗУ: {Банк 2 R | Банк 0 W}, Банк 1
	OUT     00Eh	; режим ОЗУ
	MOV  A, H
	LHLD	D_65F3
	MOV  M, A
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	EI
	INX  H
	SHLD	D_65F3
	RET
;
L_6A00:	CALL	L_633E
	CPI	00Dh
	JZ	L_6DB0
	CALL	L_68EF
	JZ	L_6D81
	MVI  C, 019h
	LXI  H, D_6800
	LXI  D, D_679F
	CALL	L_695D	; поиск
	JNZ	L_6A1F
	JMP	L_69F6
;
L_6A1F:	MVI  C, 00Ch
	LXI  H, D_6828
	CALL	L_695D	; поиск
	JNZ	L_6A33
	CALL	L_69F6
	CALL	L_6932
	JMP	L_69F7
;
L_6A33:	MVI  C, 006h
	LXI  H, D_6840
	CALL	L_695D	; поиск
	JNZ	L_6A4B
	CALL	L_69F6
L_6A41:	CALL	L_6923
	CALL	L_69F7
	MOV  A, B
	JMP	L_69F7
;
L_6A4B:	MVI  C, 001h
	LXI  H, D_6844
	CALL	L_695D	; поиск
	JNZ	L_6A67
	CALL	L_6981
	CALL	L_6939
	MOV  B, A
	MVI  C, 040h
L_6A5F:	CALL	L_6981
	ORA  C
	ORA  B
	JMP	L_69F7
;
L_6A67:	MVI  C, 008h
	LXI  H, D_6864
	CALL	L_695D	; поиск
	JNZ	L_6A7D
	DCR  C
	MOV  A, C
	CALL	L_6939
	MOV  B, A
	MVI  C, 080h
	JMP	L_6A5F
;
L_6A7D:	MVI  C, 002h
	LXI  H, D_686C
	CALL	L_695D	; поиск
	JNZ	L_6A95
	INR  C
	INR  C
	INR  C
	CALL	L_6981
	CALL	L_6939
	ORA  C
	JMP	L_69F7
;
L_6A95:	MVI  C, 001h
	LXI  H, D_6870
	CALL	L_695D	; поиск
	JNZ	L_6AB1
	CALL	L_6981
	CALL	L_6939
	ORI	006h
	CALL	L_69F7
	CALL	L_6932
	JMP	L_69F7
;
L_6AB1:	MVI  C, 006h
	LXI  H, D_6888
	CALL	L_695D	; поиск
	JNZ	L_6AD7
	MOV  A, C
	CPI	004h
	JC	L_6AC4
	ADI	005h
L_6AC4:	MOV  B, A
	CALL	L_69AD
	CALL	L_693F
	ORA  B
	PUSH PSW
	CALL	L_69F7
	POP  PSW
	ANI	0CFh
	CPI	001h
	RNZ
	JMP	L_6A41
;
L_6AD7:	MVI  C, 001h
	LXI  H, D_688C
	CALL	L_695D	; поиск
	JNZ	L_6AF2
	CALL	L_6932
	CPI	008h
	JNC	L_6D81
	CALL	L_6939
	ORI	0C7h
	JMP	L_69F7
;
L_6AF2:	MVI  C, 002h
	LXI  H, D_6898
	CALL	L_695D	; поиск
	JNZ	L_6B12
	DCR  C
	JNZ	L_6B06
	MVI  C, 0C1h
	JMP	L_6B08
;
L_6B06:	MVI  C, 0C5h
L_6B08:	CALL	L_69B6
	CALL	L_693F
	ORA  C
	JMP	L_69F7
;
L_6B12:	LDA     D_65F7
	CPI	04Ah	; 'J'
	JNZ	L_6B22
	CALL	L_69EB	; проверка продолжения команды
	JZ	L_6B2C
	ORI	002h	; J*
	JMP	L_6B2C
;
L_6B22:	CPI	043h	; 'C'
	JNZ	L_6B37
	CALL	L_69EB
	JZ	L_6D81	; ошибка
	ORI	004h	; C*
L_6B2C:	CALL	L_69F7
	MOV  A, C
	CALL	L_69F7
	MOV  A, B
	JMP	L_69F7
;
L_6B37:	CPI	052h	; 'R'
	JNZ	L_6D81
	CALL	L_69C3
	JZ	L_6D81	; ошибка
;	ORI	0C0h	; R*
	JMP	L_69F7
;
L_6B44:	LHLD	D_65F0
	PUSH D
	XCHG
	LHLD	D_65EE
	MOV  A, E
	SUB  L
	MOV  A, D
	SBB  H
	JC	L_6DB0
	POP  D
;	MOV  A, M
	CALL	RBYTE	; чтение байта с адреса HL (банк 0 и банк 1)
	INX  H
	SHLD	D_65EE
	RET
;
L_6B5A:	INR  A
	ANI	007h
	CPI	006h
	JC	L_6B64
	ADI	003h
L_6B64:	CPI	005h
	JC	L_6B6B
	ADI	002h
L_6B6B:	ADI	041h
	JMP	L_6337	; вывод символа из A
;
L_6B70:	MVI  B, 004h
L_6B72:	MOV  C, M
	CALL	L_6B7D
	INX  H
	DCR  B
	JNZ	L_6B72
L_6B7B:	MVI  C, 020h	; ' '
L_6B7D:	PUSH PSW
	MOV  A, C
	CALL	L_6337	; вывод символа из A
	POP  PSW
	RET
;
L_6B84:	MOV  A, D
	ANI	038h
	RRC
	RRC
	RRC
	RET
;
L_6B8B:	CALL	L_6B84
L_6B8E:	ADD  A
	MOV  C, A
	LXI  H, D_689C	; окончания C*, J*, R*...
	DAD  B
	MOV  C, M
	CALL	L_6B7D
	INX  H
	MOV  C, M
	CALL	L_6B7D
L_6B9D:	CALL	L_6B7B	; << вывод двух пробелов
	JMP	L_6B7B
;
L_6BA3:	CALL	L_6B84
	ANI	006h
	CPI	006h
	JNZ	L_6B5A
	MVI  C, 053h
	CALL	L_6B7D
	MVI  C, 050h
	JMP	L_6B7D
;
L_6BB7:	CALL	L_6382	; вывод 0Dh,0Ah
L_6BBA:	LHLD	D_65EE
	CALL	L_6398	; вывод HL в HEX
	JMP	L_6B9D	; вывод двух пробелов
;
L_6BC3:	LXI  H, 00000h
	DAD  SP
	SHLD	D_65F5
	LDA     D_65F2
	ORA  A
	JZ	L_6BE5
	LXI  H, 0FFFFh	; ?
	SHLD	D_65F0
	INR  A
	JNZ	L_6BE5
	INR  A
	STA     D_65F2
	LHLD	D_65EE
	JMP	L_6C00
;
L_6BE5:	CALL	L_638C
	JNZ	L_6DB0
	LXI  H, D_65F2
	MOV  A, M
	ORA  A
	JZ	L_6BF7
	DCR  M
	JZ	L_6DB0
L_6BF7:	CALL	L_6382	; вывод 0Dh,0Ah
	CALL	L_6B9D	; вывод двух пробелов
	CALL	L_6BBA	; вывод текущего адреса
L_6C00:	CALL	L_6B44
	MOV  D, A	; текущий код
	LXI  H, D_679F
	LXI  B, 00019h	; счётчик
L_6C0A:	CMP  M
	JZ	L_6D66	; >>
	INX  H
	DCR  C
	JNZ	L_6C0A	; проверка на команды из одного слова
	MVI  C, 00Ch	; ещё один счётчик
L_6C15:	CMP  M
	JZ	L_6D52	; >>
	INX  H
	DCR  C
	JNZ	L_6C15	; проверка на команды вида "слово"+D8 
	MVI  C, 006h
L_6C20:	CMP  M
	JZ	L_6D37	; >>
	INX  H
	DCR  C
	JNZ	L_6C20	; проверка на команды вида "слово"+A16 
	ANI	0C0h
	CPI	040h
	JZ	L_6D1D	; >> проверка на команды MOV (40h-7Fh)
	CPI	080h
	JZ	L_6D0E	; >> проверка на команды вида "слово"+регистр (80h-BFh)
	MOV  A, D
	ANI	0C7h
	SUI	004h
	JZ	L_6CFF	; >> проверка на команды INR R
	DCR  A
	JZ	L_6CF9	; >> проверка на команды DCR R
	DCR  A
	JZ	L_6CE5	; >> проверка на команды MVI R, ...
	MOV  A, D
	ANI	0C0h
	JZ	L_6CB3	; >> проверка на команды LXI,STAX,INX,DAD,LDAX,DCX и код меньше C0h (недокументированные 8080)
	MOV  A, D
	ANI	007h
	JZ	L_6CA8	; >> проверка на команды R*
	SUI	002h
	JZ	L_6C9D	; >> проверка на команды J*
	SUI	002h
	JZ	L_6C92	; >> проверка на команды C*
	SUI	003h
	JZ	L_6C83	; >> проверка на команды RST *
	MOV  A, D
	ANI	00Fh
	CPI	00Dh
	JZ	L_6CAZ	; >> проверка на команды JK/JNK
	ANI	008h
	JNZ	L_6D74	; >> код больше С8h/D8h/E8h/F8h (ещё недокументированные 8080)
	MOV  A, D
	ANI	007h
	MOV  C, A
	DCR  A
	LXI  H, D_6894-1
	DAD  B		; команды PUSH и POP
	CALL	L_6B70
	CALL	L_6B84
	CPI	006h
	JNZ	L_6D08
	LXI  H, D_6890
	CALL	L_6B70
	JMP	L_6BE5
;
L_6C83:	LXI  H, D_688C
	CALL	L_6B70
	CALL	L_6B84
	CALL	L_637C	; вывод числа A в HEX
	JMP	L_6BE5
;
L_6C92:	MVI  C, 043h	; 'C'
	CALL	L_6B7D
	CALL	L_6B8B
	JMP	L_6D42
;
L_6C9D:	MVI  C, 04Ah	; 'J'
	CALL	L_6B7D
	CALL	L_6B8B
	JMP	L_6D42
;
L_6CA8:	MVI  C, 052h	; 'R'
	CALL	L_6B7D
	CALL	L_6B8B
	JMP	L_6BE5
;
L_6CAZ:	MVI  C, 04Ah	; 'J'
	CALL	L_6B7D
	MVI  A, 020h
	ANA  D
	MVI  A, 008h	; 8 - JNK
	JZ	L_6CAX
	INR  A		; 9 - JK
L_6CAX:	CALL	L_6B8E
	JMP	L_6D42
;
L_6CB3:	LXI  H, D_6874
	MOV  A, D
	ANI	007h
	JZ	L_6D74	; >> код 08h/10h/18h/20h/28h/30h/38h (недокументированные 8080)
	MOV  A, D
	ANI	00Fh
	DCR  A
	JZ	L_6CD7	; >> LXI
	CPI	003h
	JC	L_6CCA	; >> STAX,INX
	SUI	005h	; DAD,LDAX,DCX
L_6CCA:	ADD  A
	ADD  A
	MOV  C, A
	DAD  B
	CALL	L_6B70
	CALL	L_6BA3
	JMP	L_6BE5
;
L_6CD7:	CALL	L_6B70
	CALL	L_6BA3
	MVI  C, 02Ch
	CALL	L_6B7D
	JMP	L_6D42
;
L_6CE5:	LXI  H, D_6870
	CALL	L_6B70
	CALL	L_6B84
	CALL	L_6B5A
	MVI  C, 02Ch
	CALL	L_6B7D
	JMP	L_6D5D
;
L_6CF9:	LXI  H, D_686C
	JMP	L_6D02
;
L_6CFF:	LXI  H, D_6868
L_6D02:	CALL	L_6B70
	CALL	L_6B84
L_6D08:	CALL	L_6B5A
	JMP	L_6BE5
;
L_6D0E:	MOV  A, D
	ANI	038h
	RRC
	MOV  C, A
	LXI  H, D_6848
	DAD  B
	CALL	L_6B70
	JMP	L_6D2E
;
L_6D1D:	LXI  H, D_6844
	CALL	L_6B70
	CALL	L_6B84
	CALL	L_6B5A
	MVI  C, 02Ch
	CALL	L_6B7D
L_6D2E:	MOV  A, D
	ANI	007h
	CALL	L_6B5A
	JMP	L_6BE5
;
L_6D37:	MOV  A, C
	ADD  A
	ADD  A
	MOV  C, A
	LXI  H, D_682C-4
	DAD  B
	CALL	L_6B70
L_6D42:	CALL	L_6B44
	PUSH PSW
	CALL	L_6B44
	MOV  D, A
	POP  PSW
	MOV  E, A
	CALL	L_6392	; вывод DE в HEX
	JMP	L_6BE5
;
L_6D52:	MOV  A, C
	ADD  A
	ADD  A
	MOV  C, A
	LXI  H, D_6804-4
	DAD  B
	CALL	L_6B70
L_6D5D:	CALL	L_6B44
	CALL	L_637C	; вывод числа A в HEX
	JMP	L_6BE5
;
L_6D66:	MOV  A, C
	ADD  A
	ADD  A
	MOV  C, A
	LXI  H, D_67C0-4	; 067BCh
	DAD  B
	CALL	L_6B70
	JMP	L_6BE5
;
L_6D74:	LXI  H, D_68D0	; вопросы
	CALL	L_6B70
	MOV  A, D
	CALL	L_637C	; вывод числа A в HEX
	JMP	L_6BE5
;
L_6D81:	LDA     D_6625
	ORA  A
	JNZ	L_6318	; >> Ошибка
	CALL	L_6382	; вывод 0Dh,0Ah
	MVI  C, 03Fh	; '?'
	CALL	L_6B7D
	LHLD	D_65F5
	SPHL
L_6D94:	LXI  H, 00000h
	DAD  SP
	SHLD	D_65F5
L_6D9B:	CALL	L_6BB7	; вывод адреса
	SHLD	D_65F3	; сохраняем адрес
	CALL	L_6321	; ввод данных в буфер (D_664A)
	CALL	L_6A00
	LHLD	D_65F3
	SHLD	D_65EE
	JMP	L_6D9B
;
L_6DB0:	LDA     D_6625
	ORA  A
	JNZ	L_6000	; рестарт
	LHLD	D_65F5
	SPHL
	RET
;
L_6DDC:	CALL	L_5710
	EI
	HLT
	DI
	RET
;
L_6DE3:	EI
	MVI  B, 04Bh
L_6DE6:	HLT
	DCR  B
	JNZ	L_6DE6
	DI
	RET
;
L_6E20:	PUSH B		; ? @INKEY >> A -- чтение с клавиатуры
	PUSH H
	LXI  H, D_7FE7
	MOV  A, M
	ORA  A
	MVI  A, 0FFh
	JZ	L_6E55
	DCR  M
	LXI  H, D_7FEA
	LDA     D_7FE9
	MOV  C, A
	MVI  B, 000h
	DAD  B
	INR  A
	ANI	007h
	STA     D_7FE9
	MOV  A, M
	CPI	080h
	JC	L_6E4D
	CPI	0A0h
	JNC	L_6E4D
	ANI	01Fh
	JMP	L_6E55
;
L_6E4D:	LDA     D_7FF9	; тип клавиатуры (0-JCUKEN, 1-QWERTY)
	ORA  A
	MOV  A, M
	CNZ	L_6E58
L_6E55:	POP  H
	POP  B
	RET
;
L_6E58:	PUSH D
	MOV  C, A
	ANI	0E0h
	MOV  B, A
	RLC
	RLC
	RLC
	LXI  H, D_6EA0
	ADD  M
	MOV  E, A
	MVI  D, 000h
	LXI  H, D_6E80
	DAD  D
	MOV  A, M
	ORA  A
	JZ	L_6E7D
	MOV  E, A
	LXI  H, D_6EA1
	DAD  D
	MOV  A, C
	ANI	01Fh
	MOV  E, A
	DAD  D
	MOV  A, M
	ORA  B
	MOV  C, A
L_6E7D:	MOV  A, C
	POP  D
	RET
;
RWORD:	CALL	RBYTE	; << чтение двух байт в DE с адреса HL (банк 0 и банк 1)
	MOV  E, A
	INX  H
	CALL	RBYTE
	MOV  D, A
	INX  H
	RET
;
RBYTE:	MOV  A, H	; << чтение байта с адреса HL (банк 0 и банк 1)
	RAL
	JC	RBYTE1	; HL >= 8000h
	STC
	RAR
;;	CPI	080h
;;	JNC	RBYTE1	; HL >= 8000h
	PUSH H
;;	STA	RB01x+1
;;	ORI	080h
	MOV  H, A
	DI
	MVI  A, B_PRG0	; ОЗУ: Банк 2, Банк 0
	OUT     00Eh	; режим ОЗУ
	MOV  H, M
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	EI
	MOV  A, H
	POP  H
;;RB01x:	MVI  H, 000h
	RET
;
RBYTE1:	MOV  A, M
	RET
;
	.ORG	06C30h
;
D_78CC:	.dw F_7300	; начало шрифтов -- кодировки символов
	.dw F_73A0	; пробел, !, ",...
	.dw F_7440	; @ABC...
	.dw F_74E0	; `abc...
	.dw F_7580	; псевдографика
	.dw F_7620	; символы
	.dw F_76C0	; юабц...
	.dw F_7760	; ЮАБЦ...
D_78DC:	.dw F_7300	; начало шрифтов
	.dw F_73A0	; пробел, !, ",...
	.dw F_76C0	; юабц...
	.dw F_7760	; ЮАБЦ...
	.dw F_7580	; псевдографика
	.dw F_7620	; символы
	.dw F_7440	; @ABC...
	.dw F_74E0	; `abc...
D_78EC:	.dw F_7300	; начало шрифтов
	.dw F_73A0	; пробел, !, ",...
	.dw F_7440	; @ABC...
	.dw F_7760	; ЮАБЦ...
	.dw F_7580	; псевдографика
	.dw F_7620	; символы
	.dw F_74E0	; `abc...
	.dw F_76C0	; юабц...
;D_78FC:	.dw F_7300	; начало шрифтов -- совпадает с D_78CC
;	.dw F_73A0	; пробел, !, ",...
;	.dw F_7440	; @ABC...
;	.dw F_74E0	; `abc...
;	.dw F_7580	; псевдографика
;	.dw F_7620	; символы
;	.dw F_76C0	; юабц...
;	.dw F_7760	; ЮАБЦ...
;
D_7FBC:	.db 0C0h	; "└" - |■■      | (adr. 7FBCh) -- таблица перекодировки
	.db 0A1h	; "б" - |■ ■    ■| (adr. 7FBDh)
	.db 0A2h	; "в" - |■ ■   ■ | (adr. 7FBEh)
	.db 0B8h	; "╕" - |■ ■■■   | (adr. 7FBFh)
	.db 0A5h	; "е" - |■ ■  ■ ■| (adr. 7FC0h)
	.db 0A6h	; "ж" - |■ ■  ■■ | (adr. 7FC1h)
	.db 0B6h	; "╢" - |■ ■■ ■■ | (adr. 7FC2h)
	.db 0A4h	; "д" - |■ ■  ■  | (adr. 7FC3h)
	.db 0B7h	; "╖" - |■ ■■ ■■■| (adr. 7FC4h)
	.db 0AAh	; "к" - |■ ■ ■ ■ | (adr. 7FC5h)
	.db 0ABh	; "л" - |■ ■ ■ ■■| (adr. 7FC6h)
	.db 0ACh	; "м" - |■ ■ ■■  | (adr. 7FC7h)
	.db 0ADh	; "н" - |■ ■ ■■ ■| (adr. 7FC8h)
	.db 0AEh	; "о" - |■ ■ ■■■ | (adr. 7FC9h)
	.db 0AFh	; "п" - |■ ■ ■■■■| (adr. 7FCAh)
	.db 0B0h	; "░" - |■ ■■    | (adr. 7FCBh)
	.db 0B1h	; "▒" - |■ ■■   ■| (adr. 7FCCh)
	.db 0C1h	; "┴" - |■■     ■| (adr. 7FCDh)
	.db 0B2h	; "▓" - |■ ■■  ■ | (adr. 7FCEh)
	.db 0B3h	; "│" - |■ ■■  ■■| (adr. 7FCFh)
	.db 0B4h	; "┤" - |■ ■■ ■  | (adr. 7FD0h)
	.db 0B5h	; "╡" - |■ ■■ ■ ■| (adr. 7FD1h)
	.db 0A8h	; "и" - |■ ■ ■   | (adr. 7FD2h)
	.db 0A3h	; "г" - |■ ■   ■■| (adr. 7FD3h)
	.db 0BEh	; "╛" - |■ ■■■■■ | (adr. 7FD4h)
	.db 0BDh	; "╜" - |■ ■■■■ ■| (adr. 7FD5h)
	.db 0A9h	; "й" - |■ ■ ■  ■| (adr. 7FD6h)
	.db 0BAh	; "║" - |■ ■■■ ■ | (adr. 7FD7h)
	.db 0BFh	; "┐" - |■ ■■■■■■| (adr. 7FD8h)
	.db 0BBh	; "╗" - |■ ■■■ ■■| (adr. 7FD9h)
	.db 0B9h	; "╣" - |■ ■■■  ■| (adr. 7FDAh)
	.db 0BEh	; "╛" - |■ ■■■■■ | (adr. 7FDBh)
;
D_6E80:	.db 001h	; "_" - |       ■| (adr. 6E80h)
	.db 000h	; "_" - |        | (adr. 6E81h)
	.db 001h	; "_" - |       ■| (adr. 6E82h)
	.db 001h	; "_" - |       ■| (adr. 6E83h)
	.db 000h	; "_" - |        | (adr. 6E84h)
	.db 000h	; "_" - |        | (adr. 6E85h)
	.db 000h	; "_" - |        | (adr. 6E86h)
	.db 000h	; "_" - |        | (adr. 6E87h)
	.db 001h	; "_" - |       ■| (adr. 6E88h)
	.db 000h	; "_" - |        | (adr. 6E89h)
	.db 000h	; "_" - |        | (adr. 6E8Ah)
	.db 000h	; "_" - |        | (adr. 6E8Bh)
	.db 000h	; "_" - |        | (adr. 6E8Ch)
	.db 000h	; "_" - |        | (adr. 6E8Dh)
	.db 001h	; "_" - |       ■| (adr. 6E8Eh)
	.db 001h	; "_" - |       ■| (adr. 6E8Fh)
	.db 001h	; "_" - |       ■| (adr. 6E90h)
	.db 000h	; "_" - |        | (adr. 6E91h)
	.db 001h	; "_" - |       ■| (adr. 6E92h)
	.db 000h	; "_" - |        | (adr. 6E93h)
	.db 000h	; "_" - |        | (adr. 6E94h)
	.db 000h	; "_" - |        | (adr. 6E95h)
	.db 001h	; "_" - |       ■| (adr. 6E96h)
	.db 000h	; "_" - |        | (adr. 6E97h)
	.db 001h	; "_" - |       ■| (adr. 6E98h)
	.db 000h	; "_" - |        | (adr. 6E99h)
	.db 001h	; "_" - |       ■| (adr. 6E9Ah)
	.db 001h	; "_" - |       ■| (adr. 6E9Bh)
	.db 000h	; "_" - |        | (adr. 6E9Ch)
	.db 000h	; "_" - |        | (adr. 6E9Dh)
	.db 000h	; "_" - |        | (adr. 6E9Eh)
	.db 000h	; "_" - |        | (adr. 6E9Fh)
D_6EA0:	.db 010h	; "_" - |   ■    | (adr. 6EA0h)
D_6EA1:	.db 000h	; "_" - |        | (adr. 6EA1h)
	.db 000h	; "_" - |        | (adr. 6EA2h)
	.db 006h	; "_" - |     ■■ | (adr. 6EA3h)
	.db 01Eh	; "_" - |   ■■■■ | (adr. 6EA4h)
	.db 017h	; "_" - |   ■ ■■■| (adr. 6EA5h)
	.db 00Ch	; "_" - |    ■■  | (adr. 6EA6h)
	.db 014h	; "_" - |   ■ ■  | (adr. 6EA7h)
	.db 001h	; "_" - |       ■| (adr. 6EA8h)
	.db 015h	; "_" - |   ■ ■ ■| (adr. 6EA9h)
	.db 01Dh	; "_" - |   ■■■ ■| (adr. 6EAAh)
	.db 002h	; "_" - |      ■ | (adr. 6EABh)
	.db 011h	; "_" - |   ■   ■| (adr. 6EACh)
	.db 012h	; "_" - |   ■  ■ | (adr. 6EADh)
	.db 00Bh	; "_" - |    ■ ■■| (adr. 6EAEh)
	.db 016h	; "_" - |   ■ ■■ | (adr. 6EAFh)
	.db 019h	; "_" - |   ■■  ■| (adr. 6EB0h)
	.db 00Ah	; "_" - |    ■ ■ | (adr. 6EB1h)
	.db 007h	; "_" - |     ■■■| (adr. 6EB2h)
	.db 01Ah	; "_" - |   ■■ ■ | (adr. 6EB3h)
	.db 008h	; "_" - |    ■   | (adr. 6EB4h)
	.db 003h	; "_" - |      ■■| (adr. 6EB5h)
	.db 00Eh	; "_" - |    ■■■ | (adr. 6EB6h)
	.db 005h	; "_" - |     ■ ■| (adr. 6EB7h)
	.db 01Bh	; "_" - |   ■■ ■■| (adr. 6EB8h)
	.db 004h	; "_" - |     ■  | (adr. 6EB9h)
	.db 00Dh	; "_" - |    ■■ ■| (adr. 6EBAh)
	.db 013h	; "_" - |   ■  ■■| (adr. 6EBBh)
	.db 010h	; "_" - |   ■    | (adr. 6EBCh)
	.db 009h	; "_" - |    ■  ■| (adr. 6EBDh)
	.db 01Ch	; "_" - |   ■■■  | (adr. 6EBEh)
	.db 00Fh	; "_" - |    ■■■■| (adr. 6EBFh)
	.db 018h	; "_" - |   ■■   | (adr. 6EC0h)
	.db 01Fh	; "_" - |   ■■■■■| (adr. 6EC1h)
	.db 000h	; "_" - |        | (adr. 6EC2h)
	.db 000h	; "_" - |        | (adr. 6EC3h)
	.db 000h	; "_" - |        | (adr. 6EC4h)
	.db 000h	; "_" - |        | (adr. 6EC5h)
	.db 000h	; "_" - |        | (adr. 6EC6h)
	.db 000h	; "_" - |        | (adr. 6EC7h)
	.db 000h	; "_" - |        | (adr. 6EC8h)
	.db 000h	; "_" - |        | (adr. 6EC9h)
	.db 000h	; "_" - |        | (adr. 6ECAh)
	.db 000h	; "_" - |        | (adr. 6ECBh)
	.db 000h	; "_" - |        | (adr. 6ECCh)
	.db 000h	; "_" - |        | (adr. 6ECDh)
	.db 000h	; "_" - |        | (adr. 6ECEh)
	.db 000h	; "_" - |        | (adr. 6ECFh)
	.db 000h	; "_" - |        | (adr. 6ED0h)
	.db 000h	; "_" - |        | (adr. 6ED1h)
	.db 000h	; "_" - |        | (adr. 6ED2h)
	.db 000h	; "_" - |        | (adr. 6ED3h)
	.db 000h	; "_" - |        | (adr. 6ED4h)
	.db 000h	; "_" - |        | (adr. 6ED5h)
	.db 000h	; "_" - |        | (adr. 6ED6h)
	.db 000h	; "_" - |        | (adr. 6ED7h)
	.db 000h	; "_" - |        | (adr. 6ED8h)
	.db 000h	; "_" - |        | (adr. 6ED9h)
	.db 000h	; "_" - |        | (adr. 6EDAh)
	.db 000h	; "_" - |        | (adr. 6EDBh)
	.db 000h	; "_" - |        | (adr. 6EDCh)
	.db 000h	; "_" - |        | (adr. 6EDDh)
	.db 000h	; "_" - |        | (adr. 6EDEh)
	.db 000h	; "_" - |        | (adr. 6EDFh)
	.db 000h	; "_" - |        | (adr. 6EE0h)
	.db 000h	; "_" - |        | (adr. 6EE1h)
	.db 000h	; "_" - |        | (adr. 6EE2h)
	.db 000h	; "_" - |        | (adr. 6EE3h)
	.db 000h	; "_" - |        | (adr. 6EE4h)
	.db 000h	; "_" - |        | (adr. 6EE5h)
	.db 000h	; "_" - |        | (adr. 6EE6h)
	.db 000h	; "_" - |        | (adr. 6EE7h)
	.db 000h	; "_" - |        | (adr. 6EE8h)
	.db 000h	; "_" - |        | (adr. 6EE9h)
	.db 000h	; "_" - |        | (adr. 6EEAh)
	.db 000h	; "_" - |        | (adr. 6EEBh)
	.db 000h	; "_" - |        | (adr. 6EECh)
	.db 000h	; "_" - |        | (adr. 6EEDh)
	.db 000h	; "_" - |        | (adr. 6EEEh)
	.db 000h	; "_" - |        | (adr. 6EEFh)
	.db 000h	; "_" - |        | (adr. 6EF0h)
	.db 000h	; "_" - |        | (adr. 6EF1h)
	.db 000h	; "_" - |        | (adr. 6EF2h)
	.db 000h	; "_" - |        | (adr. 6EF3h)
	.db 000h	; "_" - |        | (adr. 6EF4h)
	.db 000h	; "_" - |        | (adr. 6EF5h)
	.db 000h	; "_" - |        | (adr. 6EF6h)
	.db 000h	; "_" - |        | (adr. 6EF7h)
	.db 000h	; "_" - |        | (adr. 6EF8h)
	.db 000h	; "_" - |        | (adr. 6EF9h)
	.db 000h	; "_" - |        | (adr. 6EFAh)
	.db 000h	; "_" - |        | (adr. 6EFBh)
	.db 000h	; "_" - |        | (adr. 6EFCh)
	.db 000h	; "_" - |        | (adr. 6EFDh)
	.db 000h	; "_" - |        | (adr. 6EFEh)
	.db 000h	; "_" - |        | (adr. 6EFFh)
D_6F00:	.db 0C0h	; "└" - |■■      | (adr. 6F00h)
	.db 0A0h	; "а" - |■ ■     | (adr. 6F01h)
	.db 0C0h	; "└" - |■■      | (adr. 6F02h)
	.db 0A0h	; "а" - |■ ■     | (adr. 6F03h)
	.db 0C0h	; "└" - |■■      | (adr. 6F04h)
	.db 0A0h	; "а" - |■ ■     | (adr. 6F05h)
	.db 0C0h	; "└" - |■■      | (adr. 6F06h)
	.db 0A0h	; "а" - |■ ■     | (adr. 6F07h)
	.db 0C0h	; "└" - |■■      | (adr. 6F08h)
	.db 0A0h	; "а" - |■ ■     | (adr. 6F09h)
	.db 0C0h	; "└" - |■■      | (adr. 6F0Ah)
	.db 0A0h	; "а" - |■ ■     | (adr. 6F0Bh)
	.db 0C0h	; "└" - |■■      | (adr. 6F0Ch)
	.db 0A0h	; "а" - |■ ■     | (adr. 6F0Dh)
	.db 0C0h	; "└" - |■■      | (adr. 6F0Eh)
	.db 0A0h	; "а" - |■ ■     | (adr. 6F0Fh)
	.db 0C1h	; "┴" - |■■     ■| (adr. 6F10h)
	.db 0A1h	; "б" - |■ ■    ■| (adr. 6F11h)
	.db 0C1h	; "┴" - |■■     ■| (adr. 6F12h)
	.db 0A1h	; "б" - |■ ■    ■| (adr. 6F13h)
	.db 0C1h	; "┴" - |■■     ■| (adr. 6F14h)
	.db 0A1h	; "б" - |■ ■    ■| (adr. 6F15h)
	.db 0C1h	; "┴" - |■■     ■| (adr. 6F16h)
	.db 0A1h	; "б" - |■ ■    ■| (adr. 6F17h)
	.db 0C1h	; "┴" - |■■     ■| (adr. 6F18h)
	.db 0A1h	; "б" - |■ ■    ■| (adr. 6F19h)
	.db 0C1h	; "┴" - |■■     ■| (adr. 6F1Ah)
	.db 0A1h	; "б" - |■ ■    ■| (adr. 6F1Bh)
	.db 0C1h	; "┴" - |■■     ■| (adr. 6F1Ch)
	.db 0A1h	; "б" - |■ ■    ■| (adr. 6F1Dh)
	.db 0C1h	; "┴" - |■■     ■| (adr. 6F1Eh)
	.db 0A1h	; "б" - |■ ■    ■| (adr. 6F1Fh)
	.db 0C2h	; "┬" - |■■    ■ | (adr. 6F20h)
	.db 0A2h	; "в" - |■ ■   ■ | (adr. 6F21h)
	.db 0C2h	; "┬" - |■■    ■ | (adr. 6F22h)
	.db 0A2h	; "в" - |■ ■   ■ | (adr. 6F23h)
	.db 0C2h	; "┬" - |■■    ■ | (adr. 6F24h)
	.db 0A2h	; "в" - |■ ■   ■ | (adr. 6F25h)
	.db 0C2h	; "┬" - |■■    ■ | (adr. 6F26h)
	.db 0A2h	; "в" - |■ ■   ■ | (adr. 6F27h)
	.db 0C2h	; "┬" - |■■    ■ | (adr. 6F28h)
	.db 0A2h	; "в" - |■ ■   ■ | (adr. 6F29h)
	.db 0C2h	; "┬" - |■■    ■ | (adr. 6F2Ah)
	.db 0A2h	; "в" - |■ ■   ■ | (adr. 6F2Bh)
	.db 0C2h	; "┬" - |■■    ■ | (adr. 6F2Ch)
	.db 0A2h	; "в" - |■ ■   ■ | (adr. 6F2Dh)
	.db 0C2h	; "┬" - |■■    ■ | (adr. 6F2Eh)
	.db 0A2h	; "в" - |■ ■   ■ | (adr. 6F2Fh)
	.db 0C3h	; "├" - |■■    ■■| (adr. 6F30h)
	.db 0A3h	; "г" - |■ ■   ■■| (adr. 6F31h)
	.db 0C3h	; "├" - |■■    ■■| (adr. 6F32h)
	.db 0A3h	; "г" - |■ ■   ■■| (adr. 6F33h)
	.db 0C3h	; "├" - |■■    ■■| (adr. 6F34h)
	.db 0A3h	; "г" - |■ ■   ■■| (adr. 6F35h)
	.db 0C3h	; "├" - |■■    ■■| (adr. 6F36h)
	.db 0A3h	; "г" - |■ ■   ■■| (adr. 6F37h)
	.db 0C3h	; "├" - |■■    ■■| (adr. 6F38h)
	.db 0A3h	; "г" - |■ ■   ■■| (adr. 6F39h)
	.db 0C3h	; "├" - |■■    ■■| (adr. 6F3Ah)
	.db 0A3h	; "г" - |■ ■   ■■| (adr. 6F3Bh)
	.db 0C3h	; "├" - |■■    ■■| (adr. 6F3Ch)
	.db 0A3h	; "г" - |■ ■   ■■| (adr. 6F3Dh)
	.db 0C3h	; "├" - |■■    ■■| (adr. 6F3Eh)
	.db 0A3h	; "г" - |■ ■   ■■| (adr. 6F3Fh)
	.db 0C4h	; "─" - |■■   ■  | (adr. 6F40h)
	.db 0A4h	; "д" - |■ ■  ■  | (adr. 6F41h)
	.db 0C4h	; "─" - |■■   ■  | (adr. 6F42h)
	.db 0A4h	; "д" - |■ ■  ■  | (adr. 6F43h)
	.db 0C4h	; "─" - |■■   ■  | (adr. 6F44h)
	.db 0A4h	; "д" - |■ ■  ■  | (adr. 6F45h)
	.db 0C4h	; "─" - |■■   ■  | (adr. 6F46h)
	.db 0A4h	; "д" - |■ ■  ■  | (adr. 6F47h)
	.db 0C4h	; "─" - |■■   ■  | (adr. 6F48h)
	.db 0A4h	; "д" - |■ ■  ■  | (adr. 6F49h)
	.db 0C4h	; "─" - |■■   ■  | (adr. 6F4Ah)
	.db 0A4h	; "д" - |■ ■  ■  | (adr. 6F4Bh)
	.db 0C4h	; "─" - |■■   ■  | (adr. 6F4Ch)
	.db 0A4h	; "д" - |■ ■  ■  | (adr. 6F4Dh)
	.db 0C4h	; "─" - |■■   ■  | (adr. 6F4Eh)
	.db 0A4h	; "д" - |■ ■  ■  | (adr. 6F4Fh)
	.db 0C5h	; "┼" - |■■   ■ ■| (adr. 6F50h)
	.db 0A5h	; "е" - |■ ■  ■ ■| (adr. 6F51h)
	.db 0C5h	; "┼" - |■■   ■ ■| (adr. 6F52h)
	.db 0A5h	; "е" - |■ ■  ■ ■| (adr. 6F53h)
	.db 0C5h	; "┼" - |■■   ■ ■| (adr. 6F54h)
	.db 0A5h	; "е" - |■ ■  ■ ■| (adr. 6F55h)
	.db 0C5h	; "┼" - |■■   ■ ■| (adr. 6F56h)
	.db 0A5h	; "е" - |■ ■  ■ ■| (adr. 6F57h)
	.db 0C5h	; "┼" - |■■   ■ ■| (adr. 6F58h)
	.db 0A5h	; "е" - |■ ■  ■ ■| (adr. 6F59h)
	.db 0C5h	; "┼" - |■■   ■ ■| (adr. 6F5Ah)
	.db 0A5h	; "е" - |■ ■  ■ ■| (adr. 6F5Bh)
	.db 0C5h	; "┼" - |■■   ■ ■| (adr. 6F5Ch)
	.db 0A5h	; "е" - |■ ■  ■ ■| (adr. 6F5Dh)
	.db 0C5h	; "┼" - |■■   ■ ■| (adr. 6F5Eh)
	.db 0A5h	; "е" - |■ ■  ■ ■| (adr. 6F5Fh)
	.db 0C6h	; "╞" - |■■   ■■ | (adr. 6F60h)
	.db 0A6h	; "ж" - |■ ■  ■■ | (adr. 6F61h)
	.db 0C6h	; "╞" - |■■   ■■ | (adr. 6F62h)
	.db 0A6h	; "ж" - |■ ■  ■■ | (adr. 6F63h)
	.db 0C6h	; "╞" - |■■   ■■ | (adr. 6F64h)
	.db 0A6h	; "ж" - |■ ■  ■■ | (adr. 6F65h)
	.db 0C6h	; "╞" - |■■   ■■ | (adr. 6F66h)
	.db 0A6h	; "ж" - |■ ■  ■■ | (adr. 6F67h)
	.db 0C6h	; "╞" - |■■   ■■ | (adr. 6F68h)
	.db 0A6h	; "ж" - |■ ■  ■■ | (adr. 6F69h)
	.db 0C6h	; "╞" - |■■   ■■ | (adr. 6F6Ah)
	.db 0A6h	; "ж" - |■ ■  ■■ | (adr. 6F6Bh)
	.db 0C6h	; "╞" - |■■   ■■ | (adr. 6F6Ch)
	.db 0A6h	; "ж" - |■ ■  ■■ | (adr. 6F6Dh)
	.db 0C6h	; "╞" - |■■   ■■ | (adr. 6F6Eh)
	.db 0A6h	; "ж" - |■ ■  ■■ | (adr. 6F6Fh)
	.db 0C7h	; "╟" - |■■   ■■■| (adr. 6F70h)
	.db 0A7h	; "з" - |■ ■  ■■■| (adr. 6F71h)
	.db 0C7h	; "╟" - |■■   ■■■| (adr. 6F72h)
	.db 0A7h	; "з" - |■ ■  ■■■| (adr. 6F73h)
	.db 0C7h	; "╟" - |■■   ■■■| (adr. 6F74h)
	.db 0A7h	; "з" - |■ ■  ■■■| (adr. 6F75h)
	.db 0C7h	; "╟" - |■■   ■■■| (adr. 6F76h)
	.db 0A7h	; "з" - |■ ■  ■■■| (adr. 6F77h)
	.db 0C7h	; "╟" - |■■   ■■■| (adr. 6F78h)
	.db 0A7h	; "з" - |■ ■  ■■■| (adr. 6F79h)
	.db 0C7h	; "╟" - |■■   ■■■| (adr. 6F7Ah)
	.db 0A7h	; "з" - |■ ■  ■■■| (adr. 6F7Bh)
	.db 0C7h	; "╟" - |■■   ■■■| (adr. 6F7Ch)
	.db 0A7h	; "з" - |■ ■  ■■■| (adr. 6F7Dh)
	.db 0C7h	; "╟" - |■■   ■■■| (adr. 6F7Eh)
	.db 0A7h	; "з" - |■ ■  ■■■| (adr. 6F7Fh)
	.db 0C8h	; "╚" - |■■  ■   | (adr. 6F80h)
	.db 0A8h	; "и" - |■ ■ ■   | (adr. 6F81h)
	.db 0C8h	; "╚" - |■■  ■   | (adr. 6F82h)
	.db 0A8h	; "и" - |■ ■ ■   | (adr. 6F83h)
	.db 0C8h	; "╚" - |■■  ■   | (adr. 6F84h)
	.db 0A8h	; "и" - |■ ■ ■   | (adr. 6F85h)
	.db 0C8h	; "╚" - |■■  ■   | (adr. 6F86h)
	.db 0A8h	; "и" - |■ ■ ■   | (adr. 6F87h)
	.db 0C8h	; "╚" - |■■  ■   | (adr. 6F88h)
	.db 0A8h	; "и" - |■ ■ ■   | (adr. 6F89h)
	.db 0C8h	; "╚" - |■■  ■   | (adr. 6F8Ah)
	.db 0A8h	; "и" - |■ ■ ■   | (adr. 6F8Bh)
	.db 0C8h	; "╚" - |■■  ■   | (adr. 6F8Ch)
	.db 0A8h	; "и" - |■ ■ ■   | (adr. 6F8Dh)
	.db 0C8h	; "╚" - |■■  ■   | (adr. 6F8Eh)
	.db 0A8h	; "и" - |■ ■ ■   | (adr. 6F8Fh)
	.db 0C9h	; "╔" - |■■  ■  ■| (adr. 6F90h)
	.db 0A9h	; "й" - |■ ■ ■  ■| (adr. 6F91h)
	.db 0C9h	; "╔" - |■■  ■  ■| (adr. 6F92h)
	.db 0A9h	; "й" - |■ ■ ■  ■| (adr. 6F93h)
	.db 0C9h	; "╔" - |■■  ■  ■| (adr. 6F94h)
	.db 0A9h	; "й" - |■ ■ ■  ■| (adr. 6F95h)
	.db 0C9h	; "╔" - |■■  ■  ■| (adr. 6F96h)
	.db 0A9h	; "й" - |■ ■ ■  ■| (adr. 6F97h)
	.db 0C9h	; "╔" - |■■  ■  ■| (adr. 6F98h)
	.db 0A9h	; "й" - |■ ■ ■  ■| (adr. 6F99h)
	.db 0C9h	; "╔" - |■■  ■  ■| (adr. 6F9Ah)
	.db 0A9h	; "й" - |■ ■ ■  ■| (adr. 6F9Bh)
	.db 0C9h	; "╔" - |■■  ■  ■| (adr. 6F9Ch)
	.db 0A9h	; "й" - |■ ■ ■  ■| (adr. 6F9Dh)
	.db 0C9h	; "╔" - |■■  ■  ■| (adr. 6F9Eh)
	.db 0A9h	; "й" - |■ ■ ■  ■| (adr. 6F9Fh)
	.db 0CAh	; "╩" - |■■  ■ ■ | (adr. 6FA0h)
	.db 0AAh	; "к" - |■ ■ ■ ■ | (adr. 6FA1h)
	.db 0CAh	; "╩" - |■■  ■ ■ | (adr. 6FA2h)
	.db 0AAh	; "к" - |■ ■ ■ ■ | (adr. 6FA3h)
	.db 0CAh	; "╩" - |■■  ■ ■ | (adr. 6FA4h)
	.db 0AAh	; "к" - |■ ■ ■ ■ | (adr. 6FA5h)
	.db 0CAh	; "╩" - |■■  ■ ■ | (adr. 6FA6h)
	.db 0AAh	; "к" - |■ ■ ■ ■ | (adr. 6FA7h)
	.db 0CAh	; "╩" - |■■  ■ ■ | (adr. 6FA8h)
	.db 0AAh	; "к" - |■ ■ ■ ■ | (adr. 6FA9h)
	.db 0CAh	; "╩" - |■■  ■ ■ | (adr. 6FAAh)
	.db 0AAh	; "к" - |■ ■ ■ ■ | (adr. 6FABh)
	.db 0CAh	; "╩" - |■■  ■ ■ | (adr. 6FACh)
	.db 0AAh	; "к" - |■ ■ ■ ■ | (adr. 6FADh)
	.db 0CAh	; "╩" - |■■  ■ ■ | (adr. 6FAEh)
	.db 0AAh	; "к" - |■ ■ ■ ■ | (adr. 6FAFh)
	.db 0CBh	; "╦" - |■■  ■ ■■| (adr. 6FB0h)
	.db 0ABh	; "л" - |■ ■ ■ ■■| (adr. 6FB1h)
	.db 0CBh	; "╦" - |■■  ■ ■■| (adr. 6FB2h)
	.db 0ABh	; "л" - |■ ■ ■ ■■| (adr. 6FB3h)
	.db 0CBh	; "╦" - |■■  ■ ■■| (adr. 6FB4h)
	.db 0ABh	; "л" - |■ ■ ■ ■■| (adr. 6FB5h)
	.db 0CBh	; "╦" - |■■  ■ ■■| (adr. 6FB6h)
	.db 0ABh	; "л" - |■ ■ ■ ■■| (adr. 6FB7h)
	.db 0CBh	; "╦" - |■■  ■ ■■| (adr. 6FB8h)
	.db 0ABh	; "л" - |■ ■ ■ ■■| (adr. 6FB9h)
	.db 0CBh	; "╦" - |■■  ■ ■■| (adr. 6FBAh)
	.db 0ABh	; "л" - |■ ■ ■ ■■| (adr. 6FBBh)
	.db 0CBh	; "╦" - |■■  ■ ■■| (adr. 6FBCh)
	.db 0ABh	; "л" - |■ ■ ■ ■■| (adr. 6FBDh)
	.db 0CBh	; "╦" - |■■  ■ ■■| (adr. 6FBEh)
	.db 0ABh	; "л" - |■ ■ ■ ■■| (adr. 6FBFh)
	.db 0CCh	; "╠" - |■■  ■■  | (adr. 6FC0h)
	.db 0ACh	; "м" - |■ ■ ■■  | (adr. 6FC1h)
	.db 0CCh	; "╠" - |■■  ■■  | (adr. 6FC2h)
	.db 0ACh	; "м" - |■ ■ ■■  | (adr. 6FC3h)
	.db 0CCh	; "╠" - |■■  ■■  | (adr. 6FC4h)
	.db 0ACh	; "м" - |■ ■ ■■  | (adr. 6FC5h)
	.db 0CCh	; "╠" - |■■  ■■  | (adr. 6FC6h)
	.db 0ACh	; "м" - |■ ■ ■■  | (adr. 6FC7h)
	.db 0CCh	; "╠" - |■■  ■■  | (adr. 6FC8h)
	.db 0ACh	; "м" - |■ ■ ■■  | (adr. 6FC9h)
	.db 0CCh	; "╠" - |■■  ■■  | (adr. 6FCAh)
	.db 0ACh	; "м" - |■ ■ ■■  | (adr. 6FCBh)
	.db 0CCh	; "╠" - |■■  ■■  | (adr. 6FCCh)
	.db 0ACh	; "м" - |■ ■ ■■  | (adr. 6FCDh)
	.db 0CCh	; "╠" - |■■  ■■  | (adr. 6FCEh)
	.db 0ACh	; "м" - |■ ■ ■■  | (adr. 6FCFh)
	.db 0CDh	; "═" - |■■  ■■ ■| (adr. 6FD0h)
	.db 0ADh	; "н" - |■ ■ ■■ ■| (adr. 6FD1h)
	.db 0CDh	; "═" - |■■  ■■ ■| (adr. 6FD2h)
	.db 0ADh	; "н" - |■ ■ ■■ ■| (adr. 6FD3h)
	.db 0CDh	; "═" - |■■  ■■ ■| (adr. 6FD4h)
	.db 0ADh	; "н" - |■ ■ ■■ ■| (adr. 6FD5h)
	.db 0CDh	; "═" - |■■  ■■ ■| (adr. 6FD6h)
	.db 0ADh	; "н" - |■ ■ ■■ ■| (adr. 6FD7h)
	.db 0CDh	; "═" - |■■  ■■ ■| (adr. 6FD8h)
	.db 0ADh	; "н" - |■ ■ ■■ ■| (adr. 6FD9h)
	.db 0CDh	; "═" - |■■  ■■ ■| (adr. 6FDAh)
	.db 0ADh	; "н" - |■ ■ ■■ ■| (adr. 6FDBh)
	.db 0CDh	; "═" - |■■  ■■ ■| (adr. 6FDCh)
	.db 0ADh	; "н" - |■ ■ ■■ ■| (adr. 6FDDh)
	.db 0CDh	; "═" - |■■  ■■ ■| (adr. 6FDEh)
	.db 0ADh	; "н" - |■ ■ ■■ ■| (adr. 6FDFh)
	.db 0CEh	; "╬" - |■■  ■■■ | (adr. 6FE0h)
	.db 0AEh	; "о" - |■ ■ ■■■ | (adr. 6FE1h)
	.db 0CEh	; "╬" - |■■  ■■■ | (adr. 6FE2h)
	.db 0AEh	; "о" - |■ ■ ■■■ | (adr. 6FE3h)
	.db 0CEh	; "╬" - |■■  ■■■ | (adr. 6FE4h)
	.db 0AEh	; "о" - |■ ■ ■■■ | (adr. 6FE5h)
	.db 0CEh	; "╬" - |■■  ■■■ | (adr. 6FE6h)
	.db 0AEh	; "о" - |■ ■ ■■■ | (adr. 6FE7h)
	.db 0CEh	; "╬" - |■■  ■■■ | (adr. 6FE8h)
	.db 0AEh	; "о" - |■ ■ ■■■ | (adr. 6FE9h)
	.db 0CEh	; "╬" - |■■  ■■■ | (adr. 6FEAh)
	.db 0AEh	; "о" - |■ ■ ■■■ | (adr. 6FEBh)
	.db 0CEh	; "╬" - |■■  ■■■ | (adr. 6FECh)
	.db 0AEh	; "о" - |■ ■ ■■■ | (adr. 6FEDh)
	.db 0CEh	; "╬" - |■■  ■■■ | (adr. 6FEEh)
	.db 0AEh	; "о" - |■ ■ ■■■ | (adr. 6FEFh)
	.db 0CFh	; "╧" - |■■  ■■■■| (adr. 6FF0h)
	.db 0AFh	; "п" - |■ ■ ■■■■| (adr. 6FF1h)
	.db 0CFh	; "╧" - |■■  ■■■■| (adr. 6FF2h)
	.db 0AFh	; "п" - |■ ■ ■■■■| (adr. 6FF3h)
	.db 0CFh	; "╧" - |■■  ■■■■| (adr. 6FF4h)
	.db 0AFh	; "п" - |■ ■ ■■■■| (adr. 6FF5h)
	.db 0CFh	; "╧" - |■■  ■■■■| (adr. 6FF6h)
	.db 0AFh	; "п" - |■ ■ ■■■■| (adr. 6FF7h)
	.db 0CFh	; "╧" - |■■  ■■■■| (adr. 6FF8h)
	.db 0AFh	; "п" - |■ ■ ■■■■| (adr. 6FF9h)
	.db 0CFh	; "╧" - |■■  ■■■■| (adr. 6FFAh)
	.db 0AFh	; "п" - |■ ■ ■■■■| (adr. 6FFBh)
	.db 0CFh	; "╧" - |■■  ■■■■| (adr. 6FFCh)
	.db 0AFh	; "п" - |■ ■ ■■■■| (adr. 6FFDh)
	.db 0CFh	; "╧" - |■■  ■■■■| (adr. 6FFEh)
	.db 0AFh	; "п" - |■ ■ ■■■■| (adr. 6FFFh)
	.db 0D0h	; "╨" - |■■ ■    | (adr. 7000h)
	.db 0B0h	; "░" - |■ ■■    | (adr. 7001h)
	.db 0D0h	; "╨" - |■■ ■    | (adr. 7002h)
	.db 0B0h	; "░" - |■ ■■    | (adr. 7003h)
	.db 0D0h	; "╨" - |■■ ■    | (adr. 7004h)
	.db 0B0h	; "░" - |■ ■■    | (adr. 7005h)
	.db 0D0h	; "╨" - |■■ ■    | (adr. 7006h)
	.db 0B0h	; "░" - |■ ■■    | (adr. 7007h)
	.db 0D0h	; "╨" - |■■ ■    | (adr. 7008h)
	.db 0B0h	; "░" - |■ ■■    | (adr. 7009h)
	.db 0D0h	; "╨" - |■■ ■    | (adr. 700Ah)
	.db 0B0h	; "░" - |■ ■■    | (adr. 700Bh)
	.db 0D0h	; "╨" - |■■ ■    | (adr. 700Ch)
	.db 0B0h	; "░" - |■ ■■    | (adr. 700Dh)
	.db 0D0h	; "╨" - |■■ ■    | (adr. 700Eh)
	.db 0B0h	; "░" - |■ ■■    | (adr. 700Fh)
	.db 0D1h	; "╤" - |■■ ■   ■| (adr. 7010h)
	.db 0B1h	; "▒" - |■ ■■   ■| (adr. 7011h)
	.db 0D1h	; "╤" - |■■ ■   ■| (adr. 7012h)
	.db 0B1h	; "▒" - |■ ■■   ■| (adr. 7013h)
	.db 0D1h	; "╤" - |■■ ■   ■| (adr. 7014h)
	.db 0B1h	; "▒" - |■ ■■   ■| (adr. 7015h)
	.db 0D1h	; "╤" - |■■ ■   ■| (adr. 7016h)
	.db 0B1h	; "▒" - |■ ■■   ■| (adr. 7017h)
	.db 0D1h	; "╤" - |■■ ■   ■| (adr. 7018h)
	.db 0B1h	; "▒" - |■ ■■   ■| (adr. 7019h)
	.db 0D1h	; "╤" - |■■ ■   ■| (adr. 701Ah)
	.db 0B1h	; "▒" - |■ ■■   ■| (adr. 701Bh)
	.db 0D1h	; "╤" - |■■ ■   ■| (adr. 701Ch)
	.db 0B1h	; "▒" - |■ ■■   ■| (adr. 701Dh)
	.db 0D1h	; "╤" - |■■ ■   ■| (adr. 701Eh)
	.db 0B1h	; "▒" - |■ ■■   ■| (adr. 701Fh)
	.db 0D2h	; "╥" - |■■ ■  ■ | (adr. 7020h)
	.db 0B2h	; "▓" - |■ ■■  ■ | (adr. 7021h)
	.db 0D2h	; "╥" - |■■ ■  ■ | (adr. 7022h)
	.db 0B2h	; "▓" - |■ ■■  ■ | (adr. 7023h)
	.db 0D2h	; "╥" - |■■ ■  ■ | (adr. 7024h)
	.db 0B2h	; "▓" - |■ ■■  ■ | (adr. 7025h)
	.db 0D2h	; "╥" - |■■ ■  ■ | (adr. 7026h)
	.db 0B2h	; "▓" - |■ ■■  ■ | (adr. 7027h)
	.db 0D2h	; "╥" - |■■ ■  ■ | (adr. 7028h)
	.db 0B2h	; "▓" - |■ ■■  ■ | (adr. 7029h)
	.db 0D2h	; "╥" - |■■ ■  ■ | (adr. 702Ah)
	.db 0B2h	; "▓" - |■ ■■  ■ | (adr. 702Bh)
	.db 0D2h	; "╥" - |■■ ■  ■ | (adr. 702Ch)
	.db 0B2h	; "▓" - |■ ■■  ■ | (adr. 702Dh)
	.db 0D2h	; "╥" - |■■ ■  ■ | (adr. 702Eh)
	.db 0B2h	; "▓" - |■ ■■  ■ | (adr. 702Fh)
	.db 0D3h	; "╙" - |■■ ■  ■■| (adr. 7030h)
	.db 0B3h	; "│" - |■ ■■  ■■| (adr. 7031h)
	.db 0D3h	; "╙" - |■■ ■  ■■| (adr. 7032h)
	.db 0B3h	; "│" - |■ ■■  ■■| (adr. 7033h)
	.db 0D3h	; "╙" - |■■ ■  ■■| (adr. 7034h)
	.db 0B3h	; "│" - |■ ■■  ■■| (adr. 7035h)
	.db 0D3h	; "╙" - |■■ ■  ■■| (adr. 7036h)
	.db 0B3h	; "│" - |■ ■■  ■■| (adr. 7037h)
	.db 0D3h	; "╙" - |■■ ■  ■■| (adr. 7038h)
	.db 0B3h	; "│" - |■ ■■  ■■| (adr. 7039h)
	.db 0D3h	; "╙" - |■■ ■  ■■| (adr. 703Ah)
	.db 0B3h	; "│" - |■ ■■  ■■| (adr. 703Bh)
	.db 0D3h	; "╙" - |■■ ■  ■■| (adr. 703Ch)
	.db 0B3h	; "│" - |■ ■■  ■■| (adr. 703Dh)
	.db 0D3h	; "╙" - |■■ ■  ■■| (adr. 703Eh)
	.db 0B3h	; "│" - |■ ■■  ■■| (adr. 703Fh)
	.db 0D4h	; "╘" - |■■ ■ ■  | (adr. 7040h)
	.db 0B4h	; "┤" - |■ ■■ ■  | (adr. 7041h)
	.db 0D4h	; "╘" - |■■ ■ ■  | (adr. 7042h)
	.db 0B4h	; "┤" - |■ ■■ ■  | (adr. 7043h)
	.db 0D4h	; "╘" - |■■ ■ ■  | (adr. 7044h)
	.db 0B4h	; "┤" - |■ ■■ ■  | (adr. 7045h)
	.db 0D4h	; "╘" - |■■ ■ ■  | (adr. 7046h)
	.db 0B4h	; "┤" - |■ ■■ ■  | (adr. 7047h)
	.db 0D4h	; "╘" - |■■ ■ ■  | (adr. 7048h)
	.db 0B4h	; "┤" - |■ ■■ ■  | (adr. 7049h)
	.db 0D4h	; "╘" - |■■ ■ ■  | (adr. 704Ah)
	.db 0B4h	; "┤" - |■ ■■ ■  | (adr. 704Bh)
	.db 0D4h	; "╘" - |■■ ■ ■  | (adr. 704Ch)
	.db 0B4h	; "┤" - |■ ■■ ■  | (adr. 704Dh)
	.db 0D4h	; "╘" - |■■ ■ ■  | (adr. 704Eh)
	.db 0B4h	; "┤" - |■ ■■ ■  | (adr. 704Fh)
	.db 0D5h	; "╒" - |■■ ■ ■ ■| (adr. 7050h)
	.db 0B5h	; "╡" - |■ ■■ ■ ■| (adr. 7051h)
	.db 0D5h	; "╒" - |■■ ■ ■ ■| (adr. 7052h)
	.db 0B5h	; "╡" - |■ ■■ ■ ■| (adr. 7053h)
	.db 0D5h	; "╒" - |■■ ■ ■ ■| (adr. 7054h)
	.db 0B5h	; "╡" - |■ ■■ ■ ■| (adr. 7055h)
	.db 0D5h	; "╒" - |■■ ■ ■ ■| (adr. 7056h)
	.db 0B5h	; "╡" - |■ ■■ ■ ■| (adr. 7057h)
	.db 0D5h	; "╒" - |■■ ■ ■ ■| (adr. 7058h)
	.db 0B5h	; "╡" - |■ ■■ ■ ■| (adr. 7059h)
	.db 0D5h	; "╒" - |■■ ■ ■ ■| (adr. 705Ah)
	.db 0B5h	; "╡" - |■ ■■ ■ ■| (adr. 705Bh)
	.db 0D5h	; "╒" - |■■ ■ ■ ■| (adr. 705Ch)
	.db 0B5h	; "╡" - |■ ■■ ■ ■| (adr. 705Dh)
	.db 0D5h	; "╒" - |■■ ■ ■ ■| (adr. 705Eh)
	.db 0B5h	; "╡" - |■ ■■ ■ ■| (adr. 705Fh)
	.db 0D6h	; "╓" - |■■ ■ ■■ | (adr. 7060h)
	.db 0B6h	; "╢" - |■ ■■ ■■ | (adr. 7061h)
	.db 0D6h	; "╓" - |■■ ■ ■■ | (adr. 7062h)
	.db 0B6h	; "╢" - |■ ■■ ■■ | (adr. 7063h)
	.db 0D6h	; "╓" - |■■ ■ ■■ | (adr. 7064h)
	.db 0B6h	; "╢" - |■ ■■ ■■ | (adr. 7065h)
	.db 0D6h	; "╓" - |■■ ■ ■■ | (adr. 7066h)
	.db 0B6h	; "╢" - |■ ■■ ■■ | (adr. 7067h)
	.db 0D6h	; "╓" - |■■ ■ ■■ | (adr. 7068h)
	.db 0B6h	; "╢" - |■ ■■ ■■ | (adr. 7069h)
	.db 0D6h	; "╓" - |■■ ■ ■■ | (adr. 706Ah)
	.db 0B6h	; "╢" - |■ ■■ ■■ | (adr. 706Bh)
	.db 0D6h	; "╓" - |■■ ■ ■■ | (adr. 706Ch)
	.db 0B6h	; "╢" - |■ ■■ ■■ | (adr. 706Dh)
	.db 0D6h	; "╓" - |■■ ■ ■■ | (adr. 706Eh)
	.db 0B6h	; "╢" - |■ ■■ ■■ | (adr. 706Fh)
	.db 0D7h	; "╫" - |■■ ■ ■■■| (adr. 7070h)
	.db 0B7h	; "╖" - |■ ■■ ■■■| (adr. 7071h)
	.db 0D7h	; "╫" - |■■ ■ ■■■| (adr. 7072h)
	.db 0B7h	; "╖" - |■ ■■ ■■■| (adr. 7073h)
	.db 0D7h	; "╫" - |■■ ■ ■■■| (adr. 7074h)
	.db 0B7h	; "╖" - |■ ■■ ■■■| (adr. 7075h)
	.db 0D7h	; "╫" - |■■ ■ ■■■| (adr. 7076h)
	.db 0B7h	; "╖" - |■ ■■ ■■■| (adr. 7077h)
	.db 0D7h	; "╫" - |■■ ■ ■■■| (adr. 7078h)
	.db 0B7h	; "╖" - |■ ■■ ■■■| (adr. 7079h)
	.db 0D7h	; "╫" - |■■ ■ ■■■| (adr. 707Ah)
	.db 0B7h	; "╖" - |■ ■■ ■■■| (adr. 707Bh)
	.db 0D7h	; "╫" - |■■ ■ ■■■| (adr. 707Ch)
	.db 0B7h	; "╖" - |■ ■■ ■■■| (adr. 707Dh)
	.db 0D7h	; "╫" - |■■ ■ ■■■| (adr. 707Eh)
	.db 0B7h	; "╖" - |■ ■■ ■■■| (adr. 707Fh)
	.db 0D8h	; "╪" - |■■ ■■   | (adr. 7080h)
	.db 0B8h	; "╕" - |■ ■■■   | (adr. 7081h)
	.db 0D8h	; "╪" - |■■ ■■   | (adr. 7082h)
	.db 0B8h	; "╕" - |■ ■■■   | (adr. 7083h)
	.db 0D8h	; "╪" - |■■ ■■   | (adr. 7084h)
	.db 0B8h	; "╕" - |■ ■■■   | (adr. 7085h)
	.db 0D8h	; "╪" - |■■ ■■   | (adr. 7086h)
	.db 0B8h	; "╕" - |■ ■■■   | (adr. 7087h)
	.db 0D8h	; "╪" - |■■ ■■   | (adr. 7088h)
	.db 0B8h	; "╕" - |■ ■■■   | (adr. 7089h)
	.db 0D8h	; "╪" - |■■ ■■   | (adr. 708Ah)
	.db 0B8h	; "╕" - |■ ■■■   | (adr. 708Bh)
	.db 0D8h	; "╪" - |■■ ■■   | (adr. 708Ch)
	.db 0B8h	; "╕" - |■ ■■■   | (adr. 708Dh)
	.db 0D8h	; "╪" - |■■ ■■   | (adr. 708Eh)
	.db 0B8h	; "╕" - |■ ■■■   | (adr. 708Fh)
	.db 0D9h	; "┘" - |■■ ■■  ■| (adr. 7090h)
	.db 0B9h	; "╣" - |■ ■■■  ■| (adr. 7091h)
	.db 0D9h	; "┘" - |■■ ■■  ■| (adr. 7092h)
	.db 0B9h	; "╣" - |■ ■■■  ■| (adr. 7093h)
	.db 0D9h	; "┘" - |■■ ■■  ■| (adr. 7094h)
	.db 0B9h	; "╣" - |■ ■■■  ■| (adr. 7095h)
	.db 0D9h	; "┘" - |■■ ■■  ■| (adr. 7096h)
	.db 0B9h	; "╣" - |■ ■■■  ■| (adr. 7097h)
	.db 0D9h	; "┘" - |■■ ■■  ■| (adr. 7098h)
	.db 0B9h	; "╣" - |■ ■■■  ■| (adr. 7099h)
	.db 0D9h	; "┘" - |■■ ■■  ■| (adr. 709Ah)
	.db 0B9h	; "╣" - |■ ■■■  ■| (adr. 709Bh)
	.db 0D9h	; "┘" - |■■ ■■  ■| (adr. 709Ch)
	.db 0B9h	; "╣" - |■ ■■■  ■| (adr. 709Dh)
	.db 0D9h	; "┘" - |■■ ■■  ■| (adr. 709Eh)
	.db 0B9h	; "╣" - |■ ■■■  ■| (adr. 709Fh)
	.db 0DAh	; "┌" - |■■ ■■ ■ | (adr. 70A0h)
	.db 0BAh	; "║" - |■ ■■■ ■ | (adr. 70A1h)
	.db 0DAh	; "┌" - |■■ ■■ ■ | (adr. 70A2h)
	.db 0BAh	; "║" - |■ ■■■ ■ | (adr. 70A3h)
	.db 0DAh	; "┌" - |■■ ■■ ■ | (adr. 70A4h)
	.db 0BAh	; "║" - |■ ■■■ ■ | (adr. 70A5h)
	.db 0DAh	; "┌" - |■■ ■■ ■ | (adr. 70A6h)
	.db 0BAh	; "║" - |■ ■■■ ■ | (adr. 70A7h)
	.db 0DAh	; "┌" - |■■ ■■ ■ | (adr. 70A8h)
	.db 0BAh	; "║" - |■ ■■■ ■ | (adr. 70A9h)
	.db 0DAh	; "┌" - |■■ ■■ ■ | (adr. 70AAh)
	.db 0BAh	; "║" - |■ ■■■ ■ | (adr. 70ABh)
	.db 0DAh	; "┌" - |■■ ■■ ■ | (adr. 70ACh)
	.db 0BAh	; "║" - |■ ■■■ ■ | (adr. 70ADh)
	.db 0DAh	; "┌" - |■■ ■■ ■ | (adr. 70AEh)
	.db 0BAh	; "║" - |■ ■■■ ■ | (adr. 70AFh)
	.db 0DBh	; "█" - |■■ ■■ ■■| (adr. 70B0h)
	.db 0BBh	; "╗" - |■ ■■■ ■■| (adr. 70B1h)
	.db 0DBh	; "█" - |■■ ■■ ■■| (adr. 70B2h)
	.db 0BBh	; "╗" - |■ ■■■ ■■| (adr. 70B3h)
	.db 0DBh	; "█" - |■■ ■■ ■■| (adr. 70B4h)
	.db 0BBh	; "╗" - |■ ■■■ ■■| (adr. 70B5h)
	.db 0DBh	; "█" - |■■ ■■ ■■| (adr. 70B6h)
	.db 0BBh	; "╗" - |■ ■■■ ■■| (adr. 70B7h)
	.db 0DBh	; "█" - |■■ ■■ ■■| (adr. 70B8h)
	.db 0BBh	; "╗" - |■ ■■■ ■■| (adr. 70B9h)
	.db 0DBh	; "█" - |■■ ■■ ■■| (adr. 70BAh)
	.db 0BBh	; "╗" - |■ ■■■ ■■| (adr. 70BBh)
	.db 0DBh	; "█" - |■■ ■■ ■■| (adr. 70BCh)
	.db 0BBh	; "╗" - |■ ■■■ ■■| (adr. 70BDh)
	.db 0DBh	; "█" - |■■ ■■ ■■| (adr. 70BEh)
	.db 0BBh	; "╗" - |■ ■■■ ■■| (adr. 70BFh)
	.db 0DCh	; "▄" - |■■ ■■■  | (adr. 70C0h)
	.db 0BCh	; "╝" - |■ ■■■■  | (adr. 70C1h)
	.db 0DCh	; "▄" - |■■ ■■■  | (adr. 70C2h)
	.db 0BCh	; "╝" - |■ ■■■■  | (adr. 70C3h)
	.db 0DCh	; "▄" - |■■ ■■■  | (adr. 70C4h)
	.db 0BCh	; "╝" - |■ ■■■■  | (adr. 70C5h)
	.db 0DCh	; "▄" - |■■ ■■■  | (adr. 70C6h)
	.db 0BCh	; "╝" - |■ ■■■■  | (adr. 70C7h)
	.db 0DCh	; "▄" - |■■ ■■■  | (adr. 70C8h)
	.db 0BCh	; "╝" - |■ ■■■■  | (adr. 70C9h)
	.db 0DCh	; "▄" - |■■ ■■■  | (adr. 70CAh)
	.db 0BCh	; "╝" - |■ ■■■■  | (adr. 70CBh)
	.db 0DCh	; "▄" - |■■ ■■■  | (adr. 70CCh)
	.db 0BCh	; "╝" - |■ ■■■■  | (adr. 70CDh)
	.db 0DCh	; "▄" - |■■ ■■■  | (adr. 70CEh)
	.db 0BCh	; "╝" - |■ ■■■■  | (adr. 70CFh)
	.db 0DDh	; "▌" - |■■ ■■■ ■| (adr. 70D0h)
	.db 0BDh	; "╜" - |■ ■■■■ ■| (adr. 70D1h)
	.db 0DDh	; "▌" - |■■ ■■■ ■| (adr. 70D2h)
	.db 0BDh	; "╜" - |■ ■■■■ ■| (adr. 70D3h)
	.db 0DDh	; "▌" - |■■ ■■■ ■| (adr. 70D4h)
	.db 0BDh	; "╜" - |■ ■■■■ ■| (adr. 70D5h)
	.db 0DDh	; "▌" - |■■ ■■■ ■| (adr. 70D6h)
	.db 0BDh	; "╜" - |■ ■■■■ ■| (adr. 70D7h)
	.db 0DDh	; "▌" - |■■ ■■■ ■| (adr. 70D8h)
	.db 0BDh	; "╜" - |■ ■■■■ ■| (adr. 70D9h)
	.db 0DDh	; "▌" - |■■ ■■■ ■| (adr. 70DAh)
	.db 0BDh	; "╜" - |■ ■■■■ ■| (adr. 70DBh)
	.db 0DDh	; "▌" - |■■ ■■■ ■| (adr. 70DCh)
	.db 0BDh	; "╜" - |■ ■■■■ ■| (adr. 70DDh)
	.db 0DDh	; "▌" - |■■ ■■■ ■| (adr. 70DEh)
	.db 0BDh	; "╜" - |■ ■■■■ ■| (adr. 70DFh)
	.db 0DEh	; "▐" - |■■ ■■■■ | (adr. 70E0h)
	.db 0BEh	; "╛" - |■ ■■■■■ | (adr. 70E1h)
	.db 0DEh	; "▐" - |■■ ■■■■ | (adr. 70E2h)
	.db 0BEh	; "╛" - |■ ■■■■■ | (adr. 70E3h)
	.db 0DEh	; "▐" - |■■ ■■■■ | (adr. 70E4h)
	.db 0BEh	; "╛" - |■ ■■■■■ | (adr. 70E5h)
	.db 0DEh	; "▐" - |■■ ■■■■ | (adr. 70E6h)
	.db 0BEh	; "╛" - |■ ■■■■■ | (adr. 70E7h)
	.db 0DEh	; "▐" - |■■ ■■■■ | (adr. 70E8h)
	.db 0BEh	; "╛" - |■ ■■■■■ | (adr. 70E9h)
	.db 0DEh	; "▐" - |■■ ■■■■ | (adr. 70EAh)
	.db 0BEh	; "╛" - |■ ■■■■■ | (adr. 70EBh)
	.db 0DEh	; "▐" - |■■ ■■■■ | (adr. 70ECh)
	.db 0BEh	; "╛" - |■ ■■■■■ | (adr. 70EDh)
	.db 0DEh	; "▐" - |■■ ■■■■ | (adr. 70EEh)
	.db 0BEh	; "╛" - |■ ■■■■■ | (adr. 70EFh)
	.db 0DFh	; "▀" - |■■ ■■■■■| (adr. 70F0h)
	.db 0BFh	; "┐" - |■ ■■■■■■| (adr. 70F1h)
	.db 0DFh	; "▀" - |■■ ■■■■■| (adr. 70F2h)
	.db 0BFh	; "┐" - |■ ■■■■■■| (adr. 70F3h)
	.db 0DFh	; "▀" - |■■ ■■■■■| (adr. 70F4h)
	.db 0BFh	; "┐" - |■ ■■■■■■| (adr. 70F5h)
	.db 0DFh	; "▀" - |■■ ■■■■■| (adr. 70F6h)
	.db 0BFh	; "┐" - |■ ■■■■■■| (adr. 70F7h)
	.db 0DFh	; "▀" - |■■ ■■■■■| (adr. 70F8h)
	.db 0BFh	; "┐" - |■ ■■■■■■| (adr. 70F9h)
	.db 0DFh	; "▀" - |■■ ■■■■■| (adr. 70FAh)
	.db 0BFh	; "┐" - |■ ■■■■■■| (adr. 70FBh)
	.db 0DFh	; "▀" - |■■ ■■■■■| (adr. 70FCh)
	.db 0BFh	; "┐" - |■ ■■■■■■| (adr. 70FDh)
	.db 0DFh	; "▀" - |■■ ■■■■■| (adr. 70FEh)
	.db 0BFh	; "┐" - |■ ■■■■■■| (adr. 70FFh)
	.db 080h	; "А" - |■       | (adr. 7100h)
	.db 080h	; "А" - |■       | (adr. 7101h)
	.db 040h	; "@" - | ■      | (adr. 7102h)
	.db 040h	; "@" - | ■      | (adr. 7103h)
	.db 020h	; " " - |  ■     | (adr. 7104h)
	.db 020h	; " " - |  ■     | (adr. 7105h)
	.db 010h	; "_" - |   ■    | (adr. 7106h)
	.db 010h	; "_" - |   ■    | (adr. 7107h)
	.db 008h	; "_" - |    ■   | (adr. 7108h)
	.db 008h	; "_" - |    ■   | (adr. 7109h)
	.db 004h	; "_" - |     ■  | (adr. 710Ah)
	.db 004h	; "_" - |     ■  | (adr. 710Bh)
	.db 002h	; "_" - |      ■ | (adr. 710Ch)
	.db 002h	; "_" - |      ■ | (adr. 710Dh)
	.db 001h	; "_" - |       ■| (adr. 710Eh)
	.db 001h	; "_" - |       ■| (adr. 710Fh)
	.db 080h	; "А" - |■       | (adr. 7110h)
	.db 080h	; "А" - |■       | (adr. 7111h)
	.db 040h	; "@" - | ■      | (adr. 7112h)
	.db 040h	; "@" - | ■      | (adr. 7113h)
	.db 020h	; " " - |  ■     | (adr. 7114h)
	.db 020h	; " " - |  ■     | (adr. 7115h)
	.db 010h	; "_" - |   ■    | (adr. 7116h)
	.db 010h	; "_" - |   ■    | (adr. 7117h)
	.db 008h	; "_" - |    ■   | (adr. 7118h)
	.db 008h	; "_" - |    ■   | (adr. 7119h)
	.db 004h	; "_" - |     ■  | (adr. 711Ah)
	.db 004h	; "_" - |     ■  | (adr. 711Bh)
	.db 002h	; "_" - |      ■ | (adr. 711Ch)
	.db 002h	; "_" - |      ■ | (adr. 711Dh)
	.db 001h	; "_" - |       ■| (adr. 711Eh)
	.db 001h	; "_" - |       ■| (adr. 711Fh)
	.db 080h	; "А" - |■       | (adr. 7120h)
	.db 080h	; "А" - |■       | (adr. 7121h)
	.db 040h	; "@" - | ■      | (adr. 7122h)
	.db 040h	; "@" - | ■      | (adr. 7123h)
	.db 020h	; " " - |  ■     | (adr. 7124h)
	.db 020h	; " " - |  ■     | (adr. 7125h)
	.db 010h	; "_" - |   ■    | (adr. 7126h)
	.db 010h	; "_" - |   ■    | (adr. 7127h)
	.db 008h	; "_" - |    ■   | (adr. 7128h)
	.db 008h	; "_" - |    ■   | (adr. 7129h)
	.db 004h	; "_" - |     ■  | (adr. 712Ah)
	.db 004h	; "_" - |     ■  | (adr. 712Bh)
	.db 002h	; "_" - |      ■ | (adr. 712Ch)
	.db 002h	; "_" - |      ■ | (adr. 712Dh)
	.db 001h	; "_" - |       ■| (adr. 712Eh)
	.db 001h	; "_" - |       ■| (adr. 712Fh)
	.db 080h	; "А" - |■       | (adr. 7130h)
	.db 080h	; "А" - |■       | (adr. 7131h)
	.db 040h	; "@" - | ■      | (adr. 7132h)
	.db 040h	; "@" - | ■      | (adr. 7133h)
	.db 020h	; " " - |  ■     | (adr. 7134h)
	.db 020h	; " " - |  ■     | (adr. 7135h)
	.db 010h	; "_" - |   ■    | (adr. 7136h)
	.db 010h	; "_" - |   ■    | (adr. 7137h)
	.db 008h	; "_" - |    ■   | (adr. 7138h)
	.db 008h	; "_" - |    ■   | (adr. 7139h)
	.db 004h	; "_" - |     ■  | (adr. 713Ah)
	.db 004h	; "_" - |     ■  | (adr. 713Bh)
	.db 002h	; "_" - |      ■ | (adr. 713Ch)
	.db 002h	; "_" - |      ■ | (adr. 713Dh)
	.db 001h	; "_" - |       ■| (adr. 713Eh)
	.db 001h	; "_" - |       ■| (adr. 713Fh)
	.db 080h	; "А" - |■       | (adr. 7140h)
	.db 080h	; "А" - |■       | (adr. 7141h)
	.db 040h	; "@" - | ■      | (adr. 7142h)
	.db 040h	; "@" - | ■      | (adr. 7143h)
	.db 020h	; " " - |  ■     | (adr. 7144h)
	.db 020h	; " " - |  ■     | (adr. 7145h)
	.db 010h	; "_" - |   ■    | (adr. 7146h)
	.db 010h	; "_" - |   ■    | (adr. 7147h)
	.db 008h	; "_" - |    ■   | (adr. 7148h)
	.db 008h	; "_" - |    ■   | (adr. 7149h)
	.db 004h	; "_" - |     ■  | (adr. 714Ah)
	.db 004h	; "_" - |     ■  | (adr. 714Bh)
	.db 002h	; "_" - |      ■ | (adr. 714Ch)
	.db 002h	; "_" - |      ■ | (adr. 714Dh)
	.db 001h	; "_" - |       ■| (adr. 714Eh)
	.db 001h	; "_" - |       ■| (adr. 714Fh)
	.db 080h	; "А" - |■       | (adr. 7150h)
	.db 080h	; "А" - |■       | (adr. 7151h)
	.db 040h	; "@" - | ■      | (adr. 7152h)
	.db 040h	; "@" - | ■      | (adr. 7153h)
	.db 020h	; " " - |  ■     | (adr. 7154h)
	.db 020h	; " " - |  ■     | (adr. 7155h)
	.db 010h	; "_" - |   ■    | (adr. 7156h)
	.db 010h	; "_" - |   ■    | (adr. 7157h)
	.db 008h	; "_" - |    ■   | (adr. 7158h)
	.db 008h	; "_" - |    ■   | (adr. 7159h)
	.db 004h	; "_" - |     ■  | (adr. 715Ah)
	.db 004h	; "_" - |     ■  | (adr. 715Bh)
	.db 002h	; "_" - |      ■ | (adr. 715Ch)
	.db 002h	; "_" - |      ■ | (adr. 715Dh)
	.db 001h	; "_" - |       ■| (adr. 715Eh)
	.db 001h	; "_" - |       ■| (adr. 715Fh)
	.db 080h	; "А" - |■       | (adr. 7160h)
	.db 080h	; "А" - |■       | (adr. 7161h)
	.db 040h	; "@" - | ■      | (adr. 7162h)
	.db 040h	; "@" - | ■      | (adr. 7163h)
	.db 020h	; " " - |  ■     | (adr. 7164h)
	.db 020h	; " " - |  ■     | (adr. 7165h)
	.db 010h	; "_" - |   ■    | (adr. 7166h)
	.db 010h	; "_" - |   ■    | (adr. 7167h)
	.db 008h	; "_" - |    ■   | (adr. 7168h)
	.db 008h	; "_" - |    ■   | (adr. 7169h)
	.db 004h	; "_" - |     ■  | (adr. 716Ah)
	.db 004h	; "_" - |     ■  | (adr. 716Bh)
	.db 002h	; "_" - |      ■ | (adr. 716Ch)
	.db 002h	; "_" - |      ■ | (adr. 716Dh)
	.db 001h	; "_" - |       ■| (adr. 716Eh)
	.db 001h	; "_" - |       ■| (adr. 716Fh)
	.db 080h	; "А" - |■       | (adr. 7170h)
	.db 080h	; "А" - |■       | (adr. 7171h)
	.db 040h	; "@" - | ■      | (adr. 7172h)
	.db 040h	; "@" - | ■      | (adr. 7173h)
	.db 020h	; " " - |  ■     | (adr. 7174h)
	.db 020h	; " " - |  ■     | (adr. 7175h)
	.db 010h	; "_" - |   ■    | (adr. 7176h)
	.db 010h	; "_" - |   ■    | (adr. 7177h)
	.db 008h	; "_" - |    ■   | (adr. 7178h)
	.db 008h	; "_" - |    ■   | (adr. 7179h)
	.db 004h	; "_" - |     ■  | (adr. 717Ah)
	.db 004h	; "_" - |     ■  | (adr. 717Bh)
	.db 002h	; "_" - |      ■ | (adr. 717Ch)
	.db 002h	; "_" - |      ■ | (adr. 717Dh)
	.db 001h	; "_" - |       ■| (adr. 717Eh)
	.db 001h	; "_" - |       ■| (adr. 717Fh)
	.db 080h	; "А" - |■       | (adr. 7180h)
	.db 080h	; "А" - |■       | (adr. 7181h)
	.db 040h	; "@" - | ■      | (adr. 7182h)
	.db 040h	; "@" - | ■      | (adr. 7183h)
	.db 020h	; " " - |  ■     | (adr. 7184h)
	.db 020h	; " " - |  ■     | (adr. 7185h)
	.db 010h	; "_" - |   ■    | (adr. 7186h)
	.db 010h	; "_" - |   ■    | (adr. 7187h)
	.db 008h	; "_" - |    ■   | (adr. 7188h)
	.db 008h	; "_" - |    ■   | (adr. 7189h)
	.db 004h	; "_" - |     ■  | (adr. 718Ah)
	.db 004h	; "_" - |     ■  | (adr. 718Bh)
	.db 002h	; "_" - |      ■ | (adr. 718Ch)
	.db 002h	; "_" - |      ■ | (adr. 718Dh)
	.db 001h	; "_" - |       ■| (adr. 718Eh)
	.db 001h	; "_" - |       ■| (adr. 718Fh)
	.db 080h	; "А" - |■       | (adr. 7190h)
	.db 080h	; "А" - |■       | (adr. 7191h)
	.db 040h	; "@" - | ■      | (adr. 7192h)
	.db 040h	; "@" - | ■      | (adr. 7193h)
	.db 020h	; " " - |  ■     | (adr. 7194h)
	.db 020h	; " " - |  ■     | (adr. 7195h)
	.db 010h	; "_" - |   ■    | (adr. 7196h)
	.db 010h	; "_" - |   ■    | (adr. 7197h)
	.db 008h	; "_" - |    ■   | (adr. 7198h)
	.db 008h	; "_" - |    ■   | (adr. 7199h)
	.db 004h	; "_" - |     ■  | (adr. 719Ah)
	.db 004h	; "_" - |     ■  | (adr. 719Bh)
	.db 002h	; "_" - |      ■ | (adr. 719Ch)
	.db 002h	; "_" - |      ■ | (adr. 719Dh)
	.db 001h	; "_" - |       ■| (adr. 719Eh)
	.db 001h	; "_" - |       ■| (adr. 719Fh)
	.db 080h	; "А" - |■       | (adr. 71A0h)
	.db 080h	; "А" - |■       | (adr. 71A1h)
	.db 040h	; "@" - | ■      | (adr. 71A2h)
	.db 040h	; "@" - | ■      | (adr. 71A3h)
	.db 020h	; " " - |  ■     | (adr. 71A4h)
	.db 020h	; " " - |  ■     | (adr. 71A5h)
	.db 010h	; "_" - |   ■    | (adr. 71A6h)
	.db 010h	; "_" - |   ■    | (adr. 71A7h)
	.db 008h	; "_" - |    ■   | (adr. 71A8h)
	.db 008h	; "_" - |    ■   | (adr. 71A9h)
	.db 004h	; "_" - |     ■  | (adr. 71AAh)
	.db 004h	; "_" - |     ■  | (adr. 71ABh)
	.db 002h	; "_" - |      ■ | (adr. 71ACh)
	.db 002h	; "_" - |      ■ | (adr. 71ADh)
	.db 001h	; "_" - |       ■| (adr. 71AEh)
	.db 001h	; "_" - |       ■| (adr. 71AFh)
	.db 080h	; "А" - |■       | (adr. 71B0h)
	.db 080h	; "А" - |■       | (adr. 71B1h)
	.db 040h	; "@" - | ■      | (adr. 71B2h)
	.db 040h	; "@" - | ■      | (adr. 71B3h)
	.db 020h	; " " - |  ■     | (adr. 71B4h)
	.db 020h	; " " - |  ■     | (adr. 71B5h)
	.db 010h	; "_" - |   ■    | (adr. 71B6h)
	.db 010h	; "_" - |   ■    | (adr. 71B7h)
	.db 008h	; "_" - |    ■   | (adr. 71B8h)
	.db 008h	; "_" - |    ■   | (adr. 71B9h)
	.db 004h	; "_" - |     ■  | (adr. 71BAh)
	.db 004h	; "_" - |     ■  | (adr. 71BBh)
	.db 002h	; "_" - |      ■ | (adr. 71BCh)
	.db 002h	; "_" - |      ■ | (adr. 71BDh)
	.db 001h	; "_" - |       ■| (adr. 71BEh)
	.db 001h	; "_" - |       ■| (adr. 71BFh)
	.db 080h	; "А" - |■       | (adr. 71C0h)
	.db 080h	; "А" - |■       | (adr. 71C1h)
	.db 040h	; "@" - | ■      | (adr. 71C2h)
	.db 040h	; "@" - | ■      | (adr. 71C3h)
	.db 020h	; " " - |  ■     | (adr. 71C4h)
	.db 020h	; " " - |  ■     | (adr. 71C5h)
	.db 010h	; "_" - |   ■    | (adr. 71C6h)
	.db 010h	; "_" - |   ■    | (adr. 71C7h)
	.db 008h	; "_" - |    ■   | (adr. 71C8h)
	.db 008h	; "_" - |    ■   | (adr. 71C9h)
	.db 004h	; "_" - |     ■  | (adr. 71CAh)
	.db 004h	; "_" - |     ■  | (adr. 71CBh)
	.db 002h	; "_" - |      ■ | (adr. 71CCh)
	.db 002h	; "_" - |      ■ | (adr. 71CDh)
	.db 001h	; "_" - |       ■| (adr. 71CEh)
	.db 001h	; "_" - |       ■| (adr. 71CFh)
	.db 080h	; "А" - |■       | (adr. 71D0h)
	.db 080h	; "А" - |■       | (adr. 71D1h)
	.db 040h	; "@" - | ■      | (adr. 71D2h)
	.db 040h	; "@" - | ■      | (adr. 71D3h)
	.db 020h	; " " - |  ■     | (adr. 71D4h)
	.db 020h	; " " - |  ■     | (adr. 71D5h)
	.db 010h	; "_" - |   ■    | (adr. 71D6h)
	.db 010h	; "_" - |   ■    | (adr. 71D7h)
	.db 008h	; "_" - |    ■   | (adr. 71D8h)
	.db 008h	; "_" - |    ■   | (adr. 71D9h)
	.db 004h	; "_" - |     ■  | (adr. 71DAh)
	.db 004h	; "_" - |     ■  | (adr. 71DBh)
	.db 002h	; "_" - |      ■ | (adr. 71DCh)
	.db 002h	; "_" - |      ■ | (adr. 71DDh)
	.db 001h	; "_" - |       ■| (adr. 71DEh)
	.db 001h	; "_" - |       ■| (adr. 71DFh)
	.db 080h	; "А" - |■       | (adr. 71E0h)
	.db 080h	; "А" - |■       | (adr. 71E1h)
	.db 040h	; "@" - | ■      | (adr. 71E2h)
	.db 040h	; "@" - | ■      | (adr. 71E3h)
	.db 020h	; " " - |  ■     | (adr. 71E4h)
	.db 020h	; " " - |  ■     | (adr. 71E5h)
	.db 010h	; "_" - |   ■    | (adr. 71E6h)
	.db 010h	; "_" - |   ■    | (adr. 71E7h)
	.db 008h	; "_" - |    ■   | (adr. 71E8h)
	.db 008h	; "_" - |    ■   | (adr. 71E9h)
	.db 004h	; "_" - |     ■  | (adr. 71EAh)
	.db 004h	; "_" - |     ■  | (adr. 71EBh)
	.db 002h	; "_" - |      ■ | (adr. 71ECh)
	.db 002h	; "_" - |      ■ | (adr. 71EDh)
	.db 001h	; "_" - |       ■| (adr. 71EEh)
	.db 001h	; "_" - |       ■| (adr. 71EFh)
	.db 080h	; "А" - |■       | (adr. 71F0h)
	.db 080h	; "А" - |■       | (adr. 71F1h)
	.db 040h	; "@" - | ■      | (adr. 71F2h)
	.db 040h	; "@" - | ■      | (adr. 71F3h)
	.db 020h	; " " - |  ■     | (adr. 71F4h)
	.db 020h	; " " - |  ■     | (adr. 71F5h)
	.db 010h	; "_" - |   ■    | (adr. 71F6h)
	.db 010h	; "_" - |   ■    | (adr. 71F7h)
	.db 008h	; "_" - |    ■   | (adr. 71F8h)
	.db 008h	; "_" - |    ■   | (adr. 71F9h)
	.db 004h	; "_" - |     ■  | (adr. 71FAh)
	.db 004h	; "_" - |     ■  | (adr. 71FBh)
	.db 002h	; "_" - |      ■ | (adr. 71FCh)
	.db 002h	; "_" - |      ■ | (adr. 71FDh)
	.db 001h	; "_" - |       ■| (adr. 71FEh)
	.db 001h	; "_" - |       ■| (adr. 71FFh)
	.db 080h	; "А" - |■       | (adr. 7200h)
	.db 080h	; "А" - |■       | (adr. 7201h)
	.db 040h	; "@" - | ■      | (adr. 7202h)
	.db 040h	; "@" - | ■      | (adr. 7203h)
	.db 020h	; " " - |  ■     | (adr. 7204h)
	.db 020h	; " " - |  ■     | (adr. 7205h)
	.db 010h	; "_" - |   ■    | (adr. 7206h)
	.db 010h	; "_" - |   ■    | (adr. 7207h)
	.db 008h	; "_" - |    ■   | (adr. 7208h)
	.db 008h	; "_" - |    ■   | (adr. 7209h)
	.db 004h	; "_" - |     ■  | (adr. 720Ah)
	.db 004h	; "_" - |     ■  | (adr. 720Bh)
	.db 002h	; "_" - |      ■ | (adr. 720Ch)
	.db 002h	; "_" - |      ■ | (adr. 720Dh)
	.db 001h	; "_" - |       ■| (adr. 720Eh)
	.db 001h	; "_" - |       ■| (adr. 720Fh)
	.db 080h	; "А" - |■       | (adr. 7210h)
	.db 080h	; "А" - |■       | (adr. 7211h)
	.db 040h	; "@" - | ■      | (adr. 7212h)
	.db 040h	; "@" - | ■      | (adr. 7213h)
	.db 020h	; " " - |  ■     | (adr. 7214h)
	.db 020h	; " " - |  ■     | (adr. 7215h)
	.db 010h	; "_" - |   ■    | (adr. 7216h)
	.db 010h	; "_" - |   ■    | (adr. 7217h)
	.db 008h	; "_" - |    ■   | (adr. 7218h)
	.db 008h	; "_" - |    ■   | (adr. 7219h)
	.db 004h	; "_" - |     ■  | (adr. 721Ah)
	.db 004h	; "_" - |     ■  | (adr. 721Bh)
	.db 002h	; "_" - |      ■ | (adr. 721Ch)
	.db 002h	; "_" - |      ■ | (adr. 721Dh)
	.db 001h	; "_" - |       ■| (adr. 721Eh)
	.db 001h	; "_" - |       ■| (adr. 721Fh)
	.db 080h	; "А" - |■       | (adr. 7220h)
	.db 080h	; "А" - |■       | (adr. 7221h)
	.db 040h	; "@" - | ■      | (adr. 7222h)
	.db 040h	; "@" - | ■      | (adr. 7223h)
	.db 020h	; " " - |  ■     | (adr. 7224h)
	.db 020h	; " " - |  ■     | (adr. 7225h)
	.db 010h	; "_" - |   ■    | (adr. 7226h)
	.db 010h	; "_" - |   ■    | (adr. 7227h)
	.db 008h	; "_" - |    ■   | (adr. 7228h)
	.db 008h	; "_" - |    ■   | (adr. 7229h)
	.db 004h	; "_" - |     ■  | (adr. 722Ah)
	.db 004h	; "_" - |     ■  | (adr. 722Bh)
	.db 002h	; "_" - |      ■ | (adr. 722Ch)
	.db 002h	; "_" - |      ■ | (adr. 722Dh)
	.db 001h	; "_" - |       ■| (adr. 722Eh)
	.db 001h	; "_" - |       ■| (adr. 722Fh)
	.db 080h	; "А" - |■       | (adr. 7230h)
	.db 080h	; "А" - |■       | (adr. 7231h)
	.db 040h	; "@" - | ■      | (adr. 7232h)
	.db 040h	; "@" - | ■      | (adr. 7233h)
	.db 020h	; " " - |  ■     | (adr. 7234h)
	.db 020h	; " " - |  ■     | (adr. 7235h)
	.db 010h	; "_" - |   ■    | (adr. 7236h)
	.db 010h	; "_" - |   ■    | (adr. 7237h)
	.db 008h	; "_" - |    ■   | (adr. 7238h)
	.db 008h	; "_" - |    ■   | (adr. 7239h)
	.db 004h	; "_" - |     ■  | (adr. 723Ah)
	.db 004h	; "_" - |     ■  | (adr. 723Bh)
	.db 002h	; "_" - |      ■ | (adr. 723Ch)
	.db 002h	; "_" - |      ■ | (adr. 723Dh)
	.db 001h	; "_" - |       ■| (adr. 723Eh)
	.db 001h	; "_" - |       ■| (adr. 723Fh)
	.db 080h	; "А" - |■       | (adr. 7240h)
	.db 080h	; "А" - |■       | (adr. 7241h)
	.db 040h	; "@" - | ■      | (adr. 7242h)
	.db 040h	; "@" - | ■      | (adr. 7243h)
	.db 020h	; " " - |  ■     | (adr. 7244h)
	.db 020h	; " " - |  ■     | (adr. 7245h)
	.db 010h	; "_" - |   ■    | (adr. 7246h)
	.db 010h	; "_" - |   ■    | (adr. 7247h)
	.db 008h	; "_" - |    ■   | (adr. 7248h)
	.db 008h	; "_" - |    ■   | (adr. 7249h)
	.db 004h	; "_" - |     ■  | (adr. 724Ah)
	.db 004h	; "_" - |     ■  | (adr. 724Bh)
	.db 002h	; "_" - |      ■ | (adr. 724Ch)
	.db 002h	; "_" - |      ■ | (adr. 724Dh)
	.db 001h	; "_" - |       ■| (adr. 724Eh)
	.db 001h	; "_" - |       ■| (adr. 724Fh)
	.db 080h	; "А" - |■       | (adr. 7250h)
	.db 080h	; "А" - |■       | (adr. 7251h)
	.db 040h	; "@" - | ■      | (adr. 7252h)
	.db 040h	; "@" - | ■      | (adr. 7253h)
	.db 020h	; " " - |  ■     | (adr. 7254h)
	.db 020h	; " " - |  ■     | (adr. 7255h)
	.db 010h	; "_" - |   ■    | (adr. 7256h)
	.db 010h	; "_" - |   ■    | (adr. 7257h)
	.db 008h	; "_" - |    ■   | (adr. 7258h)
	.db 008h	; "_" - |    ■   | (adr. 7259h)
	.db 004h	; "_" - |     ■  | (adr. 725Ah)
	.db 004h	; "_" - |     ■  | (adr. 725Bh)
	.db 002h	; "_" - |      ■ | (adr. 725Ch)
	.db 002h	; "_" - |      ■ | (adr. 725Dh)
	.db 001h	; "_" - |       ■| (adr. 725Eh)
	.db 001h	; "_" - |       ■| (adr. 725Fh)
	.db 080h	; "А" - |■       | (adr. 7260h)
	.db 080h	; "А" - |■       | (adr. 7261h)
	.db 040h	; "@" - | ■      | (adr. 7262h)
	.db 040h	; "@" - | ■      | (adr. 7263h)
	.db 020h	; " " - |  ■     | (adr. 7264h)
	.db 020h	; " " - |  ■     | (adr. 7265h)
	.db 010h	; "_" - |   ■    | (adr. 7266h)
	.db 010h	; "_" - |   ■    | (adr. 7267h)
	.db 008h	; "_" - |    ■   | (adr. 7268h)
	.db 008h	; "_" - |    ■   | (adr. 7269h)
	.db 004h	; "_" - |     ■  | (adr. 726Ah)
	.db 004h	; "_" - |     ■  | (adr. 726Bh)
	.db 002h	; "_" - |      ■ | (adr. 726Ch)
	.db 002h	; "_" - |      ■ | (adr. 726Dh)
	.db 001h	; "_" - |       ■| (adr. 726Eh)
	.db 001h	; "_" - |       ■| (adr. 726Fh)
	.db 080h	; "А" - |■       | (adr. 7270h)
	.db 080h	; "А" - |■       | (adr. 7271h)
	.db 040h	; "@" - | ■      | (adr. 7272h)
	.db 040h	; "@" - | ■      | (adr. 7273h)
	.db 020h	; " " - |  ■     | (adr. 7274h)
	.db 020h	; " " - |  ■     | (adr. 7275h)
	.db 010h	; "_" - |   ■    | (adr. 7276h)
	.db 010h	; "_" - |   ■    | (adr. 7277h)
	.db 008h	; "_" - |    ■   | (adr. 7278h)
	.db 008h	; "_" - |    ■   | (adr. 7279h)
	.db 004h	; "_" - |     ■  | (adr. 727Ah)
	.db 004h	; "_" - |     ■  | (adr. 727Bh)
	.db 002h	; "_" - |      ■ | (adr. 727Ch)
	.db 002h	; "_" - |      ■ | (adr. 727Dh)
	.db 001h	; "_" - |       ■| (adr. 727Eh)
	.db 001h	; "_" - |       ■| (adr. 727Fh)
	.db 080h	; "А" - |■       | (adr. 7280h)
	.db 080h	; "А" - |■       | (adr. 7281h)
	.db 040h	; "@" - | ■      | (adr. 7282h)
	.db 040h	; "@" - | ■      | (adr. 7283h)
	.db 020h	; " " - |  ■     | (adr. 7284h)
	.db 020h	; " " - |  ■     | (adr. 7285h)
	.db 010h	; "_" - |   ■    | (adr. 7286h)
	.db 010h	; "_" - |   ■    | (adr. 7287h)
	.db 008h	; "_" - |    ■   | (adr. 7288h)
	.db 008h	; "_" - |    ■   | (adr. 7289h)
	.db 004h	; "_" - |     ■  | (adr. 728Ah)
	.db 004h	; "_" - |     ■  | (adr. 728Bh)
	.db 002h	; "_" - |      ■ | (adr. 728Ch)
	.db 002h	; "_" - |      ■ | (adr. 728Dh)
	.db 001h	; "_" - |       ■| (adr. 728Eh)
	.db 001h	; "_" - |       ■| (adr. 728Fh)
	.db 080h	; "А" - |■       | (adr. 7290h)
	.db 080h	; "А" - |■       | (adr. 7291h)
	.db 040h	; "@" - | ■      | (adr. 7292h)
	.db 040h	; "@" - | ■      | (adr. 7293h)
	.db 020h	; " " - |  ■     | (adr. 7294h)
	.db 020h	; " " - |  ■     | (adr. 7295h)
	.db 010h	; "_" - |   ■    | (adr. 7296h)
	.db 010h	; "_" - |   ■    | (adr. 7297h)
	.db 008h	; "_" - |    ■   | (adr. 7298h)
	.db 008h	; "_" - |    ■   | (adr. 7299h)
	.db 004h	; "_" - |     ■  | (adr. 729Ah)
	.db 004h	; "_" - |     ■  | (adr. 729Bh)
	.db 002h	; "_" - |      ■ | (adr. 729Ch)
	.db 002h	; "_" - |      ■ | (adr. 729Dh)
	.db 001h	; "_" - |       ■| (adr. 729Eh)
	.db 001h	; "_" - |       ■| (adr. 729Fh)
	.db 080h	; "А" - |■       | (adr. 72A0h)
	.db 080h	; "А" - |■       | (adr. 72A1h)
	.db 040h	; "@" - | ■      | (adr. 72A2h)
	.db 040h	; "@" - | ■      | (adr. 72A3h)
	.db 020h	; " " - |  ■     | (adr. 72A4h)
	.db 020h	; " " - |  ■     | (adr. 72A5h)
	.db 010h	; "_" - |   ■    | (adr. 72A6h)
	.db 010h	; "_" - |   ■    | (adr. 72A7h)
	.db 008h	; "_" - |    ■   | (adr. 72A8h)
	.db 008h	; "_" - |    ■   | (adr. 72A9h)
	.db 004h	; "_" - |     ■  | (adr. 72AAh)
	.db 004h	; "_" - |     ■  | (adr. 72ABh)
	.db 002h	; "_" - |      ■ | (adr. 72ACh)
	.db 002h	; "_" - |      ■ | (adr. 72ADh)
	.db 001h	; "_" - |       ■| (adr. 72AEh)
	.db 001h	; "_" - |       ■| (adr. 72AFh)
	.db 080h	; "А" - |■       | (adr. 72B0h)
	.db 080h	; "А" - |■       | (adr. 72B1h)
	.db 040h	; "@" - | ■      | (adr. 72B2h)
	.db 040h	; "@" - | ■      | (adr. 72B3h)
	.db 020h	; " " - |  ■     | (adr. 72B4h)
	.db 020h	; " " - |  ■     | (adr. 72B5h)
	.db 010h	; "_" - |   ■    | (adr. 72B6h)
	.db 010h	; "_" - |   ■    | (adr. 72B7h)
	.db 008h	; "_" - |    ■   | (adr. 72B8h)
	.db 008h	; "_" - |    ■   | (adr. 72B9h)
	.db 004h	; "_" - |     ■  | (adr. 72BAh)
	.db 004h	; "_" - |     ■  | (adr. 72BBh)
	.db 002h	; "_" - |      ■ | (adr. 72BCh)
	.db 002h	; "_" - |      ■ | (adr. 72BDh)
	.db 001h	; "_" - |       ■| (adr. 72BEh)
	.db 001h	; "_" - |       ■| (adr. 72BFh)
	.db 080h	; "А" - |■       | (adr. 72C0h)
	.db 080h	; "А" - |■       | (adr. 72C1h)
	.db 040h	; "@" - | ■      | (adr. 72C2h)
	.db 040h	; "@" - | ■      | (adr. 72C3h)
	.db 020h	; " " - |  ■     | (adr. 72C4h)
	.db 020h	; " " - |  ■     | (adr. 72C5h)
	.db 010h	; "_" - |   ■    | (adr. 72C6h)
	.db 010h	; "_" - |   ■    | (adr. 72C7h)
	.db 008h	; "_" - |    ■   | (adr. 72C8h)
	.db 008h	; "_" - |    ■   | (adr. 72C9h)
	.db 004h	; "_" - |     ■  | (adr. 72CAh)
	.db 004h	; "_" - |     ■  | (adr. 72CBh)
	.db 002h	; "_" - |      ■ | (adr. 72CCh)
	.db 002h	; "_" - |      ■ | (adr. 72CDh)
	.db 001h	; "_" - |       ■| (adr. 72CEh)
	.db 001h	; "_" - |       ■| (adr. 72CFh)
	.db 080h	; "А" - |■       | (adr. 72D0h)
	.db 080h	; "А" - |■       | (adr. 72D1h)
	.db 040h	; "@" - | ■      | (adr. 72D2h)
	.db 040h	; "@" - | ■      | (adr. 72D3h)
	.db 020h	; " " - |  ■     | (adr. 72D4h)
	.db 020h	; " " - |  ■     | (adr. 72D5h)
	.db 010h	; "_" - |   ■    | (adr. 72D6h)
	.db 010h	; "_" - |   ■    | (adr. 72D7h)
	.db 008h	; "_" - |    ■   | (adr. 72D8h)
	.db 008h	; "_" - |    ■   | (adr. 72D9h)
	.db 004h	; "_" - |     ■  | (adr. 72DAh)
	.db 004h	; "_" - |     ■  | (adr. 72DBh)
	.db 002h	; "_" - |      ■ | (adr. 72DCh)
	.db 002h	; "_" - |      ■ | (adr. 72DDh)
	.db 001h	; "_" - |       ■| (adr. 72DEh)
	.db 001h	; "_" - |       ■| (adr. 72DFh)
	.db 080h	; "А" - |■       | (adr. 72E0h)
	.db 080h	; "А" - |■       | (adr. 72E1h)
	.db 040h	; "@" - | ■      | (adr. 72E2h)
	.db 040h	; "@" - | ■      | (adr. 72E3h)
	.db 020h	; " " - |  ■     | (adr. 72E4h)
	.db 020h	; " " - |  ■     | (adr. 72E5h)
	.db 010h	; "_" - |   ■    | (adr. 72E6h)
	.db 010h	; "_" - |   ■    | (adr. 72E7h)
	.db 008h	; "_" - |    ■   | (adr. 72E8h)
	.db 008h	; "_" - |    ■   | (adr. 72E9h)
	.db 004h	; "_" - |     ■  | (adr. 72EAh)
	.db 004h	; "_" - |     ■  | (adr. 72EBh)
	.db 002h	; "_" - |      ■ | (adr. 72ECh)
	.db 002h	; "_" - |      ■ | (adr. 72EDh)
	.db 001h	; "_" - |       ■| (adr. 72EEh)
	.db 001h	; "_" - |       ■| (adr. 72EFh)
	.db 080h	; "А" - |■       | (adr. 72F0h)
	.db 080h	; "А" - |■       | (adr. 72F1h)
	.db 040h	; "@" - | ■      | (adr. 72F2h)
	.db 040h	; "@" - | ■      | (adr. 72F3h)
	.db 020h	; " " - |  ■     | (adr. 72F4h)
	.db 020h	; " " - |  ■     | (adr. 72F5h)
	.db 010h	; "_" - |   ■    | (adr. 72F6h)
	.db 010h	; "_" - |   ■    | (adr. 72F7h)
	.db 008h	; "_" - |    ■   | (adr. 72F8h)
	.db 008h	; "_" - |    ■   | (adr. 72F9h)
	.db 004h	; "_" - |     ■  | (adr. 72FAh)
	.db 004h	; "_" - |     ■  | (adr. 72FBh)
	.db 002h	; "_" - |      ■ | (adr. 72FCh)
	.db 002h	; "_" - |      ■ | (adr. 72FDh)
	.db 001h	; "_" - |       ■| (adr. 72FEh)
	.db 001h	; "_" - |       ■| (adr. 72FFh)
;
F_7300:	.db 000h	; |        | (adr. 7300h)
	.db 000h	; |        | (adr. 7301h)
	.db 000h	; |        | (adr. 7302h)
	.db 000h	; |        | (adr. 7303h)
	.db 000h	; |        | (adr. 7304h)
	.db 03Eh	; |  ■■■■■ | (adr. 7305h)
	.db 055h	; | ■ ■ ■ ■| (adr. 7306h)
	.db 051h	; | ■ ■   ■| (adr. 7307h)
	.db 055h	; | ■ ■ ■ ■| (adr. 7308h)
	.db 03Eh	; |  ■■■■■ | (adr. 7309h)
	.db 03Eh	; |  ■■■■■ | (adr. 730Ah)
	.db 06Bh	; | ■■ ■ ■■| (adr. 730Bh)
	.db 06Fh	; | ■■ ■■■■| (adr. 730Ch)
	.db 06Bh	; | ■■ ■ ■■| (adr. 730Dh)
	.db 03Eh	; |  ■■■■■ | (adr. 730Eh)
	.db 00Ch	; |    ■■  | (adr. 730Fh)
	.db 01Eh	; |   ■■■■ | (adr. 7310h)
	.db 03Ch	; |  ■■■■  | (adr. 7311h)
	.db 01Eh	; |   ■■■■ | (adr. 7312h)
	.db 00Ch	; |    ■■  | (adr. 7313h)
	.db 008h	; |    ■   | (adr. 7314h)
	.db 01Ch	; |   ■■■  | (adr. 7315h)
	.db 03Eh	; |  ■■■■■ | (adr. 7316h)
	.db 01Ch	; |   ■■■  | (adr. 7317h)
	.db 008h	; |    ■   | (adr. 7318h)
	.db 01Ch	; |   ■■■  | (adr. 7319h)
	.db 049h	; | ■  ■  ■| (adr. 731Ah)
	.db 07Fh	; | ■■■■■■■| (adr. 731Bh)
	.db 049h	; | ■  ■  ■| (adr. 731Ch)
	.db 01Ch	; |   ■■■  | (adr. 731Dh)
	.db 01Ch	; |   ■■■  | (adr. 731Eh)
	.db 08Eh	; |■   ■■■ | (adr. 731Fh)
	.db 07Fh	; | ■■■■■■■| (adr. 7320h)
	.db 08Eh	; |■   ■■■ | (adr. 7321h)
	.db 01Ch	; |   ■■■  | (adr. 7322h)
	.db 000h	; |        | (adr. 7323h)
	.db 008h	; |    ■   | (adr. 7324h)
	.db 01Ch	; |   ■■■  | (adr. 7325h)
	.db 008h	; |    ■   | (adr. 7326h)
	.db 000h	; |        | (adr. 7327h)
	.db 07Fh	; | ■■■■■■■| (adr. 7328h)
	.db 077h	; | ■■■ ■■■| (adr. 7329h)
	.db 063h	; | ■■   ■■| (adr. 732Ah)
	.db 077h	; | ■■■ ■■■| (adr. 732Bh)
	.db 07Fh	; | ■■■■■■■| (adr. 732Ch)
	.db 000h	; |        | (adr. 732Dh)
	.db 01Ch	; |   ■■■  | (adr. 732Eh)
	.db 014h	; |   ■ ■  | (adr. 732Fh)
	.db 01Ch	; |   ■■■  | (adr. 7330h)
	.db 000h	; |        | (adr. 7331h)
	.db 07Fh	; | ■■■■■■■| (adr. 7332h)
	.db 063h	; | ■■   ■■| (adr. 7333h)
	.db 06Bh	; | ■■ ■ ■■| (adr. 7334h)
	.db 063h	; | ■■   ■■| (adr. 7335h)
	.db 07Fh	; | ■■■■■■■| (adr. 7336h)
	.db 018h	; |   ■■   | (adr. 7337h)
	.db 024h	; |  ■  ■  | (adr. 7338h)
	.db 018h	; |   ■■   | (adr. 7339h)
	.db 006h	; |     ■■ | (adr. 733Ah)
	.db 006h	; |     ■■ | (adr. 733Bh)
	.db 004h	; |     ■  | (adr. 733Ch)
	.db 02Ah	; |  ■ ■ ■ | (adr. 733Dh)
	.db 079h	; | ■■■■  ■| (adr. 733Eh)
	.db 02Ah	; |  ■ ■ ■ | (adr. 733Fh)
	.db 004h	; |     ■  | (adr. 7340h)
	.db 040h	; | ■      | (adr. 7341h)
	.db 040h	; | ■      | (adr. 7342h)
	.db 07Eh	; | ■■■■■■ | (adr. 7343h)
	.db 009h	; |    ■  ■| (adr. 7344h)
	.db 00Eh	; |    ■■■ | (adr. 7345h)
	.db 040h	; | ■      | (adr. 7346h)
	.db 07Fh	; | ■■■■■■■| (adr. 7347h)
	.db 005h	; |     ■ ■| (adr. 7348h)
	.db 025h	; |  ■  ■ ■| (adr. 7349h)
	.db 01Fh	; |   ■■■■■| (adr. 734Ah)
	.db 02Ah	; |  ■ ■ ■ | (adr. 734Bh)
	.db 01Ch	; |   ■■■  | (adr. 734Ch)
	.db 077h	; | ■■■ ■■■| (adr. 734Dh)
	.db 01Ch	; |   ■■■  | (adr. 734Eh)
	.db 02Ah	; |  ■ ■ ■ | (adr. 734Fh)
	.db 000h	; |        | (adr. 7350h)
	.db 07Fh	; | ■■■■■■■| (adr. 7351h)
	.db 03Eh	; |  ■■■■■ | (adr. 7352h)
	.db 01Ch	; |   ■■■  | (adr. 7353h)
	.db 008h	; |    ■   | (adr. 7354h)
	.db 008h	; |    ■   | (adr. 7355h)
	.db 01Ch	; |   ■■■  | (adr. 7356h)
	.db 03Eh	; |  ■■■■■ | (adr. 7357h)
	.db 07Fh	; | ■■■■■■■| (adr. 7358h)
	.db 000h	; |        | (adr. 7359h)
	.db 014h	; |   ■ ■  | (adr. 735Ah)
	.db 036h	; |  ■■ ■■ | (adr. 735Bh)
	.db 07Fh	; | ■■■■■■■| (adr. 735Ch)
	.db 036h	; |  ■■ ■■ | (adr. 735Dh)
	.db 014h	; |   ■ ■  | (adr. 735Eh)
	.db 000h	; |        | (adr. 735Fh)
	.db 05Fh	; | ■ ■■■■■| (adr. 7360h)
	.db 000h	; |        | (adr. 7361h)
	.db 05Fh	; | ■ ■■■■■| (adr. 7362h)
	.db 000h	; |        | (adr. 7363h)
	.db 046h	; | ■   ■■ | (adr. 7364h)
	.db 045h	; | ■   ■ ■| (adr. 7365h)
	.db 03Fh	; |  ■■■■■■| (adr. 7366h)
	.db 001h	; |       ■| (adr. 7367h)
	.db 03Dh	; |  ■■■■ ■| (adr. 7368h)
	.db 048h	; | ■  ■   | (adr. 7369h)
	.db 056h	; | ■ ■ ■■ | (adr. 736Ah)
	.db 055h	; | ■ ■ ■ ■| (adr. 736Bh)
	.db 035h	; |  ■■ ■ ■| (adr. 736Ch)
	.db 009h	; |    ■  ■| (adr. 736Dh)
	.db 070h	; | ■■■    | (adr. 736Eh)
	.db 070h	; | ■■■    | (adr. 736Fh)
	.db 070h	; | ■■■    | (adr. 7370h)
	.db 070h	; | ■■■    | (adr. 7371h)
	.db 070h	; | ■■■    | (adr. 7372h)
	.db 004h	; |     ■  | (adr. 7373h)
	.db 052h	; | ■ ■  ■ | (adr. 7374h)
	.db 07Fh	; | ■■■■■■■| (adr. 7375h)
	.db 052h	; | ■ ■  ■ | (adr. 7376h)
	.db 004h	; |     ■  | (adr. 7377h)
	.db 004h	; |     ■  | (adr. 7378h)
	.db 006h	; |     ■■ | (adr. 7379h)
	.db 07Fh	; | ■■■■■■■| (adr. 737Ah)
	.db 006h	; |     ■■ | (adr. 737Bh)
	.db 004h	; |     ■  | (adr. 737Ch)
	.db 010h	; |   ■    | (adr. 737Dh)
	.db 030h	; |  ■■    | (adr. 737Eh)
	.db 07Fh	; | ■■■■■■■| (adr. 737Fh)
	.db 030h	; |  ■■    | (adr. 7380h)
	.db 010h	; |   ■    | (adr. 7381h)
	.db 008h	; |    ■   | (adr. 7382h)
	.db 008h	; |    ■   | (adr. 7383h)
	.db 03Eh	; |  ■■■■■ | (adr. 7384h)
	.db 01Ch	; |   ■■■  | (adr. 7385h)
	.db 008h	; |    ■   | (adr. 7386h)
	.db 008h	; |    ■   | (adr. 7387h)
	.db 01Ch	; |   ■■■  | (adr. 7388h)
	.db 03Eh	; |  ■■■■■ | (adr. 7389h)
	.db 008h	; |    ■   | (adr. 738Ah)
	.db 008h	; |    ■   | (adr. 738Bh)
	.db 038h	; |  ■■■   | (adr. 738Ch)
	.db 020h	; |  ■     | (adr. 738Dh)
	.db 020h	; |  ■     | (adr. 738Eh)
	.db 020h	; |  ■     | (adr. 738Fh)
	.db 020h	; |  ■     | (adr. 7390h)
	.db 008h	; |    ■   | (adr. 7391h)
	.db 01Ch	; |   ■■■  | (adr. 7392h)
	.db 008h	; |    ■   | (adr. 7393h)
	.db 01Ch	; |   ■■■  | (adr. 7394h)
	.db 008h	; |    ■   | (adr. 7395h)
	.db 038h	; |  ■■■   | (adr. 7396h)
	.db 03Ch	; |  ■■■■  | (adr. 7397h)
	.db 03Eh	; |  ■■■■■ | (adr. 7398h)
	.db 03Ch	; |  ■■■■  | (adr. 7399h)
	.db 038h	; |  ■■■   | (adr. 739Ah)
	.db 00Eh	; |    ■■■ | (adr. 739Bh)
	.db 01Eh	; |   ■■■■ | (adr. 739Ch)
	.db 03Eh	; |  ■■■■■ | (adr. 739Dh)
	.db 01Eh	; |   ■■■■ | (adr. 739Eh)
	.db 00Eh	; |    ■■■ | (adr. 739Fh)
F_73A0:	.db 000h	; |        | (adr. 73A0h)
	.db 000h	; |        | (adr. 73A1h)
	.db 000h	; |        | (adr. 73A2h)
	.db 000h	; |        | (adr. 73A3h)
	.db 000h	; |        | (adr. 73A4h)
	.db 000h	; |        | (adr. 73A5h)
	.db 000h	; |        | (adr. 73A6h)
	.db 05Fh	; | ■ ■■■■■| (adr. 73A7h)
	.db 000h	; |        | (adr. 73A8h)
	.db 000h	; |        | (adr. 73A9h)
	.db 000h	; |        | (adr. 73AAh)
	.db 003h	; |      ■■| (adr. 73ABh)
	.db 000h	; |        | (adr. 73ACh)
	.db 003h	; |      ■■| (adr. 73ADh)
	.db 000h	; |        | (adr. 73AEh)
	.db 014h	; |   ■ ■  | (adr. 73AFh)
	.db 03Eh	; |  ■■■■■ | (adr. 73B0h)
	.db 014h	; |   ■ ■  | (adr. 73B1h)
	.db 03Eh	; |  ■■■■■ | (adr. 73B2h)
	.db 014h	; |   ■ ■  | (adr. 73B3h)
	.db 022h	; |  ■   ■ | (adr. 73B4h)
	.db 01Ch	; |   ■■■  | (adr. 73B5h)
	.db 014h	; |   ■ ■  | (adr. 73B6h)
	.db 01Ch	; |   ■■■  | (adr. 73B7h)
	.db 022h	; |  ■   ■ | (adr. 73B8h)
	.db 023h	; |  ■   ■■| (adr. 73B9h)
	.db 013h	; |   ■  ■■| (adr. 73BAh)
	.db 008h	; |    ■   | (adr. 73BBh)
	.db 064h	; | ■■  ■  | (adr. 73BCh)
	.db 062h	; | ■■   ■ | (adr. 73BDh)
	.db 036h	; |  ■■ ■■ | (adr. 73BEh)
	.db 049h	; | ■  ■  ■| (adr. 73BFh)
	.db 056h	; | ■ ■ ■■ | (adr. 73C0h)
	.db 020h	; |  ■     | (adr. 73C1h)
	.db 050h	; | ■ ■    | (adr. 73C2h)
	.db 000h	; |        | (adr. 73C3h)
	.db 00Bh	; |    ■ ■■| (adr. 73C4h)
	.db 007h	; |     ■■■| (adr. 73C5h)
	.db 000h	; |        | (adr. 73C6h)
	.db 000h	; |        | (adr. 73C7h)
	.db 000h	; |        | (adr. 73C8h)
	.db 01Ch	; |   ■■■  | (adr. 73C9h)
	.db 022h	; |  ■   ■ | (adr. 73CAh)
	.db 041h	; | ■     ■| (adr. 73CBh)
	.db 000h	; |        | (adr. 73CCh)
	.db 000h	; |        | (adr. 73CDh)
	.db 041h	; | ■     ■| (adr. 73CEh)
	.db 022h	; |  ■   ■ | (adr. 73CFh)
	.db 01Ch	; |   ■■■  | (adr. 73D0h)
	.db 000h	; |        | (adr. 73D1h)
	.db 024h	; |  ■  ■  | (adr. 73D2h)
	.db 018h	; |   ■■   | (adr. 73D3h)
	.db 07Eh	; | ■■■■■■ | (adr. 73D4h)
	.db 018h	; |   ■■   | (adr. 73D5h)
	.db 024h	; |  ■  ■  | (adr. 73D6h)
	.db 008h	; |    ■   | (adr. 73D7h)
	.db 008h	; |    ■   | (adr. 73D8h)
	.db 03Eh	; |  ■■■■■ | (adr. 73D9h)
	.db 008h	; |    ■   | (adr. 73DAh)
	.db 008h	; |    ■   | (adr. 73DBh)
	.db 000h	; |        | (adr. 73DCh)
	.db 058h	; | ■ ■■   | (adr. 73DDh)
	.db 038h	; |  ■■■   | (adr. 73DEh)
	.db 000h	; |        | (adr. 73DFh)
	.db 000h	; |        | (adr. 73E0h)
	.db 008h	; |    ■   | (adr. 73E1h)
	.db 008h	; |    ■   | (adr. 73E2h)
	.db 008h	; |    ■   | (adr. 73E3h)
	.db 008h	; |    ■   | (adr. 73E4h)
	.db 008h	; |    ■   | (adr. 73E5h)
	.db 000h	; |        | (adr. 73E6h)
	.db 060h	; | ■■     | (adr. 73E7h)
	.db 060h	; | ■■     | (adr. 73E8h)
	.db 000h	; |        | (adr. 73E9h)
	.db 000h	; |        | (adr. 73EAh)
	.db 020h	; |  ■     | (adr. 73EBh)
	.db 010h	; |   ■    | (adr. 73ECh)
	.db 008h	; |    ■   | (adr. 73EDh)
	.db 004h	; |     ■  | (adr. 73EEh)
	.db 002h	; |      ■ | (adr. 73EFh)
	.db 03Eh	; |  ■■■■■ | (adr. 73F0h)
	.db 051h	; | ■ ■   ■| (adr. 73F1h)
	.db 049h	; | ■  ■  ■| (adr. 73F2h)
	.db 045h	; | ■   ■ ■| (adr. 73F3h)
	.db 03Eh	; |  ■■■■■ | (adr. 73F4h)
	.db 000h	; |        | (adr. 73F5h)
	.db 004h	; |     ■  | (adr. 73F6h)
	.db 002h	; |      ■ | (adr. 73F7h)
	.db 07Fh	; | ■■■■■■■| (adr. 73F8h)
	.db 000h	; |        | (adr. 73F9h)
	.db 042h	; | ■    ■ | (adr. 73FAh)
	.db 061h	; | ■■    ■| (adr. 73FBh)
	.db 051h	; | ■ ■   ■| (adr. 73FCh)
	.db 049h	; | ■  ■  ■| (adr. 73FDh)
	.db 046h	; | ■   ■■ | (adr. 73FEh)
	.db 021h	; |  ■    ■| (adr. 73FFh)
	.db 041h	; | ■     ■| (adr. 7400h)
	.db 049h	; | ■  ■  ■| (adr. 7401h)
	.db 04Dh	; | ■  ■■ ■| (adr. 7402h)
	.db 033h	; |  ■■  ■■| (adr. 7403h)
	.db 018h	; |   ■■   | (adr. 7404h)
	.db 014h	; |   ■ ■  | (adr. 7405h)
	.db 012h	; |   ■  ■ | (adr. 7406h)
	.db 07Fh	; | ■■■■■■■| (adr. 7407h)
	.db 010h	; |   ■    | (adr. 7408h)
	.db 027h	; |  ■  ■■■| (adr. 7409h)
	.db 045h	; | ■   ■ ■| (adr. 740Ah)
	.db 045h	; | ■   ■ ■| (adr. 740Bh)
	.db 045h	; | ■   ■ ■| (adr. 740Ch)
	.db 039h	; |  ■■■  ■| (adr. 740Dh)
	.db 03Eh	; |  ■■■■■ | (adr. 740Eh)
	.db 049h	; | ■  ■  ■| (adr. 740Fh)
	.db 049h	; | ■  ■  ■| (adr. 7410h)
	.db 049h	; | ■  ■  ■| (adr. 7411h)
	.db 032h	; |  ■■  ■ | (adr. 7412h)
	.db 000h	; |        | (adr. 7413h)
	.db 001h	; |       ■| (adr. 7414h)
	.db 079h	; | ■■■■  ■| (adr. 7415h)
	.db 005h	; |     ■ ■| (adr. 7416h)
	.db 003h	; |      ■■| (adr. 7417h)
	.db 036h	; |  ■■ ■■ | (adr. 7418h)
	.db 049h	; | ■  ■  ■| (adr. 7419h)
	.db 049h	; | ■  ■  ■| (adr. 741Ah)
	.db 049h	; | ■  ■  ■| (adr. 741Bh)
	.db 036h	; |  ■■ ■■ | (adr. 741Ch)
	.db 026h	; |  ■  ■■ | (adr. 741Dh)
	.db 049h	; | ■  ■  ■| (adr. 741Eh)
	.db 049h	; | ■  ■  ■| (adr. 741Fh)
	.db 049h	; | ■  ■  ■| (adr. 7420h)
	.db 03Eh	; |  ■■■■■ | (adr. 7421h)
	.db 000h	; |        | (adr. 7422h)
	.db 066h	; | ■■  ■■ | (adr. 7423h)
	.db 066h	; | ■■  ■■ | (adr. 7424h)
	.db 000h	; |        | (adr. 7425h)
	.db 000h	; |        | (adr. 7426h)
	.db 000h	; |        | (adr. 7427h)
	.db 05Bh	; | ■ ■■ ■■| (adr. 7428h)
	.db 03Bh	; |  ■■■ ■■| (adr. 7429h)
	.db 000h	; |        | (adr. 742Ah)
	.db 000h	; |        | (adr. 742Bh)
	.db 000h	; |        | (adr. 742Ch)
	.db 008h	; |    ■   | (adr. 742Dh)
	.db 014h	; |   ■ ■  | (adr. 742Eh)
	.db 022h	; |  ■   ■ | (adr. 742Fh)
	.db 041h	; | ■     ■| (adr. 7430h)
	.db 014h	; |   ■ ■  | (adr. 7431h)
	.db 014h	; |   ■ ■  | (adr. 7432h)
	.db 014h	; |   ■ ■  | (adr. 7433h)
	.db 014h	; |   ■ ■  | (adr. 7434h)
	.db 014h	; |   ■ ■  | (adr. 7435h)
	.db 041h	; | ■     ■| (adr. 7436h)
	.db 022h	; |  ■   ■ | (adr. 7437h)
	.db 014h	; |   ■ ■  | (adr. 7438h)
	.db 008h	; |    ■   | (adr. 7439h)
	.db 000h	; |        | (adr. 743Ah)
	.db 006h	; |     ■■ | (adr. 743Bh)
	.db 001h	; |       ■| (adr. 743Ch)
	.db 059h	; | ■ ■■  ■| (adr. 743Dh)
	.db 009h	; |    ■  ■| (adr. 743Eh)
	.db 006h	; |     ■■ | (adr. 743Fh)
F_7440:	.db 03Eh	; |  ■■■■■ | (adr. 7440h)
	.db 041h	; | ■     ■| (adr. 7441h)
	.db 059h	; | ■ ■■  ■| (adr. 7442h)
	.db 055h	; | ■ ■ ■ ■| (adr. 7443h)
	.db 01Eh	; |   ■■■■ | (adr. 7444h)
	.db 07Ch	; | ■■■■■  | (adr. 7445h)
	.db 012h	; |   ■  ■ | (adr. 7446h)
	.db 011h	; |   ■   ■| (adr. 7447h)
	.db 012h	; |   ■  ■ | (adr. 7448h)
	.db 07Ch	; | ■■■■■  | (adr. 7449h)
	.db 07Fh	; | ■■■■■■■| (adr. 744Ah)
	.db 049h	; | ■  ■  ■| (adr. 744Bh)
	.db 049h	; | ■  ■  ■| (adr. 744Ch)
	.db 049h	; | ■  ■  ■| (adr. 744Dh)
	.db 036h	; |  ■■ ■■ | (adr. 744Eh)
	.db 03Eh	; |  ■■■■■ | (adr. 744Fh)
	.db 041h	; | ■     ■| (adr. 7450h)
	.db 041h	; | ■     ■| (adr. 7451h)
	.db 041h	; | ■     ■| (adr. 7452h)
	.db 022h	; |  ■   ■ | (adr. 7453h)
	.db 041h	; | ■     ■| (adr. 7454h)
	.db 07Fh	; | ■■■■■■■| (adr. 7455h)
	.db 041h	; | ■     ■| (adr. 7456h)
	.db 041h	; | ■     ■| (adr. 7457h)
	.db 03Eh	; |  ■■■■■ | (adr. 7458h)
	.db 07Fh	; | ■■■■■■■| (adr. 7459h)
	.db 049h	; | ■  ■  ■| (adr. 745Ah)
	.db 049h	; | ■  ■  ■| (adr. 745Bh)
	.db 049h	; | ■  ■  ■| (adr. 745Ch)
	.db 041h	; | ■     ■| (adr. 745Dh)
	.db 07Fh	; | ■■■■■■■| (adr. 745Eh)
	.db 009h	; |    ■  ■| (adr. 745Fh)
	.db 009h	; |    ■  ■| (adr. 7460h)
	.db 009h	; |    ■  ■| (adr. 7461h)
	.db 001h	; |       ■| (adr. 7462h)
	.db 03Eh	; |  ■■■■■ | (adr. 7463h)
	.db 041h	; | ■     ■| (adr. 7464h)
	.db 041h	; | ■     ■| (adr. 7465h)
	.db 049h	; | ■  ■  ■| (adr. 7466h)
	.db 03Ah	; |  ■■■ ■ | (adr. 7467h)
	.db 07Fh	; | ■■■■■■■| (adr. 7468h)
	.db 008h	; |    ■   | (adr. 7469h)
	.db 008h	; |    ■   | (adr. 746Ah)
	.db 008h	; |    ■   | (adr. 746Bh)
	.db 07Fh	; | ■■■■■■■| (adr. 746Ch)
	.db 000h	; |        | (adr. 746Dh)
	.db 041h	; | ■     ■| (adr. 746Eh)
	.db 07Fh	; | ■■■■■■■| (adr. 746Fh)
	.db 041h	; | ■     ■| (adr. 7470h)
	.db 000h	; |        | (adr. 7471h)
	.db 021h	; |  ■    ■| (adr. 7472h)
	.db 041h	; | ■     ■| (adr. 7473h)
	.db 041h	; | ■     ■| (adr. 7474h)
	.db 041h	; | ■     ■| (adr. 7475h)
	.db 03Fh	; |  ■■■■■■| (adr. 7476h)
	.db 07Fh	; | ■■■■■■■| (adr. 7477h)
	.db 008h	; |    ■   | (adr. 7478h)
	.db 014h	; |   ■ ■  | (adr. 7479h)
	.db 022h	; |  ■   ■ | (adr. 747Ah)
	.db 041h	; | ■     ■| (adr. 747Bh)
	.db 07Fh	; | ■■■■■■■| (adr. 747Ch)
	.db 040h	; | ■      | (adr. 747Dh)
	.db 040h	; | ■      | (adr. 747Eh)
	.db 040h	; | ■      | (adr. 747Fh)
	.db 060h	; | ■■     | (adr. 7480h)
	.db 07Fh	; | ■■■■■■■| (adr. 7481h)
	.db 002h	; |      ■ | (adr. 7482h)
	.db 00Ch	; |    ■■  | (adr. 7483h)
	.db 002h	; |      ■ | (adr. 7484h)
	.db 07Fh	; | ■■■■■■■| (adr. 7485h)
	.db 07Fh	; | ■■■■■■■| (adr. 7486h)
	.db 004h	; |     ■  | (adr. 7487h)
	.db 008h	; |    ■   | (adr. 7488h)
	.db 010h	; |   ■    | (adr. 7489h)
	.db 07Fh	; | ■■■■■■■| (adr. 748Ah)
	.db 03Eh	; |  ■■■■■ | (adr. 748Bh)
	.db 041h	; | ■     ■| (adr. 748Ch)
	.db 041h	; | ■     ■| (adr. 748Dh)
	.db 041h	; | ■     ■| (adr. 748Eh)
	.db 03Eh	; |  ■■■■■ | (adr. 748Fh)
	.db 07Fh	; | ■■■■■■■| (adr. 7490h)
	.db 009h	; |    ■  ■| (adr. 7491h)
	.db 009h	; |    ■  ■| (adr. 7492h)
	.db 009h	; |    ■  ■| (adr. 7493h)
	.db 006h	; |     ■■ | (adr. 7494h)
	.db 03Eh	; |  ■■■■■ | (adr. 7495h)
	.db 041h	; | ■     ■| (adr. 7496h)
	.db 051h	; | ■ ■   ■| (adr. 7497h)
	.db 061h	; | ■■    ■| (adr. 7498h)
	.db 07Eh	; | ■■■■■■ | (adr. 7499h)
	.db 07Fh	; | ■■■■■■■| (adr. 749Ah)
	.db 009h	; |    ■  ■| (adr. 749Bh)
	.db 019h	; |   ■■  ■| (adr. 749Ch)
	.db 029h	; |  ■ ■  ■| (adr. 749Dh)
	.db 046h	; | ■   ■■ | (adr. 749Eh)
	.db 026h	; |  ■  ■■ | (adr. 749Fh)
	.db 049h	; | ■  ■  ■| (adr. 74A0h)
	.db 049h	; | ■  ■  ■| (adr. 74A1h)
	.db 049h	; | ■  ■  ■| (adr. 74A2h)
	.db 032h	; |  ■■  ■ | (adr. 74A3h)
	.db 001h	; |       ■| (adr. 74A4h)
	.db 001h	; |       ■| (adr. 74A5h)
	.db 07Fh	; | ■■■■■■■| (adr. 74A6h)
	.db 001h	; |       ■| (adr. 74A7h)
	.db 001h	; |       ■| (adr. 74A8h)
	.db 03Fh	; |  ■■■■■■| (adr. 74A9h)
	.db 040h	; | ■      | (adr. 74AAh)
	.db 040h	; | ■      | (adr. 74ABh)
	.db 040h	; | ■      | (adr. 74ACh)
	.db 03Fh	; |  ■■■■■■| (adr. 74ADh)
	.db 01Fh	; |   ■■■■■| (adr. 74AEh)
	.db 020h	; |  ■     | (adr. 74AFh)
	.db 040h	; | ■      | (adr. 74B0h)
	.db 020h	; |  ■     | (adr. 74B1h)
	.db 01Fh	; |   ■■■■■| (adr. 74B2h)
	.db 03Fh	; |  ■■■■■■| (adr. 74B3h)
	.db 040h	; | ■      | (adr. 74B4h)
	.db 038h	; |  ■■■   | (adr. 74B5h)
	.db 040h	; | ■      | (adr. 74B6h)
	.db 03Fh	; |  ■■■■■■| (adr. 74B7h)
	.db 063h	; | ■■   ■■| (adr. 74B8h)
	.db 014h	; |   ■ ■  | (adr. 74B9h)
	.db 008h	; |    ■   | (adr. 74BAh)
	.db 014h	; |   ■ ■  | (adr. 74BBh)
	.db 063h	; | ■■   ■■| (adr. 74BCh)
	.db 003h	; |      ■■| (adr. 74BDh)
	.db 004h	; |     ■  | (adr. 74BEh)
	.db 078h	; | ■■■■   | (adr. 74BFh)
	.db 004h	; |     ■  | (adr. 74C0h)
	.db 003h	; |      ■■| (adr. 74C1h)
	.db 061h	; | ■■    ■| (adr. 74C2h)
	.db 059h	; | ■ ■■  ■| (adr. 74C3h)
	.db 049h	; | ■  ■  ■| (adr. 74C4h)
	.db 04Dh	; | ■  ■■ ■| (adr. 74C5h)
	.db 043h	; | ■    ■■| (adr. 74C6h)
	.db 000h	; |        | (adr. 74C7h)
	.db 07Fh	; | ■■■■■■■| (adr. 74C8h)
	.db 041h	; | ■     ■| (adr. 74C9h)
	.db 041h	; | ■     ■| (adr. 74CAh)
	.db 000h	; |        | (adr. 74CBh)
	.db 002h	; |      ■ | (adr. 74CCh)
	.db 004h	; |     ■  | (adr. 74CDh)
	.db 008h	; |    ■   | (adr. 74CEh)
	.db 010h	; |   ■    | (adr. 74CFh)
	.db 020h	; |  ■     | (adr. 74D0h)
	.db 000h	; |        | (adr. 74D1h)
	.db 041h	; | ■     ■| (adr. 74D2h)
	.db 041h	; | ■     ■| (adr. 74D3h)
	.db 07Fh	; | ■■■■■■■| (adr. 74D4h)
	.db 000h	; |        | (adr. 74D5h)
	.db 004h	; |     ■  | (adr. 74D6h)
	.db 002h	; |      ■ | (adr. 74D7h)
	.db 001h	; |       ■| (adr. 74D8h)
	.db 002h	; |      ■ | (adr. 74D9h)
	.db 004h	; |     ■  | (adr. 74DAh)
	.db 040h	; | ■      | (adr. 74DBh)
	.db 040h	; | ■      | (adr. 74DCh)
	.db 040h	; | ■      | (adr. 74DDh)
	.db 040h	; | ■      | (adr. 74DEh)
	.db 040h	; | ■      | (adr. 74DFh)
F_74E0:	.db 000h	; |        | (adr. 74E0h)
	.db 001h	; |       ■| (adr. 74E1h)
	.db 002h	; |      ■ | (adr. 74E2h)
	.db 000h	; |        | (adr. 74E3h)
	.db 000h	; |        | (adr. 74E4h)
	.db 032h	; |  ■■  ■ | (adr. 74E5h)
	.db 04Ah	; | ■  ■ ■ | (adr. 74E6h)
	.db 04Ah	; | ■  ■ ■ | (adr. 74E7h)
	.db 03Ch	; |  ■■■■  | (adr. 74E8h)
	.db 040h	; | ■      | (adr. 74E9h)
	.db 07Eh	; | ■■■■■■ | (adr. 74EAh)
	.db 048h	; | ■  ■   | (adr. 74EBh)
	.db 048h	; | ■  ■   | (adr. 74ECh)
	.db 048h	; | ■  ■   | (adr. 74EDh)
	.db 030h	; |  ■■    | (adr. 74EEh)
	.db 038h	; |  ■■■   | (adr. 74EFh)
	.db 044h	; | ■   ■  | (adr. 74F0h)
	.db 044h	; | ■   ■  | (adr. 74F1h)
	.db 044h	; | ■   ■  | (adr. 74F2h)
	.db 044h	; | ■   ■  | (adr. 74F3h)
	.db 030h	; |  ■■    | (adr. 74F4h)
	.db 048h	; | ■  ■   | (adr. 74F5h)
	.db 048h	; | ■  ■   | (adr. 74F6h)
	.db 048h	; | ■  ■   | (adr. 74F7h)
	.db 07Eh	; | ■■■■■■ | (adr. 74F8h)
	.db 038h	; |  ■■■   | (adr. 74F9h)
	.db 054h	; | ■ ■ ■  | (adr. 74FAh)
	.db 054h	; | ■ ■ ■  | (adr. 74FBh)
	.db 054h	; | ■ ■ ■  | (adr. 74FCh)
	.db 018h	; |   ■■   | (adr. 74FDh)
	.db 000h	; |        | (adr. 74FEh)
	.db 008h	; |    ■   | (adr. 74FFh)
	.db 07Eh	; | ■■■■■■ | (adr. 7500h)
	.db 009h	; |    ■  ■| (adr. 7501h)
	.db 009h	; |    ■  ■| (adr. 7502h)
	.db 00Ch	; |    ■■  | (adr. 7503h)
	.db 012h	; |   ■  ■ | (adr. 7504h)
	.db 052h	; | ■ ■  ■ | (adr. 7505h)
	.db 052h	; | ■ ■  ■ | (adr. 7506h)
	.db 07Eh	; | ■■■■■■ | (adr. 7507h)
	.db 07Fh	; | ■■■■■■■| (adr. 7508h)
	.db 008h	; |    ■   | (adr. 7509h)
	.db 004h	; |     ■  | (adr. 750Ah)
	.db 004h	; |     ■  | (adr. 750Bh)
	.db 078h	; | ■■■■   | (adr. 750Ch)
	.db 000h	; |        | (adr. 750Dh)
	.db 048h	; | ■  ■   | (adr. 750Eh)
	.db 07Ah	; | ■■■■ ■ | (adr. 750Fh)
	.db 040h	; | ■      | (adr. 7510h)
	.db 000h	; |        | (adr. 7511h)
	.db 040h	; | ■      | (adr. 7512h)
	.db 040h	; | ■      | (adr. 7513h)
	.db 044h	; | ■   ■  | (adr. 7514h)
	.db 03Dh	; |  ■■■■ ■| (adr. 7515h)
	.db 000h	; |        | (adr. 7516h)
	.db 000h	; |        | (adr. 7517h)
	.db 07Fh	; | ■■■■■■■| (adr. 7518h)
	.db 010h	; |   ■    | (adr. 7519h)
	.db 028h	; |  ■ ■   | (adr. 751Ah)
	.db 044h	; | ■   ■  | (adr. 751Bh)
	.db 000h	; |        | (adr. 751Ch)
	.db 042h	; | ■    ■ | (adr. 751Dh)
	.db 07Eh	; | ■■■■■■ | (adr. 751Eh)
	.db 040h	; | ■      | (adr. 751Fh)
	.db 000h	; |        | (adr. 7520h)
	.db 07Ch	; | ■■■■■  | (adr. 7521h)
	.db 004h	; |     ■  | (adr. 7522h)
	.db 078h	; | ■■■■   | (adr. 7523h)
	.db 004h	; |     ■  | (adr. 7524h)
	.db 078h	; | ■■■■   | (adr. 7525h)
	.db 07Ch	; | ■■■■■  | (adr. 7526h)
	.db 008h	; |    ■   | (adr. 7527h)
	.db 004h	; |     ■  | (adr. 7528h)
	.db 004h	; |     ■  | (adr. 7529h)
	.db 078h	; | ■■■■   | (adr. 752Ah)
	.db 038h	; |  ■■■   | (adr. 752Bh)
	.db 044h	; | ■   ■  | (adr. 752Ch)
	.db 044h	; | ■   ■  | (adr. 752Dh)
	.db 044h	; | ■   ■  | (adr. 752Eh)
	.db 038h	; |  ■■■   | (adr. 752Fh)
	.db 07Eh	; | ■■■■■■ | (adr. 7530h)
	.db 012h	; |   ■  ■ | (adr. 7531h)
	.db 012h	; |   ■  ■ | (adr. 7532h)
	.db 012h	; |   ■  ■ | (adr. 7533h)
	.db 00Ch	; |    ■■  | (adr. 7534h)
	.db 00Ch	; |    ■■  | (adr. 7535h)
	.db 012h	; |   ■  ■ | (adr. 7536h)
	.db 012h	; |   ■  ■ | (adr. 7537h)
	.db 012h	; |   ■  ■ | (adr. 7538h)
	.db 07Eh	; | ■■■■■■ | (adr. 7539h)
	.db 07Ch	; | ■■■■■  | (adr. 753Ah)
	.db 008h	; |    ■   | (adr. 753Bh)
	.db 004h	; |     ■  | (adr. 753Ch)
	.db 004h	; |     ■  | (adr. 753Dh)
	.db 004h	; |     ■  | (adr. 753Eh)
	.db 008h	; |    ■   | (adr. 753Fh)
	.db 054h	; | ■ ■ ■  | (adr. 7540h)
	.db 054h	; | ■ ■ ■  | (adr. 7541h)
	.db 054h	; | ■ ■ ■  | (adr. 7542h)
	.db 020h	; |  ■     | (adr. 7543h)
	.db 004h	; |     ■  | (adr. 7544h)
	.db 03Fh	; |  ■■■■■■| (adr. 7545h)
	.db 044h	; | ■   ■  | (adr. 7546h)
	.db 044h	; | ■   ■  | (adr. 7547h)
	.db 020h	; |  ■     | (adr. 7548h)
	.db 03Ch	; |  ■■■■  | (adr. 7549h)
	.db 040h	; | ■      | (adr. 754Ah)
	.db 040h	; | ■      | (adr. 754Bh)
	.db 03Ch	; |  ■■■■  | (adr. 754Ch)
	.db 040h	; | ■      | (adr. 754Dh)
	.db 00Ch	; |    ■■  | (adr. 754Eh)
	.db 030h	; |  ■■    | (adr. 754Fh)
	.db 040h	; | ■      | (adr. 7550h)
	.db 030h	; |  ■■    | (adr. 7551h)
	.db 00Ch	; |    ■■  | (adr. 7552h)
	.db 03Ch	; |  ■■■■  | (adr. 7553h)
	.db 040h	; | ■      | (adr. 7554h)
	.db 038h	; |  ■■■   | (adr. 7555h)
	.db 040h	; | ■      | (adr. 7556h)
	.db 03Ch	; |  ■■■■  | (adr. 7557h)
	.db 044h	; | ■   ■  | (adr. 7558h)
	.db 028h	; |  ■ ■   | (adr. 7559h)
	.db 010h	; |   ■    | (adr. 755Ah)
	.db 028h	; |  ■ ■   | (adr. 755Bh)
	.db 044h	; | ■   ■  | (adr. 755Ch)
	.db 000h	; |        | (adr. 755Dh)
	.db 04Ch	; | ■  ■■  | (adr. 755Eh)
	.db 030h	; |  ■■    | (adr. 755Fh)
	.db 010h	; |   ■    | (adr. 7560h)
	.db 00Ch	; |    ■■  | (adr. 7561h)
	.db 044h	; | ■   ■  | (adr. 7562h)
	.db 064h	; | ■■  ■  | (adr. 7563h)
	.db 054h	; | ■ ■ ■  | (adr. 7564h)
	.db 04Ch	; | ■  ■■  | (adr. 7565h)
	.db 044h	; | ■   ■  | (adr. 7566h)
	.db 000h	; |        | (adr. 7567h)
	.db 008h	; |    ■   | (adr. 7568h)
	.db 036h	; |  ■■ ■■ | (adr. 7569h)
	.db 041h	; | ■     ■| (adr. 756Ah)
	.db 041h	; | ■     ■| (adr. 756Bh)
	.db 000h	; |        | (adr. 756Ch)
	.db 000h	; |        | (adr. 756Dh)
	.db 06Dh	; | ■■ ■■ ■| (adr. 756Eh)
	.db 000h	; |        | (adr. 756Fh)
	.db 000h	; |        | (adr. 7570h)
	.db 041h	; | ■     ■| (adr. 7571h)
	.db 041h	; | ■     ■| (adr. 7572h)
	.db 036h	; |  ■■ ■■ | (adr. 7573h)
	.db 008h	; |    ■   | (adr. 7574h)
	.db 000h	; |        | (adr. 7575h)
	.db 018h	; |   ■■   | (adr. 7576h)
	.db 004h	; |     ■  | (adr. 7577h)
	.db 008h	; |    ■   | (adr. 7578h)
	.db 010h	; |   ■    | (adr. 7579h)
	.db 00Ch	; |    ■■  | (adr. 757Ah)
	.db 07Eh	; | ■■■■■■ | (adr. 757Bh)
	.db 07Eh	; | ■■■■■■ | (adr. 757Ch)
	.db 07Eh	; | ■■■■■■ | (adr. 757Dh)
	.db 07Eh	; | ■■■■■■ | (adr. 757Eh)
	.db 07Eh	; | ■■■■■■ | (adr. 757Fh)
F_7580:	.db 055h	; | ■ ■ ■ ■| (adr. 7580h)
	.db 000h	; |        | (adr. 7581h)
	.db 0AAh	; |■ ■ ■ ■ | (adr. 7582h)
	.db 000h	; |        | (adr. 7583h)
	.db 055h	; | ■ ■ ■ ■| (adr. 7584h)
	.db 055h	; | ■ ■ ■ ■| (adr. 7585h)
	.db 0AAh	; |■ ■ ■ ■ | (adr. 7586h)
	.db 055h	; | ■ ■ ■ ■| (adr. 7587h)
	.db 0AAh	; |■ ■ ■ ■ | (adr. 7588h)
	.db 055h	; | ■ ■ ■ ■| (adr. 7589h)
	.db 024h	; |  ■  ■  | (adr. 758Ah)
	.db 080h	; |■       | (adr. 758Bh)
	.db 012h	; |   ■  ■ | (adr. 758Ch)
	.db 040h	; | ■      | (adr. 758Dh)
	.db 009h	; |    ■  ■| (adr. 758Eh)
	.db 000h	; |        | (adr. 758Fh)
	.db 000h	; |        | (adr. 7590h)
	.db 0FFh	; |■■■■■■■■| (adr. 7591h)
	.db 000h	; |        | (adr. 7592h)
	.db 000h	; |        | (adr. 7593h)
	.db 008h	; |    ■   | (adr. 7594h)
	.db 008h	; |    ■   | (adr. 7595h)
	.db 0FFh	; |■■■■■■■■| (adr. 7596h)
	.db 000h	; |        | (adr. 7597h)
	.db 000h	; |        | (adr. 7598h)
	.db 00Ah	; |    ■ ■ | (adr. 7599h)
	.db 00Ah	; |    ■ ■ | (adr. 759Ah)
	.db 0FFh	; |■■■■■■■■| (adr. 759Bh)
	.db 000h	; |        | (adr. 759Ch)
	.db 000h	; |        | (adr. 759Dh)
	.db 008h	; |    ■   | (adr. 759Eh)
	.db 0FFh	; |■■■■■■■■| (adr. 759Fh)
	.db 000h	; |        | (adr. 75A0h)
	.db 0FFh	; |■■■■■■■■| (adr. 75A1h)
	.db 000h	; |        | (adr. 75A2h)
	.db 008h	; |    ■   | (adr. 75A3h)
	.db 078h	; | ■■■■   | (adr. 75A4h)
	.db 008h	; |    ■   | (adr. 75A5h)
	.db 078h	; | ■■■■   | (adr. 75A6h)
	.db 000h	; |        | (adr. 75A7h)
	.db 00Ah	; |    ■ ■ | (adr. 75A8h)
	.db 00Ah	; |    ■ ■ | (adr. 75A9h)
	.db 0FFh	; |■■■■■■■■| (adr. 75AAh)
	.db 000h	; |        | (adr. 75ABh)
	.db 000h	; |        | (adr. 75ACh)
	.db 00Ah	; |    ■ ■ | (adr. 75ADh)
	.db 0FBh	; |■■■■■ ■■| (adr. 75AEh)
	.db 000h	; |        | (adr. 75AFh)
	.db 0FFh	; |■■■■■■■■| (adr. 75B0h)
	.db 000h	; |        | (adr. 75B1h)
	.db 000h	; |        | (adr. 75B2h)
	.db 0FFh	; |■■■■■■■■| (adr. 75B3h)
	.db 000h	; |        | (adr. 75B4h)
	.db 0FFh	; |■■■■■■■■| (adr. 75B5h)
	.db 000h	; |        | (adr. 75B6h)
	.db 00Ah	; |    ■ ■ | (adr. 75B7h)
	.db 07Ah	; | ■■■■ ■ | (adr. 75B8h)
	.db 002h	; |      ■ | (adr. 75B9h)
	.db 07Eh	; | ■■■■■■ | (adr. 75BAh)
	.db 000h	; |        | (adr. 75BBh)
	.db 00Ah	; |    ■ ■ | (adr. 75BCh)
	.db 08Bh	; |■   ■ ■■| (adr. 75BDh)
	.db 008h	; |    ■   | (adr. 75BEh)
	.db 08Fh	; |■   ■■■■| (adr. 75BFh)
	.db 000h	; |        | (adr. 75C0h)
	.db 008h	; |    ■   | (adr. 75C1h)
	.db 08Fh	; |■   ■■■■| (adr. 75C2h)
	.db 008h	; |    ■   | (adr. 75C3h)
	.db 08Fh	; |■   ■■■■| (adr. 75C4h)
	.db 000h	; |        | (adr. 75C5h)
	.db 00Ah	; |    ■ ■ | (adr. 75C6h)
	.db 00Ah	; |    ■ ■ | (adr. 75C7h)
	.db 08Fh	; |■   ■■■■| (adr. 75C8h)
	.db 000h	; |        | (adr. 75C9h)
	.db 000h	; |        | (adr. 75CAh)
	.db 008h	; |    ■   | (adr. 75CBh)
	.db 008h	; |    ■   | (adr. 75CCh)
	.db 078h	; | ■■■■   | (adr. 75CDh)
	.db 000h	; |        | (adr. 75CEh)
	.db 000h	; |        | (adr. 75CFh)
	.db 000h	; |        | (adr. 75D0h)
	.db 000h	; |        | (adr. 75D1h)
	.db 08Fh	; |■   ■■■■| (adr. 75D2h)
	.db 008h	; |    ■   | (adr. 75D3h)
	.db 008h	; |    ■   | (adr. 75D4h)
	.db 008h	; |    ■   | (adr. 75D5h)
	.db 008h	; |    ■   | (adr. 75D6h)
	.db 08Fh	; |■   ■■■■| (adr. 75D7h)
	.db 008h	; |    ■   | (adr. 75D8h)
	.db 008h	; |    ■   | (adr. 75D9h)
	.db 008h	; |    ■   | (adr. 75DAh)
	.db 008h	; |    ■   | (adr. 75DBh)
	.db 078h	; | ■■■■   | (adr. 75DCh)
	.db 008h	; |    ■   | (adr. 75DDh)
	.db 008h	; |    ■   | (adr. 75DEh)
	.db 000h	; |        | (adr. 75DFh)
	.db 000h	; |        | (adr. 75E0h)
	.db 0FFh	; |■■■■■■■■| (adr. 75E1h)
	.db 008h	; |    ■   | (adr. 75E2h)
	.db 008h	; |    ■   | (adr. 75E3h)
	.db 008h	; |    ■   | (adr. 75E4h)
	.db 008h	; |    ■   | (adr. 75E5h)
	.db 008h	; |    ■   | (adr. 75E6h)
	.db 008h	; |    ■   | (adr. 75E7h)
	.db 008h	; |    ■   | (adr. 75E8h)
	.db 008h	; |    ■   | (adr. 75E9h)
	.db 008h	; |    ■   | (adr. 75EAh)
	.db 0FFh	; |■■■■■■■■| (adr. 75EBh)
	.db 008h	; |    ■   | (adr. 75ECh)
	.db 008h	; |    ■   | (adr. 75EDh)
	.db 000h	; |        | (adr. 75EEh)
	.db 000h	; |        | (adr. 75EFh)
	.db 0FFh	; |■■■■■■■■| (adr. 75F0h)
	.db 00Ah	; |    ■ ■ | (adr. 75F1h)
	.db 00Ah	; |    ■ ■ | (adr. 75F2h)
	.db 000h	; |        | (adr. 75F3h)
	.db 0FFh	; |■■■■■■■■| (adr. 75F4h)
	.db 000h	; |        | (adr. 75F5h)
	.db 0FFh	; |■■■■■■■■| (adr. 75F6h)
	.db 008h	; |    ■   | (adr. 75F7h)
	.db 000h	; |        | (adr. 75F8h)
	.db 08Fh	; |■   ■■■■| (adr. 75F9h)
	.db 008h	; |    ■   | (adr. 75FAh)
	.db 08Bh	; |■   ■ ■■| (adr. 75FBh)
	.db 00Ah	; |    ■ ■ | (adr. 75FCh)
	.db 000h	; |        | (adr. 75FDh)
	.db 07Eh	; | ■■■■■■ | (adr. 75FEh)
	.db 002h	; |      ■ | (adr. 75FFh)
	.db 07Ah	; | ■■■■ ■ | (adr. 7600h)
	.db 00Ah	; |    ■ ■ | (adr. 7601h)
	.db 00Ah	; |    ■ ■ | (adr. 7602h)
	.db 08Bh	; |■   ■ ■■| (adr. 7603h)
	.db 00Ah	; |    ■ ■ | (adr. 7604h)
	.db 08Bh	; |■   ■ ■■| (adr. 7605h)
	.db 00Ah	; |    ■ ■ | (adr. 7606h)
	.db 00Ah	; |    ■ ■ | (adr. 7607h)
	.db 07Ah	; | ■■■■ ■ | (adr. 7608h)
	.db 00Ah	; |    ■ ■ | (adr. 7609h)
	.db 07Ah	; | ■■■■ ■ | (adr. 760Ah)
	.db 00Ah	; |    ■ ■ | (adr. 760Bh)
	.db 000h	; |        | (adr. 760Ch)
	.db 0FFh	; |■■■■■■■■| (adr. 760Dh)
	.db 000h	; |        | (adr. 760Eh)
	.db 0FFh	; |■■■■■■■■| (adr. 760Fh)
	.db 00Ah	; |    ■ ■ | (adr. 7610h)
	.db 00Ah	; |    ■ ■ | (adr. 7611h)
	.db 00Ah	; |    ■ ■ | (adr. 7612h)
	.db 00Ah	; |    ■ ■ | (adr. 7613h)
	.db 00Ah	; |    ■ ■ | (adr. 7614h)
	.db 00Ah	; |    ■ ■ | (adr. 7615h)
	.db 00Ah	; |    ■ ■ | (adr. 7616h)
	.db 0FBh	; |■■■■■ ■■| (adr. 7617h)
	.db 000h	; |        | (adr. 7618h)
	.db 0FBh	; |■■■■■ ■■| (adr. 7619h)
	.db 00Ah	; |    ■ ■ | (adr. 761Ah)
	.db 00Ah	; |    ■ ■ | (adr. 761Bh)
	.db 00Ah	; |    ■ ■ | (adr. 761Ch)
	.db 08Bh	; |■   ■ ■■| (adr. 761Dh)
	.db 00Ah	; |    ■ ■ | (adr. 761Eh)
	.db 00Ah	; |    ■ ■ | (adr. 761Fh)
F_7620:	.db 01Ch	; |   ■■■  | (adr. 7620h)
	.db 022h	; |  ■   ■ | (adr. 7621h)
	.db 01Eh	; |   ■■■■ | (adr. 7622h)
	.db 0BFh	; |■ ■■■■■■| (adr. 7623h)
	.db 020h	; |  ■     | (adr. 7624h)
	.db 07Eh	; | ■■■■■■ | (adr. 7625h)
	.db 015h	; |   ■ ■ ■| (adr. 7626h)
	.db 015h	; |   ■ ■ ■| (adr. 7627h)
	.db 01Fh	; |   ■■■■■| (adr. 7628h)
	.db 00Ah	; |    ■ ■ | (adr. 7629h)
	.db 03Fh	; |  ■■■■■■| (adr. 762Ah)
	.db 03Fh	; |  ■■■■■■| (adr. 762Bh)
	.db 001h	; |       ■| (adr. 762Ch)
	.db 001h	; |       ■| (adr. 762Dh)
	.db 003h	; |      ■■| (adr. 762Eh)
	.db 0B1h	; |■ ■■   ■| (adr. 762Fh)
	.db 0AAh	; |■ ■ ■ ■ | (adr. 7630h)
	.db 0A4h	; |■ ■  ■  | (adr. 7631h)
	.db 0A0h	; |■ ■     | (adr. 7632h)
	.db 0B1h	; |■ ■■   ■| (adr. 7633h)
	.db 001h	; |       ■| (adr. 7634h)
	.db 03Fh	; |  ■■■■■■| (adr. 7635h)
	.db 001h	; |       ■| (adr. 7636h)
	.db 03Fh	; |  ■■■■■■| (adr. 7637h)
	.db 001h	; |       ■| (adr. 7638h)
	.db 01Ch	; |   ■■■  | (adr. 7639h)
	.db 022h	; |  ■   ■ | (adr. 763Ah)
	.db 022h	; |  ■   ■ | (adr. 763Bh)
	.db 01Eh	; |   ■■■■ | (adr. 763Ch)
	.db 002h	; |      ■ | (adr. 763Dh)
	.db 040h	; | ■      | (adr. 763Eh)
	.db 03Fh	; |  ■■■■■■| (adr. 763Fh)
	.db 010h	; |   ■    | (adr. 7640h)
	.db 00Fh	; |    ■■■■| (adr. 7641h)
	.db 010h	; |   ■    | (adr. 7642h)
	.db 002h	; |      ■ | (adr. 7643h)
	.db 001h	; |       ■| (adr. 7644h)
	.db 03Fh	; |  ■■■■■■| (adr. 7645h)
	.db 002h	; |      ■ | (adr. 7646h)
	.db 001h	; |       ■| (adr. 7647h)
	.db 0CCh	; |■■  ■■  | (adr. 7648h)
	.db 0D2h	; |■■ ■  ■ | (adr. 7649h)
	.db 0F3h	; |■■■■  ■■| (adr. 764Ah)
	.db 0D2h	; |■■ ■  ■ | (adr. 764Bh)
	.db 0CCh	; |■■  ■■  | (adr. 764Ch)
	.db 01Fh	; |   ■■■■■| (adr. 764Dh)
	.db 0A4h	; |■ ■  ■  | (adr. 764Eh)
	.db 0A4h	; |■ ■  ■  | (adr. 764Fh)
	.db 0A4h	; |■ ■  ■  | (adr. 7650h)
	.db 01Fh	; |   ■■■■■| (adr. 7651h)
	.db 012h	; |   ■  ■ | (adr. 7652h)
	.db 09Fh	; |■  ■■■■■| (adr. 7653h)
	.db 080h	; |■       | (adr. 7654h)
	.db 09Fh	; |■  ■■■■■| (adr. 7655h)
	.db 012h	; |   ■  ■ | (adr. 7656h)
	.db 018h	; |   ■■   | (adr. 7657h)
	.db 025h	; |  ■  ■ ■| (adr. 7658h)
	.db 0A7h	; |■ ■  ■■■| (adr. 7659h)
	.db 0A6h	; |■ ■  ■■ | (adr. 765Ah)
	.db 09Ch	; |■  ■■■  | (adr. 765Bh)
	.db 00Ch	; |    ■■  | (adr. 765Ch)
	.db 012h	; |   ■  ■ | (adr. 765Dh)
	.db 01Eh	; |   ■■■■ | (adr. 765Eh)
	.db 012h	; |   ■  ■ | (adr. 765Fh)
	.db 00Ch	; |    ■■  | (adr. 7660h)
	.db 04Ch	; | ■  ■■  | (adr. 7661h)
	.db 052h	; | ■ ■  ■ | (adr. 7662h)
	.db 03Fh	; |  ■■■■■■| (adr. 7663h)
	.db 092h	; |■  ■  ■ | (adr. 7664h)
	.db 08Ch	; |■   ■■  | (adr. 7665h)
	.db 00Eh	; |    ■■■ | (adr. 7666h)
	.db 01Fh	; |   ■■■■■| (adr. 7667h)
	.db 0B5h	; |■ ■■ ■ ■| (adr. 7668h)
	.db 0A4h	; |■ ■  ■  | (adr. 7669h)
	.db 0A4h	; |■ ■  ■  | (adr. 766Ah)
	.db 03Fh	; |  ■■■■■■| (adr. 766Bh)
	.db 081h	; |■      ■| (adr. 766Ch)
	.db 080h	; |■       | (adr. 766Dh)
	.db 081h	; |■      ■| (adr. 766Eh)
	.db 03Fh	; |  ■■■■■■| (adr. 766Fh)
	.db 000h	; |        | (adr. 7670h)
	.db 010h	; |   ■    | (adr. 7671h)
	.db 078h	; | ■■■■   | (adr. 7672h)
	.db 07Ch	; | ■■■■■  | (adr. 7673h)
	.db 000h	; |        | (adr. 7674h)
	.db 048h	; | ■  ■   | (adr. 7675h)
	.db 06Ch	; | ■■ ■■  | (adr. 7676h)
	.db 074h	; | ■■■ ■  | (adr. 7677h)
	.db 05Ch	; | ■ ■■■  | (adr. 7678h)
	.db 048h	; | ■  ■   | (adr. 7679h)
	.db 028h	; |  ■ ■   | (adr. 767Ah)
	.db 06Ch	; | ■■ ■■  | (adr. 767Bh)
	.db 054h	; | ■ ■ ■  | (adr. 767Ch)
	.db 07Ch	; | ■■■■■  | (adr. 767Dh)
	.db 028h	; |  ■ ■   | (adr. 767Eh)
	.db 01Ch	; |   ■■■  | (adr. 767Fh)
	.db 01Ch	; |   ■■■  | (adr. 7680h)
	.db 010h	; |   ■    | (adr. 7681h)
	.db 07Ch	; | ■■■■■  | (adr. 7682h)
	.db 07Ch	; | ■■■■■  | (adr. 7683h)
	.db 05Ch	; | ■ ■■■  | (adr. 7684h)
	.db 05Ch	; | ■ ■■■  | (adr. 7685h)
	.db 054h	; | ■ ■ ■  | (adr. 7686h)
	.db 074h	; | ■■■ ■  | (adr. 7687h)
	.db 024h	; |  ■  ■  | (adr. 7688h)
	.db 038h	; |  ■■■   | (adr. 7689h)
	.db 05Ch	; | ■ ■■■  | (adr. 768Ah)
	.db 054h	; | ■ ■ ■  | (adr. 768Bh)
	.db 074h	; | ■■■ ■  | (adr. 768Ch)
	.db 020h	; |  ■     | (adr. 768Dh)
	.db 004h	; |     ■  | (adr. 768Eh)
	.db 044h	; | ■   ■  | (adr. 768Fh)
	.db 064h	; | ■■  ■  | (adr. 7690h)
	.db 03Ch	; |  ■■■■  | (adr. 7691h)
	.db 01Ch	; |   ■■■  | (adr. 7692h)
	.db 028h	; |  ■ ■   | (adr. 7693h)
	.db 07Ch	; | ■■■■■  | (adr. 7694h)
	.db 054h	; | ■ ■ ■  | (adr. 7695h)
	.db 07Ch	; | ■■■■■  | (adr. 7696h)
	.db 028h	; |  ■ ■   | (adr. 7697h)
	.db 008h	; |    ■   | (adr. 7698h)
	.db 05Ch	; | ■ ■■■  | (adr. 7699h)
	.db 054h	; | ■ ■ ■  | (adr. 769Ah)
	.db 07Ch	; | ■■■■■  | (adr. 769Bh)
	.db 038h	; |  ■■■   | (adr. 769Ch)
	.db 038h	; |  ■■■   | (adr. 769Dh)
	.db 07Ch	; | ■■■■■  | (adr. 769Eh)
	.db 044h	; | ■   ■  | (adr. 769Fh)
	.db 07Ch	; | ■■■■■  | (adr. 76A0h)
	.db 038h	; |  ■■■   | (adr. 76A1h)
	.db 018h	; |   ■■   | (adr. 76A2h)
	.db 03Ch	; |  ■■■■  | (adr. 76A3h)
	.db 024h	; |  ■  ■  | (adr. 76A4h)
	.db 03Ch	; |  ■■■■  | (adr. 76A5h)
	.db 018h	; |   ■■   | (adr. 76A6h)
	.db 007h	; |     ■■■| (adr. 76A7h)
	.db 08Fh	; |■   ■■■■| (adr. 76A8h)
	.db 088h	; |■   ■   | (adr. 76A9h)
	.db 08Fh	; |■   ■■■■| (adr. 76AAh)
	.db 007h	; |     ■■■| (adr. 76ABh)
	.db 000h	; |        | (adr. 76ACh)
	.db 002h	; |      ■ | (adr. 76ADh)
	.db 00Fh	; |    ■■■■| (adr. 76AEh)
	.db 08Fh	; |■   ■■■■| (adr. 76AFh)
	.db 000h	; |        | (adr. 76B0h)
	.db 009h	; |    ■  ■| (adr. 76B1h)
	.db 08Dh	; |■   ■■ ■| (adr. 76B2h)
	.db 08Eh	; |■   ■■■ | (adr. 76B3h)
	.db 08Bh	; |■   ■ ■■| (adr. 76B4h)
	.db 009h	; |    ■  ■| (adr. 76B5h)
	.db 005h	; |     ■ ■| (adr. 76B6h)
	.db 08Dh	; |■   ■■ ■| (adr. 76B7h)
	.db 08Ah	; |■   ■ ■ | (adr. 76B8h)
	.db 08Fh	; |■   ■■■■| (adr. 76B9h)
	.db 005h	; |     ■ ■| (adr. 76BAh)
	.db 083h	; |■     ■■| (adr. 76BBh)
	.db 083h	; |■     ■■| (adr. 76BCh)
	.db 002h	; |      ■ | (adr. 76BDh)
	.db 08Fh	; |■   ■■■■| (adr. 76BEh)
	.db 08Fh	; |■   ■■■■| (adr. 76BFh)
F_76C0:	.db 07Ch	; | ■■■■■  | (adr. 76C0h)
	.db 010h	; |   ■    | (adr. 76C1h)
	.db 038h	; |  ■■■   | (adr. 76C2h)
	.db 044h	; | ■   ■  | (adr. 76C3h)
	.db 038h	; |  ■■■   | (adr. 76C4h)
	.db 032h	; |  ■■  ■ | (adr. 76C5h)
	.db 04Ah	; | ■  ■ ■ | (adr. 76C6h)
	.db 04Ah	; | ■  ■ ■ | (adr. 76C7h)
	.db 03Ch	; |  ■■■■  | (adr. 76C8h)
	.db 040h	; | ■      | (adr. 76C9h)
	.db 038h	; |  ■■■   | (adr. 76CAh)
	.db 054h	; | ■ ■ ■  | (adr. 76CBh)
	.db 054h	; | ■ ■ ■  | (adr. 76CCh)
	.db 054h	; | ■ ■ ■  | (adr. 76CDh)
	.db 022h	; |  ■   ■ | (adr. 76CEh)
	.db 03Ch	; |  ■■■■  | (adr. 76CFh)
	.db 020h	; |  ■     | (adr. 76D0h)
	.db 020h	; |  ■     | (adr. 76D1h)
	.db 03Ch	; |  ■■■■  | (adr. 76D2h)
	.db 060h	; | ■■     | (adr. 76D3h)
	.db 060h	; | ■■     | (adr. 76D4h)
	.db 038h	; |  ■■■   | (adr. 76D5h)
	.db 024h	; |  ■  ■  | (adr. 76D6h)
	.db 03Ch	; |  ■■■■  | (adr. 76D7h)
	.db 060h	; | ■■     | (adr. 76D8h)
	.db 038h	; |  ■■■   | (adr. 76D9h)
	.db 054h	; | ■ ■ ■  | (adr. 76DAh)
	.db 054h	; | ■ ■ ■  | (adr. 76DBh)
	.db 054h	; | ■ ■ ■  | (adr. 76DCh)
	.db 018h	; |   ■■   | (adr. 76DDh)
	.db 018h	; |   ■■   | (adr. 76DEh)
	.db 024h	; |  ■  ■  | (adr. 76DFh)
	.db 07Eh	; | ■■■■■■ | (adr. 76E0h)
	.db 024h	; |  ■  ■  | (adr. 76E1h)
	.db 018h	; |   ■■   | (adr. 76E2h)
	.db 07Ch	; | ■■■■■  | (adr. 76E3h)
	.db 004h	; |     ■  | (adr. 76E4h)
	.db 004h	; |     ■  | (adr. 76E5h)
	.db 004h	; |     ■  | (adr. 76E6h)
	.db 004h	; |     ■  | (adr. 76E7h)
	.db 044h	; | ■   ■  | (adr. 76E8h)
	.db 028h	; |  ■ ■   | (adr. 76E9h)
	.db 010h	; |   ■    | (adr. 76EAh)
	.db 028h	; |  ■ ■   | (adr. 76EBh)
	.db 044h	; | ■   ■  | (adr. 76ECh)
	.db 03Ch	; |  ■■■■  | (adr. 76EDh)
	.db 040h	; | ■      | (adr. 76EEh)
	.db 040h	; | ■      | (adr. 76EFh)
	.db 020h	; |  ■     | (adr. 76F0h)
	.db 07Ch	; | ■■■■■  | (adr. 76F1h)
	.db 03Ch	; |  ■■■■  | (adr. 76F2h)
	.db 040h	; | ■      | (adr. 76F3h)
	.db 042h	; | ■    ■ | (adr. 76F4h)
	.db 020h	; |  ■     | (adr. 76F5h)
	.db 07Ch	; | ■■■■■  | (adr. 76F6h)
	.db 07Ch	; | ■■■■■  | (adr. 76F7h)
	.db 010h	; |   ■    | (adr. 76F8h)
	.db 010h	; |   ■    | (adr. 76F9h)
	.db 028h	; |  ■ ■   | (adr. 76FAh)
	.db 044h	; | ■   ■  | (adr. 76FBh)
	.db 040h	; | ■      | (adr. 76FCh)
	.db 038h	; |  ■■■   | (adr. 76FDh)
	.db 004h	; |     ■  | (adr. 76FEh)
	.db 004h	; |     ■  | (adr. 76FFh)
	.db 07Ch	; | ■■■■■  | (adr. 7700h)
	.db 07Ch	; | ■■■■■  | (adr. 7701h)
	.db 008h	; |    ■   | (adr. 7702h)
	.db 010h	; |   ■    | (adr. 7703h)
	.db 008h	; |    ■   | (adr. 7704h)
	.db 07Ch	; | ■■■■■  | (adr. 7705h)
	.db 07Ch	; | ■■■■■  | (adr. 7706h)
	.db 010h	; |   ■    | (adr. 7707h)
	.db 010h	; |   ■    | (adr. 7708h)
	.db 010h	; |   ■    | (adr. 7709h)
	.db 07Ch	; | ■■■■■  | (adr. 770Ah)
	.db 038h	; |  ■■■   | (adr. 770Bh)
	.db 044h	; | ■   ■  | (adr. 770Ch)
	.db 044h	; | ■   ■  | (adr. 770Dh)
	.db 044h	; | ■   ■  | (adr. 770Eh)
	.db 038h	; |  ■■■   | (adr. 770Fh)
	.db 07Ch	; | ■■■■■  | (adr. 7710h)
	.db 004h	; |     ■  | (adr. 7711h)
	.db 004h	; |     ■  | (adr. 7712h)
	.db 004h	; |     ■  | (adr. 7713h)
	.db 07Ch	; | ■■■■■  | (adr. 7714h)
	.db 048h	; | ■  ■   | (adr. 7715h)
	.db 034h	; |  ■■ ■  | (adr. 7716h)
	.db 014h	; |   ■ ■  | (adr. 7717h)
	.db 014h	; |   ■ ■  | (adr. 7718h)
	.db 07Ch	; | ■■■■■  | (adr. 7719h)
	.db 07Eh	; | ■■■■■■ | (adr. 771Ah)
	.db 012h	; |   ■  ■ | (adr. 771Bh)
	.db 012h	; |   ■  ■ | (adr. 771Ch)
	.db 012h	; |   ■  ■ | (adr. 771Dh)
	.db 00Ch	; |    ■■  | (adr. 771Eh)
	.db 038h	; |  ■■■   | (adr. 771Fh)
	.db 044h	; | ■   ■  | (adr. 7720h)
	.db 044h	; | ■   ■  | (adr. 7721h)
	.db 044h	; | ■   ■  | (adr. 7722h)
	.db 044h	; | ■   ■  | (adr. 7723h)
	.db 004h	; |     ■  | (adr. 7724h)
	.db 004h	; |     ■  | (adr. 7725h)
	.db 07Ch	; | ■■■■■  | (adr. 7726h)
	.db 004h	; |     ■  | (adr. 7727h)
	.db 004h	; |     ■  | (adr. 7728h)
	.db 000h	; |        | (adr. 7729h)
	.db 04Ch	; | ■  ■■  | (adr. 772Ah)
	.db 030h	; |  ■■    | (adr. 772Bh)
	.db 010h	; |   ■    | (adr. 772Ch)
	.db 00Ch	; |    ■■  | (adr. 772Dh)
	.db 044h	; | ■   ■  | (adr. 772Eh)
	.db 028h	; |  ■ ■   | (adr. 772Fh)
	.db 07Ch	; | ■■■■■  | (adr. 7730h)
	.db 028h	; |  ■ ■   | (adr. 7731h)
	.db 044h	; | ■   ■  | (adr. 7732h)
	.db 07Eh	; | ■■■■■■ | (adr. 7733h)
	.db 04Ah	; | ■  ■ ■ | (adr. 7734h)
	.db 04Ah	; | ■  ■ ■ | (adr. 7735h)
	.db 04Ch	; | ■  ■■  | (adr. 7736h)
	.db 030h	; |  ■■    | (adr. 7737h)
	.db 000h	; |        | (adr. 7738h)
	.db 07Ch	; | ■■■■■  | (adr. 7739h)
	.db 048h	; | ■  ■   | (adr. 773Ah)
	.db 048h	; | ■  ■   | (adr. 773Bh)
	.db 030h	; |  ■■    | (adr. 773Ch)
	.db 07Ch	; | ■■■■■  | (adr. 773Dh)
	.db 048h	; | ■  ■   | (adr. 773Eh)
	.db 030h	; |  ■■    | (adr. 773Fh)
	.db 000h	; |        | (adr. 7740h)
	.db 07Ch	; | ■■■■■  | (adr. 7741h)
	.db 028h	; |  ■ ■   | (adr. 7742h)
	.db 044h	; | ■   ■  | (adr. 7743h)
	.db 054h	; | ■ ■ ■  | (adr. 7744h)
	.db 054h	; | ■ ■ ■  | (adr. 7745h)
	.db 028h	; |  ■ ■   | (adr. 7746h)
	.db 07Ch	; | ■■■■■  | (adr. 7747h)
	.db 040h	; | ■      | (adr. 7748h)
	.db 07Ch	; | ■■■■■  | (adr. 7749h)
	.db 040h	; | ■      | (adr. 774Ah)
	.db 07Ch	; | ■■■■■  | (adr. 774Bh)
	.db 044h	; | ■   ■  | (adr. 774Ch)
	.db 054h	; | ■ ■ ■  | (adr. 774Dh)
	.db 054h	; | ■ ■ ■  | (adr. 774Eh)
	.db 054h	; | ■ ■ ■  | (adr. 774Fh)
	.db 038h	; |  ■■■   | (adr. 7750h)
	.db 03Ch	; |  ■■■■  | (adr. 7751h)
	.db 020h	; |  ■     | (adr. 7752h)
	.db 03Ch	; |  ■■■■  | (adr. 7753h)
	.db 020h	; |  ■     | (adr. 7754h)
	.db 07Ch	; | ■■■■■  | (adr. 7755h)
	.db 01Ch	; |   ■■■  | (adr. 7756h)
	.db 010h	; |   ■    | (adr. 7757h)
	.db 010h	; |   ■    | (adr. 7758h)
	.db 010h	; |   ■    | (adr. 7759h)
	.db 07Ch	; | ■■■■■  | (adr. 775Ah)
	.db 004h	; |     ■  | (adr. 775Bh)
	.db 07Ch	; | ■■■■■  | (adr. 775Ch)
	.db 048h	; | ■  ■   | (adr. 775Dh)
	.db 048h	; | ■  ■   | (adr. 775Eh)
	.db 030h	; |  ■■    | (adr. 775Fh)
F_7760:	.db 07Fh	; | ■■■■■■■| (adr. 7760h)
	.db 008h	; |    ■   | (adr. 7761h)
	.db 03Eh	; |  ■■■■■ | (adr. 7762h)
	.db 041h	; | ■     ■| (adr. 7763h)
	.db 03Eh	; |  ■■■■■ | (adr. 7764h)
	.db 07Ch	; | ■■■■■  | (adr. 7765h)
	.db 012h	; |   ■  ■ | (adr. 7766h)
	.db 011h	; |   ■   ■| (adr. 7767h)
	.db 012h	; |   ■  ■ | (adr. 7768h)
	.db 07Ch	; | ■■■■■  | (adr. 7769h)
	.db 07Fh	; | ■■■■■■■| (adr. 776Ah)
	.db 049h	; | ■  ■  ■| (adr. 776Bh)
	.db 049h	; | ■  ■  ■| (adr. 776Ch)
	.db 049h	; | ■  ■  ■| (adr. 776Dh)
	.db 031h	; |  ■■   ■| (adr. 776Eh)
	.db 03Fh	; |  ■■■■■■| (adr. 776Fh)
	.db 020h	; |  ■     | (adr. 7770h)
	.db 020h	; |  ■     | (adr. 7771h)
	.db 020h	; |  ■     | (adr. 7772h)
	.db 07Fh	; | ■■■■■■■| (adr. 7773h)
	.db 060h	; | ■■     | (adr. 7774h)
	.db 03Eh	; |  ■■■■■ | (adr. 7775h)
	.db 021h	; |  ■    ■| (adr. 7776h)
	.db 03Fh	; |  ■■■■■■| (adr. 7777h)
	.db 060h	; | ■■     | (adr. 7778h)
	.db 07Fh	; | ■■■■■■■| (adr. 7779h)
	.db 049h	; | ■  ■  ■| (adr. 777Ah)
	.db 049h	; | ■  ■  ■| (adr. 777Bh)
	.db 049h	; | ■  ■  ■| (adr. 777Ch)
	.db 041h	; | ■     ■| (adr. 777Dh)
	.db 01Ch	; |   ■■■  | (adr. 777Eh)
	.db 022h	; |  ■   ■ | (adr. 777Fh)
	.db 07Fh	; | ■■■■■■■| (adr. 7780h)
	.db 022h	; |  ■   ■ | (adr. 7781h)
	.db 01Ch	; |   ■■■  | (adr. 7782h)
	.db 07Fh	; | ■■■■■■■| (adr. 7783h)
	.db 001h	; |       ■| (adr. 7784h)
	.db 001h	; |       ■| (adr. 7785h)
	.db 001h	; |       ■| (adr. 7786h)
	.db 003h	; |      ■■| (adr. 7787h)
	.db 063h	; | ■■   ■■| (adr. 7788h)
	.db 014h	; |   ■ ■  | (adr. 7789h)
	.db 008h	; |    ■   | (adr. 778Ah)
	.db 014h	; |   ■ ■  | (adr. 778Bh)
	.db 063h	; | ■■   ■■| (adr. 778Ch)
	.db 07Fh	; | ■■■■■■■| (adr. 778Dh)
	.db 010h	; |   ■    | (adr. 778Eh)
	.db 008h	; |    ■   | (adr. 778Fh)
	.db 004h	; |     ■  | (adr. 7790h)
	.db 07Fh	; | ■■■■■■■| (adr. 7791h)
	.db 07Fh	; | ■■■■■■■| (adr. 7792h)
	.db 020h	; |  ■     | (adr. 7793h)
	.db 013h	; |   ■  ■■| (adr. 7794h)
	.db 008h	; |    ■   | (adr. 7795h)
	.db 07Fh	; | ■■■■■■■| (adr. 7796h)
	.db 07Fh	; | ■■■■■■■| (adr. 7797h)
	.db 008h	; |    ■   | (adr. 7798h)
	.db 014h	; |   ■ ■  | (adr. 7799h)
	.db 022h	; |  ■   ■ | (adr. 779Ah)
	.db 041h	; | ■     ■| (adr. 779Bh)
	.db 040h	; | ■      | (adr. 779Ch)
	.db 07Ch	; | ■■■■■  | (adr. 779Dh)
	.db 002h	; |      ■ | (adr. 779Eh)
	.db 001h	; |       ■| (adr. 779Fh)
	.db 07Fh	; | ■■■■■■■| (adr. 77A0h)
	.db 07Fh	; | ■■■■■■■| (adr. 77A1h)
	.db 002h	; |      ■ | (adr. 77A2h)
	.db 00Ch	; |    ■■  | (adr. 77A3h)
	.db 002h	; |      ■ | (adr. 77A4h)
	.db 07Fh	; | ■■■■■■■| (adr. 77A5h)
	.db 07Fh	; | ■■■■■■■| (adr. 77A6h)
	.db 008h	; |    ■   | (adr. 77A7h)
	.db 008h	; |    ■   | (adr. 77A8h)
	.db 008h	; |    ■   | (adr. 77A9h)
	.db 07Fh	; | ■■■■■■■| (adr. 77AAh)
	.db 03Eh	; |  ■■■■■ | (adr. 77ABh)
	.db 041h	; | ■     ■| (adr. 77ACh)
	.db 041h	; | ■     ■| (adr. 77ADh)
	.db 041h	; | ■     ■| (adr. 77AEh)
	.db 03Eh	; |  ■■■■■ | (adr. 77AFh)
	.db 07Fh	; | ■■■■■■■| (adr. 77B0h)
	.db 001h	; |       ■| (adr. 77B1h)
	.db 001h	; |       ■| (adr. 77B2h)
	.db 001h	; |       ■| (adr. 77B3h)
	.db 07Fh	; | ■■■■■■■| (adr. 77B4h)
	.db 046h	; | ■   ■■ | (adr. 77B5h)
	.db 029h	; |  ■ ■  ■| (adr. 77B6h)
	.db 019h	; |   ■■  ■| (adr. 77B7h)
	.db 009h	; |    ■  ■| (adr. 77B8h)
	.db 07Fh	; | ■■■■■■■| (adr. 77B9h)
	.db 07Fh	; | ■■■■■■■| (adr. 77BAh)
	.db 009h	; |    ■  ■| (adr. 77BBh)
	.db 009h	; |    ■  ■| (adr. 77BCh)
	.db 009h	; |    ■  ■| (adr. 77BDh)
	.db 006h	; |     ■■ | (adr. 77BEh)
	.db 03Eh	; |  ■■■■■ | (adr. 77BFh)
	.db 041h	; | ■     ■| (adr. 77C0h)
	.db 041h	; | ■     ■| (adr. 77C1h)
	.db 041h	; | ■     ■| (adr. 77C2h)
	.db 022h	; |  ■   ■ | (adr. 77C3h)
	.db 001h	; |       ■| (adr. 77C4h)
	.db 001h	; |       ■| (adr. 77C5h)
	.db 07Fh	; | ■■■■■■■| (adr. 77C6h)
	.db 001h	; |       ■| (adr. 77C7h)
	.db 001h	; |       ■| (adr. 77C8h)
	.db 007h	; |     ■■■| (adr. 77C9h)
	.db 048h	; | ■  ■   | (adr. 77CAh)
	.db 048h	; | ■  ■   | (adr. 77CBh)
	.db 048h	; | ■  ■   | (adr. 77CCh)
	.db 03Fh	; |  ■■■■■■| (adr. 77CDh)
	.db 063h	; | ■■   ■■| (adr. 77CEh)
	.db 014h	; |   ■ ■  | (adr. 77CFh)
	.db 07Fh	; | ■■■■■■■| (adr. 77D0h)
	.db 014h	; |   ■ ■  | (adr. 77D1h)
	.db 063h	; | ■■   ■■| (adr. 77D2h)
	.db 07Fh	; | ■■■■■■■| (adr. 77D3h)
	.db 049h	; | ■  ■  ■| (adr. 77D4h)
	.db 049h	; | ■  ■  ■| (adr. 77D5h)
	.db 049h	; | ■  ■  ■| (adr. 77D6h)
	.db 036h	; |  ■■ ■■ | (adr. 77D7h)
	.db 07Fh	; | ■■■■■■■| (adr. 77D8h)
	.db 048h	; | ■  ■   | (adr. 77D9h)
	.db 048h	; | ■  ■   | (adr. 77DAh)
	.db 048h	; | ■  ■   | (adr. 77DBh)
	.db 030h	; |  ■■    | (adr. 77DCh)
	.db 07Fh	; | ■■■■■■■| (adr. 77DDh)
	.db 048h	; | ■  ■   | (adr. 77DEh)
	.db 030h	; |  ■■    | (adr. 77DFh)
	.db 000h	; |        | (adr. 77E0h)
	.db 07Fh	; | ■■■■■■■| (adr. 77E1h)
	.db 022h	; |  ■   ■ | (adr. 77E2h)
	.db 041h	; | ■     ■| (adr. 77E3h)
	.db 041h	; | ■     ■| (adr. 77E4h)
	.db 049h	; | ■  ■  ■| (adr. 77E5h)
	.db 036h	; |  ■■ ■■ | (adr. 77E6h)
	.db 07Fh	; | ■■■■■■■| (adr. 77E7h)
	.db 040h	; | ■      | (adr. 77E8h)
	.db 07Fh	; | ■■■■■■■| (adr. 77E9h)
	.db 040h	; | ■      | (adr. 77EAh)
	.db 07Fh	; | ■■■■■■■| (adr. 77EBh)
	.db 022h	; |  ■   ■ | (adr. 77ECh)
	.db 049h	; | ■  ■  ■| (adr. 77EDh)
	.db 049h	; | ■  ■  ■| (adr. 77EEh)
	.db 049h	; | ■  ■  ■| (adr. 77EFh)
	.db 03Eh	; |  ■■■■■ | (adr. 77F0h)
	.db 03Fh	; |  ■■■■■■| (adr. 77F1h)
	.db 020h	; |  ■     | (adr. 77F2h)
	.db 03Fh	; |  ■■■■■■| (adr. 77F3h)
	.db 020h	; |  ■     | (adr. 77F4h)
	.db 07Fh	; | ■■■■■■■| (adr. 77F5h)
	.db 00Fh	; |    ■■■■| (adr. 77F6h)
	.db 008h	; |    ■   | (adr. 77F7h)
	.db 008h	; |    ■   | (adr. 77F8h)
	.db 008h	; |    ■   | (adr. 77F9h)
	.db 07Fh	; | ■■■■■■■| (adr. 77FAh)
	.db 07Eh	; | ■■■■■■ | (adr. 77FBh)
	.db 07Eh	; | ■■■■■■ | (adr. 77FCh)
	.db 07Eh	; | ■■■■■■ | (adr. 77FDh)
	.db 07Eh	; | ■■■■■■ | (adr. 77FEh)
	.db 07Eh	; | ■■■■■■ | (adr. 77FFh)
;
	.ORG	07600h
L_7800:	JMP	L_6000	; ? @INIT рестарт
L_7803:	JMP	L_7EFF	; ? @KEY	-- ввод символа с клавиатуры,	выход: А = код
L_7806:	JMP	L_7840	; ? @INTAP	-- ввод байта с магнитной ленты, A=FF - с поиском синхробайта, =08 - без поиска, выход А = полученный байт
L_7809:	JMP	L_793F	; ? @CONOUT	-- вывод на экран символа из C
L_780C:	JMP	L_789B	; ? @OUTAP	-- вывод на МГ байта из C
L_780F:	JMP	L_7F29	; ? @LIST	-- вывод на принтер символа (с перекодировкой) из C
L_7812:	JMP	L_7EF7	; ? @CONIN	-- опрос статуса клавиатуры,	выход A=FF - клавиша нажата, =00 - не нажата
L_7815:	JMP	L_792A	; ? @DUMP	-- вывод числа в HEX из A
L_7818:	JMP	L_7832	; ? @SPIC	-- вывод строки до 00h с адреса из HL (из ОЗУ Банк0 и Банк1)
L_781B:	JMP	L_6E20	; ? @INKEY	-- чтение с клавиатуры,		выход A=FF - клавиша не нажата, =XX - код клавиши
;
L_781E:	PUSH PSW
L_781F:	IN	005h
	ANI	001h
	JNZ	L_781F
	MOV  A, C
	OUT	007h
	MVI  A, 0EFh
	OUT	005h
	MVI  A, 0FFh
	OUT	005h
	POP  PSW
	RET
;
L_7832:	CALL	RBYTE	; ? @SPIC << HL (ссылка на текст) -- вывод строки до 00h из ОЗУ Банк0 и Банк1
	ANA  A
	RZ
	PUSH B
	MOV  C, A
	CALL	L_793F	; вывод на экран символа C
	POP  B
	INX  H
	JMP	L_7832
;
L_7833:	MOV  A, M	; ? @SPIC << HL (ссылка на текст) -- вывод строки до 00h (монитор)
	ANA  A
	RZ
	PUSH B
	MOV  C, A
	CALL	L_793F	; вывод на экран символа C
	POP  B
	INX  H
	JMP	L_7833
;
L_7840:	PUSH B		; ? @INTAP ввод байта с магнитной ленты
	PUSH D
	MVI  C, 000h
	MOV  D, A
	IN	001h
	ANI	010h
	MOV  E, A
L_784A:	IN	001h
	ANI	010h
	CMP  E
	JZ	L_784A
	RLC
	RLC
	RLC
	RLC
	MOV  A, C
	RAL
	MOV  C, A
	CALL	L_788A
	IN	001h
	ANI	010h
	MOV  E, A
	MOV  A, D
	ORA  A
	JP	L_787F	; >> если A < 80h
	MOV  A, C
	CPI	0E6h
	JNZ	L_7873
	XRA  A
	STA     D_7FFB
	JMP	L_787D
;
L_7873:	CPI	019h
	JNZ	L_784A
	MVI  A, 0FFh
	STA     D_7FFB
L_787D:	MVI  D, 009h
L_787F:	DCR  D
	JNZ	L_784A
	LDA     D_7FFB
	XRA  C
	POP  D
	POP  B
	RET
;
L_788A:	PUSH PSW
	LDA     D_7FF5
L_788E:	DCR  A
	JNZ	L_788E
	IN	001h
	ANI	040h
	JZ	L_7800	; рестарт
	POP  PSW
	RET
;
L_789B:	PUSH B		; ? @OUTAP << A (число) -- вывод на МГ
	PUSH D
	PUSH PSW
	MOV  D, A
	MVI  A, 002h
	STA     D_7FFC
	MVI  C, 008h
L_78A6:	MOV  A, D
	RLC
	MOV  D, A
	MVI  A, 001h
	XRA  D
	ANI	001h
	OUT	000h
	CALL	L_78C5
	MVI  A, 000h
	XRA  D
	ANI	001h
	OUT	000h
	CALL	L_78C5
	DCR  C
	JNZ	L_78A6
	POP  PSW
	POP  D
	POP  B
	RET
;
L_78C5:	PUSH PSW
	LDA     D_7FF4
	JMP	L_788E
;
L_790C:	PUSH H
	PUSH D
	PUSH B
	LXI  H, 00000h
	DAD  SP	
	SHLD	Lx792Z+1
	LXI SP,	KSTEK
	PUSH PSW
	CALL	L_7AD2
	DCR  E
	MVI  H, 007h
	MVI  A, B_EKR	; ОЗУ: Банк 2, Банк 3
	OUT     00Eh	; режим ОЗУ
	POP  PSW
L_7917:	PUSH H
	ANA  A
	CZ	L_7B53
	CNZ	L_7B34
	POP  H
	INX  B
Lx7921:	RLC		; <- INX B / RLC
	DCR  H
	JNZ	L_7917
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
Lx792Z:	LXI SP,	0
	POP  B
	POP  D
	POP  H
	RET
;
L_792A:	MOV  B, A	; ? @DUMP << A (число) -- вывод числа в HEX
	RRC
	RRC
	RRC
	RRC
	CALL	L_7933
	MOV  A, B
L_7933:	ANI	00Fh
	CPI	00Ah
	JM	L_793C
	ADI	007h
L_793C:	ADI	030h
	MOV  C, A
L_793F:	DI		; ? @CONOUT << C (символ) -- вывод на экран символа
	PUSH PSW
	PUSH B
	PUSH D
	PUSH H
	MVI  A, B_PRG0	; ОЗУ: Банк 2, Банк 0
	OUT     00Eh	; режим ОЗУ
	MVI  A, 0C3h	; JMP ...
	STA     M_0000+8000h	;
	STA     M_0005+8000h	;
	STA     M_0038+8000h	;
VxMB1:	LXI  H, MBIOSV	;L_7800	; рестарт
	SHLD	M_0001+8000h	; ... MBIOSV
VxC52:	LXI  H, CALL5V	;L_5400
	SHLD	M_0006+8000h	; ... CALL5V
VxR71:	LXI  H, RST7V	;L_7D76
	SHLD	M_0039+8000h	; ... RST7V
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	MVI  A, 002h
	OUT     00Dh	; Номер банка Экрана
	EI
	IN	001h
	ANI	040h	; кл. "УС"
	JNZ	L_7980	; >> не нажата
	CALL	L_7812	; опрос статуса клавиатуры
	ORA  A
	JZ	L_7980	; >> клавиши не нажаты
	CALL	L_6E20	; чтение с клавиатуры
	CPI	013h	; УС+S
	JNZ	L_7980
L_7978:	CALL	L_7EFF	; ? @KEY
	CPI	011h	; УС+Q
	JNZ	L_7978	; пауза
L_7980:	LXI  H, D_7FE1	; <<
	MOV  A, M
	CPI	080h
	JZ	L_7CA8	; 80->
	CPI	040h
	JZ	L_7D23	; 40->
	CPI	020h
	JZ	L_7A8C	; 20->
	ORA  A
	JNZ	L_79BE	; !00->
	MOV  A, C
	CPI	01Bh	; управляющий символ
	JNZ	L_79A1	; нет >>
L_799D:	INR  M
	JMP	L_7C14
;
L_79A1:	CPI	001h
	JNZ	L_79AE
	MVI  A, 080h
	STA     D_7FE1
	JMP	L_7C14
;
L_79AE:	CPI	00Ch
	JZ	L_7BC8	; >> стирание экрана
	CPI	01Fh
	JZ	L_7BC8	; >> стирание экрана
	JM	L_7BFD	; >> если A=[0..1Eh; 9Fh..FFh] (S=1)
	JMP	L_7A8C
;
L_79BE:	CPI	001h	; <- !00
	JNZ	L_7A44
	MOV  A, C
	CPI	059h	; прямая адресация курсора
	JZ	L_799D
	LXI  H, L_7CC2
	PUSH H
	CPI	041h
	MVI  C, 019h
	RZ
	CPI	042h
	MVI  C, 01Ah
	RZ
	CPI	043h
	MVI  C, 018h
	RZ
	CPI	044h
	MVI  C, 008h
	RZ
	CPI	04Ah
	MVI  C, 00Ch
	RZ
	CPI	048h
	MVI  C, 00Bh
	RZ
	POP  H
	CPI	045h
	MVI  C, 00Ch
	JZ	L_7CAF
	CPI	05Dh
	JZ	L_7CC9
	CPI	05Eh
	JZ	L_7CF3
	CPI	05Ch
	JZ	L_7A2E
	CPI	02Fh
	JZ	L_7A36
	CPI	05Bh
	JZ	L_7A36
	CPI	050h
	JZ	L_7D1B
	CPI	061h
	JZ	L_7D41
	CPI	062h
	JZ	L_7D48
	JMP	L_7A84
;
L_7A1E:	MVI  A, 008h
	LXI  H, D_78DC
	JMP	L_7A3B
;
L_7A26:	MVI  A, 000h
;	LXI  H, D_78CC
	JMP	L_7A38	;L_7A3B
;
L_7A2E:	MVI  A, 010h
	LXI  H, D_78EC
	JMP	L_7A3B
;
L_7A36:	MVI  A, 018h
L_7A38:	LXI  H, D_78CC	; D_78FC
L_7A3B:	SHLD	L_7A8C+1
	STA     D_6EA0
	JMP	L_7A84
;
L_7A44:	CPI	003h
	JZ	L_7A6D
	MOV  A, C
	SUI	020h
	JP	L_7A52
	JMP	L_7A57
;
L_7A52:	CPI	019h
	JM	L_7A59
L_7A57:	MVI  A, 018h
L_7A59:	RLC
	MOV  C, A
	RLC
	RLC
	ADD  C
	CMA
	INR  A
	SUI	00Ah
	MOV  C, A
	LDA     D_7FDE
	ADD  C
	STA     D_7FDF
	JMP	L_799D
;
L_7A6D:	MOV  A, C
	SUI	020h
	JP	Lx7A76
	JMP	L_7A7F
;
Lx7A76:	NOP		; <- RLC / NOP
	CPI	050h
	JP	L_7A7F
	JMP	L_7A81
;
L_7A7F:	MVI  A, 04Fh
L_7A81:	STA     D_7FE0
L_7A84:	LXI  H, D_7FE1
	MVI  M, 000h
	JMP	L_7C14
;
L_7A8C:	LXI  H, D_78EC	; D_78CC / D_78DC / D_78EC
	MOV  A, C
	MVI  D, 008h
L_7A92:	SUI	020h
	JNC	L_7A9C	; >=20h
	ADI	020h
	JMP	L_7AA2
;
L_7A9C:	INX  H
	INX  H
	DCR  D
	JNZ	L_7A92
L_7AA2:	MOV  C, M
	INX  H
	MOV  B, M
	MVI  H, 000h
	MOV  L, A
	MOV  D, H
	MOV  E, L
	DAD  H
	DAD  H
	DAD  D
	DAD  B
	PUSH H
	CALL	L_7AD2
	LDA     L_7AC9
	RRC
	MVI  A, 0FFh
	JC	L_7ABC
	XRA  A
L_7ABC:	CALL	L_7AEB
	MVI  D, 006h
L_7AC1:	INX  B
Lx7AC2:	NOP		; <- INX B / NOP
	DCR  D
	JZ	L_7B74
	POP  H
	MOV  A, M
L_7AC9:	NOP		; <- NOP / CMA
	INX  H
	PUSH H
	CALL	L_7AEB
	JMP	L_7AC1
;
L_7AD2:	LDA     D_7FE0	; номер позиции в строке
	MOV  L, A
	MVI  H, 000h
	DAD  H
	PUSH H
	POP  B
	DAD  H
	DAD  B		; HL * 6
	LXI  B, 00010h	; ?
	DAD  B		; +10h
	MOV  A, H
	ANI	001h
	MOV  B, A
	MOV  C, L	; BC = 000xxxxxh & HL
	LDA     D_7FDF
	MOV  E, A
	RET
;
L_7AEB:	PUSH PSW
	CALL	L_7AFF
	LDA     Lx7AC2
	ANA  A
	JNZ	L_7AF8
	POP  PSW
	RET
;
L_7AF8:	INX  B
	POP  PSW
	CALL	L_7AFF
	DCX  B
	RET
;
L_7AFF:	PUSH D
	PUSH B
	LXI  H, D_6F00
	DAD  B
	MOV  D, M
	INR  H
	INR  H
	RLC
	MOV  C, A
	MOV  A, M
	XCHG
	MOV  D, A
	CMA
	MOV  E, A
	DI
	MVI  A, B_EKR	; ОЗУ: Банк 2, Банк 3
	OUT     00Eh	; режим ОЗУ
	LDA     L_7AC9
	RRC
	MVI  B, 009h
	JMP	L_7B1B
;
L_7B18:	MOV  A, C
	RLC
	MOV  C, A
L_7B1B:	JC	L_7B29
	MOV  A, E
	ANA  M
	MOV  M, A
	INR  L
	DCR  B
	JNZ	L_7B18
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	EI
	POP  B
	POP  D
	RET
;
L_7B29:	MOV  A, D
	ORA  M
	MOV  M, A
	INR  L
	DCR  B
	JNZ	L_7B18
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	EI
	POP  B
	POP  D
	RET
;
L_7B34:	PUSH PSW
	LXI  H, D_6F00
	DAD  B
	MOV  D, M
	INR  H
	INR  H
	MOV  A, M
	XCHG
	ORA  M
	MOV  M, A
	XCHG
	POP  PSW
Lx7B42:	RET		; <- INX B / RET
;
	PUSH PSW
	LXI  H, D_6F00
	DAD  B
	MOV  D, M
	INR  H
	INR  H
	MOV  A, M
	XCHG
	ORA  M
	MOV  M, A	; курсор ?
	XCHG
	POP  PSW
	DCX  B
	RET
;
L_7B53:	PUSH PSW
	LXI  H, D_6F00
	DAD  B
	MOV  D, M
	INR  H
	INR  H
	MOV  A, M
	XCHG
	CMA
	ANA  M
	MOV  M, A	; курсор ?
	XCHG
	POP  PSW
Lx7B62:	RET		; <- INX B / RET
;
	PUSH PSW
	LXI  H,	D_6F00
	DAD  B
	MOV  D, M
	INR  H
	INR  H
	MOV  A, M
	XCHG
	CMA
	ANA  M
	MOV  M, A
	XCHG
	POP  PSW
	DCX  B
	RET
;
L_7B74:	POP  H		; << сдвиг экрана вверх при заполнении
	LXI  H, D_7FE0
	INR  M
Lx7B79:	NOP		; <- INR M / NOP
	MOV  A, M
	CPI	050h
	JM	L_7C14
L_7B80:	MVI  M, 000h
	LDA     D_7FDF
	SUI	00Ah
	STA     D_7FDF
	MOV  C, A
	ADI	004h
	MOV  B, A
	LDA     D_7FDE
	CMP  B
	JNZ	L_7C14
	SUI	00Ah
	STA     D_7FDE
	MOV  A, C
	SUI	005h
	MOV  C, A
	MVI  H, 0A0h	; начало экрана
	DI
	MVI  A, B_EKR	; ОЗУ: Банк 2, Банк 3
	OUT     00Eh	; режим ОЗУ
	MVI  A, 0E0h	; конец экрана
	MVI  D, 000h	; очистка строки
L_7BA4:	MOV  L, C
	MOV  M, D
	INR  L
	MOV  M, D
	INR  L
	MOV  M, D
	INR  L
	MOV  M, D
	INR  L
	MOV  M, D
	INR  L
	MOV  M, D
	INR  L
	MOV  M, D
	INR  L
	MOV  M, D
	INR  L
	MOV  M, D
	INR  L
	MOV  M, D
	INR  L
	MOV  M, D
	INR  L
	MOV  M, D
	INR  L
	MOV  M, D
	INR  L
	MOV  M, D
	INR  H
	CMP  H
	JNZ	L_7BA4
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	EI
	JMP	L_7C14
;
L_7BC8:	LXI  H, 00000h	; << стирание экрана
	DAD  SP
	SHLD	D_7FFE
	DI
	MVI  A, B_EKR	; ОЗУ: Банк 2, Банк 3
	OUT     00Eh	; режим ОЗУ
	LXI  SP,M_E000	; конец экрана
	LXI  B, 00000h	; чем заполнять
	LXI  D, 0FFF8h	; -8
	LXI  H, 03FF8h	; счётчик
L_7BDC:	PUSH B
	PUSH B
	PUSH B
	PUSH B
	DAD  D
	JC	L_7BDC
	LHLD	D_7FFE
	SPHL
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	EI
	LXI  H, D_7FDE
	MVI  M, 0FFh
L_7BEE:	XRA  A
	STA     D_7FE0
	LDA     D_7FDE
	SUI	00Ah
	STA     D_7FDF
	JMP	L_7C14
;
L_7BFD:	MOV  A, C
	CPI	008h
	LXI  H, D_7FE0
	JNZ	L_7C36
	MOV  A, M
	DCR  A
Lx7C08:	NOP		; <- DCR A / NOP
L_7C09:	JP	L_7C0D
	XRA  A
L_7C0D:	CPI	04Fh
	JC	L_7C13
	XRA  A
L_7C13:	MOV  M, A
L_7C14:	LDA     D_7FE1
	CPI	020h
	JNZ	L_7C2A
	LDA     D_7FE0
X_7C1F:	ANI	007h	; <- ... 007h / ... 00Fh
	MVI  C, 020h
	JNZ	L_7980
	XRA  A
	STA     D_7FE1
L_7C2A:	POP  H
	POP  D
	POP  B
	LDA     D_7FFA
	ORA  A
	CNZ	L_7F29	; вывод на принтер символа (с перекодировкой)
	POP  PSW
	RET
;
L_7C36:	CPI	018h
	JNZ	L_7C41
	MOV  A, M
	INR  A
Lx7C3D:	NOP		; <- INR A / NOP
	JMP	L_7C09
;
L_7C41:	CPI	00Ah
	JNZ	L_7C49
	JMP	L_7B80
;
L_7C49:	CPI	00Bh
	JZ	L_7BEE
	CPI	00Eh
	JZ	L_7A1E
	CPI	00Fh
	JZ	L_7A26
	CPI	007h
	JZ	L_7D50
	CPI	009h
	JZ	L_7D6D
	JMP	L_7C65
;
L_7C65:	CPI	00Dh
	JNZ	L_7C6E
	XRA  A
	JMP	L_7C13
;
L_7C6E:	CPI	019h
	LXI  H, D_7FDF
	JNZ	L_7C8D
	LDA     D_7FDE
	MVI  C, 00Ah
L_7C7B:	INR  M
	CMP  M
	JZ	L_7C87
	DCR  C
	JNZ	L_7C7B
	JMP	L_7C14
;
L_7C87:	SUI	0FAh
L_7C89:	MOV  M, A
	JMP	L_7C14
;
L_7C8D:	CPI	01Ah
	JNZ	L_7A8C
	LDA     D_7FDE
	MVI  C, 00Ah
L_7C97:	DCR  M
	CMP  M
	JZ	L_7CA3
	DCR  C
	JNZ	L_7C97
	JMP	L_7C14
;
L_7CA3:	SUI	00Ah
	JMP	L_7C89
;
L_7CA8:	XRA  A		; <- 80
	STA     D_7FE1
	JMP	L_7A8C
;
L_7CAF:	LXI  H, D_78CC
	SHLD	L_7A8C+1
	CALL	L_7CF9
	LXI  H, 03680h	; стандартные цвета палитры
	SHLD	D_7FF6
	XRA  A		; NOP
	STA     L_7AC9
L_7CC2:	XRA  A
	STA     D_7FE1
	JMP	L_7980
;
L_7CC9:	MVI  A, 003h	; INX B
	STA     Lx7AC2
	STA     Lx7B42
	STA     Lx7B62
	STA     Lx7921
	MVI  A, 007h	; RLC
	STA     Lx7A76
	MVI  A, 03Ch	; INR A
	STA     Lx7C3D
	MVI  A, 03Dh	; DCR A
	STA     Lx7C08
	MVI  A, 034h	; INR M
	STA     Lx7B79
	MVI  A, 00Fh	; RRC
	STA     X_7C1F+1
	JMP	L_7A84
;
L_7CF3:	CALL	L_7CF9
	JMP	L_7A84
;
L_7CF9:	MVI  A, 0C9h	; RET
	STA     Lx7B42
	STA     Lx7B62
	MVI  A, 000h	; NOP
	STA     Lx7AC2
	STA     Lx7A76
	STA     Lx7C08
	STA     Lx7C3D
	STA     Lx7B79
	MVI  A, 007h	; RLC
	STA     X_7C1F+1
	STA     Lx7921
	RET
;
L_7D1B:	MVI  A, 040h
	STA     D_7FE1
	JMP	L_7C14
;
L_7D23:	LDA     D_7FF2	; <- 40
	CPI	000h
	JZ	L_7D36
	XRA  A
	STA     D_7FF2
	MOV  A, C
	STA     D_7FF7
	JMP	L_7A84
;
L_7D36:	INR  A
	STA     D_7FF2
	MOV  A, C
	STA     D_7FF6
	JMP	L_7C14
;
L_7D41:	XRA  A		; NOP
	STA     L_7AC9
	JMP	L_7A84
;
L_7D48:	MVI  A, 02Fh	; CMA
	STA     L_7AC9
	JMP	L_7A84
;
L_7D50:	CALL	L_7D56
	JMP	L_7A84
;
L_7D56:	PUSH H		; << "пик"
	LXI  H, 00000h	; счётчик
L_7D5A:	MOV  A, L
	ANI	008h
	JZ	L_7D62
	MVI  A, 001h
L_7D62:	OUT	000h
	MOV  A, H
	ANI	020h
	INX  H
	JZ	L_7D5A
	POP  H
	RET
;
L_7D6D:	MVI  A, 020h
	STA     D_7FE1
	MOV  C, A
	JMP	L_7980
;
L_7D76:	PUSH PSW	; <<< Обработчик прерывания
	PUSH B
	PUSH D
	PUSH H
	LHLD	D_7FF6	; цвета палитры
	LXI  D, 0100Fh	; счётчики
L_7D80:	MOV  A, E
	OUT	002h
	ANI	006h
	MOV  A, L	; цвет фона
;	MVI  C, 003h
	JZ	L_7D8C
	MOV  A, H	; цвет текста
L_7D8C:	OUT	00Ch
;	DCR  C
;	JNZ	L_7D8C	; цикл повторения записи палитры
	DCR  E
	DCR  D
	JNZ	L_7D80	; цикл записи палитры
	LXI  H, D_7FFD
	INR  M
	MVI  A, 08Ah
	OUT	000h	; работаем с клавиатурой
	LDA     D_7FFC
	OUT	001h	; индикатор РУС
	IN	001h
	ANI	080h	; кнопка РУС/ЛАТ
	LXI  H, D_7FE6
	JNZ	L_7DBF	; >> не нажата
	MOV  A, M
	ORA  A
	JZ	L_7DC1
	MVI  M, 000h
	LXI  H, D_7FE4
	MOV  A, M
	XRI	008h
	MOV  M, A
	JMP	L_7DC1
;
L_7DBF:	MVI  M, 0FFh
L_7DC1:	XRA  A
	OUT	003h
	IN	002h
	CPI	0FFh
	JZ	L_7DE5	; >> кнопки не нажаты
	LXI  B, 0FE08h	; B=FEh -- выбор столбца клавиатуры, C=08h -- счётчик
	LXI  D, 00800h	; ?
	MOV  A, B
L_7DD2:	OUT	003h
	IN	002h
	CPI	0FFh
	JNZ	L_7E12
	MOV  A, E
	ADD  D
	MOV  E, A
	MOV  A, B
	RLC
	MOV  B, A
	DCR  C
	JNZ	L_7DD2
L_7DE5:	CALL	L_7DF3
	XRA  A
	STA     D_7FE3
	CMA
	STA     D_7FE5
L_7EF1:	POP  H
	POP  D
	POP  B
	POP  PSW
	EI
	RET
;
L_7DF3:	LDA     D_7FE4
	ANI	009h
	MOV  H, A
	LDA     D_7FFC	; индикатор РУС
	ANI	002h
	ADD  H
	MOV  H, A
	MVI  A, 088h
	OUT	000h
	MOV  A, H
	OUT	001h	; установка индикатора РУС/ЛАТ
	LDA     D_7FDE
	OUT	003h	; сдвиг экрана
	XRA  A
	ORI	010h	; 512*256
	OUT	002h	; установка режима экрана
	RET
;
L_7E12:	RAR
	JNC	L_7E2A
	INR  E
	JMP	L_7E12
;
D_7E1A:	.db 089h	; "Й" - |■   ■  ■| (adr. 7E1Ah)
	.db 08Ah	; "К" - |■   ■ ■ | (adr. 7E1Bh)
	.db 08Dh	; "Н" - |■   ■■ ■| (adr. 7E1Ch)
	.db 07Fh	; "" - | ■■■■■■■| (adr. 7E1Dh)
	.db 088h	; "И" - |■   ■   | (adr. 7E1Eh)
	.db 099h	; "Щ" - |■  ■■  ■| (adr. 7E1Fh)
	.db 098h	; "Ш" - |■  ■■   | (adr. 7E20h)
	.db 09Ah	; "Ъ" - |■  ■■ ■ | (adr. 7E21h)
	.db 08Bh	; "Л" - |■   ■ ■■| (adr. 7E22h)
	.db 08Ch	; "М" - |■   ■■  | (adr. 7E23h)
	.db 09Bh	; "Ы" - |■  ■■ ■■| (adr. 7E24h)
	.db 080h	; "А" - |■       | (adr. 7E25h)
	.db 081h	; "Б" - |■      ■| (adr. 7E26h)
	.db 082h	; "В" - |■     ■ | (adr. 7E27h)
	.db 083h	; "Г" - |■     ■■| (adr. 7E28h)
	.db 0F0h	; "Ё" - |■■■■    | (adr. 7E29h)
;
L_7E2A:	CALL	L_7DF3
	LXI  H, L_7E91
	PUSH H
	IN	001h
	MOV  B, A
	MOV  A, E
	CPI	03Fh
	MVI  A, 020h
	RZ
	MOV  A, E
	CPI	010h
	JNC	L_7E52
	LXI  H, D_7E1A
	MVI  D, 000h
	DAD  D
	MOV  A, M
	CPI	07Fh
	RNZ
	MOV  A, B
	ANI	020h
	MVI  A, 05Fh
	RZ
	MOV  A, M
	RET
;
L_7E52:	CPI	020h
	JNC	L_7E74
	CPI	01Ch
	JNC	L_7E68
	MOV  A, B
	ANI	020h
	MOV  A, E
	JZ	L_7E65
	ADI	010h
L_7E65:	ADI	010h
	RET
;
L_7E68:	MOV  A, B
	ANI	020h
	MOV  A, E
	JNZ	L_7E71
	ADI	010h
L_7E71:	ADI	010h
	RET
;
L_7E74:	MOV  A, B
	ANI	040h
	JNZ	L_7E7E
	MOV  A, E
	ANI	01Fh
	RET
;
L_7E7E:	MOV  A, B
	ANI	020h
	MOV  B, A
	LDA     D_7FE4
	ANI	008h
	ORA  B
	MOV  A, E
	JPO	L_7E8E
	ADI	020h
L_7E8E:	ADI	020h
	RET
;
L_7E91:	LXI  H, L_7EF1	; адрес выхода из прерывания
	PUSH H
	MOV  B, A
	LDA     D_7FE5
	CPI	0FFh
	JZ	L_7EB6
	CMP  B
	RNZ
	LXI  H, D_7FE3
	MOV  A, M
	CPI	032h
	JZ	L_7EAB
L_7EA9:	INR  M
	RET
;
L_7EAB:	LXI  H, D_7FE2
	MOV  A, M
	CPI	006h
	JNZ	L_7EA9
	MVI  M, 000h
L_7EB6:	MOV  A, B
	STA     D_7FE5
	CPI	0F0h
	JNZ	L_7EC8
	LDA     D_7FF3
	ADI	080h
	STA     D_7FF3
	RET
;
L_7EC8:	CPI	021h
	JC	L_7ED7
	CPI	07Fh
	JNC	L_7ED7
	LDA     D_7FF3
	ADD  B
	MOV  B, A
L_7ED7:	LXI  H, D_7FE7
	MOV  A, M
	CPI	008h
	RNC
	INR  M
	LDA     D_7FE8
	MOV  E, A
	MVI  D, 000h
	LXI  H, D_7FEA
	DAD  D
	INR  A
	ANI	007h
	STA     D_7FE8
	MOV  M, B
	RET
;
L_7EF7:	LDA     D_7FE7	; << опрос статуса клавиатуры,	выход A=FF - клавиша нажата, =00 - не нажата
	ANA  A
	RZ
	MVI  A, 0FFh
	RET
;
L_7EFF:	LDA     D_7FFD	; ? @KEY
	ANI	004h
	CALL	L_790C	; курсор ???
	CALL	L_6E20	; чтение с клавиатуры
	CPI	0FFh
	JZ	L_7EFF	; клавиша не нажата, цикл
	CPI	010h	; УС+P
	JNZ	L_7F22	; >>
	LDA     D_7FFA
	CMA
	STA     D_7FFA
	ORA  A
	CNZ	L_7D56	; "пик"
	JMP	L_7EFF
;
L_7F22:	PUSH PSW
	XRA  A
	CALL	L_790C	; курсор ???
	POP  PSW
	RET
;
L_7F29:	PUSH PSW	; ? @LIST << C (символ) -- вывод на печать символа (с перекодировкой)
	PUSH H
	PUSH D
	PUSH B
	MOV  A, C
	ANI	07Fh
	MOV  C, A
	LDA     D_7FF8	; тип принтера
	CPI	000h
	JZ	L_7F96
	CPI	001h
	JZ	L_7F83
	MOV  A, C
	CPI	01Bh
	JZ	L_7F57
	LDA     D_7FDC
	ORA  A
	JZ	L_7F75
	CPI	01Bh
	JZ	L_7F5D
	MOV  A, C
	ANI	001h
	STA     D_7FDD
L_7F56:	XRA  A
L_7F57:	STA     D_7FDC
	JMP	L_7F99
;
L_7F5D:	MOV  A, C
	CPI	052h
	JNZ	L_7F69
	STA     D_7FDC
	JMP	L_7F99
;
L_7F69:	MVI  C, 01Bh
	CALL	L_781E
	MOV  C, A
	CALL	L_781E
	JMP	L_7F56
;
L_7F75:	LDA     D_7FDD
	CPI	000h
	JZ	L_7F96
	MOV  A, C
	CPI	060h
	JC	L_7F9E
L_7F83:	MOV  A, C
	ANI	07Fh
	MOV  C, A
	CPI	060h
	JC	L_7F96
	LXI  H, D_7FBC
	MVI  D, 000h
	SUI	060h
	MOV  E, A
	DAD  D
	MOV  C, M
L_7F96:	CALL	L_781E
L_7F99:	POP  B
	POP  D
	POP  H
	POP  PSW
	RET
;
L_7F9E:	MOV  A, C
	ANI	07Fh
	MOV  C, A
	CPI	040h
	JC	L_7F96
	LXI  H, D_7FBC
	MVI  D, 000h
	SUI	040h
	MOV  E, A
	DAD  D
	MOV  A, M
	CPI	080h
	JC	L_7FB8
	ADI	030h
L_7FB8:	MOV  C, A
	JMP	L_7F96
;
D_7FDC:	.db 000h	; "_" - |        | (adr. 7FDCh)
D_7FDD:	.db 000h	; "_" - |        | (adr. 7FDDh)
D_7FDE:	.db 0FFh	; сдвиг экрана
D_7FDF:	.db 0F5h	; номер строки (смещение от низа экрана)
D_7FE0:	.db 001h	; номер позиции в строке
D_7FE1:	.db 000h	; "_" - |        | (adr. 7FE1h)
D_7FE2:	.db 000h	; "_" - |        | (adr. 7FE2h)
D_7FE3:	.db 000h	; "_" - |        | (adr. 7FE3h)
D_7FE4:	.db 006h	; состояние ЛАТ / РУС (06 / 0E)
D_7FE5:	.db 0FFh	; " " - |■■■■■■■■| (adr. 7FE5h)
D_7FE6:	.db 0FFh	; кнопка РУС/ЛАТ (FF = не нажата)
D_7FE7:	.db 000h	; "_" - |        | (adr. 7FE7h)
D_7FE8:	.db 000h	; позиция записи в буфер клавиатуры
D_7FE9:	.db 000h	; позиция чтения из буфера клавиатуры
D_7FEA:	.db 000h	; 0 циклический буфер клавиатуры
	.db 000h	; 1
	.db 000h	; 2
	.db 000h	; 3
	.db 000h	; 4
	.db 000h	; 5
	.db 000h	; 6
	.db 000h	; 7
D_7FF2:	.db 000h	; "_" - |        | (adr. 7FF2h)
D_7FF3:	.db 000h	; "_" - |        | (adr. 7FF3h)
D_7FF4:	.db 03Ch	; скорость записи (Вектор =32)
D_7FF5:	.db 05Bh	; скорость чтения (Вектор =4B)
D_7FF6:	.db 080h	; цвет фона
D_7FF7:	.db 036h	; цвет текста
D_7FF8:	.db 000h	; тип принтера (0,1,2)
D_7FF9:	.db 000h	; тип клавиатуры (0-JCUKEN, 1-QWERTY)
D_7FFA:	.db 000h	; "_" - |        | (adr. 7FFAh)
D_7FFB:	.db 000h	; "_" - |        | (adr. 7FFBh)
D_7FFC:	.db 000h	; индикатор РУС ???
D_7FFD:	.db 000h	; счётчик циклов в обработчике прерываний
D_7FFE:	.dw 00000h	; адрес стека
;
VEKT2:	.ORG	07E00h
#define STEK1	07F80h	; для CALL 5, BIOS
#define STEK2	08000h	; для RST 7
#define STEK3	L_BIOS	; для RST 5 07F00h
;
L_CAL5:	DI
	LXI  H,	0
	DAD  SP
	SHLD	LxC5SP+1
	LXI SP,	STEK1
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	EI		; =======================
	CALL	M_0005	
	DI
	MOV  H, A
	XRA  A		; ОЗУ: Банк 0, Банк 1
	OUT     00Eh	; режим ОЗУ
	MOV  A, H	; =======================
LxC5SP:	LXI  H, 0
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
	LXI SP,	STEK2	; =======================
	CALL	M_0038
	SPHL
	XRA  A		; ОЗУ: Банк 0, Банк 1
	OUT     00Eh	; режим ОЗУ
	POP	PSW	; =======================
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
	STA	L_R5A+1
	MVI  A, B_MONR	; ОЗУ: {Банк 0 R | Банк 2 W}, Банк 1
	OUT     00Eh	; режим ОЗУ
L_R5A:	MVI  A, 0	; A
	LXI SP,	STEK3	; стек в Банке 2
	PUSH PSW	; =PSW
	PUSH H		; =SP
L_R5HL:	LXI  H, 0
	PUSH H		; =HL
L_R5AD:	LXI  H, 0
;;	PUSH H		; =ADR
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	JMP	M_0028	; =======================
;
INIT:	DI
	XRA  A
	JMP	BIOS00
;
BIOS:	DI
	POP	H
	MOV	A,L
	SUI	3
BIOS00:	STA	BIOS02+1
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	JNZ	BIOS01	; ===========================
	MVI  A, 0C3h	; JMP ...
	STA     M_0000	;
	STA     M_0005	;
	STA     M_0038	;
	LXI  H, MBIOS	; рестарт
	SHLD	M_0000+1	; ... MBIOS
	LXI  H, L_5400
	SHLD	M_0005+1	; ... CALL5L
	LXI  H, L_7D76
	SHLD	M_0038+1	; ... RST7L
BIOS01:	LXI  H,	0
	DAD SP
	LXI SP,	STEK1
	PUSH H
	EI
BIOS02:	CALL	MBIOS	;<<<< изменяется
	DI
	PUSH PSW
	XRA  A		; ОЗУ: Банк 0, Банк 1
	OUT	00Eh	; режим ОЗУ
	POP  PSW	; =========================
	POP  H
	SPHL
	EI
	RET
;
RUN:	STA	Rx01+1	; <<< запуск программ
	MVI  A, B_PRG0	; ОЗУ: Банк 2, Банк 0
	OUT	00Eh	; режим ОЗУ
Rx01:	MVI  A, 0
	STA	Rx02+8001h
	SHLD	Rx03+8001h
RxSTA:	LXI  H, 0	; < сюда пишется адрес перехода
	SHLD	RxSTB+8001h
	MVI  A, 0	; ОЗУ: Банк 0, Банк 1
	OUT	00Eh	; режим ОЗУ
			; ============================
Rx02:	MVI  A, 0	; восстанавливаем A
Rx03:	LXI  H, 0	; восстанавливаем HL
	EI
RxSTB:	JMP	0	; >>
;
RUNC:	XRA  A		; ОЗУ: Банк 0, Банк 1	<<< запуск программ C
	OUT	00Eh	; режим ОЗУ
			; ============================
	PUSH H
	LXI  H, RRET
	XTHL		; адрес возврата в стек
	EI
	PCHL		; >> переход к подпрограмме с передачей значений BC и DE
;
RRET:	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1	<<< возврат из C
	OUT     00Eh	; режим ОЗУ
	JMP	L_6000	; рестарт
;
	.ORG	L_CAL5+100h	;07F00h
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
; [7F1Eh] таблица исправления адресов Монитора в "вариант 2"
V_C5:	.DW	VxC51+1				; 		<- адрес, где менять
	.DW	(L_CAL5 / 00100h) | 0BA00h	; ... | "CMP D" <- чем заменять
	.DW	VxC52+1	;
	.DW	L_CAL5
V_R7:	.DW	VxR71+1	;
	.DW	L_RST7	;RST7V
V_R5:	.DW	VxR51+1	;
	.DW	L_RST5	;RST5V
V_MB:	.DW	L_5FC3+1	;
	.DW	(L_BIOS / 00100h) | 0BA00h	; ... | "CMP D"
	.DW	VxMB1+1	;
	.DW	L_BIOS	;MBIOSV
V_RN:	.DW	VxRN1+1 ;
	.DW	RUN	;RUNV
	.DW	VxRN2+1 ;
	.DW	RUNC	;RUNCV
	.DW	VxRN3+1 ;
	.DW	RUNC	;RUNCV
V_RS:	.DW	VxRS1+1	;
	.DW	RxSTA+1	;RxSTAV+1
V_HS:	.DW	D_66F4	;
	.DW	L_CAL5-10h	;HSTEK
	.DW	VxHS1+1	;
	.DW	L_CAL5-10h	;HSTEK
	.DW	0	; конец исправлений
	.DW	0
;
	.END	; (at <=7FFFh)
