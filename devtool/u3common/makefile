SYSTEMINC = /usr/include/
U3TINC = ../include/
INCLUDE = -I$(SYSTEMINC) -I$(U3TINC)
COMPILERFLAGS = -c -Wall -O2
CC = gcc
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)

.PHONY: clean all

all: u3common.o

u3common.o: u3common.c $(U3TINC)u3common.h
	$(CC) $(CFLAGS) -o u3common.o u3common.c

clean:
	rm -f u3common.o
