module minirv(
  input clk,
  input [31:0] inst,
  output [31:0] PC
);
  wire [4:0] rs1, rs2, rd, control;
  wire [31:0] imm, add1, add2, sum;

IDU idu (
  .inst(inst),
  .rs1 (rs1),
  .rs2 (rs2),
  .rd  (rd),
  .imm (imm),
  .control(control)
);





endmodule
