// ============================================================================
// IDU.v — Instruction Decode Unit (RV32E + M)
// ----------------------------------------------------------------------------
// 参照 NEMU ~/ysyx-workbench/nemu/src/isa/riscv32/inst.c 实现的全部指令译码。
// 译码风格: 每条指令一个精确字段匹配信号 (opcode/funct3/funct7 全精确,
// 仅寄存器字段不参与比较), 不使用 casez — 非法编码不会被通配吞掉,
// 全部落入 control[`CTRL_ILLEGAL] (预留, 由最上层接引脚处理)。
// 立即数: 在译码阶段按指令类型完成扩展 (immI/S/B/U/J 符号扩展,
// 移位立即数零扩展), 输出完整 32 位 imm。
// 控制信号: 单一 control 总线, 位域定义见 ctrl_defs.v。
// 寄存器: RV32E = 16 个寄存器 (x0~x15), 寄存器号取字段低 4 位。
// ============================================================================
`include "ctrl_defs.v"

module IDU(
  input  [31:0]       inst,
  output [3:0]        rs1,
  output [3:0]        rs2,
  output [3:0]        rd,
  output [31:0]       imm,
  output [`CTRL_NUM-1:0] control
);

  // ================= 字段提取 =================
  wire [6:0] op = inst[6:0];
  wire [2:0] f3 = inst[14:12];
  wire [6:0] f7 = inst[31:25];
  assign rs1 = inst[18:15];   // RV32E: 16 寄存器, 取低 4 位
  assign rs2 = inst[23:20];
  assign rd  = inst[10:7];

  // ================= 立即数生成 (译码阶段完成扩展) =================
  wire [31:0] immI  = {{20{inst[31]}}, inst[31:20]};            // I 型: 符号扩展
  wire [31:0] immS  = {{20{inst[31]}}, inst[31:25], inst[11:7]}; // S 型: 符号扩展
  wire [31:0] immB  = {{19{inst[31]}}, inst[31], inst[7],       // B 型: 符号扩展, bit0=0
                       inst[30:25], inst[11:8], 1'b0};
  wire [31:0] immU  = {inst[31:12], 12'b0};                     // U 型: 高 20 位, 低 12 位清零
  wire [31:0] immJ  = {{11{inst[31]}}, inst[31], inst[19:12],   // J 型: 符号扩展, bit0=0
                       inst[20], inst[30:21], 1'b0};
  wire [31:0] immSH = {27'b0, inst[24:20]};                     // 移位量: 零扩展 5 位

  // ================= 每条指令一个精确匹配信号 =================
  // ---- R 型 (opcode 0110011, funct3+funct7 全精确) ----
  wire dec_add  = (op == 7'b0110011) && (f3 == 3'b000) && (f7 == 7'b0000000);
  wire dec_sub  = (op == 7'b0110011) && (f3 == 3'b000) && (f7 == 7'b0100000);
  wire dec_sll  = (op == 7'b0110011) && (f3 == 3'b001) && (f7 == 7'b0000000);
  wire dec_slt  = (op == 7'b0110011) && (f3 == 3'b010) && (f7 == 7'b0000000);
  wire dec_sltu = (op == 7'b0110011) && (f3 == 3'b011) && (f7 == 7'b0000000);
  wire dec_xor  = (op == 7'b0110011) && (f3 == 3'b100) && (f7 == 7'b0000000);
  wire dec_srl  = (op == 7'b0110011) && (f3 == 3'b101) && (f7 == 7'b0000000);
  wire dec_sra  = (op == 7'b0110011) && (f3 == 3'b101) && (f7 == 7'b0100000);
  wire dec_or   = (op == 7'b0110011) && (f3 == 3'b110) && (f7 == 7'b0000000);
  wire dec_and  = (op == 7'b0110011) && (f3 == 3'b111) && (f7 == 7'b0000000);
  // ---- M 型 (funct7=0000001, 与 R 型同 opcode) ----
  wire dec_mul   = (op == 7'b0110011) && (f3 == 3'b000) && (f7 == 7'b0000001);
  wire dec_mulh  = (op == 7'b0110011) && (f3 == 3'b001) && (f7 == 7'b0000001);
  wire dec_mulhu = (op == 7'b0110011) && (f3 == 3'b011) && (f7 == 7'b0000001);
  wire dec_div   = (op == 7'b0110011) && (f3 == 3'b100) && (f7 == 7'b0000001);
  wire dec_divu  = (op == 7'b0110011) && (f3 == 3'b101) && (f7 == 7'b0000001);
  wire dec_rem   = (op == 7'b0110011) && (f3 == 3'b110) && (f7 == 7'b0000001);
  wire dec_remu  = (op == 7'b0110011) && (f3 == 3'b111) && (f7 == 7'b0000001);
  // ---- Load (opcode 0000011) ----
  wire dec_lb  = (op == 7'b0000011) && (f3 == 3'b000);
  wire dec_lh  = (op == 7'b0000011) && (f3 == 3'b001);
  wire dec_lw  = (op == 7'b0000011) && (f3 == 3'b010);
  wire dec_lbu = (op == 7'b0000011) && (f3 == 3'b100);
  wire dec_lhu = (op == 7'b0000011) && (f3 == 3'b101);
  // ---- Store (opcode 0100011) ----
  wire dec_sb = (op == 7'b0100011) && (f3 == 3'b000);
  wire dec_sh = (op == 7'b0100011) && (f3 == 3'b001);
  wire dec_sw = (op == 7'b0100011) && (f3 == 3'b010);
  // ---- OP-IMM (opcode 0010011; slti/sltiu/xori/ori/andi 无 funct7 约束) ----
  wire dec_addi  = (op == 7'b0010011) && (f3 == 3'b000);
  wire dec_slti  = (op == 7'b0010011) && (f3 == 3'b010);
  wire dec_sltiu = (op == 7'b0010011) && (f3 == 3'b011);
  wire dec_xori  = (op == 7'b0010011) && (f3 == 3'b100);
  wire dec_ori   = (op == 7'b0010011) && (f3 == 3'b110);
  wire dec_andi  = (op == 7'b0010011) && (f3 == 3'b111);
  wire dec_slli  = (op == 7'b0010011) && (f3 == 3'b001) && (f7 == 7'b0000000);
  wire dec_srli  = (op == 7'b0010011) && (f3 == 3'b101) && (f7 == 7'b0000000);
  wire dec_srai  = (op == 7'b0010011) && (f3 == 3'b101) && (f7 == 7'b0100000);
  // ---- U 型 ----
  wire dec_lui   = (op == 7'b0110111);
  wire dec_auipc = (op == 7'b0010111);
  // ---- 跳转 ----
  wire dec_jal   = (op == 7'b1101111);
  wire dec_jalr  = (op == 7'b1100111) && (f3 == 3'b000);
  // ---- 分支 (opcode 1100011) ----
  wire dec_beq  = (op == 7'b1100011) && (f3 == 3'b000);
  wire dec_bne  = (op == 7'b1100011) && (f3 == 3'b001);
  wire dec_blt  = (op == 7'b1100011) && (f3 == 3'b100);
  wire dec_bge  = (op == 7'b1100011) && (f3 == 3'b101);
  wire dec_bltu = (op == 7'b1100011) && (f3 == 3'b110);
  wire dec_bgeu = (op == 7'b1100011) && (f3 == 3'b111);
  // ---- SYSTEM ----
  // ebreak: imm=1, funct3=000, opcode=1110011; ecall(imm=0) 未匹配 → illegal
  wire dec_ebreak = (inst == 32'h0010_0073);

  // 任意合法指令 (供 illegal 判定)
  wire dec_any = |{dec_add,  dec_sub,  dec_sll,  dec_slt,  dec_sltu, dec_xor,
                   dec_srl,  dec_sra,  dec_or,   dec_and,
                   dec_mul,  dec_mulh, dec_mulhu, dec_div, dec_divu, dec_rem, dec_remu,
                   dec_lb,   dec_lh,   dec_lw,   dec_lbu,  dec_lhu,
                   dec_sb,   dec_sh,   dec_sw,
                   dec_addi, dec_slti, dec_sltiu, dec_xori, dec_ori, dec_andi,
                   dec_slli, dec_srli, dec_srai,
                   dec_lui,  dec_auipc,
                   dec_jal,  dec_jalr,
                   dec_beq,  dec_bne,  dec_blt,  dec_bge,  dec_bltu, dec_bgeu,
                   dec_ebreak};

  // ================= 立即数类型选择 =================
  localparam IMM_I = 0, IMM_S = 1, IMM_B = 2, IMM_U = 3, IMM_J = 4,
             IMM_SH = 5, IMM_NONE = 6;
  reg [2:0] imm_sel;
  always @(*) begin
    imm_sel = IMM_NONE;
    if (dec_lb | dec_lh | dec_lw | dec_lbu | dec_lhu |
        dec_jalr | dec_addi | dec_slti | dec_sltiu | dec_xori | dec_ori | dec_andi)
      imm_sel = IMM_I;
    if (dec_sb | dec_sh | dec_sw)        imm_sel = IMM_S;
    if (dec_beq | dec_bne | dec_blt |
        dec_bge | dec_bltu | dec_bgeu)   imm_sel = IMM_B;
    if (dec_lui | dec_auipc)             imm_sel = IMM_U;
    if (dec_jal)                         imm_sel = IMM_J;
    if (dec_slli | dec_srli | dec_srai)  imm_sel = IMM_SH;
  end

  reg [31:0] imm_r;
  always @(*) begin
    case (imm_sel)
      IMM_I:    imm_r = immI;
      IMM_S:    imm_r = immS;
      IMM_B:    imm_r = immB;
      IMM_U:    imm_r = immU;
      IMM_J:    imm_r = immJ;
      IMM_SH:   imm_r = immSH;
      default:  imm_r = 32'b0;
    endcase
  end
  assign imm = imm_r;

  // ================= 控制总线 =================
  // 写寄存器: 所有带 rd 的指令 (load/U/跳转/OP-IMM/R/M)
  wire wen_reg = |{dec_lb, dec_lh, dec_lw, dec_lbu, dec_lhu,
                   dec_lui, dec_auipc, dec_jal, dec_jalr,
                   dec_addi, dec_slti, dec_sltiu, dec_xori, dec_ori, dec_andi,
                   dec_slli, dec_srli, dec_srai,
                   dec_add, dec_sub, dec_sll, dec_slt, dec_sltu,
                   dec_xor, dec_srl, dec_sra, dec_or, dec_and,
                   dec_mul, dec_mulh, dec_mulhu, dec_div, dec_divu,
                   dec_rem, dec_remu};
  wire wen_mem  = dec_sb | dec_sh | dec_sw;
  wire ren_mem  = dec_lb | dec_lh | dec_lw | dec_lbu | dec_lhu;
  wire is_branch = dec_beq | dec_bne | dec_blt | dec_bge | dec_bltu | dec_bgeu;
  wire is_jal   = dec_jal;
  wire is_jalr  = dec_jalr;
  wire halt     = dec_ebreak;
  wire illegal  = ~dec_any;

  // ALU 操作码: 同一 ALU 行为的所有指令 OR 成一组
  wire [4:0] alu_op =
      ({5{dec_add | dec_addi | dec_lb | dec_lh | dec_lw | dec_lbu | dec_lhu |
          dec_sb | dec_sh | dec_sw | dec_jal | dec_jalr | dec_auipc |
          dec_beq | dec_bne | dec_blt | dec_bge | dec_bltu | dec_bgeu}} & `ALU_ADD)
    | ({5{dec_sub}}                                         & `ALU_SUB)
    | ({5{dec_sll | dec_slli}}                              & `ALU_SLL)
    | ({5{dec_srl | dec_srli}}                              & `ALU_SRL)
    | ({5{dec_sra | dec_srai}}                              & `ALU_SRA)
    | ({5{dec_slt | dec_slti}}                              & `ALU_SLT)
    | ({5{dec_sltu | dec_sltiu}}                            & `ALU_SLTU)
    | ({5{dec_xor | dec_xori}}                              & `ALU_XOR)
    | ({5{dec_or | dec_ori}}                                & `ALU_OR)
    | ({5{dec_and | dec_andi}}                              & `ALU_AND)
    | ({5{dec_lui}}                                         & `ALU_PASS_IMM)
    | ({5{dec_mul}}                                         & `ALU_MUL)
    | ({5{dec_mulh}}                                        & `ALU_MULH)
    | ({5{dec_mulhu}}                                       & `ALU_MULHU)
    | ({5{dec_div}}                                         & `ALU_DIV)
    | ({5{dec_divu}}                                        & `ALU_DIVU)
    | ({5{dec_rem}}                                         & `ALU_REM)
    | ({5{dec_remu}}                                        & `ALU_REMU);

  // auipc/branch/jal 的加法需要 src1=PC, 使 sum=PC+imm
  wire alu_src1_pc = dec_auipc | dec_jal | dec_beq | dec_bne | dec_blt |
                     dec_bge | dec_bltu | dec_bgeu;

  wire alu_src2_imm = dec_addi | dec_slti | dec_sltiu | dec_xori | dec_ori |
                      dec_andi | dec_slli | dec_srli | dec_srai | wen_mem |
                      ren_mem | dec_jal | dec_jalr | dec_auipc | is_branch;

  // 访存宽度与 load 符号扩展
  wire [1:0] mem_size =
      ({2{dec_lb | dec_lbu | dec_sb}} & `MEM_1B)
    | ({2{dec_lh | dec_lhu | dec_sh}} & `MEM_2B)
    | ({2{dec_lw | dec_sw}}           & `MEM_4B);
  wire mem_sign = dec_lb | dec_lh;   // lb/lh 符号扩展; lbu/lhu/lw 零扩展

  // 回写来源: 0=ALU 结果, 1=内存数据, 2=PC+4
  wire [1:0] wb_src =
      ({2{dec_lb | dec_lh | dec_lw | dec_lbu | dec_lhu}} & 2'd1)
    | ({2{dec_jal | dec_jalr}}                           & 2'd2);

  // 分支条件类型
  wire [2:0] br_type =
      ({3{dec_beq}}  & `BR_EQ)  | ({3{dec_bne}}  & `BR_NE)
    | ({3{dec_blt}}  & `BR_LT)  | ({3{dec_bge}}  & `BR_GE)
    | ({3{dec_bltu}} & `BR_LTU) | ({3{dec_bgeu}} & `BR_GEU);

  // 拼接成总线 (与 ctrl_defs.v 位域一一对应, 高位 → 低位)
  assign control = {alu_src2_imm, br_type, wb_src, mem_sign, mem_size, alu_src1_pc, alu_op,
                    illegal, halt, is_jalr, is_jal, is_branch,
                    ren_mem, wen_mem, wen_reg};

endmodule
