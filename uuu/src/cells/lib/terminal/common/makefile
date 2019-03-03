# $Header: /cvsroot/uuu/uuu/src/cells/lib/terminal/common/makefile,v 1.2 2001/12/10 15:46:33 instinc Exp $

INCS = \
	macros.inc \
	ozone.inc \
	vid/lib.term.inc

libterminal: common.o
	$(ELF2UBF) $(E2UFLAGS) common.o libterminal

common.o: common.asm $(INCS) makefile
	$(AS) -f elf common.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(LIB_INST_DIR)/libterminal

$(LIB_INST_DIR)/libterminal: libterminal
	cp libterminal $(LIB_INST_DIR)/libterminal

clean:
	rm -f common.o libterminal
