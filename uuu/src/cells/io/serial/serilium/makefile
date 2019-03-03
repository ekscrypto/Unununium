# $Header: /cvsroot/uuu/uuu/src/cells/io/serial/serilium/makefile,v 1.3 2001/12/09 19:37:51 instinc Exp $

INCS = \
	macros.inc \
	error_codes.inc

serilium: serilium.o
	$(ELF2UBF) $(E2UFLAGS) serilium.o serilium

serilium.o: serilium.asm $(INCS) makefile
	$(AS) -f elf serilium.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/serilium

$(CELL_INST_DIR)/serilium: serilium
	cp serilium $(CELL_INST_DIR)/serilium

clean:
	rm -f serilium.o serilium
