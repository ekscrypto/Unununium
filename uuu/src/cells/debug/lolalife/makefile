# $Header: /cvsroot/uuu/uuu/src/cells/debug/lolalife/makefile,v 1.3 2001/12/09 16:21:46 instinc Exp $

INCS = \
       macros.inc \
       error_codes.inc

lolalife: lolalife.o
	$(ELF2UBF) $(E2UFLAGS) lolalife.o lolalife

lolalife.o: lolalife.asm $(INCS)
	$(AS) -f elf lolalife.asm -p macros.inc -p error_codes.inc $(ASFLAGS)

.PHONY: clean install

install: $(CELL_INST_DIR)/lolalife

$(CELL_INST_DIR)/lolalife: lolalife
	cp lolalife $(CELL_INST_DIR)/lolalife

clean:
	rm -f lolalife.o lolalife
