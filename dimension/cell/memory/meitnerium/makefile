# $Header: /cvsroot/uuu/dimension/cell/memory/meitnerium/makefile,v 1.1.1.1 2002/01/17 04:31:13 instinc Exp $

INCS = \
	macros.inc \
	errors.inc \
	vid/mem.inc \
	vid/mem.fixed.inc

meitnerium: meitnerium.o
	$(ELF2UBF) $(E2UFLAGS) meitnerium.o meitnerium

meitnerium.o: meitnerium.asm $(INCS)
	$(AS) -f elf meitnerium.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/meitnerium

$(CELL_INST_DIR)/meitnerium: meitnerium
	cp meitnerium $(CELL_INST_DIR)/meitnerium

clean:
	rm -f meitnerium.o meitnerium
