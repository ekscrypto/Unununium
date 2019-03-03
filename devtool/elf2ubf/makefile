# $Header: /cvsroot/uuu/devtool/elf2ubf/makefile,v 1.1.1.1 2002/11/29 23:48:14 instinc Exp $

.PHONY: clean all install


all: elf2ubf ubfdump

elf2ubf: elf2ubf.c elf.h ubf.h
	$(CC) -o elf2ubf $(CFLAGS) -s $<

ubfdump: ubfdump.c elf.h ubf.h
	$(CC) -o ubfdump $(CFLAGS) -s $<

clean:
	rm elf2ubf ubfdump

install: all
	cp elf2ubf ubfdump $(PREFIX)/bin

