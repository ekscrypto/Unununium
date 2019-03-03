# $Header: /cvsroot/uuu/uuu/src/cells/dyn_link/executioner/makefile,v 1.4 2001/12/18 02:06:07 daboy Exp $

INCS = \
	macros.inc \
	error_codes.inc \
	ozone.inc \
	vid/vfs.inc \
	vid/mem.inc \
	vid/sys_log.inc \
	sys_log.inc \
	vid/debug.ehex.inc \
	vid/void.inc \
	vid/process.inc \
	vid/thread.inc \
	ubf.inc \
	process.inc \
	vid/file.inc

executioner: executioner.o
	$(ELF2UBF) $(E2UFLAGS) executioner.o executioner

executioner.o: executioner.asm $(INCS) makefile
	$(AS) -f elf executioner.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/executioner

$(CELL_INST_DIR)/executioner: executioner
	cp executioner $(CELL_INST_DIR)/executioner

clean:
	rm -f executioner.o executioner
