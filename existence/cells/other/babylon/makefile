# $Header: /cvsroot/uuu/existence/cells/other/babylon/makefile,v 1.1 2003/01/12 03:25:11 instinc Exp $

INCS = \
  	macros.inc \
	vid/rp.inc \
	thread.inc

babylon: babylon.o
	$(ELF2UBF) $(E2UFLAGS) babylon.o babylon

babylon.o: babylon.asm $(INCS) makefile
	$(AS) -f elf babylon.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/babylon

$(CELL_INST_DIR)/babylon: babylon
	cp babylon $(CELL_INST_DIR)/babylon

clean:
	rm -f babylon.o babylon
