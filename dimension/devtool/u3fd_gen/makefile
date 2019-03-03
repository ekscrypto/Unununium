CC = gcc
CFLAGS = -Wall -O3
PREFIX = /usr/local

.PHONY: all clean install

all: u3fd_gen boot2h

u3fd_gen: u3fd_gen.c
	$(CC) -o u3fd_gen $(CFLAGS) -s $<

boot2h: boot2h.c
	$(CC) -o boot2h $(CFLAGS) -s $<

clean:
	rm -f u3fd_gen boot2h

install: all
	cp u3fd_gen boot2h $(PREFIX)/bin
