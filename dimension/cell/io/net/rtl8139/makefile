# $Header: /cvsroot/uuu/dimension/cell/io/net/rtl8139/makefile,v 1.1 2003/09/01 16:24:29 blackmilk Exp $

INCS = \
	macros.inc \
	errors.inc \
	vid/mem.inc \
	vid/sys_log.inc \
	vid/int.inc \
        vid/rtl8139.inc \
	vid/debug.diable.inc \
	sys_log.inc

rtl8139: rtl8139.o
	$(ELF2UBF) $(E2UFLAGS) rtl8139.o rtl8139

rtl8139.o: rtl8139.asm $(INCS) makefile
	$(AS) -f elf rtl8139.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/sb16

$(CELL_INST_DIR)/rtl8139: rtl8139
	cp irony $(CELL_INST_DIR)/rtl8139

clean:
	rm -f rtl8139.o rtl8139
