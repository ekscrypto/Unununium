BOOT_RECORD = $(CURDIR)/../../src/boot/ext2_boot
INITIALIZER = $(CURDIR)/../../src/apps/init

UUU_DIR = $(CURDIR)/uuu
APP_INST_DIR = $(UUU_DIR)/bin
CELL_INST_DIR = $(UUU_DIR)/cell
LIB_INST_DIR = $(UUU_DIR)/lib
export APP_INST_DIR CELL_INST_DIR LIB_INST_DIR

INCPATH = $(CURDIR)/../../include/
export INCPATH

AS = nasm
ASFLAGS = -w+orphan-labels -w+number-overflow -w+macro-params -w+macro-selfref $(addprefix -i,$(INCPATH))
export AS ASFLAGS

ELF2UBF = elf2ubf
E2UFLAGS =
export ELF2UBF E2UFLAGS

CELLDIR = $(CURDIR)/../../src/cells/
APPDIR = $(CURDIR)/../../src/apps/
LIBDIR = $(CURDIR)/../../src/cells/lib/

CELLS =\
memory_manager/oxygen \
memory_manager/noblame \
memory_manager/meitnerium \
debug/diable \
debug/bochs \
debug/ehex \
debug/lanthane \
debug/yttrium \
debug/lolalife \
bios32/naphta \
3d/hydro3d \
bus/pci/kerosen \
dyn_link/executioner \
fs/devfs \
fs/ext2 \
ics/helium \
idt_irq/potassium \
io/console/silver \
io/fdc/chromium \
io/ide/iode \
io/kbd_at/dragon \
io/kbd_at/dragon/dvorak \
io/kbd_at/dragon/english \
io/mouse/microsoft \
io/mouse/ps2 \
io/null/nulldev \
io/nvram/mini-archiver \
jit/hydrogen

LIBS = \
app/common \
environment \
maths/rng/parkmiller \
string/common

APPS = \
ls \
dmesg \
shells/ish

VPATH = $(INCPATH)
export VPATH

.PHONY: all install

all: $(CELLS) $(APPS) $(LIBS) $(BOOT_RECORD)/boot.bin $(INITIALIZER)/init

$(APPS):
	@$(MAKE) --directory $(APPDIR)$@

$(CELLS):
	@$(MAKE) --directory $(CELLDIR)$@

$(LIBS):
	@$(MAKE) --directory $(LIBDIR)$@

$(BOOT_RECORD)/boot.bin:
	@$(MAKE) --directory $(BOOT_RECORD)
	cp $(BOOT_RECORD)/boot.bin $(CURDIR)/boot.bin

$(INITIALIZER)/init:
	@$(MAKE) --directory $(INITIALIZER)
	cp $(INITIALIZER)/init $(CURDIR)/init

install: all
	mkdir -p $(APP_INST_DIR)
	cp $(CURDIR)/init $(APP_INST_DIR)/init
	@[ -d $(APP_INST_DIR) ] || mkdir -p $(APP_INST_DIR)
	@$(foreach dir,$(APPS),$(MAKE) --directory $(APPDIR) --directory $(dir) install;)
	mkdir -p $(CELL_INST_DIR)
	@[ -d $(CELL_INST_DIR) ] || mkdir -p $(CELL_INST_DIR)
	@$(foreach dir,$(CELLS),$(MAKE) --directory $(CELLDIR) --directory $(dir) install;)
	mkdir -p $(LIB_INST_DIR)
	@[ -d $(APP_INST_DIR) ] || mkdir -p $(LIB_INST_DIR)
	@$(foreach dir,$(LIBS),$(MAKE) --directory $(LIBDIR) --directory $(dir) install;)
	mkdir -p $(UUU_DIR)/conf
	cp $(CURDIR)/config $(UUU_DIR)/conf/frustration
	@echo Installation Completed, please make sure to update your $(UUU_DIR)/conf/init file to make an entry for /conf/frustration
