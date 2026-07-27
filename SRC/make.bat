@echo off
rem Need "Telemark Assembler" and "LZSA"
set TASMTABS=D:\Work\~TASM
set TASMOPTS=-85 -b
for %%D in (monitor vektors1 logo main) do D:\Work\~TASM\tasm %%D.asm
copy /b logo.obj+vektors1.obj+monitor.obj p1.bin
lzsa -f1 -r -c -v -stats p1.bin pmon.pak
copy /b /y main.obj+pmon.pak mon50.rom
