# $Header: /cvsroot/uuu/uuu/src/cells/video/drivers/VGA/makefile,v 1.3 2001/12/10 18:48:21 instinc Exp $

INCS = \
       macros.inc \
       error_codes.inc \
       vid/realmode.inc \
       vid/video.inc

vga: VGA.o
	$(ELF2UBF) $(E2UFLAGS) VGA.o vga

VGA.o: VGA.asm $(INCS) makefile
	$(AS) -f elf VGA.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/vga

$(CELL_INST_DIR)/vga: vga
	cp vga $(CELL_INST_DIR)/vga

clean:
	rm -f VGA.o vga
