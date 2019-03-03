# $Header: /cvsroot/uuu/uuu/src/cells/io/ide/iode/makefile,v 1.4 2001/12/09 17:28:47 instinc Exp $

INCS = \
	ozone.inc \
	vid/mem.inc \
	vid/sys_log.inc \
	vid/devfs.inc \
	macros.inc \
	error_codes.inc

iode: iode.o
	$(ELF2UBF) $(E2UFLAGS) iode.o iode

iode.o: iode.asm $(INCS) makefile
	$(AS) -f elf iode.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/iode

$(CELL_INST_DIR)/iode: iode
	cp iode $(CELL_INST_DIR)/iode

clean:
	rm -f iode.o iode
