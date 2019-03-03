# $Header: /cvsroot/uuu/uuu/src/cells/debug/yttrium/makefile,v 1.4 2001/12/09 16:18:32 instinc Exp $

INCS = \
       macros.inc \
       error_codes.inc

yttrium: yttrium.o
	$(ELF2UBF) $(E2UFLAGS) yttrium.o yttrium

yttrium.o: yttrium.asm font.inc $(INCS)
	$(AS) -f elf yttrium.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/yttrium

$(CELL_INST_DIR)/yttrium: yttrium
	cp yttrium $(CELL_INST_DIR)/yttrium

clean:
	rm -f yttrium.o yttrium
