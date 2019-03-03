# $Header: /cvsroot/uuu/dimension/cell/console/silver/makefile,v 1.1.1.1 2002/01/17 04:31:27 instinc Exp $

INCS = \
	vid/sys_log.inc \
	sys_log.inc \
	errors.inc \
	macros.inc \
	fs/fs.inc \
	vid/devfs.inc \
	vid/realmode.inc \
	vid/sys_log.inc \
	vid/mem.inc \
	vid/screen.inc \
	vid/debug.diable.inc \
	vid/kbd.inc \
	vid/lib.string.inc \
	vid/terminal.inc \
	screen.inc \
	vid/timer.inc

silver: silver.o
	$(ELF2UBF) $(E2UFLAGS) silver.o silver

silver.o: silver.asm $(INCS) makefile
	$(AS) -f elf silver.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/silver

$(CELL_INST_DIR)/silver: silver
	cp silver $(CELL_INST_DIR)/silver

clean:
	rm -f silver.o silver
