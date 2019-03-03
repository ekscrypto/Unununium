# $Header: /cvsroot/uuu/uuu/src/cells/debug/bochs/makefile,v 1.4 2001/12/09 16:03:38 instinc Exp $

INCS = \
       macros.inc \
       error_codes.inc

bochs: bochs.o
	$(ELF2UBF) $(E2UFLAGS) bochs.o bochs

bochs.o: bochs.asm $(INCS)
	$(AS) -f elf bochs.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/bochs

$(CELL_INST_DIR)/bochs: bochs
	cp bochs $(CELL_INST_DIR)/bochs

clean:
	rm -f bochs.o bochs
