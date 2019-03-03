# $Header: /cvsroot/uuu/uuu/src/cells/jit/hydrogen/makefile,v 1.10 2001/12/09 20:10:38 instinc Exp $

INCS = \
	macros.inc \
	error_codes.inc \
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
