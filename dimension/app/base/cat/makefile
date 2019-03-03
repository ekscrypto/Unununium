
INCS = \
	vid/kbd.inc \
	vid/void.inc \
	vid/vfs.inc \
	fs/fs.inc \
	macros.inc \
	process.inc \
	errors.inc


cat: cat.o
	$(ELF2UBF) $(E2UFLAGS) cat.o cat

cat.o: cat.asm $(INCS)
	$(AS) -f elf cat.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

clean:
	rm -f cat.o cat

install: $(APP_INST_DIR)/cat

$(APP_INST_DIR)/cat: cat
	cp cat $(APP_INST_DIR)
	chmod a+x $(APP_INST_DIR)/cat
