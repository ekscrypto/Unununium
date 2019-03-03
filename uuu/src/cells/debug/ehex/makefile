# $Header: /cvsroot/uuu/uuu/src/cells/debug/ehex/makefile,v 1.4 2001/12/09 16:10:46 instinc Exp $

SCR = \
       scr/help.scr \
       scr/closing.scr \
       scr/edition.scr \
       scr/opening.scr

INCS = \
       macros.inc \
       error_codes.inc

ehex: ehex.o
	$(ELF2UBF) $(E2UFLAGS) ehex.o ehex

ehex.o: ehex.asm makefile $(INCS) $(SCR)
	$(AS) -f elf ehex.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/ehex

$(CELL_INST_DIR)/ehex: ehex
	cp ehex $(CELL_INST_DIR)/ehex

clean:
	rm -f ehex.o ehex
