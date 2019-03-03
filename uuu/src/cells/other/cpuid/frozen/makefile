# $Header: /cvsroot/uuu/uuu/src/cells/other/cpuid/frozen/makefile,v 1.3 2001/12/10 16:22:21 instinc Exp $

INCS = \
	macros.inc \
	error_codes.inc \
	vid/cpu.inc \
	vid/sys_log.inc \
	define.def

frozen: frozen.o
	$(ELF2UBF) $(E2UFLAGS) frozen.o frozen

frozen.o: frozen.asm $(INCS) makefile
	$(AS) -f elf frozen.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/frozen

$(CELL_INST_DIR)/frozen: frozen
	cp frozen $(CELL_INST_DIR)/frozen

clean:
	rm -f frozen.o frozen
