# $Header: /cvsroot/uuu/dimension/cell/debug/bochs/makefile,v 1.1.1.1 2002/01/17 04:30:58 instinc Exp $

INCS = \
       macros.inc \
       vid/debug.bochs.inc \
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
