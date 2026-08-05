#include "vars.inc"
;
STEK1:	.EQU	LogoAdr	; 04000h	; для CALL 5, BIOS
;
	.ORG	LogoAdr	; запускается с адреса 0C000h
	MVI  A, 0BBh	; ОЗУ: Банк 2, Банк 2
	OUT     00Eh	; режим ОЗУ
	JMP	START	; переход на адреса 040ххh
START:	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	MVI  A, 088h
	OUT	000h
	MVI  A, 0FFh
	OUT	003h	; сдвиг экрана
	MVI  A,	010h	; 512*256
	OUT	002h	; установка режима экрана
	MVI  A, 0C3h	; JMP ...
	STA     M_0000	;
	STA     M_0005	;
	STA     M_0038	;
	LXI  H, MBIOS
	SHLD	M_0001	; ... MBIOS
	LXI  H, CALL5L
	SHLD	M_0006	; ... CALL5L
	LXI  H, RST7L
	SHLD	M_0039	; ... RST7L
	LXI SP,	STEK1
STRT0:	LXI  H, str1
	EI
	CALL	IO7833	; вывод строки до 0
L_WKEY:	CALL	IO7803	; ввод символа с клавиатуры
	CPI	049h	; "I"
	JZ	L_HELP
	CPI	032h	; "2"
	JZ	L_V2
	CPI	031h	; "1"
	JNZ	L_WKEY	; цикл ожидания правильной кнопки
	DI
	CALL	CLRMEM
L_V1:	LXI  H, MARKV	; куда
	LXI  D, L_VKTR	; откуда
	LXI  B, VektLen	; сколько
CP_VRT:	LDAX D
	MOV  M, A
	INX  D
	INX  H
	DCX  B
	MOV  A, B
	ORA  C
	JNZ	CP_VRT
	JMP	INITV	; >> запуск монитора
;	
L_V2:;	MOV  C, A
;	CALL	IO7809	; вывод на экран символа из C
	DI
	LXI SP,	TABV2L	; таблица изменения адресов
L_V200:	POP  D
	POP  H
	MOV  A, D
	ORA  E
	JZ	L_V201	; >> до обнуления адреса
	SHLX		; M(DE) <- L; M(DE+1) <- H
	JMP	L_V200	; цикл корректировки адресов на "вариант 2"
;
L_V201:	LXI SP,	STEK1
	CALL	CLRMEM
	LXI  D, VEKT2L	; откуда/куда
	LXI  B, Vekt2Ln	; сколько/2
	MVI  A, B_MONW	; ОЗУ: (Банк 2 R / Банк 0 W), Банк 1
	OUT     00Eh	; режим ОЗУ
L_V202:	LHLX
	SHLX
	INR  E
	INX  D
	DCX  B
	MOV  A, B
	ORA  C
	JNZ	L_V202
	MVI  A, 0FFh
	STA	07DA0h	; метка для ассемблер-редактора, чтобы не писал "мало памяти"
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	JMP	INITV	; >> запуск монитора
;
CLRMEM:	MVI  A, B_MONW	; ОЗУ: (Банк 2 R / Банк 0 W), Банк 1
	OUT     00Eh	; режим ОЗУ
	LXI  D, 0
	LXI  H, 0
L_CLRM:	SHLX		; M(DE) <- L; M(DE+1) <- H
	INR  E
	INR  E
	JNZ	L_CLRM	;
	INR  D
	JNZ	L_CLRM	; очистка памяти 0-64k
	MVI  A, B_MON	; ОЗУ: Банк 2, Банк 1
	OUT     00Eh	; режим ОЗУ
	RET
;
L_HELP:	LXI  H, SHELP
	CALL	IO7833
L_H00:	CALL	IO7803
	CPI	020h	; " "
	JNZ	L_H00
	JMP	STRT0
;
str1:	.db 01Bh, 04Ah			; Стирание экрана
	.db 01Bh, 05Dh			; Двойная ширина символов
	.db 01Bh, 062h			; Вывод символов в негативе
	.db 01Bh, 059h, 020h, 020h	; Перемещение курсора в координаты 0, 0
	.db 00Eh			; рус
	.db "   *  pk-6128c  *   "
	.db 00Ah, 00Dh
	.db " monitor WERS (5.0) "
	.db 00Ah, 00Dh
; 	.db "   super monstr-3   "
;	.db 00Ah, 00Dh
	.db " wOLGOGRAD  08.2026 "
	.db 00Ah, 00Dh
	.db 01Bh, 05Eh			; Одинарная ширина символов
	.db 01Bh, 061h			; Отключение вывода в негативе
	.db 00Eh			; рус
	.db "aDRESA ozu MONITORA: "
	.db 00Fh			; лат
	.db "14000H-17FFFH;"
;	.db 00Ah, 00Dh
	.db 00Eh			; рус
	.db " |KRANA: "
	.db 00Fh			; лат
	.db "1A000H-1DFFFH."
	.db 00Ah, 00Dh
	.db 00Eh			; рус
	.db "wYBERITE ADRESA "
	.db "DLQ WEKTOROW WYZOWA "
	.db "MONITORA:"
	.db 00Fh			; лат
	.db " 1,2"
	.db 00Ah, 00Dh
	.db " <1>: 0FE00H-0FFFFH"
	.db 00Ah, 00Dh
	.db " <2>: 07E00H-07FFFH"
	.db 00Ah, 00Dh, 00Ah, 00Dh
	.db " <I>: "
	.db 00Eh			; рус
	.db "instrukciq"
	.db 00Ah, 00Dh
	.db 01Bh, 05Ch			; KOI-7
;	.db "$"
	.db 000h
;	
SHELP:	.db 01Fh
	.db "               "
	.db "              "
	.db "direktiwy monitora"
	.db 00Ah, 00Dh, 00Ah, 00Dh
	.db " w dannoj wersii "
	.db "monitora-otlad~ika "
	.db "dobawleno ~etyre nowye "
	.db "direktiwy:"
	.db 00Ah, 00Dh, 00Ah, 00Dh
	.db "direktiwa B - "
	.db "prednazna~ena dlq "
	.db "zagruzki dannyh "
	.db "s magnitnoj lenty "
	.db "w formate ROM."
;	.db 00Ah, 00Dh
	.db "  komanda 'BM' wypolnqet "
	.db "zagruzku so sme}eniem "
	.db "na 1 blok."
	.db 00Ah, 00Dh, 00Ah, 00Dh
	.db "direktiwa J - "
	.db "prednazna~ena dlq "
	.db "o~istki |krana. "
	.db "ona analogi~na "
	.db "posledowatelx-"
	.db 00Ah, 00Dh
	.db "  nosti komand 'K+"
	.db "<wk>,<str>,<F4>' monitora "
	.db "ili komande CLS "
	.db "bejsika."
	.db 00Ah, 00Dh, 00Ah, 00Dh
	.db "direktiwa Y - "
	.db "prednazna~ena dlq "
	.db "opredeleniq konstanty "
	.db "~teniq programm s"
	.db 00Ah, 00Dh
	.db "  magnitnoj lenty. "
	.db "po |toj direktiwe "
	.db "movno opredelitx "
	.db "konstantu dlq "
	.db "programm,"
	.db 00Ah, 00Dh
	.db "  zapisannyh w "
	.db "l`bom formate. dlq "
	.db "opredeleniq konstanty "
	.db "zapisi nuvno razdelitx"
	.db 00Ah, 00Dh
	.db "  konstantu ~teniq na 1,5."
	.db 00Ah, 00Dh, 00Ah, 00Dh
	.db "direktiwa Z - "
	.db "prednazna~ena dlq "
	.db "wremennogo pokaza |krana "
	.db "po standartnym adresam"
	.db 00Ah, 00Dh
	.db "  wektora "
	.db "(bank 1, 08000H-0FFFFH)."
	.db 00Ah, 00Dh, 00Ah, 00Dh
	.db " krome togo, direktiwa G "
	.db "polu~ila nowyj kl`~ "
	.db "'-G', kotoryj zapuskaet "
	.db "programmy s"
;	.db 00Ah, 00Dh
	.db "perekl`~eniem |krana na "
	.db "bank 1 (08000H-0FFFFH)."
	.db " ostalxnye direktiwy "
	.db "ne otli~a`t-sq "
	.db "ot bazowoj wersii "
	.db "monitora-otlad~ika "
	.db "dlq pk wektor-06c."
	.db 00Ah, 00Dh, 000h
;
L_VKTR:	.end
	
