# $Header: /cvsroot/uuu/uuu/src/cells/bus/pci/kerosen/makefile,v 1.3 2001/12/09 16:42:06 instinc Exp $

INCS = \
       macros.inc \
       error_codes.inc

kerosen: kerosen.o
	$(ELF2UBF) $(E2UFLAGS) kerosen.o kerosen

kerosen.o: kerosen.asm $(INCS)
	$(AS) -f elf kerosen.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/kerosen

$(CELL_INST_DIR)/kerosen: kerosen
	cp kerosen $(CELL_INST_DIR)/kerosen

clean:
	rm -f kerosen.o kerosen
