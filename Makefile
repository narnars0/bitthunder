#
#	BitThunder Top-Level Makefile
#

BASE:=$(dir $(CURDIR)/$(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))
BUILD_BASE:=$(BASE)
MODULE_NAME:="BitThunder"

ifndef PROJECT_DIR
PROJECT_DIR:=$(shell pwd)
PROJECT_CONFIG:=n
else
PROJECT_CONFIG:=y
endif

BUILD_DIR:=$(PROJECT_DIR)/build/
TARGETS:=$(PROJECT_DIR)/vmthunder.img
TARGET_DEPS:=$(PROJECT_DIR)/vmthunder.elf


CONFIG_:=BT_CONFIG_
CONFIG_HEADER_NAME:=bt_bsp_config.h

ifneq ($(PROJECT_CONFIG), y)
CONFIG_PATH:=$(PROJECT_DIR)/
CONFIG_HEADER_PATH:=$(BASE)lib/include
else
CONFIG_PATH:=$(PROJECT_DIR)
CONFIG_HEADER_PATH:=$(PROJECT_DIR)/include
endif

include $(BASE).dbuild/dbuild.mk

$(PROJECT_DIR)/.config:
	$(Q)echo " ******************************************************"
	$(Q)echo "   >>>> No .config file found, run make menuconfig"
	$(Q)echo " ******************************************************"
	@false;

all: $(PROJECT_DIR)/vmthunder.elf $(PROJECT_DIR)/vmthunder.img $(PROJECT_DIR)/vmthunder.syms
	$(Q)$(SIZE) $(PROJECT_DIR)/vmthunder.elf

ifeq ($(BT_CONFIG_BUILD_DISASSEMBLE), y)
all: $(PROJECT_DIR)/vmthunder.list
endif

list: $(PROJECT_DIR)/vmthunder.list
.PHONY: list

test:
	@echo $(BASE)
	@echo $(PROJECT_DIR)
	@echo $(PROJECT_CONFIG)
	@echo $(LDFLAGS)

$(PROJECT_DIR)/vmthunder.img: $(PROJECT_DIR)/vmthunder.elf
	$(Q)$(PRETTY) IMAGE $(MODULE_NAME) $@
	$(Q)$(OBJCOPY) $(PROJECT_DIR)/vmthunder.elf -O binary $@

$(PROJECT_DIR)/vmthunder.elf: $(OBJECTS) $(LINKER_SCRIPTS)
	$(Q)$(PRETTY) --dbuild "LD" $(MODULE_NAME) $@
	$(Q)$(CC) -march=$(CC_MARCH) -mtune=$(CC_MTUNE) $(CC_TCFLAGS) $(CC_MACHFLAGS) $(CC_MFPU) $(CC_FPU_ABI) -o $@ -T $(LINKER_SCRIPT) -Wl,-Map=$(PROJECT_DIR)/vmthunder.map $(OBJECTS) $(LDFLAGS) $(LDLIBS) -lm -lc -lgcc

$(PROJECT_DIR)/vmthunder.list: $(PROJECT_DIR)/vmthunder.elf
	$(Q)$(PRETTY) LIST $(MODULE_NAME) $@
ifeq ($(BT_CONFIG_BUILD_DISASSEMBLE_SOURCE), y)
	$(Q)$(OBJDUMP) -D -S $(PROJECT_DIR)/vmthunder.elf > $@
else
	$(Q)$(OBJDUMP) -D $(PROJECT_DIR)/vmthunder.elf > $@
endif

$(PROJECT_DIR)/vmthunder.syms: $(PROJECT_DIR)/vmthunder.elf
	$(Q)$(PRETTY) SYMS $(MODULE_NAME) $@
	$(Q)$(OBJDUMP) -t $(PROJECT_DIR)/vmthunder.elf > $@

$(OBJECTS) $(OBJECTS-y): $(PROJECT_DIR)/.config

project.init:
	$(Q)touch $(PROJECT_DIR)/Kconfig
	$(Q)touch $(PROJECT_DIR)/objects.mk
	$(Q)touch $(PROJECT_DIR)/README.md
	$(Q)touch $(PROJECT_DIR)/main.c
	-$(Q)mkdir $(PROJECT_DIR)/include
	$(Q)echo "PROJECT_DIR=\$$(shell pwd)" >> $(PROJECT_DIR)/Makefile
	$(Q)echo "include $(shell $(RELPATH) $(BASE) $(PROJECT_DIR))/Makefile" >> $(PROJECT_DIR)/Makefile

project.git.init:
	-$(Q)cd $(PROJECT_DIR) && git init .
	-$(Q)cd $(PROJECT_DIR) && git submodule add git://github.com/jameswalmsley/bitthunder.git bitthunder
	$(Q)touch $(PROJECT_DIR)/Kconfig
	$(Q)touch $(PROJECT_DIR)/objects.mk
	$(Q)touch $(PROJECT_DIR)/README.md
	$(Q)touch $(PROJECT_DIR)/main.c
	-$(Q)mkdir $(PROJECT_DIR)/include
	$(Q)echo "export PROJECT_DIR=\$$(shell pwd)" >> $(PROJECT_DIR)/Makefile
	$(Q)echo "include bitthunder/Makefile" >> $(PROJECT_DIR)/Makefile

mrproper:
ifneq ($(PROJECT_CONFIG),y)
	$(Q)rm $(PRM_FLAGS) $(PROJECT_DIR)/.config $(BASE)lib/include/bt_bsp_config.h $(PRM_PIPE)
else
	$(Q)rm $(PRM_FLAGS) $(PROJECT_DIR)/.config $(PROJECT_DIR)/include/bt_bsp_config.h $(PRM_PIPE)
endif

clean: clean_images
clean_images:
	$(Q)rm $(PRM_FLAGS) $(PROJECT_DIR)/vmthunder.elf $(PROJECT_DIR)/vmthunder.img $(PROJECT_DIR)/vmthunder.elf $(PROJECT_DIR)/vmthunder.list $(PROJECT_DIR)/vmthunder.map $(PROJECT_DIR)/vmthunder.syms $(PRM_PIPE)
