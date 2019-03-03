# $Header: /cvsroot/uuu/uuu/src/cells/io/console/silver/Makefile,v 1.4 2001/12/19 02:25:42 daboy Exp $

INCS = \
	vid/sys_log.inc \
	sys_log.inc \
	error_codes.inc \
	macros.inc \
	ozone.inc \
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

silver.o: silver.asm $(INCS) Makefile
	$(AS) -f elf silver.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/silver

$(CELL_INST_DIR)/silver: silver
	cp silver $(CELL_INST_DIR)/silver

clean:
	rm -f silver.o silver
