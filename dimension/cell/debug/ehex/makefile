# $Header: /cvsroot/uuu/dimension/cell/debug/ehex/makefile,v 1.2 2002/10/07 00:19:28 raptor-32 Exp $

SCR = \
       scr/help.scr \
       scr/closing.scr \
       scr/edition.scr \
       scr/opening.scr

INCS = \
       macros.inc \
       errors.inc \
       vid/debug.ehex.inc

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
