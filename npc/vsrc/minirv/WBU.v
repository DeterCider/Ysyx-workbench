`include "ctrl_defs.v"
module WBU(
  input [31:0] src1,
  input [31:0] src2,
  input [31:0] sum,
  input [31:0] mem_data,
  input [31:0] next_PC,
  input [1:0] wb_src,
  input is_branch,
  input is_jal,
  input is_jalr,
  input [2:0] br_type,
  output reg [31:0] result,
  output reg [31:0] pcjump
);


assign result = (wb_src == 2'd0)? sum:
                (wb_src == 2'd1)? mem_data:
                (wb_src == 2'd2)? next_PC: 0;

always @(*) begin
  if(is_branch) begin
    case(br_type)
      `BR_EQ:  pcjump = (src1 == src2)? sum: next_PC;
      `BR_NE:  pcjump = (src1 != src2)? sum: next_PC;
      `BR_LT:  pcjump = ($signed(src1) < $signed(src2))? sum: next_PC;
      `BR_GE:  pcjump = ($signed(src1) >= $signed(src2))? sum: next_PC;
      `BR_LTU: pcjump = (src1 < src2)? sum: next_PC;
      `BR_GEU: pcjump = (src1 >= src2)? sum: next_PC;
      default: pcjump = next_PC;
    endcase
  end
  else pcjump = (is_jal) ? sum:
                (is_jalr)? sum & (~1): next_PC;
end

endmodule
