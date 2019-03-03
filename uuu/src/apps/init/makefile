# $Header: /cvsroot/uuu/uuu/src/apps/init/makefile,v 1.3 2001/12/15 19:59:38 instinc Exp $

INCS = \
	   vid/mem.inc \
	   macros.inc \
	   error_codes.inc \
	   sys_log.inc \
	   init.inc

init: init.o
	elf2ubf init.o init

init.o: init.asm $(INCS) makefile
	$(AS) -f elf init.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(APP_INST_DIR)/init

$(APP_INST_DIR)/init: init
	cp init $(APP_INST_DIR)/init

clean:
	rm -f init.o init
