// ============================================================================
// ctrl_defs.v — minirv (RV32E+M) 控制信号总线定义
// ----------------------------------------------------------------------------
// IDU 输出单一 control 总线, 所有下游单元按位域消费:
//   control[`CTRL_ALU_OP +: 5] 等位域请用 `CTRL_xxx 宏引用, 不要写死数字
//
// 信号总线总览 (低位 → 高位, 共 22 位):
//   [0]    wen_reg      写寄存器堆            (EXU/WBU/GPRs)
//   [1]    wen_mem      写内存 (store)        (LSU)
//   [2]    ren_mem      读内存 (load)         (LSU)
//   [3]    is_branch    条件分支               (顶层 PC 更新, 结合 br_type)
//   [4]    is_jal       jal: PC=PC+imm, rd=PC+4 (顶层 PC 更新 / WBU)
//   [5]    is_jalr      jalr: PC=(rs1+imm)&~1   (顶层 PC 更新 / WBU)
//   [6]    halt         ebreak 停机             (顶层 halt 输出)
//   [7]    illegal      未匹配任何合法编码       (预留, 顶层接引脚处理)
//   [12:8] alu_op       ALU 操作码 (见 ALU_xxx) (EXU)
//   [13]   alu_src1_pc  ALU 的 src1 选 PC       (EXU; auipc/branch/jal 用)
//   [15:14] mem_size    访存宽度 0=1B 1=2B 2=4B (LSU)
//   [16]   mem_sign     load 符号扩展 1=有符号  (LSU/WBU; lb/lh 置位)
//   [18:17] wb_src      回写来源 0=ALU 1=内存 2=PC+4 (WBU)
//   [21:19] br_type     分支条件类型 (见 BR_xxx; 仅 is_branch 有效)
//   [22]   alu_src2_imm ALU 的 src2 选 imm       (EXU)
//
// 立即数不在总线内: IDU 单独输出 imm[31:0], 已在译码阶段按类型完成扩展
// (immI/S/B/U/J 符号扩展, 移位立即数零扩展), 见 IDU.v
// ============================================================================
`ifndef CTRL_DEFS_V
`define CTRL_DEFS_V

// ---------------- 控制总线位域 ----------------
`define CTRL_WEN_REG      0    // 写寄存器堆
`define CTRL_WEN_MEM      1    // 写内存 (store)
`define CTRL_REN_MEM      2    // 读内存 (load)
`define CTRL_IS_BRANCH    3    // 条件分支 (PC = taken ? PC+imm : PC+4)
`define CTRL_IS_JAL       4    // jal  (PC = PC+imm, rd = PC+4)
`define CTRL_IS_JALR      5    // jalr (PC = (rs1+imm)&~1, rd = PC+4)
`define CTRL_HALT         6    // ebreak 停机
`define CTRL_ILLEGAL      7    // 非法指令 (未匹配任何编码, 顶层接引脚)
`define CTRL_ALU_OP       8    // [12:8] ALU 操作码, 5 位
`define CTRL_ALU_SRC1_PC  13   // ALU src1 选择 PC (auipc/branch/jal 计算 PC+imm)
`define CTRL_MEM_SIZE     14   // [15:14] 访存宽度: 0=字节 1=半字 2=字
`define CTRL_MEM_SIGN     16   // load 符号扩展: 1=有符号(lb/lh) 0=无符号
`define CTRL_WB_SRC       17   // [18:17] 回写来源: 0=ALU结果 1=内存数据 2=PC+4
`define CTRL_BR_TYPE      19   // [21:19] 分支条件类型 (仅 is_branch 有效)
`define CTRL_ALU_SRC2_IMM 22   // ALU src2 选择 imm (addi/slti/sltiu/xori/ori/andi/slli/srli/srai/loads/stores/jalr/jal/auipc/branches)
`define CTRL_NUM          23   // 总线总宽度

// ---------------- ALU 操作码 ----------------
`define ALU_ADD      5'd0
`define ALU_SUB      5'd1
`define ALU_SLL      5'd2
`define ALU_SRL      5'd3
`define ALU_SRA      5'd4
`define ALU_SLT      5'd5
`define ALU_SLTU     5'd6
`define ALU_XOR      5'd7
`define ALU_OR       5'd8
`define ALU_AND      5'd9
`define ALU_PASS_IMM 5'd10   // lui: 结果 = imm (直通)
`define ALU_MUL      5'd11
`define ALU_MULH     5'd12
`define ALU_MULHU    5'd13
`define ALU_DIV      5'd14
`define ALU_DIVU     5'd15
`define ALU_REM      5'd16
`define ALU_REMU     5'd17

// ---------------- 分支条件类型 ----------------
`define BR_EQ   3'd0
`define BR_NE   3'd1
`define BR_LT   3'd2
`define BR_GE   3'd3
`define BR_LTU  3'd4
`define BR_GEU  3'd5

// ---------------- 访存宽度 ----------------
`define MEM_1B  2'd0
`define MEM_2B  2'd1
`define MEM_4B  2'd2

`endif
