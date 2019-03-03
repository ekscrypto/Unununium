# $Header: /cvsroot/uuu/dimension/cell/lib/string/common/makefile,v 1.1.1.1 2002/01/17 04:31:33 instinc Exp $

INCS = \
	macros.inc \
	vid/lib.string.inc \
	fs/fs.inc

libstring: common.o
	$(ELF2UBF) $(E2UFLAGS) common.o libstring

common.o: common.asm $(INCS) makefile
	$(AS) -f elf common.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(LIB_INST_DIR)/libstring

$(LIB_INST_DIR)/libstring: libstring
	cp libstring $(LIB_INST_DIR)/libstring

clean:
	rm -f common.o libstring
