PROJECT ?= top
# 默认项目名为 top
TOP_MODULE ?= $(PROJECT)
# 顶层模块名（假设与项目名一致）
CSRC_DIR := ./csrc/$(PROJECT)
# cpp文件目录 csrc/xxx/
VSRC_DIR  := ./vsrc/$(PROJECT)
# 模块目录：vsrc/xxx/
VSRC_FILES := $(shell find $(VSRC_DIR) -type f \( -name "*.v" -o -name "*.sv" \))
# 收集所有 .v/.sv
CSRC_FILES := $(shell find $(CSRC_DIR) -type f \( -name "*.c" -o -name "*.cpp" \))
VERILATOR_CFLAGS += -MMD --build -cc  \
				-O3 --trace-fst -j 0 -Wall --exe
NXDC_FILES = ./constr/$(PROJECT).nxdc
#引脚约束文件
INC_PATH ?=


#输出目录
OBJ_DIR ?= build

include ../Makefile
include $(NVBOARD_HOME)/scripts/nvboard.mk

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOP_MODULE)\""

# constraint file
SRC_AUTO_BIND = $(abspath $(OBJ_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	@mkdir -p $(OBJ_DIR)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

CSRC_FILES += $(SRC_AUTO_BIND)


all: $(OBJ_DIR)/V$(TOP_MODULE)
$(OBJ_DIR)/V$(TOP_MODULE): $(CSRC_FILES) $(VSRC_FILES) $(NVBOARD_ARCHIVE)
	verilator $(VERILATOR_CFLAGS) \
		--Mdir $(OBJ_DIR) \
		--top-module $(TOP_MODULE) \
		--build -o V$(TOP_MODULE) \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		$^

sim: all
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(OBJ_DIR)/V$(TOP_MODULE)

clean: 
	rm -rf $(OBJ_DIR)

