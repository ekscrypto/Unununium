# $Header: /cvsroot/uuu/dimension/cell/io/bus/pci/erode/makefile,v 1.2 2002/08/27 01:39:05 instinc Exp $

INCS = \
       macros.inc \
       errors.inc \
       vid/bios32.inc \
       vid/gdt.inc \
       vid/pci.inc \
       vid/sys_log.inc \
       vid/debug.diable.inc

erode: erode.o
	$(ELF2UBF) $(E2UFLAGS) erode.o erode

erode.o: erode.asm $(INCS) makefile
	$(AS) -f elf erode.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/erode

$(CELL_INST_DIR)/erode: erode
	cp erode $(CELL_INST_DIR)/erode

clean:
	rm -f erode.o erode
