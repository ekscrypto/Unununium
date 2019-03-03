# $Header: /cvsroot/uuu/dimension/cell/dyn/hydrogen/makefile,v 1.1.1.1 2002/01/17 04:31:06 instinc Exp $

INCS = \
	macros.inc \
	errors.inc \
	vid/void.inc \
	vid/sys_log.inc \
	vid/mem.fixed.inc

hydrogen: hydrogen.o
	$(ELF2UBF) $(E2UFLAGS) hydrogen.o hydrogen

hydrogen.o: hydrogen.asm $(INCS) makefile
	$(AS) -f elf hydrogen.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/hydrogen

$(CELL_INST_DIR)/hydrogen: hydrogen
	cp hydrogen $(CELL_INST_DIR)/hydrogen

clean:
	rm -f hydrogen.o hydrogen
