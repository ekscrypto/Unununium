# $Header: /cvsroot/uuu/uuu/src/apps/log_browser/makefile,v 1.4 2001/11/01 00:53:32 daboy Exp $

log_browser: log_browser.o
	$(ELF2UBF) $(E2UFLAGS) log_browser.o log_browser

log_browser.o: log_browser.asm macros.inc
	$(AS) -f elf log_browser.asm $(ASFLAGS) -p macros.inc

.PHONY: clean install

clean:
	rm -f *.o log_browser

install: $(APP_INST_DIR)/log_browser

$(APP_INST_DIR)/log_browser: log_browser
	cp log_browser $(APP_INST_DIR)
