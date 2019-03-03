# $Header: /cvsroot/uuu/uuu/src/cells/fs/devfs/makefile,v 1.5 2001/12/09 16:56:23 instinc Exp $

INCS = \
       ozone.inc \
       error_codes.inc \
       macros.inc \
       vid/devfs.inc \
       vid/vfs.inc \
       vid/sys_log.inc \
       sys_log.inc \
       vid/mem.inc \
       vid/lib.string.inc \
       vid/debug.ehex.inc

devfs: devfs.o
	$(ELF2UBF) $(E2UFLAGS) devfs.o devfs

devfs.o: devfs.asm $(INCS) makefile
	$(AS) -f elf devfs.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/devfs

$(CELL_INST_DIR)/devfs: devfs
	cp devfs $(CELL_INST_DIR)/devfs

clean:
	rm -f devfs.o devfs
