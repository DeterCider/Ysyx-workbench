#***************************************************************************************
# minirv RTL 源文件清单
#
# 机制: csrc/minirv/Makefile 先 find 全量收集 *.v/*.sv, 再用 SRCS-BLACKLIST 过滤,
#       因此新增 RTL 源文件无需改动本文件; 只需把"不该进主构建"的文件加入黑名单
#
# 规则:
#   1. tb* 开头的文件是单元测试台 (tb_idu.v / tb_exu.v / tb_wbu.v), 不纳入主构建
#   2. *.bak 是历史备份文件
#   3. ctrl_defs.v 是 `include 头文件 (仅宏定义, 无模块), 不作为源文件传给 verilator
#***************************************************************************************/

SRCS-BLACKLIST += ../../vsrc/minirv/tb%
SRCS-BLACKLIST += ../../vsrc/minirv/%.bak
SRCS-BLACKLIST += ../../vsrc/minirv/ctrl_defs.v
