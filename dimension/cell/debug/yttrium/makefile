# $Header: /cvsroot/uuu/dimension/cell/debug/yttrium/makefile,v 1.2 2002/01/27 07:17:35 instinc Exp $

INCS = \
       macros.inc \
       errors.inc \
       vid/sys_log.inc \
       vid/mem.inc \
       vid/debug.diable.inc \
       vid/debug.gfx.inc \
       vid/debug.bochs.inc \
       vid/lib.string.inc

yttrium: yttrium.o
	$(ELF2UBF) $(E2UFLAGS) yttrium.o yttrium

yttrium.o: yttrium.asm font.inc $(INCS)
	$(AS) -f elf yttrium.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/yttrium

$(CELL_INST_DIR)/yttrium: yttrium
	cp yttrium $(CELL_INST_DIR)/yttrium

clean:
	rm -f yttrium.o yttrium
