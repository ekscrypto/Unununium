# $Header: /cvsroot/uuu/dimension/app/shell/ish/makefile,v 1.1.1.1 2002/01/17 04:30:55 instinc Exp $

INCS = \
	vid/realmode.inc \
	vid/kbd.inc \
	vid/lib.string.inc \
	vid/mem.inc \
	vid/process.inc \
	vid/sys_log.inc \
	sys_log.inc \
	vid/void.inc \
	vid/vfs.inc \
	vid/lib.term.inc \
	vid/lib.env.inc \
	vid/debug.ehex.inc \
	process.inc \
	fs/fs.inc \
	vid/debug.diable.inc \
	vid/thread.inc \
	macros.inc \
	errors.inc


ish: ish.o
	$(ELF2UBF) $(E2UFLAGS) ish.o ish

ish.o: ish.asm $(INCS)
	$(AS) -f elf ish.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

clean:
	rm -f ish.o ish

install: $(APP_INST_DIR)/ish

$(APP_INST_DIR)/ish: ish
	cp ish $(APP_INST_DIR)
	chmod a+x $(APP_INST_DIR)/ish
