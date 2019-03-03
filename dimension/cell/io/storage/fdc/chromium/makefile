# $Header: /cvsroot/uuu/dimension/cell/io/storage/fdc/chromium/makefile,v 1.1.1.1 2002/01/17 04:31:21 instinc Exp $

INCS = \
	macros.inc \
	errors.inc \
	fs/fs.inc \
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
