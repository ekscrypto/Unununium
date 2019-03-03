# $Header: /cvsroot/uuu/uuu/src/cells/debug/lanthane/makefile,v 1.3 2001/12/09 16:15:48 instinc Exp $

INCS = \
       macros.inc \
       error_codes.inc

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
