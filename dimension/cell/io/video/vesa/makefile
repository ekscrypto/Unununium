# $Header: /cvsroot/uuu/dimension/cell/io/video/vesa/makefile,v 1.1 2002/11/19 18:35:48 blackmilk Exp $

INCS = \
       macros.inc \
       errors.inc \
       sys_log.inc \
       vid/realmode.inc \
       vid/video.inc \
       vid/sys_log.inc \
       vid/mem.inc

vesa: vesa.o
	$(ELF2UBF) $(E2UFLAGS) vesa.o vesa

vesa.o: vesa.asm $(INCS) makefile
	$(AS) -f elf vesa.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/vesa

$(CELL_INST_DIR)/vbe3: vesa
	cp vesa $(CELL_INST_DIR)/vesa

clean:
	rm -f vesa.o vesa
