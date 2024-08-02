CC=g++
ASMBIN=nasm

all : asm cc link

asm : 
	$(ASMBIN) -o sdiv.o -f elf -g -F dwarf sdiv.asm

cc : 
	$(CC) -m32 -c -g -O0 main.cpp

link : 
	$(CC) -m32 -g -o sdiv main.o sdiv.o

clean :
	rm *.o
	rm sdiv