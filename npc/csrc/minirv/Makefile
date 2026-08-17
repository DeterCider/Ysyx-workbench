# CONFIG_ITRACE = y


# Include all filelist.mk to merge file lists
FILELIST_MK = $(shell find -L ./ ../../vsrc/minirv -name "filelist.mk")
include $(FILELIST_MK)

SRCS-BLACKLIST ?=
SRCS-BLACKLIST += ./build/%      # 必须：否则 find 会把 verilator 生成的 build/Vminirv__*.cpp 当源文件！
SRCS-BLACKLIST += ./tools/%      # 排除第三方 capstone 源码树

CSRC := $(shell find . -type f \( -name "*.c" -o -name "*.cpp" \))
CSRC := $(sort $(filter-out $(SRCS-BLACKLIST), $(CSRC)))

VSRC := $(shell find ../../vsrc/minirv -type f \( -name "*.v" -o -name "*.sv" \))
VSRC := $(sort $(filter-out $(SRCS-BLACKLIST), $(VSRC)))
VSRC += $(shell find ../../vsrc/tools   -type f \( -name "*.v" -o -name "*.sv" \))

CXXFLAGS := $(INCFLAGS) -DTOP_NAME="\"V$(TOP_MODULE)\""
CXXFLAGS += -I$(abspath ./include)                # common.h / isa.h ...
CXXFLAGS += -I$(abspath ./build)                  # rtl.c 需要的 Vminirv.h
CXXFLAGS += -I$(abspath ./tools/capstone/repo/include)  # disasm.c 的 capstone 头

LDFLAGS := -lreadline                             # sdb.c 的 readline
OBJ_DIR ?= build

# verilator 编译选项 (csrc 独立构建, 不继承 npc 根 Makefile)
VERILATOR_CFLAGS ?= -MMD --build -cc --trace-fst -j 0 --exe -O3

all: build/Vminirv

$(OBJ_DIR)/Vminirv: $(VSRC) $(CSRC)
	verilator $(VERILATOR_CFLAGS) -I../../vsrc/minirv $^ \
		--Mdir $(OBJ_DIR) \
		--top-module minirv \
		--build -o Vminirv \
		$(addprefix -CFLAGS , $(CXXFLAGS)) \
		$(addprefix -LDFLAGS , $(LDFLAGS))

am-run: all
	build/Vminirv $(ARGS) $(IMG)

gdb: all
	gdb -s $(OBJ_DIR)/Vminirv --args $(OBJ_DIR)/Vminirv $(IMG)

clean:
	rm -rf $(OBJ_DIR)

.PHONY: all am-run clean gdb sim

.DEFAULT_GOAL := all
