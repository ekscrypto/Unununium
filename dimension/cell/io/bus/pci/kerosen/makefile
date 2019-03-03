# $Header: /cvsroot/uuu/dimension/cell/io/bus/pci/kerosen/makefile,v 1.1.1.1 2002/01/17 04:31:17 instinc Exp $

INCS = \
       macros.inc \
       error_codes.inc \
       vid/bios32.inc \
       vid/gdt.inc \
       vid/pci.inc \
       vid/sys_log.inc \
       vid/debug.diable.inc

kerosen: kerosen.o
	$(ELF2UBF) $(E2UFLAGS) kerosen.o kerosen

kerosen.o: kerosen.asm $(INCS) makefile
	$(AS) -f elf kerosen.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/kerosen

$(CELL_INST_DIR)/kerosen: kerosen
	cp kerosen $(CELL_INST_DIR)/kerosen

clean:
	rm -f kerosen.o kerosen
