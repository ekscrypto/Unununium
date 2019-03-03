# $Header: /cvsroot/uuu/uuu/distro/XGS/makefile,v 1.30 2001/10/26 17:18:04 daboy Exp $

INCPATH = $(CURDIR)/../../include/

AS = nasm
ASFLAGS = -w+orphan-labels -w+number-overflow -w+macro-params -w+macro-selfref $(addprefix -i,$(INCPATH))

U3L = u3l
U3LFLAGS = --offset=00008000 --abort-on-warning --generate-vid-listing u3core.bin --redefinition-allowed --generate-core-map

export AS ASFLAGS INCPATH	# export these for submakes to use
VPATH = $(INCPATH)		# look for missing files in the include dir
export VPATH

CELLS = \
memory_manager/noblame \
debug/bochs \
debug/yttrium \
debug/ehex \
memory_manager/meitnerium \
ics/helium \
idt_irq/potassium \
realmode/calcium \
debug/diable \
io/kbd_at/osmium io/kbd_at/languages/english_us io/kbd_at/scan2ndx/cicero \
3d/hydro3d

CELLDIR = ../../src/cells/

APPS = \
xgs_test \
log_browser \
games/boxed_in \
games/ttt

APPDIR = ../../src/apps/

.PHONY: all $(CELLS) clean

all: boot mboot
	@echo -e "\nCongratulations, you have built something no C programer could dream of :P\nmake install to install Uuu on a floppy.\n"

boot: ../../src/boot/eks_boot/boot.asm u3core.bin
	cp u3core.bin ../../src/boot/eks_boot/
	$(AS) -f bin ../../src/boot/eks_boot/boot.asm $(ASFLAGS)
	mv ../../src/boot/eks_boot/boot ./boot
	rm -f ../../src/boot/eks_boot/u3core.bin

mboot: ../../src/boot/berk_boot/boot.asm u3core.bin
	cp u3core.bin ../../src/boot/berk_boot/
	$(AS) -f bin ../../src/boot/berk_boot/boot.asm -DUUU $(ASFLAGS)
	mv ../../src/boot/berk_boot/boot ./mboot
	rm -f ../../src/boot/berk_boot/u3core.bin

u3core.bin: $(CELLS) $(APPS) osw.o test.o
	$(U3L) +osw.o $(addprefix +$(CELLDIR),$(join $(CELLS),$(addprefix /,$(addsuffix .o,$(notdir $(CELLS)))))) +test.o $(U3LFLAGS) $(addprefix +$(APPDIR),$(join $(APPS),$(addprefix /,$(addsuffix .o,$(notdir $(APPS))))))

$(CELLS):
	@$(MAKE) -C $(CELLDIR)$@

$(APPS):
	@$(MAKE) -C $(APPDIR)$@

osw.o: osw.asm macros.inc
	$(AS) -f elf osw.asm $(ASFLAGS) -p macros.inc

test.o: test.asm
	$(AS) -f elf test.asm -p../../include/macros.inc -p../../include/error_codes.inc $(ASFLAGS)

clean:
	rm -f u3core.bin *.o boot functions.txt
	@$(foreach dir,$(CELLS),$(MAKE) -C $(CELLDIR) -C $(dir) clean;)
	@$(foreach dir,$(APPS),$(MAKE) -C $(APPDIR) -C $(dir) clean;)

install: boot
	@echo "make: copying system image on first floppy drive"
	@if [ -w /dev/fd0 ]; then dd if=boot of=/dev/fd0 bs=512; \
	elif [ -w /dev/floppy/0 ]; then dd if=boot of=/dev/floppy/0 bs=512; \
	elif [ -w /dev/disk/floppy/raw ]; then dd if=boot of=/dev/disk/floppy/raw bs=512; \
	elif [ -w /dev/rfd0c ]; then dd if=boot of=/dev/rfd0c bs=512; \
	else echo 'No writeable floppy drive found'; exit 1; \
	fi;
	@echo "make: image succesfully created."
