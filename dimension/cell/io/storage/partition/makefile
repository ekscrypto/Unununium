
INCS = \
	macros.inc \
	errors.inc \
	fs/fs.inc \
	vid/part.inc \
	vid/mem.inc \
	vid/sys_log.inc \
	vid/lib.string.inc \
	vid/devfs.inc \
	vid/int.inc \
	vid/vfs.inc \
	vid/part.inc \
	vid/debug.diable.inc \
	sys_log.inc

partition: partition.o
	$(ELF2UBF) $(E2UFLAGS) partition.o partition

partition.o: partition.asm $(INCS) makefile
	$(AS) -f elf partition.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/partition

$(CELL_INST_DIR)/partition: partition
	cp partition $(CELL_INST_DIR)/partition

clean:
	rm -f partition.o partition
