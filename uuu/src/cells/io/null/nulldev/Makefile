# $Header: /cvsroot/uuu/uuu/src/cells/io/null/nulldev/Makefile,v 1.2 2001/12/09 18:02:05 instinc Exp $

INCS = \
	macros.inc \
	error_codes.inc \
	vid/devfs.inc \
	vid/sys_log.inc \
	vid/debug.diable.inc \
	vid/mem.inc \
	ozone.inc

nulldev: nulldev.o
	$(ELF2UBF) $(E2UFLAGS) nulldev.o nulldev

nulldev.o: nulldev.asm $(INCS) Makefile
	$(AS) -f elf nulldev.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/nulldev

$(CELL_INST_DIR)/nulldev: nulldev
	cp nulldev $(CELL_INST_DIR)/nulldev

clean:
	rm -f nulldev.o nulldev
