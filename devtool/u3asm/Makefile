#
# U3ASM
# $Header: /cvsroot/uuu/devtool/u3asm/Makefile,v 2.7 2003/06/24 01:48:51 daboy Exp $
# Copyright 2003 by Phil Frost; see file "License".
#

YACC=bison
YFLAGS=-v

LEX=flex++
LFLAGS=-bsp

CXXFLAGS=-Wall -ggdb

CPPFLAGS=-include mem_stats.h

LD=g++
LDFLAGS=-ggdb

DOXYGEN=doxygen
DOXYFLAGS=

objs=\
    main.o \
    label.o \
    data_instruction.o \
    regular_instruction.o \
    assembler.o \
    program_options.o \
    parse.o \
    section.o \
    lex.o

.PHONY: all clean doc encoding_tables

all: u3asm encoding_tables
	@echo -e '\n*** build successful ***\n'

u3asm: $(objs)
	$(LD) -o $@ $(LDFLAGS) $^

parse.cc parse.h: parse.y
	$(YACC) $(YFLAGS) -o parse.cc $<
	mv parse.hh parse.h

lex.cc: lex.l parse.h
	$(LEX) $(LFLAGS) -t $< > $@

lex.o: lex.cc
	$(CXX) $(CPPFLAGS) $(CXXFLAGS)  -Wno-unused-function -Wno-unused-variable -c -o $@ $<

# we must make deps for lex.l first, because it uses parse.h from parse.y
# also mention lex.cc so make doesn't delete it after making the deps
lex.d: lex.cc parse.d

encoding_tables:
	$(MAKE) -C encoding_tables

clean:
	rm -f *.d *.o u3asm parse.h parse.output parse.cc lex.cc lex.backup
	rm -rf doc
	$(MAKE) -C encoding_tables clean

doc: lex.cc parse.cc
	$(DOXYGEN) $(DOXYFLAGS)

%.d: %.cc
	@echo 'making dependencies for $<'
	@$(CXX) -MM $(CPPFLAGS) $< | sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' > $@

-include $(objs:.o=.d)
