# $Header: /cvsroot/uuu/dimension/app/base/ps/makefile,v 1.1.1.1 2002/01/17 04:30:55 instinc Exp $

INCS = \
	process.inc \
	fs/fs.inc \
	vid/lib.string.inc \
	vid/process.inc \
	macros.inc

ps: ps.o
	$(ELF2UBF) $(E2UFLAGS) ps.o ps

ps.o: ps.asm $(INCS) makefile
	$(AS) -f elf ps.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

clean:
	rm -f ps.o ps

install: $(APP_INST_DIR)/ps

$(APP_INST_DIR)/ps: ps
	cp ps $(APP_INST_DIR)
	chmod a+x $(APP_INST_DIR)/ps
