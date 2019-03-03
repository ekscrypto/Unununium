# $Header: /cvsroot/uuu/uuu/src/cells/io/kbd_at/dragon/makefile,v 1.3 2001/12/09 17:34:15 instinc Exp $

INCS = \
	macros.inc \
	error_codes.inc \
	vid/int.inc \
	vid/kbd.inc

dragon: dragon.o
	$(ELF2UBF) $(E2UFLAGS) dragon.o dragon

dragon.o: dragon.asm $(INCS) makefile
	$(AS) -f elf dragon.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/dragon

$(CELL_INST_DIR)/dragon: dragon
	cp dragon $(CELL_INST_DIR)/dragon

clean:
	rm -f dragon.o dragon
