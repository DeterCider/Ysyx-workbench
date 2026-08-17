// tb_idu.v — IDU 译码正确性测试台 (v3)
// 指令编码由字段构造器按 RV32 编码规则组装, 消除手写编码错误;
// 期望拼接 = {src2_imm, br_type, wb_src, sign, size, src1pc, alu_op,
//             illegal, halt, jalr, jal, branch, ren, wem, wr} (23 位, 与 ctrl_defs 一致)
`include "ctrl_defs.v"
module tb;
  reg [31:0] inst;
  wire [3:0] rs1, rs2, rd;
  wire [31:0] imm;
  wire [`CTRL_NUM-1:0] control;
  integer errors;

  IDU idu(.inst(inst), .rs1(rs1), .rs2(rs2), .rd(rd), .imm(imm), .control(control));

  // ================= 编码构造器 =================
  function [31:0] rtype(input [6:0] f7, input [4:0] rs2, input [4:0] rs1,
                        input [2:0] f3, input [4:0] rd);
    rtype = {f7, rs2, rs1, f3, rd, 7'b0110011};
  endfunction
  function [31:0] itype(input [11:0] imm12, input [4:0] rs1, input [2:0] f3,
                        input [4:0] rd, input [6:0] op);
    itype = {imm12, rs1, f3, rd, op};
  endfunction
  function [31:0] stype(input [11:0] imm12, input [4:0] rs2, input [4:0] rs1,
                        input [2:0] f3);
    stype = {imm12[11:5], rs2, rs1, f3, imm12[4:0], 7'b0100011};
  endfunction
  function [31:0] btype(input [12:0] imm13, input [4:0] rs2, input [4:0] rs1,
                        input [2:0] f3);
    btype = {imm13[12], imm13[10:5], rs2, rs1, f3, imm13[4:1], imm13[11], 7'b1100011};
  endfunction
  function [31:0] utype(input [19:0] imm20, input [4:0] rd, input [6:0] op);
    utype = {imm20, rd, op};
  endfunction
  function [31:0] jtype(input [20:0] imm21, input [4:0] rd);
    jtype = {imm21[20], imm21[10:1], imm21[11], imm21[19:12], rd, 7'b1101111};
  endfunction
  function [31:0] shifti(input [6:0] f7, input [4:0] shamt, input [4:0] rs1,
                         input [2:0] f3, input [4:0] rd);
    shifti = {f7, shamt, rs1, f3, rd, 7'b0010011};
  endfunction

  task check(input [31:0] i, input [`CTRL_NUM-1:0] exp_ctrl,
             input [31:0] exp_imm, input [3:0] exp_rd,
             input [3:0] exp_rs1, input [3:0] exp_rs2);
    begin
      inst = i;
      #1;
      if (control !== exp_ctrl || imm !== exp_imm || rd !== exp_rd ||
          rs1 !== exp_rs1 || rs2 !== exp_rs2) begin
        $display("FAIL %08h", i);
        $display("  ctrl = %023b exp = %023b", control, exp_ctrl);
        $display("  imm  = %08h exp = %08h", imm, exp_imm);
        $display("  rd=%0d exp=%0d rs1=%0d exp=%0d rs2=%0d exp=%0d",
                 rd, exp_rd, rs1, exp_rs1, rs2, exp_rs2);
        errors = errors + 1;
      end else begin
        $display("PASS %08h imm=%08h", i, imm);
      end
    end
  endtask

  initial begin
    errors = 0;
    // ---------- R 型 (src2_imm=0) ----------
    check(rtype(7'b0000000,3,2,3'b000,1), {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd3); // add
    check(rtype(7'b0100000,3,2,3'b000,1), {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_SUB, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd3); // sub
    check(rtype(7'b0000000,3,2,3'b001,1), {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_SLL, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd3); // sll
    check(rtype(7'b0000000,3,2,3'b010,1), {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_SLT, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd3); // slt
    check(rtype(7'b0000000,3,2,3'b011,1), {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_SLTU,1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd3); // sltu
    check(rtype(7'b0000000,3,2,3'b100,1), {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_XOR, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd3); // xor
    check(rtype(7'b0000000,3,2,3'b101,1), {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_SRL, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd3); // srl
    check(rtype(7'b0100000,3,2,3'b101,1), {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_SRA, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd3); // sra
    check(rtype(7'b0000000,3,2,3'b110,1), {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_OR,  1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd3); // or
    check(rtype(7'b0000000,3,2,3'b111,1), {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_AND, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd3); // and
    // ---------- M 型 (src2_imm=0) ----------
    check(rtype(7'b0000001,3,2,3'b000,1), {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_MUL,  1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd3); // mul
    check(rtype(7'b0000001,3,2,3'b001,1), {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_MULH, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd3); // mulh
    check(rtype(7'b0000001,3,2,3'b011,1), {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_MULHU,1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd3); // mulhu
    check(rtype(7'b0000001,3,2,3'b100,1), {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_DIV,  1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd3); // div
    check(rtype(7'b0000001,3,2,3'b101,1), {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_DIVU, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd3); // divu
    check(rtype(7'b0000001,3,2,3'b110,1), {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_REM,  1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd3); // rem
    check(rtype(7'b0000001,3,2,3'b111,1), {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_REMU, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd3); // remu
    // ---------- Load (src2_imm=1) ----------
    check(itype(12'h000,2,3'b000,1,7'b0000011), {1'b1,`BR_EQ,2'd1,1'b1,`MEM_1B,1'b0,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b1,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd0); // lb
    check(itype(12'h000,2,3'b001,1,7'b0000011), {1'b1,`BR_EQ,2'd1,1'b1,`MEM_2B,1'b0,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b1,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd0); // lh
    check(itype(12'h004,2,3'b010,1,7'b0000011), {1'b1,`BR_EQ,2'd1,1'b0,`MEM_4B,1'b0,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b1,1'b0,1'b1}, 32'h4,4'd1,4'd2,4'd4); // lw
    check(itype(12'h000,2,3'b100,1,7'b0000011), {1'b1,`BR_EQ,2'd1,1'b0,`MEM_1B,1'b0,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b1,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd0); // lbu
    check(itype(12'h000,2,3'b101,1,7'b0000011), {1'b1,`BR_EQ,2'd1,1'b0,`MEM_2B,1'b0,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b1,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd0); // lhu
    // ---------- Store (src2_imm=1) ----------
    check(stype(12'h000,3,2,3'b000), {1'b1,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b1,1'b0}, 32'h0,4'd0,4'd2,4'd3); // sb
    check(stype(12'h000,3,2,3'b001), {1'b1,`BR_EQ,2'd0,1'b0,`MEM_2B,1'b0,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b1,1'b0}, 32'h0,4'd0,4'd2,4'd3); // sh
    check(stype(12'h008,3,2,3'b010), {1'b1,`BR_EQ,2'd0,1'b0,`MEM_4B,1'b0,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b1,1'b0}, 32'h8,4'd8,4'd2,4'd3); // sw
    // ---------- OP-IMM (src2_imm=1) ----------
    check(itype(12'hFFF,2,3'b000,1,7'b0010011), {1'b1,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'hFFFFFFFF,4'd1,4'd2,4'd15); // addi -1
    check(itype(12'h003,2,3'b010,1,7'b0010011), {1'b1,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_SLT, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h3,4'd1,4'd2,4'd3); // slti
    check(itype(12'h800,2,3'b010,1,7'b0010011), {1'b1,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_SLT, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'hFFFFF800,4'd1,4'd2,4'd0); // slti 负数
    check(itype(12'h003,2,3'b011,1,7'b0010011), {1'b1,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_SLTU,1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h3,4'd1,4'd2,4'd3); // sltiu
    check(itype(12'h003,2,3'b100,1,7'b0010011), {1'b1,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_XOR, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h3,4'd1,4'd2,4'd3); // xori
    check(itype(12'h003,2,3'b110,1,7'b0010011), {1'b1,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_OR,  1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h3,4'd1,4'd2,4'd3); // ori
    check(itype(12'h003,2,3'b111,1,7'b0010011), {1'b1,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_AND, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h3,4'd1,4'd2,4'd3); // andi
    check(shifti(7'b0000000,3,2,3'b001,1),     {1'b1,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_SLL, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h3,4'd1,4'd2,4'd3); // slli
    check(shifti(7'b0000000,3,2,3'b101,1),     {1'b1,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_SRL, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h3,4'd1,4'd2,4'd3); // srli
    check(shifti(7'b0100000,3,2,3'b101,1),     {1'b1,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_SRA, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h3,4'd1,4'd2,4'd3); // srai
    // ---------- U 型 (lui: src2_imm=0; auipc: src2_imm=1) ----------
    check(utype(20'h12345,1,7'b0110111), {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_PASS_IMM, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h12345000,4'd1,4'd8,4'd3); // lui
    check(utype(20'h00000,1,7'b0010111), {1'b1,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b1,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd1,4'd0,4'd0); // auipc
    // ---------- 跳转 (src2_imm=1) ----------
    check(jtype(21'h00000,1), {1'b1,`BR_EQ,2'd2,1'b0,`MEM_1B,1'b1,`ALU_ADD, 1'b0,1'b0,1'b0,1'b1,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd1,4'd0,4'd0); // jal
    check(itype(12'h000,2,3'b000,1,7'b1100111), {1'b1,`BR_EQ,2'd2,1'b0,`MEM_1B,1'b0,`ALU_ADD, 1'b0,1'b0,1'b1,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd1,4'd2,4'd0); // jalr
    // ---------- 分支 (src2_imm=1) ----------
    check(btype(13'h0004,2,1,3'b000), {1'b1,`BR_EQ, 2'd0,1'b0,`MEM_1B,1'b1,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b1, 1'b0,1'b0,1'b0}, 32'h4,4'd4,4'd1,4'd2); // beq
    check(btype(13'h0004,2,1,3'b001), {1'b1,`BR_NE, 2'd0,1'b0,`MEM_1B,1'b1,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b1, 1'b0,1'b0,1'b0}, 32'h4,4'd4,4'd1,4'd2); // bne
    check(btype(13'h0004,2,1,3'b100), {1'b1,`BR_LT, 2'd0,1'b0,`MEM_1B,1'b1,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b1, 1'b0,1'b0,1'b0}, 32'h4,4'd4,4'd1,4'd2); // blt
    check(btype(13'h0004,2,1,3'b101), {1'b1,`BR_GE, 2'd0,1'b0,`MEM_1B,1'b1,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b1, 1'b0,1'b0,1'b0}, 32'h4,4'd4,4'd1,4'd2); // bge
    check(btype(13'h0004,2,1,3'b110), {1'b1,`BR_LTU,2'd0,1'b0,`MEM_1B,1'b1,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b1, 1'b0,1'b0,1'b0}, 32'h4,4'd4,4'd1,4'd2); // bltu
    check(btype(13'h0004,2,1,3'b111), {1'b1,`BR_GEU,2'd0,1'b0,`MEM_1B,1'b1,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b1, 1'b0,1'b0,1'b0}, 32'h4,4'd4,4'd1,4'd2); // bgeu
    check(btype(13'h1000,2,1,3'b000), {1'b1,`BR_EQ, 2'd0,1'b0,`MEM_1B,1'b1,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b1, 1'b0,1'b0,1'b0}, 32'hFFFFF000,4'd0,4'd1,4'd2); // beq -4096
    // ---------- SYSTEM / 非法 (src2_imm=0) ----------
    check(32'h00100073, {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_ADD, 1'b0,1'b1,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b0}, 32'h0,4'd0,4'd0,4'd1); // ebreak
    check(32'h00000073, {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_ADD, 1'b1,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b0}, 32'h0,4'd0,4'd0,4'd0); // ecall → illegal
    check(32'hFFFFFFFF, {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_ADD, 1'b1,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b0}, 32'h0,4'd15,4'd15,4'd15); // 全 1 → illegal
    check(itype(12'h000,0,3'b000,16,7'b0010011), {1'b1,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd0,4'd0,4'd0); // addi x16 → rd=x0
    // ---------- 原始编码抽查 ----------
    check(32'hFFF10093, {1'b1,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'hFFFFFFFF,4'd1,4'd2,4'd15); // addi x1,x2,-1
    check(32'h00412083, {1'b1,`BR_EQ,2'd1,1'b0,`MEM_4B,1'b0,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b1,1'b0,1'b1}, 32'h4,4'd1,4'd2,4'd4); // lw x1,4(x2)
    check(32'h00312423, {1'b1,`BR_EQ,2'd0,1'b0,`MEM_4B,1'b0,`ALU_ADD, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b1,1'b0}, 32'h8,4'd8,4'd2,4'd3); // sw x3,8(x2)
    check(32'h000000EF, {1'b1,`BR_EQ,2'd2,1'b0,`MEM_1B,1'b1,`ALU_ADD, 1'b0,1'b0,1'b0,1'b1,1'b0, 1'b0,1'b0,1'b1}, 32'h0,4'd1,4'd0,4'd0); // jal x1,0
    check(32'h123450B7, {1'b0,`BR_EQ,2'd0,1'b0,`MEM_1B,1'b0,`ALU_PASS_IMM, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1}, 32'h12345000,4'd1,4'd8,4'd3); // lui x1,0x12345

    if (errors == 0) $display("== ALL TESTS PASSED =="); else $display("== %0d TESTS FAILED ==", errors);
    $finish;
  end
endmodule
