# $Header: /cvsroot/uuu/dimension/cell/debug/diable/makefile,v 1.1.1.1 2002/01/17 04:30:58 instinc Exp $

.PHONY: clean install

INCS =\
	macros.inc \
	errors.inc

diable: diable.o
	$(ELF2UBF) $(E2UFLAGS) diable.o diable

diable.o: diable.asm $(INCS) makefile
	$(AS) -f elf diable.asm $(ASFLAGS) $(addprefix -p,$(INCS))

install: $(CELL_INST_DIR)/diable

$(CELL_INST_DIR)/diable: diable
	cp diable $(CELL_INST_DIR)/diable

clean:
	rm -f diable.o diable
