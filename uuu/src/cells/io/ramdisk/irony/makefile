# $Header: /cvsroot/uuu/uuu/src/cells/io/ramdisk/irony/makefile,v 1.1 2001/12/27 09:28:33 lukas2000 Exp $

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

irony: irony.o
	$(ELF2UBF) $(E2UFLAGS) irony.o irony

irony.o: irony.asm $(INCS) makefile
	$(AS) -f elf irony.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/irony

$(CELL_INST_DIR)/irony: irony
	cp irony $(CELL_INST_DIR)/irony

clean:
	rm -f irony.o irony
