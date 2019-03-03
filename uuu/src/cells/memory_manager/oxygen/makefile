# $Header: /cvsroot/uuu/uuu/src/cells/memory_manager/oxygen/makefile,v 1.11 2001/12/10 21:05:29 daboy Exp $

.PHONY: clean install

INCS = \
oxygen.def \
oxygen.mac \
hdr_core.inc \
macros.inc \
error_codes.inc \
vid/mem.inc \
vid/debug.diable.inc

oxygen: oxygen.o
	$(ELF2UBF) $(E2UFLAGS) oxygen.o oxygen

oxygen.o: oxygen.asm $(INCS) portal.bin makefile
	$(AS) -f elf oxygen.asm $(addprefix -p,$(INCS)) $(ASFLAGS)

portal.bin: portal.inc
	$(AS) -f bin portal.inc -o portal.bin $(ASFLAGS)

install: $(CELL_INST_DIR)/oxygen

$(CELL_INST_DIR)/oxygen: oxygen
	cp oxygen $(CELL_INST_DIR)

clean:
	rm -rf *.o oxygen
