# $Header: /cvsroot/uuu/uuu/src/cells/video/display_manager/silicium/makefile,v 1.6 2002/01/11 20:57:10 daboy Exp $

INCS = \
	macros.inc \
	error_codes.inc \
	vid/screen.inc \
	vid/mem.inc \
	vid/realmode.inc \
	vid/sys_log.inc \
	vid/console.inc

silicium: silicium.o
	$(ELF2UBF) $(E2UFLAGS) silicium.o silicium

silicium.o: silicium.asm $(INCS) makefile
	$(AS) -f elf silicium.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/silicium

$(CELL_INST_DIR)/silicium: silicium
	cp silicium $(CELL_INST_DIR)/silicium

clean:
	rm -f silicium.o silicium
