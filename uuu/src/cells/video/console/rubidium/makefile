# $Header: /cvsroot/uuu/uuu/src/cells/video/console/rubidium/makefile,v 1.2 2001/12/10 18:18:07 instinc Exp $

INCS = \
	macros.inc \
	error_codes.inc \
	vid/console.inc \
	vid/mem.inc \
	vid/mem.fixed.inc 

rubidium: rubidium.o
	$(ELF2UBF) $(E2UFLAGS) rubidium.o rubidium

rubidium.o: rubidium.asm $(INCS) makefile
	$(AS) -f elf rubidium.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/rubidium

$(CELL_INST_DIR)/rubidium: rubidium
	cp rubidium $(CELL_INST_DIR)/rubidium

clean:
	rm -f rubidium.o rubidium
