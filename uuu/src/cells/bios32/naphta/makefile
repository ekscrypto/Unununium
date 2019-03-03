# $Header: /cvsroot/uuu/uuu/src/cells/bios32/naphta/makefile,v 1.3 2001/12/09 16:37:20 instinc Exp $

INCS = \
       macros.inc \
       error_codes.inc

naphta: naphta.o
	$(ELF2UBF) $(E2UFLAGS) naphta.o naphta

naphta.o: naphta.asm $(INCS)
	$(AS) -f elf naphta.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/naphta

$(CELL_INST_DIR)/naphta: naphta
	cp naphta $(CELL_INST_DIR)/naphta

clean:
	rm -f naphta.o naphta
