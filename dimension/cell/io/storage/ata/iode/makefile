# $Header: /cvsroot/uuu/dimension/cell/io/storage/ata/iode/makefile,v 1.3 2003/01/14 22:13:31 myselph Exp $

INCS = \
	macros.inc \
	errors.inc \
	fs/fs.inc \
	vid/mem.inc \
	vid/sys_log.inc \
	vid/devfs.inc \
	vid/int.inc \
	vid/debug.diable.inc \
	vid/part.inc \
	sys_log.inc

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
