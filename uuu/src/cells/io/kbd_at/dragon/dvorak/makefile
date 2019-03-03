# $Header: /cvsroot/uuu/uuu/src/cells/io/kbd_at/dragon/dvorak/makefile,v 1.2 2001/12/09 17:37:47 instinc Exp $


INCS = \
	macros.inc \
	vid/kbd.inc

kbd_dvorak: dvorak.o
	$(ELF2UBF) $(E2UFLAGS) dvorak.o kbd_dvorak

dvorak.o: dvorak.asm $(INCS) makefile
	$(AS) -f elf dvorak.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/kbd_dvorak

$(CELL_INST_DIR)/kbd_dvorak: kbd_dvorak
	cp kbd_dvorak $(CELL_INST_DIR)/kbd_dvorak

clean:
	rm -f dvorak.o kbd_dvorak
