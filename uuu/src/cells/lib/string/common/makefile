# $Header: /cvsroot/uuu/uuu/src/cells/lib/string/common/makefile,v 1.3 2001/12/10 00:00:10 instinc Exp $

INCS = \
	macros.inc \
	vid/lib.string.inc \
	ozone.inc

libstring: common.o
	$(ELF2UBF) $(E2UFLAGS) common.o libstring

common.o: common.asm $(INCS) makefile
	$(AS) -f elf common.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(LIB_INST_DIR)/libstring

$(LIB_INST_DIR)/libstring: libstring
	cp libstring $(LIB_INST_DIR)/libstring

clean:
	rm -f libstring.o libstring
