# $Header: /cvsroot/uuu/uuu/src/apps/ls/makefile,v 1.3 2001/11/19 21:59:16 daboy Exp $

ls: ls.o
	$(ELF2UBF) $(E2UFLAGS) ls.o ls

ls.o: ls.asm macros.inc
	$(AS) -f elf ls.asm $(ASFLAGS) -p macros.inc

.PHONY: clean install

clean:
	rm -f *.o ls

install: $(APP_INST_DIR)/ls

$(APP_INST_DIR)/ls: ls
	cp ls $(APP_INST_DIR)
