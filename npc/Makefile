PROJECT ?= top
# 默认项目名为 top
TOP_MODULE ?= $(PROJECT)
# 顶层模块名（假设与项目名一致）
CSRC_MAIN := ./csrc/$(PROJECT)_main.cpp
# 主文件：xxx_main.cpp
VSRC_DIR  := ./vsrc/$(PROJECT)
# 模块目录：vsrc/xxx/
VSRC_FILES := $(shell find $(VSRC_DIR) -type f \( -name "*.v" -o -name "*.sv" \))
# 收集所有 .v/.sv

#检查制定文件是否存在
ifeq ($(wildcard $(CSRC_MAIN)),)
$(error Main file $(CSRC_MAIN) not found!)
endif

ifeq ($(VSRC_FILES),)
$(error No Verilog files found in $(VSRC_DIR)!)
endif

#输出目录
OBJ_DIR ?= obj_dir

all: $(OBJ_DIR)/V$(TOP_MODULE)
$(OBJ_DIR)/V$(TOP_MODULE): $(CSRC_MAIN) $(VSRC_FILES)
	@mkdir -p $(OBJ_DIR)
	verilator --cc --exe --build --trace-fst -j 0 -Wall \
		--top-module $(TOP_MODULE) \
		--build -o V$(TOP_MODULE) \
		$(CSRC_MAIN) $(VSRC_FILES)

sim: all
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	./obj_dir/V$(TOP_MODULE)

clean: 
	rm -rf $(OBJ_DIR)

include ../Makefile
