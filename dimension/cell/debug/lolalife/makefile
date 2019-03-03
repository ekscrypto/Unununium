# $Header: /cvsroot/uuu/dimension/cell/debug/lolalife/makefile,v 1.1.1.1 2002/01/17 04:31:01 instinc Exp $

INCS = \
       macros.inc \
       errors.inc \
       vid/int.inc

lolalife: lolalife.o
	$(ELF2UBF) $(E2UFLAGS) lolalife.o lolalife

lolalife.o: lolalife.asm $(INCS) makefile
	$(AS) -f elf lolalife.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/lolalife

$(CELL_INST_DIR)/lolalife: lolalife
	cp lolalife $(CELL_INST_DIR)/lolalife

clean:
	rm -f lolalife.o lolalife
