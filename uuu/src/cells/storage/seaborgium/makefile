# $Header: /cvsroot/uuu/uuu/src/cells/storage/seaborgium/makefile,v 1.4 2001/12/10 16:58:01 instinc Exp $

INCS = \
	ozone.inc \
	macros.inc \
	error_codes.inc \
	vid/mem.inc \
	vid/sys_log.inc \
	vid/devfs.inc

seaborgium: seaborgium.o
	$(ELF2UBF) $(E2UFLAGS) seaborgium.o seaborgium

seaborgium.o: seaborgium.asm $(INCS) makefile
	$(AS) -f elf seaborgium.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/seaborgium

$(CELL_INST_DIR)/seaborgium: seaborgium
	cp seaborgium $(CELL_INST_DIR)/seaborgium

clean:
	rm -f seaborgium.o seaborgium
