# $Header: /cvsroot/uuu/uuu/src/apps/memstat/makefile,v 1.1 2001/12/19 02:06:58 daboy Exp $

memstat: memstat.o
	$(ELF2UBF) $(E2UFLAGS) memstat.o memstat

memstat.o: memstat.asm macros.inc
	$(AS) -f elf memstat.asm $(ASFLAGS) -p macros.inc

.PHONY: clean install

clean:
	rm -f *.o memstat

install: $(APP_INST_DIR)/memstat

$(APP_INST_DIR)/memstat: memstat
	cp memstat $(APP_INST_DIR)
