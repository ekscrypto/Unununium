# $Header: /cvsroot/uuu/uuu/src/cells/memory_manager/noblame/makefile,v 1.4 2001/12/10 16:03:11 instinc Exp $

INCS =\
	macros.inc \
	error_codes.inc \
	hdr_core.inc

noblame: noblame.o
	$(ELF2UBF) $(E2UFLAGS) noblame.o noblame

noblame.o: noblame.asm $(INCS) makefile
	$(AS) -f elf noblame.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/noblame

$(CELL_INST_DIR)/noblame: noblame
	cp noblame $(CELL_INST_DIR)/noblame

clean:
	rm -f *.o
