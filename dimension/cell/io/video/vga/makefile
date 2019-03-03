# $Header: /cvsroot/uuu/dimension/cell/io/video/vga/makefile,v 1.1.1.1 2002/01/17 04:31:26 instinc Exp $

INCS = \
       macros.inc \
       errors.inc \
       vid/realmode.inc \
       vid/video.inc

vga: vga.o
	$(ELF2UBF) $(E2UFLAGS) vga.o vga

vga.o: vga.asm $(INCS) makefile
	$(AS) -f elf vga.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/vga

$(CELL_INST_DIR)/vga: vga
	cp vga $(CELL_INST_DIR)/vga

clean:
	rm -f vga.o vga
