# $Header: /cvsroot/uuu/uuu/src/cells/3d/hydro3d/makefile,v 1.4 2001/12/09 16:39:47 instinc Exp $

INCS = \
       macros.inc

hydro3d: hydro3d.o
	$(ELF2UBF) $(E2UFLAGS) hydro3d.o hydro3d

hydro3d.o: hydro3d.asm hydro3d.inc $(INCS)
	$(AS) -f elf hydro3d.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/hydro3d

$(CELL_INST_DIR)/hydro3d: hydro3d
	cp hydro3d $(CELL_INST_DIR)/hydro3d

clean:
	rm -f hydro3d.o hydro3d
