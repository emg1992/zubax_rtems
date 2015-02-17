#
# Copyright (C) 2015 Pavel Kirienko <pavel.kirienko@zubax.com>
# Distributed under the terms of the MIT license.
#

LOCAL_DIR := $(abspath $(realpath $(dir $(lastword $(MAKEFILE_LIST)))))

EXEC ?= firmware.exe
PGM ?= ${ARCH}/$(EXEC)

MANAGERS ?= all

#
# Search for source files if the top-level makefile doesn't specify them explicitly
#
ifdef SRC_DIR
  ifeq ($(and $(CSRCS),$(CXXSRCS)),)
    CSRCS = $(wildcard $(SRC_DIR)/*.c)        \
            $(wildcard $(SRC_DIR)/*/*.c)      \
            $(wildcard $(SRC_DIR)/*/*/*.c)    \
            $(wildcard $(SRC_DIR)/*/*/*/*.c)  \
            $(wildcard $(SRC_DIR)/*/*/*/*/*.c)

    CXXSRCS = $(wildcard $(SRC_DIR)/*.cpp)        \
              $(wildcard $(SRC_DIR)/*/*.cpp)      \
              $(wildcard $(SRC_DIR)/*/*/*.cpp)    \
              $(wildcard $(SRC_DIR)/*/*/*/*.cpp)  \
              $(wildcard $(SRC_DIR)/*/*/*/*/*.cpp)
  endif
endif

#
# Common compiler flags
# Application specific flags are appended so the default flags can be overriden
#
common_flags = -Wall -Wextra -Wundef -Wfloat-equal -Wmissing-declarations -pedantic \
               -ffunction-sections -fdata-sections

AM_CFLAGS := $(common_flags) -std=c99 $(AM_CFLAGS)
AM_CXXFLAGS := $(common_flags) -std=c++11 $(AM_CXXFLAGS)

AM_LDFLAGS := -Wl,--gc-sections $(AM_LDFLAGS)

#
# RTEMS makefiles
#
ifndef RTEMS_MAKEFILE_PATH
  $(error RTEMS environment is not configured. Have you sourced env.sh?)
endif

VARIANT ?= OPTIMIZE
ifeq ($(VARIANT),DEBUG)
else ifeq ($(VARIANT),OPTIMIZE)
else
  $(error Unrecognized build variant: $(VARIANT))
endif

include $(RTEMS_MAKEFILE_PATH)/Makefile.inc
include $(RTEMS_CUSTOM)
include $(PROJECT_ROOT)/make/leaf.cfg

#
# Rules
#
COBJS_ = $(CSRCS:.c=.o)
COBJS = $(COBJS_:%=${ARCH}/%)

CXXOBJS_ = $(CXXSRCS:.cpp=.o)
CXXOBJS = $(CXXOBJS_:%=${ARCH}/%)

OBJS = $(COBJS) $(CXXOBJS)

# Copying directory structure to the output directory
$(info $(foreach var,$(dir $(CSRCS) $(CXXSRCS)),$(shell mkdir -vp "${ARCH}/$(var)")))

include $(LOCAL_DIR)/flashers/rules.mk

all:    ${ARCH} $(PGM)

$(PGM): $(OBJS)
	$(make-cxx-exe)
