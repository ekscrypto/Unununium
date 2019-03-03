# $Header: /cvsroot/uuu/uuu/src/cells/idt_irq/potassium/makefile,v 1.6 2001/12/09 17:12:20 instinc Exp $

INCS = \
	macros.inc \
	error_codes.inc \
	vid/mem.inc \
	vid/gdt.inc \
	vid/int.inc \
	vid/ics.inc

potassium: potassium.o
	$(ELF2UBF) $(E2UFLAGS) potassium.o potassium

potassium.o: potassium.asm $(INCS) makefile
	$(AS) -f elf potassium.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/potassium

$(CELL_INST_DIR)/potassium: potassium
	cp potassium $(CELL_INST_DIR)/potassium

clean:
	rm -f potassium.o potassium
