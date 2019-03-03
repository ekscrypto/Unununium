# $Header: /cvsroot/uuu/uuu/src/tools/elf2ubf/makefile,v 1.2 2001/10/24 01:16:35 daboy Exp $
# This makefile is screwed

all: elf2ubf ubfdump

elf2ubf: elf2ubf.c
	gcc -s -Wall -O3 -o elf2ubf elf2ubf.c

ubfdump: ubfdump.c
	gcc -s -Wall -O3 -o ubfdump ubfdump.c

elf2ubf.c: elf.h ubf.h

ubfdump.c: elf.h ubf.h

.PHONY: clean

clean:
	rm elf2ubf ubfdump
