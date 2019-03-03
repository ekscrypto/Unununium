NASM = nasm
NASMFLAGS = -w+orphan-labels -w+number-overflow -w+macro-params -w+macro-selfref

U3L = u3l
U3LFLAGS = --offset=00008000 --abort-on-warning --generate-fid-listing u3core.bin

CELLS = memory_manager/oxygen idt_irq/potassium jit/hydrogen realmode/calcium debug/diable
CELLDIR = ../../src/cells/

.PHONY: all $(CELLS) clean

all: boot
	@echo Congratulations, you have built something no C programer would dream of :P
	@echo \`make install\' to install Uuu on a floppy.

boot: boot.asm u3core.bin
	$(NASM) -f bin boot.asm $(NASMFLAGS)

u3core.bin: $(CELLS) osw.o
	$(U3L) +osw.o $(addprefix +$(CELLDIR),$(join $(CELLS),$(addprefix /,$(addsuffix .o,$(notdir $(CELLS)))))) $(U3LFLAGS)

$(CELLS):
	@$(MAKE) -C $(CELLDIR)$@

osw.o: osw.asm
	$(NASM) -f elf osw.asm $(NASMFLAGS)

clean:
	rm -f u3core.bin *.o boot functions.txt
	@$(foreach dir,$(CELLS),$(MAKE) -C $(CELLDIR) -C $(dir) clean;)

install: boot
	@echo "make: copying system image on first floppy drive"
	@if [ -w /dev/fd0 ]; then dd if=boot of=/dev/fd0 bs=512; \
	elif [ -w /dev/floppy/0 ]; then dd if=boot of=/dev/floppy/0 bs=512; \
	elif [ -w /dev/disk/floppy/raw] ; then dd if=boot of=/dev/disk/floppy/raw bs=512; \
	elif [ -w /dev/rfd0c ]; then dd if=boot of=/dev/rfd0c bs=512; \
	else echo 'No writeable floppy drive found'; exit 1; \
	fi;
	@echo "make: image succesfully created."
