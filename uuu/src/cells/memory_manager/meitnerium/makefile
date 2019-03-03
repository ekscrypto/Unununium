# $Header: /cvsroot/uuu/uuu/src/cells/memory_manager/meitnerium/makefile,v 1.4 2001/12/09 16:29:35 instinc Exp $

INCS = \
       macros.inc \
       error_codes.inc

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
