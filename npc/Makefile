PROJECT ?= top
# 默认项目名为 top
TOP_MODULE ?= $(PROJECT)
# 顶层模块名（假设与项目名一致）
CSRC_DIR := ./csrc/$(PROJECT)
# cpp文件目录 csrc/xxx/
VSRC_DIR  := ./vsrc/$(PROJECT)
# 模块目录：vsrc/xxx/
VSRC_FILES := $(shell find $(VSRC_DIR) -type f \( -name "*.v" -o -name "*.sv" \))
VSRC_Tools_FILES := $(shell find ./vsrc/tools/ -type f \( -name "*.v" -o -name "*.sv" \)) 
# 收集所有 .v/.sv
CSRC_FILES := $(shell find $(CSRC_DIR) -type f \( -name "*.c" -o -name "*.cpp" \))
VERILATOR_CFLAGS += -MMD --build -cc  \
				--trace-fst -j 0  --exe -O3
NXDC_FILES = ./constr/$(PROJECT).nxdc
#引脚约束文件
INC_PATH ?=
IMG ?=

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

clean: 
	rm -rf $(OBJ_DIR)


all: $(OBJ_DIR)/V$(TOP_MODULE)
$(OBJ_DIR)/V$(TOP_MODULE): $(CSRC_FILES) $(VSRC_FILES) $(NVBOARD_ARCHIVE) $(VSRC_Tools_FILES)
	verilator $(VERILATOR_CFLAGS) $^\
		--Mdir $(OBJ_DIR) \
		--top-module $(TOP_MODULE) \
		--build -o V$(TOP_MODULE) \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS))

am-run: all
	$(OBJ_DIR)/V$(TOP_MODULE) $(IMG)

#NoNvBoard: $(CSRC_FILES) $(VSRC_FILES)
#	verilator $(VERILATOR_CFLAGS) \
		--Mdir $(OBJ_DIR) \
		--top-module $(TOP_MODULE) \
		--build -o V$(TOP_MODULE) \
		$^

sim: all
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(OBJ_DIR)/V$(TOP_MODULE)


