# $Header: /cvsroot/uuu/dimension/cell/io/ui/kb/lang/english/makefile,v 1.1.1.1 2002/01/17 04:31:25 instinc Exp $

INCS = \
	macros.inc \
	vid/kbd.inc

kbd_english: english.o
	$(ELF2UBF) $(E2UFLAGS) english.o kbd_english

english.o: english.asm $(INCS) makefile
	$(AS) -f elf english.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/kbd_english

$(CELL_INST_DIR)/kbd_english: kbd_english
	cp kbd_english $(CELL_INST_DIR)/kbd_english

clean:
	rm -f english.o kbd_english
