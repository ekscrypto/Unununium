# $Header: /cvsroot/uuu/dimension/cell/debug/lanthane/makefile,v 1.1.1.1 2002/01/17 04:31:00 instinc Exp $

INCS = \
       macros.inc \
       errors.inc \
       vid/lib.string.inc \
       vid/sys_log.inc \
       fs/fs.inc

lanthane: lanthane.o
	$(ELF2UBF) $(E2UFLAGS) lanthane.o lanthane

lanthane.o: lanthane.asm $(INCS)
	$(AS) -f elf lanthane.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/lanthane

$(CELL_INST_DIR)/lanthane: lanthane
	cp lanthane $(CELL_INST_DIR)/lanthane

clean:
	rm -f lanthane.o lanthane
