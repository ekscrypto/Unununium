# $Header: /cvsroot/uuu/dimension/cell/memory/octane/makefile,v 1.1 2002/02/02 13:20:48 instinc Exp $

.PHONY: clean install

INCS = \
macros.inc \
errors.inc \
process.inc \
vid/mem.inc \
vid/debug.diable.inc

octane: octane.o
	$(ELF2UBF) $(E2UFLAGS) octane.o octane

octane.o: octane.asm $(INCS) makefile
	$(AS) -f elf octane.asm $(addprefix -p,$(INCS)) $(ASFLAGS)

install: $(CELL_INST_DIR)/octane

$(CELL_INST_DIR)/octane: octane
	cp octane $(CELL_INST_DIR)

clean:
	rm -rf octane.o octane
