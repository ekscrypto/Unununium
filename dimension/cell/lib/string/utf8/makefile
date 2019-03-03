# $Header: /cvsroot/uuu/dimension/cell/lib/string/utf8/makefile,v 1.1 2002/11/24 19:52:58 doobie_do Exp $

INCS = \
	macros.inc \
	vid/utf8.inc

libutf8: utf8.o
	$(ELF2UBF) $(E2UFLAGS) utf8.o libutf8

utf8.o: utf8.asm $(INCS) makefile
	$(AS) -f elf utf8.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(LIB_INST_DIR)/libutf8

$(LIB_INST_DIR)/libutf8: libutf8
	cp libutf8 $(LIB_INST_DIR)/libutf8

clean:
	rm -f utf8.o libutf8
