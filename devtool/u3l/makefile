.PHONY: all clean install

all: u3l


u3l: u3l.o $(DEVTOOLDIR)u3common/u3common.o
	echo $(CFLAGS)
	$(CC) -s -o u3l u3l.o $(DEVTOOLDIR)u3common/u3common.o $(CFLAGS)

u3l.o: u3l.c	\
	$(INCLUDES)u3common.h \
	$(INCLUDES)u3l.h

clean:
	rm -f u3l.o u3l

install: all
	cp u3l $(PREFIX)/bin
