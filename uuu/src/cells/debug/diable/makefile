# $Header: /cvsroot/uuu/uuu/src/cells/debug/diable/makefile,v 1.5 2001/12/09 15:57:51 instinc Exp $

.PHONY: clean install

INCS =\
	macros.inc \
	error_codes.inc

diable: diable.o
	$(ELF2UBF) $(E2UFLAGS) diable.o diable

diable.o: diable.asm macros.inc error_codes.inc
	$(AS) -f elf diable.asm $(ASFLAGS) $(addprefix -p,$(INCS))

install: $(CELL_INST_DIR)/diable

$(CELL_INST_DIR)/diable: diable
	cp diable $(CELL_INST_DIR)/diable

clean:
	rm -f diable.o diable
