# $Header: /cvsroot/uuu/uuu/src/cells/io/fdc/chromium/makefile,v 1.3 2001/12/09 17:23:33 instinc Exp $

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

chromium: chromium.o
	$(ELF2UBF) $(E2UFLAGS) chromium.o chromium

chromium.o: chromium.asm $(INCS) makefile
	$(AS) -f elf chromium.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/chromium

$(CELL_INST_DIR)/chromium: chromium
	cp chromium $(CELL_INST_DIR)/chromium

clean:
	rm -f chromium.o chromium
