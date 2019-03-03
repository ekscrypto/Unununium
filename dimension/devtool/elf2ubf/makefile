# $Header: /cvsroot/uuu/dimension/devtool/elf2ubf/makefile,v 1.3 2002/10/05 20:14:55 daboy Exp $

CC = gcc
CFLAGS = -Wall -O3
PREFIX = /usr/local

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
