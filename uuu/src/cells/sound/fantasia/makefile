# $Header: /cvsroot/uuu/uuu/src/cells/sound/fantasia/makefile,v 1.3 2001/12/10 16:34:07 instinc Exp $

INCS = \
	macros.inc

fantasia: fantasia.o
	$(ELF2UBF) $(E2UFLAGS) fantasia.o fantasia

fantasia.o: fantasia.asm $(INCS) makefile
	$(AS) -f elf fantasia.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/fantasia

$(CELL_INST_DIR)/fantasia: fantasia
	cp fantasia $(CELL_INST_DIR)/fantasia

clean:
	rm -f fantasia.o fantasia
