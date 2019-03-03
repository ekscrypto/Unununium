# $Header: /cvsroot/uuu/uuu/src/apps/ps/makefile,v 1.1 2001/12/18 01:39:41 daboy Exp $

ps: ps.o
	$(ELF2UBF) $(E2UFLAGS) ps.o ps

ps.o: ps.asm macros.inc
	$(AS) -f elf ps.asm $(ASFLAGS) -p macros.inc

.PHONY: clean install

clean:
	rm -f *.o ps

install: $(APP_INST_DIR)/ps

$(APP_INST_DIR)/ps: ps
	cp ps $(APP_INST_DIR)
	chmod a+x $(APP_INST_DIR)/ps
