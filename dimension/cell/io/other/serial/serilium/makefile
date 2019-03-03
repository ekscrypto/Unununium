# $Header: /cvsroot/uuu/dimension/cell/io/other/serial/serilium/makefile,v 1.1.1.1 2002/01/17 04:31:18 instinc Exp $

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
