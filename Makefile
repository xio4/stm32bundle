#+---------------------------------------------------------------------------
#
# Copyright © 2010 Anton Gusev aka AHTOXA (HTTP://AHTOXA.NET)
#
# File: makefile
#
# Contents: makefile to build arm Cortex-M3 software with gcc
#
#----------------------------------------------------------------------------

############# program name
TARGET = main

# Processor frequency.
F_CPU = 8000000

# program version
VER_MAJOR = 0
VER_MINOR = 1

TOOL = arm-none-eabi-
# TOOL = arm-kgp-eabi-

# compile options
MCU = cortex-m3

# Optimization level, can be [0, 1, 2, 3, s]. 
#     0 = turn off optimization. s = optimize for size.
OPT=2

# Debugging format.
DEBUG =

USE_LTO = 

# Select family
# STM32F10X_LD : STM32 Low density devices
# STM32F10X_LD_VL : STM32 Low density Value Line devices
# STM32F10X_MD : STM32 Medium density devices
# STM32F10X_MD_VL : STM32 Medium density Value Line devices
# STM32F10X_HD : STM32 High density devices
# STM32F10X_HD_VL : STM32 XL-density devices
# STM32F10X_CL : STM32 Connectivity line devices
# STM32F10X_XL : STM32 XL-density devices
CHIP = STM32F10X_MD

#defines
DEFS = -D$(CHIP)
DEFS += -DVER_MAJOR=$(VER_MAJOR)
DEFS += -DVER_MINOR=$(VER_MINOR)

###########################################################
# common part for all my cortex-m3 projects
###########################################################

BASE = .
CC = $(TOOL)gcc
CXX = $(TOOL)g++
LD = $(TOOL)g++
AS = $(CC) -x assembler-with-cpp
OBJCOPY = $(TOOL)objcopy
OBJDUMP = $(TOOL)objdump
SIZE = $(TOOL)size -d
FLASHER = openocd
RM = rm -f
RMA = rm -rf
CP = cp
MD = mkdir

# dirs
SRCDIR = $(BASE)/src
LIBDIR = $(BASE)/lib
OBJDIR = $(BASE)/obj
EXEDIR = $(BASE)/bin
LSTDIR = $(BASE)/lst
LDDIR = $(BASE)/ld
BAKDIR = $(BASE)/bak

#files
HEX = $(EXEDIR)/$(TARGET).hex
BIN = $(EXEDIR)/$(TARGET).bin
ELF = $(EXEDIR)/$(TARGET).elf
MAP = $(LSTDIR)/$(TARGET).map
LSS = $(LSTDIR)/$(TARGET).lss
OK = $(EXEDIR)/$(TARGET).ok

# linker script (chip dependent)
# LD_SCRIPT = $(LDDIR)/$(CHIP).ld
LD_SCRIPT = $(LDDIR)/stm32_flash.ld

# scmRTOS dir
#SCMDIR = ../scmRTOS
#COMMON = ../SamplesCommon
SCMDIR=
COMMON=

# source directories (all *.c, *.cpp and *.S files included)
DIRS := $(SRCDIR)
DIRS += $(LIBDIR)
#DIRS += $(COMMON)
#DIRS += $(SCMDIR)/Common $(SCMDIR)/CortexM3
#DIRS += $(SCMDIR)/Extensions/Profiler

# includes
INCS := $(patsubst %, -I "%", $(DIRS))

# individual source files
SRCS := 

#calc obj files list
OBJS := $(SRCS)
OBJS += $(wildcard $(addsuffix /*.cpp, $(DIRS)))
OBJS += $(wildcard $(addsuffix /*.c, $(DIRS)))
OBJS += $(wildcard $(addsuffix /*.S, $(DIRS)))
OBJS := $(notdir $(OBJS))
OBJS := $(OBJS:.cpp=.o)
OBJS := $(OBJS:.c=.o)
OBJS := $(OBJS:.S=.o)
OBJS := $(patsubst %, $(OBJDIR)/%, $(OBJS))

#files to archive
ARCFILES = \
$(SRCDIR) \
$(LDDIR) \
$(SCMDIR) \
$(BASE)/Makefile \
$(BASE)/.cproject \
$(BASE)/.project

# flags
FLAGS = -mcpu=$(MCU) -mthumb
FLAGS += -DF_CPU=$(F_CPU)
FLAGS += $(INCS)
FLAGS += -MD
FLAGS += $(DEFS)
FLAGS += -Wa,-adhlns=$(addprefix $(LSTDIR)/, $(notdir $(addsuffix .lst, $(basename $<))))
FLAGS += -c -fno-common -mlittle-endian -fshort-enums
FLAGS += -nostdlib -nostdinc
# FLAGS+=-Wl,-Ttext,0x20000000 -Wl,-e,0x20000000

ifeq ($(DEBUG),1)
 	MSG_MODE=--- debug mode
	FLAGS += -g
else 
	MSG_MODE=--- release mode
	FLAGS += -O$(OPT)
endif

# FLAGS += -Wl,-Ttext,0x20000000 -Wl,-e,0x20000000

AFLAGS = $(FLAGS)

CFLAGS = $(FLAGS)
CFLAGS += -std=gnu99
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -Wall -Wextra
CFLAGS += -Wimplicit -Wcast-align -Wpointer-arith -Wredundant-decls
CFLAGS += -Wshadow -Wcast-qual -Wcast-align -Wnested-externs -pedantic

CXXFLAGS = $(FLAGS)
CXXFLAGS += -fno-exceptions -fno-rtti
CXXFLAGS += -ffunction-sections -fdata-sections
CXXFLAGS += -fno-threadsafe-statics
CXXFLAGS += -funsigned-bitfields -fshort-enums
CXXFLAGS += -Wall -Wextra
CXXFLAGS += -Winline
CXXFLAGS += -Wpointer-arith -Wredundant-decls
CXXFLAGS += -Wshadow -Wcast-qual -Wcast-align -pedantic

LD_FLAGS = -mcpu=$(MCU)
LD_FLAGS += -mthumb
LD_FLAGS += -nostartfiles
LD_FLAGS += -L$(LDDIR)
LD_FLAGS += -Wl,-Map="$(MAP)",--cref
LD_FLAGS += -Wl,--gc-sections
LD_FLAGS += -T$(LD_SCRIPT)

ifeq ($(USE_LTO),1)
	CFLAGS += -flto
	CXXFLAGS += -flto
	LD_FLAGS += -flto $(OPTIMIZE)
endif




#openocd command-line

# debug level (d0..d3)
oocd_params = -d0
# interface and board/target settings (using the OOCD target-library here)
# oocd_params += -c "fast enable"
oocd_params += -f interface/arm-usb-ocd.cfg
oocd_params += -f board/stm32f10x_128k_eval.cfg
oocd_params += -c init -c targets
oocd_params_program = $(oocd_params)
# commands to prepare flash-write
oocd_params_program += -c "halt"
# flash-write and -verify
oocd_params_program += -c "flash write_image erase $(ELF)"
oocd_params_program += -c "verify_image $(ELF)"
# reset target
oocd_params_program += -c "reset run"
# terminate OOCD after programming
oocd_params_program += -c shutdown

oocd_params_reset = $(oocd_params)
oocd_params_reset += -c "reset run"
oocd_params_reset += -c shutdown

.SILENT :

.PHONY: all dmode start dirs build clean program reset archive

############# targets
all : dmode start dirs $(ELF) $(BIN) $(HEX) $(LSS) $(OK)
build: clean all


# Display compiler version information.
gccversion : 
	@$(CC) --version


dmode:
	@echo $(MSG_MODE)

start:
	@echo --- building $(TARGET)
	
$(LSS): $(ELF) Makefile
	@echo --- making asm-lst...
# @$(OBJDUMP) -dStC $(ELF) > $(LSS)
	@$(OBJDUMP) -dC $(ELF) > $(LSS)

$(OK): $(ELF)
	@$(SIZE) $(ELF)
	@echo "Errors: none"

$(ELF): $(OBJS) Makefile
	@echo --- linking...
	$(LD) $(OBJS) $(LIBS) $(LD_FLAGS) -o "$(ELF)"

$(HEX): $(ELF)
	@echo --- make hex...
	@$(OBJCOPY) -O ihex $(ELF) $(HEX)

$(BIN): $(ELF)
	@echo --- make binary...
	@$(OBJCOPY) -O binary $(ELF) $(BIN)

program: $(ELF)
	@echo "Programming with OPENOCD"
	$(FLASHER) $(oocd_params_program)

reset:
	@echo Resetting device
	$(FLASHER) $(oocd_params_reset)

VPATH := $(DIRS)

$(OBJDIR)/%.o: %.cpp Makefile
	@echo --- compiling CPP files $<...
	$(CXX) -c $(CXXFLAGS) -o $@ $<

$(OBJDIR)/%.o: %.c Makefile
	@echo --- compiling C files $<...
	$(CC) -c $(CFLAGS) -o $@ $<

$(OBJDIR)/%.o: %.S Makefile
	@echo --- assembling $<...
	$(AS) -c $(AFLAGS) -o $@ $<

dirs: $(OBJDIR) $(EXEDIR) $(LSTDIR) $(BAKDIR)

$(OBJDIR):
	-@$(MD) $(OBJDIR)

$(EXEDIR):
	-@$(MD) $(EXEDIR)

$(LSTDIR):
	-@$(MD) $(LSTDIR)

$(BAKDIR):
	-@$(MD) $(BAKDIR)

clean:
	-@$(RM) $(OBJDIR)/*.d 2>/dev/null
	-@$(RM) $(OBJDIR)/*.o 2>/dev/null
	-@$(RM) $(LSTDIR)/*.lst 2>/dev/null
	-@$(RM) $(ELF)
	-@$(RM) $(HEX)
	-@$(RM) $(LSS)
	-@$(RM) $(MAP)
	-@$(RMA) $(OBJDIR)
	-@$(RMA) $(EXEDIR)
	-@$(RMA) $(LSTDIR)
	-@$(RMA) $(BAKDIR)

archive:
	@echo --- archiving...
	7z a $(BAKDIR)/$(TARGET)_`date +%Y-%m-%d,%H-%M-%S` $(ARCFILES)
	@echo --- done!

# dependencies
ifeq (,$(findstring build,$(MAKECMDGOALS)))
ifeq (,$(findstring clean,$(MAKECMDGOALS)))
ifeq (,$(findstring dirs,$(MAKECMDGOALS)))
-include $(wildcard $(OBJDIR)/*.d)
endif
endif
endif
