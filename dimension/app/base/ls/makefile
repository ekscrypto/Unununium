# $Header: /cvsroot/uuu/dimension/app/base/ls/makefile,v 1.1.1.1 2002/01/17 04:30:55 instinc Exp $

INCS = \
	vid/vfs.inc \
	vid/lib.string.inc \
	vid/lib.app.inc \
	vid/process.inc \
	fs/fs.inc \
	process.inc \
	macros.inc

ls: ls.o
	$(ELF2UBF) $(E2UFLAGS) ls.o ls

ls.o: ls.asm $(INCS) makefile
	$(AS) -f elf ls.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

clean:
	rm -f ls.o ls

install: $(APP_INST_DIR)/ls

$(APP_INST_DIR)/ls: ls
	cp ls $(APP_INST_DIR)
	chmod a+x $(APP_INST_DIR)/ls
