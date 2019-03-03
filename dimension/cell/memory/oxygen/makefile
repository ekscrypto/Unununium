# $Header: /cvsroot/uuu/dimension/cell/memory/oxygen/makefile,v 1.1.1.1 2002/01/17 04:31:14 instinc Exp $

.PHONY: clean install

INCS = \
oxygen.def \
core.inc \
macros.inc \
errors.inc \
vid/mem.inc \
vid/debug.diable.inc

oxygen: oxygen.o
	$(ELF2UBF) $(E2UFLAGS) oxygen.o oxygen

oxygen.o: oxygen.asm $(INCS) makefile
	$(AS) -f elf oxygen.asm $(addprefix -p,$(INCS)) $(ASFLAGS)

install: $(CELL_INST_DIR)/oxygen

$(CELL_INST_DIR)/oxygen: oxygen
	cp oxygen $(CELL_INST_DIR)

clean:
	rm -rf oxygen.o oxygen
