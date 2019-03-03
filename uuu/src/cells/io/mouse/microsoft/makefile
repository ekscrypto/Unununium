# $Header: /cvsroot/uuu/uuu/src/cells/io/mouse/microsoft/makefile,v 1.3 2001/12/09 17:52:32 instinc Exp $

INCS = \
	macros.inc \
	error_codes.inc

mouse_ms: microsoft.o
	$(ELF2UBF) $(E2UFLAGS) microsoft.o mouse_ms

microsoft.o: microsoft.asm $(INCS) makefile
	$(AS) -f elf microsoft.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/mouse_ms

$(CELL_INST_DIR)/mouse_ms: mouse_ms
	cp mouse_ms $(CELL_INST_DIR)/mouse_ms

clean:
	rm -f microsoft.o mouse_ms
