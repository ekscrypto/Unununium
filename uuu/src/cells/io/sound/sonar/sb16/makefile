# $Header: /cvsroot/uuu/uuu/src/cells/io/sound/sonar/sb16/makefile,v 1.1 2001/12/31 12:37:55 lukas2000 Exp $

INCS = \
	macros.inc \
	error_codes.inc \
	ozone.inc \
	vid/mem.inc \
	vid/sys_log.inc \
	vid/devfs.inc \
	vid/int.inc \
	vid/debug.diable.inc \
	sys_log.inc

sb16: sb16.o
	$(ELF2UBF) $(E2UFLAGS) sb16.o sb16

sb16.o: sb16.asm $(INCS) makefile
	$(AS) -f elf sb16.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/sb16

$(CELL_INST_DIR)/sb16: sb16
	cp irony $(CELL_INST_DIR)/sb16

clean:
	rm -f sb16.o sb16
