# $Header: /cvsroot/uuu/dimension/cell/io/ui/mouse/ps2/makefile,v 1.1.1.1 2002/01/17 04:31:23 instinc Exp $

INCS = \
	macros.inc \
	error_codes.inc \
	vid/kbd.inc \
	vid/int.inc \
	vid/pd0.inc \
	vid/pd1.inc \
	vid/sys_log.inc

mouse_ps2: ps2.o
	$(ELF2UBF) $(E2UFLAGS) ps2.o mouse_ps2

ps2.o: ps2.asm $(INCS) makefile
	$(AS) -f elf ps2.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/mouse_ps2

$(CELL_INST_DIR)/mouse_ps2: mouse_ps2
	cp mouse_ps2 $(CELL_INST_DIR)/mouse_ps2

clean:
	rm -f ps2.o mouse_ps2
