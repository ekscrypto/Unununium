# $Header: /cvsroot/uuu/dimension/cell/io/ui/kb/dragon/makefile,v 1.1.1.1 2002/01/17 04:31:26 instinc Exp $

INCS = \
	macros.inc \
	errors.inc \
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
