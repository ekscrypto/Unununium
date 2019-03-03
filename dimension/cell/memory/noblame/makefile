# $Header: /cvsroot/uuu/dimension/cell/memory/noblame/makefile,v 1.1.1.1 2002/01/17 04:31:13 instinc Exp $

INCS =\
	macros.inc \
	error_codes.inc \
	hdr_core.inc \
	vid/mem.inc

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
