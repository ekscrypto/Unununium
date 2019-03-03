# $Header: /cvsroot/uuu/dimension/app/base/memstat/makefile,v 1.1.1.1 2002/01/17 04:30:55 instinc Exp $

INCS = \
	vid/lib.string.inc \
	vid/mem.inc \
	process.inc \
	fs/fs.inc \
	macros.inc

memstat: memstat.o
	$(ELF2UBF) $(E2UFLAGS) memstat.o memstat

memstat.o: memstat.asm $(INCS) makefile
	$(AS) -f elf memstat.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

clean:
	rm -f memstat.o memstat

install: $(APP_INST_DIR)/memstat

$(APP_INST_DIR)/memstat: memstat
	cp memstat $(APP_INST_DIR)
	chmod a+x $(APP_INST_DIR)/memstat
