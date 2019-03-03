# $Header: /cvsroot/uuu/dimension/cell/comm/helium/makefile,v 1.1.1.1 2002/01/17 04:31:31 instinc Exp $

INCS = \
       macros.inc \
       errors.inc \
       vid/ics.inc \
       vid/mem.fixed.inc \
       vid/sys_log.inc

helium: helium.o
	$(ELF2UBF) $(E2UFLAGS) helium.o helium

helium.o: helium.asm $(INCS) makefile
	$(AS) -f elf helium.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/helium

$(CELL_INST_DIR)/helium: helium
	cp helium $(CELL_INST_DIR)/helium

clean:
	rm -f helium.o helium
