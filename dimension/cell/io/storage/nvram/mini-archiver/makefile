# $Header: /cvsroot/uuu/dimension/cell/io/storage/nvram/mini-archiver/makefile,v 1.1.1.1 2002/01/17 04:31:22 instinc Exp $

INCS = \
	macros.inc \
	error_codes.inc \
	vid/devfs.inc \
	vid/sys_log.inc \
	vid/debug.diable.inc \
	vid/mem.inc \
	ozone.inc

mini-archiver: mini-archiver.o
	$(ELF2UBF) $(E2UFLAGS) mini-archiver.o mini-archiver

mini-archiver.o: mini-archiver.asm $(INCS) makefile
	$(AS) -f elf mini-archiver.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/mini-archiver

$(CELL_INST_DIR)/mini-archiver: mini-archiver
	cp mini-archiver $(CELL_INST_DIR)/mini-archiver

clean:
	rm -f mini-archiver.o mini-archiver
