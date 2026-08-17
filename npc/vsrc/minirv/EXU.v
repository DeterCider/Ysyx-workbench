`include "ctrl_defs.v"
module EXU(
  input [31:0] src1,
  input [31:0] src2,
  input [31:0] imm,
  input [31:0] pc,
  input [`CTRL_NUM-1:0] control,
  output reg [31:0] sum
);

//wire的初始化为连续赋值, reg的行为类似initial
wire signed [63:0] mul_tmp = $signed(src1) * $signed(src2);
wire [63:0] mulu_tmp = src1 * src2;

//操作数虽然处理方式相同，但是有src1 与 src2, PC 与 src1, src1 与 imm三种类型
wire [31:0] op1 = (control[`CTRL_ALU_SRC1_PC])? pc: src1;
wire [31:0] op2 = (control[`CTRL_ALU_SRC2_IMM])? imm: src2;

//除法溢出行为未定义

always @(*) begin
  case(control[`CTRL_ALU_OP +: 5])
    `ALU_ADD: sum = op1 + op2;
    `ALU_SUB: sum = op1 - op2;
    `ALU_SLL: sum = op1 << op2[4:0];
    `ALU_SRL: sum = op1 >> op2[4:0];
    `ALU_SRA: sum = $signed(op1) >>> op2[4:0];
    `ALU_SLT: sum = ($signed(op1) < $signed(op2))? 1: 0;
    `ALU_SLTU: sum = (op1 < op2)? 1: 0;
    `ALU_XOR: sum = op1 ^ op2;
    `ALU_OR: sum = op1 | op2;
    `ALU_AND: sum = op1 & op2;
    `ALU_PASS_IMM: sum = imm;
    `ALU_MUL: sum = mul_tmp[31: 0];
    `ALU_MULH: sum = mul_tmp[63: 32];
    `ALU_MULHU: sum = mulu_tmp[63: 32];
    `ALU_DIV: sum = (op2 == 0)? $signed(-1): $signed(op1)/$signed(op2);
    `ALU_DIVU: sum = (op2 == 0)? $signed(-1): op1/op2;
    `ALU_REM: sum = (op2 == 0)? op1: $signed(op1) % $signed(op2);
    `ALU_REMU: sum = (op2 == 0)? op1: op1 % op2;
    default: sum = 32'd0;
  endcase
end



endmodule
