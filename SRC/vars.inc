CALL5V:	.EQU	0FE00h	; =L_CAL5	адреса из vektors
RST7V:	.EQU	0FE1Bh	; =L_RST7
RST5V:	.EQU	0FE33h	; =L_RST5
MBIOSV:	.EQU	0FF00h	; =L_BIOS
RUNV:	.EQU	0FE9Ch	; =RUN
RxSTAV:	.EQU	0FEA6h	; =RxSTA
RUNCV:	.EQU	0FEA9h	; =RUNC
INITV:	.EQU	MBIOSV	; =L_BIOS
MARKV:	.EQU	0FDA0h	; =MARK
;
#define VektLen	382	; размер модуля векторов 1, для ПП переноса
#define Vekt2Ln	(TABV2L-VEKT2L+1)/2	; размер модуля векторов 2, для ПП переноса
#define LogoAdr 04000h	; начало logo.obj
#define LogoLen	1479	; размер logo.obj, для выравнивания
;
MBIOS:	.EQU	07600h	; =L_7800	адреса из основного модуля
IO7803:	.EQU	07603h	; =L_7803	@KEY -- ввод символа с клавиатуры
IO7809:	.EQU	07609h	; =L_7809	@CONOUT -- вывод на экран символа из C
IO7833:	.EQU	07642h	; =L_7833	@SPIC -- вывод строки до 00h с адреса из HL
;
CALL5L:	.EQU	04C80h	; =L_5400	l*1
RST7L:	.EQU	07B84h	; =L_7D76	l*1
VEKT2L:	.EQU	07E00h	; =VEKT2	l*1
TABV2L:	.EQU	07F1Eh	; =V_C5		l*1
;
#define B_EKR	0AAh	; ОЗУ: Банк 2, Банк 3 -- подключение экрана
#define B_MON	088h	; ОЗУ: Банк 2, Банк 1 -- монитор-отладчик
#define B_MONW	008h	; ОЗУ: {Банк 2 R | Банк 0 W}, Банк 1 -- монитор-отладчик с записью в Банк 0
#define B_MONR	080h	; ОЗУ: {Банк 0 R | Банк 2 W}, Банк 1 -- монитор-отладчик с записью в Банк 0
#define B_PRG0	099h	; ОЗУ: Банк 2, Банк 0 -- программа
#define B_PRG1	088h	; ОЗУ: Банк 2, Банк 1 -- программа
;
M_0000:	.EQU    00000h
M_0001:	.EQU    00001h
M_0005:	.EQU    00005h	; CALL 5
M_0006:	.EQU    00006h
M_0028:	.EQU    00028h	; RST 5
M_0029:	.EQU    00029h
M_0038:	.EQU    00038h	; RST 7
M_0039:	.EQU    00039h
;
#define FreeSpace CALL5L-LogoAdr-LogoLen
