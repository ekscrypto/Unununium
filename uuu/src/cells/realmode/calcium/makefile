# $Header: /cvsroot/uuu/uuu/src/cells/realmode/calcium/makefile,v 1.8 2001/12/10 16:30:03 instinc Exp $

INCS = \
	macros.inc \
	error_codes.inc \
	vid/mem.inc \
	vid/debug.diable.inc \
	vid/gdt.inc \
	vid/realmode.inc

calcium: calcium.o
	$(ELF2UBF) $(E2UFLAGS) calcium.o calcium

calcium.o: calcium.asm $(INCS) makefile
	$(AS) -f elf calcium.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/calcium

$(CELL_INST_DIR)/calcium: calcium
	cp calcium $(CELL_INST_DIR)/calcium

clean:
	rm -f calcium.o calcium
