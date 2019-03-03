U3TBASE = $(CURDIR)/../
CC = gcc
CFLAGS = -Wall -O2 -I$(U3TBASE)include/
PREFIX = /usr/local

.PHONY: clean all install

all: u3l

u3l.o: u3l.c \
	$(U3TBASE)include/u3common.h \
	$(U3TBASE)include/u3l.h

u3l: u3l.o $(U3TBASE)u3common/u3common.o
	$(CC) -s -o u3l u3l.o $(U3TBASE)u3common/u3common.o

clean:
	rm -f u3l.o u3l

install: all
	cp u3l $(PREFIX)/bin
