# $Header: /cvsroot/uuu/existence/cells/other/iridia/makefile,v 1.4 2003/01/12 03:21:10 instinc Exp $

INCS = \
	macros.inc \
	errors.inc \
	vid/int.inc \
	vid/irq.inc \
	thread.inc

iridia: iridia.o
	$(ELF2UBF) $(E2UFLAGS) iridia.o iridia

iridia.o: iridia.asm $(INCS) makefile
	$(AS) -f elf iridia.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/iridia

$(CELL_INST_DIR)/iridia: iridia
	cp iridia $(CELL_INST_DIR)/iridia

clean:
	rm -f iridia.o iridia
