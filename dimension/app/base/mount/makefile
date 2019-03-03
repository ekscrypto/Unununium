
INCS = \
	vid/void.inc \
	vid/vfs.inc \
	fs/fs.inc \
	macros.inc \
	process.inc \
	errors.inc


mount: mount.o
	$(ELF2UBF) $(E2UFLAGS) mount.o mount

mount.o: mount.asm $(INCS)
	$(AS) -f elf mount.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

clean:
	rm -f mount.o mount

install: $(APP_INST_DIR)/mount

$(APP_INST_DIR)/mount: mount
	cp mount $(APP_INST_DIR)
	chmod a+x $(APP_INST_DIR)/mount
