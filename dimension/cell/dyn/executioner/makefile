# $Header: /cvsroot/uuu/dimension/cell/dyn/executioner/makefile,v 1.1.1.1 2002/01/17 04:31:05 instinc Exp $

INCS = \
	macros.inc \
	errors.inc \
	fs/fs.inc \
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
	vid/file.inc \
	vid/debug.diable.inc

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
