# $Header: /cvsroot/uuu/dimension/system/frustration/makefile,v 1.5 2002/08/10 13:52:45 instinc Exp $

# This is the root of the Uuu FS. By default it's 'uuu' in the currect
# directory, but if you have created a boot disk for Uuu you could mount
# that device and set this to the directory that disk is mounted under.
UUU_DIR = $(CURDIR)/uuu

# This is the directory the Uuu apps will be placed in.
APP_INST_DIR = $(UUU_DIR)/bin
export APP_INST_DIR

# This is the absloute path to the Uuu assembley include files
INCPATH = $(CURDIR)/../../include/
export INCPATH

# These define the target platform type, mostly required for bug workarounds.
# Currently defined are:
# __BOCHS__
# __VMWARE__
#TARGET_PLATFORM = __VMWARE__

# These define the assmebler to use and the flags for it
AS = nasm
ASFLAGS = -w+orphan-labels -w+number-overflow -w+macro-params -w+macro-selfref $(addprefix -i,$(INCPATH)) $(addprefix -D,$(TARGET_PLATFORM))
export AS ASFLAGS

# These define the program used to make the core and the flags for it
U3L = u3l
U3LFLAGS = --global-offset=00100000 --abort-on-warning --generate-vid-listing --allow-redefinitions  --generate-core-map --stack-location=00001000

# These define the program to use to convert an ELF file (generated by the
# assembler) to a UBF file (executable by Uuu)
ELF2UBF = elf2ubf
E2UFLAGS =
export ELF2UBF E2UFLAGS

# The floppy disk generator
U3FDGEN = u3fd_gen
U3FDFLAGS =
export U3FDGEN U3FDFLAGS

# These define what directories to find the source for the cells and apps
CELLDIR = ../../cell/
APPDIR = ../../app/

# This defines what cells to include in the core.
#
# A friendly note to developers: if you add a cell to the CVS makefile and it
# is broken, I'll rip your head off your shoulder using a plastic pen!
CELLS = \
memory/octane \
debug/lanthane \
memory/meitnerium \
dyn/hydrogen \
lib/string/fasthash \
lib/string/common \
lib/app/common \
lib/terminal/common \
lib/environment \
comm/helium \
other/potassium \
debug/lolalife \
process/strontium \
io/ui/kb/dragon \
io/ui/kb/lang/english \
other/calcium \
debug/diable \
fs/ozone \
fs/devfs \
io/storage/fdc/chromium \
fs/ext2 \
io/video/vga \
console/silicium \
console/silver \
dyn/executioner

# This defined the apps to build
APPS = \
base/cat \
base/ls \
base/dmesg \
base/ps \
shell/ish \
base/memstat

# *** nothing below this line should have to be modified ***

VPATH = $(INCPATH)
export VPATH

.PHONY: all help

help:
	@echo
	@echo "The following targets are availible to build:"
	@echo "  core_install - install the core on the floppy"
	@echo "  apps_install - install Uuu applications on the floppy"
	@echo "  install - install the core and apps and generate uuu.bin disk image"
	@echo
	@echo "The uuu.bin file is a bootable disk image, you can dd/cat/rawrite it to"
	@echo "a floppy disk and boot with it."
	@echo
	@echo "You will need u3l, elf2ubf and u3fd_gen, they are all located in"
	@echo "dimension/devtool/ if you need to build them."
	@echo

u3core.bin: $(CELLS) osw.o test.o
	$(U3L) +osw.o $(addprefix +$(CELLDIR),$(join $(CELLS),$(addprefix /,$(addsuffix .o,$(notdir $(CELLS)))))) +test.o $(U3LFLAGS) u3core.bin

.PHONY: $(CELLS)

$(CELLS):
	@$(MAKE) --directory $(CELLDIR)$@

.PHONY: $(APPS)

$(APPS):
	@$(MAKE) --directory $(APPDIR)$@

OSW_INCS = \
	fs/fs.inc \
	macros.inc \
	core.inc \
	vid/terminal.inc \
	vid/vfs.inc \
	vid/int.inc \
	vid/void.inc \
	vid/debug.diable.inc \
	vid/process.inc \
	vid/lib.string.inc \
	vid/mem.inc \
	vid/sys_log.inc \
	vid/thread.inc \
	sys_log.inc \
	process.inc

osw.o: osw.asm $(INCS) makefile
	$(AS) -f elf osw.asm $(ASFLAGS) $(addprefix -p,$(OSW_INCS))

TEST_INCS = \
	macros.inc \
	errors.inc

test.o: test.asm
	$(AS) -f elf test.asm $(ASFLAGS) $(addprefix -p,$(TEST_INCS))

.PHONY: clean

clean:
	rm -rf u3core.bin *.o boot mboot functions.txt u3core.bin u3core.map
	rm -rf $(UUU_DIR) uuu.bin
	@$(foreach dir,$(CELLS),$(MAKE) -C $(CELLDIR) -C $(dir) clean;)
	@$(foreach dir,$(APPS),$(MAKE) -C $(APPDIR) -C $(dir) clean;)

.PHONY: install

uuu.bin: install

install: core_install apps_install
	$(U3FDGEN) $(U3FDFLAGS) uuu.bin $(UUU_DIR)/ u3core.bin


.PHONY: apps_install

apps_install:
	@[ -d $(APP_INST_DIR) ] || mkdir -p $(APP_INST_DIR)
	@$(foreach dir,$(APPS),$(MAKE) -C $(APPDIR) -C $(dir) install;)

.PHONY: core_install

core_install: u3core.bin
	@[ -d $(UUU_DIR) ] || mkdir $(UUU_DIR)
	cp u3core.bin $(UUU_DIR)
