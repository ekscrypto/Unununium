# $Header: /cvsroot/uuu/existence/cells/memory/octane/makefile,v 1.2 2003/01/12 03:22:10 instinc Exp $

.PHONY: clean install

INCS = \
	macros.inc \
	errors.inc \
	thread.inc \
	vid/mem.inc \
	vid/sem.inc

octane: octane.o
	$(ELF2UBF) $(E2UFLAGS) octane.o octane

octane.o: octane.asm $(INCS) makefile
	$(AS) -f elf octane.asm $(addprefix -p,$(INCS)) $(ASFLAGS)

install: $(CELL_INST_DIR)/octane

$(CELL_INST_DIR)/octane: octane
	cp octane $(CELL_INST_DIR)

clean:
	rm -rf octane.o octane
