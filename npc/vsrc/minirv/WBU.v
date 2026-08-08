//write reg
module WBU(
  input [31:0] sum,
  input [31:0] mem_data,
  input [31:0] PC,
  input [3:0] control,
  output reg [31:0] result
);


always @(*)begin
  case(control)
    1,2: result = mem_data;
    3,7,8: result = sum;
    4: result = PC + 4;
    default: result = 0;
  endcase
end


endmodule
