module EXU(
  input [31:0] src1,
  input [31:0] src2,
  input [31:0] imm,
  input [3:0] control,
  output reg [3:0] mask,
  output reg [31:0] sum
);


always @(*) begin
  mask = 4'b1111;
  case(control)
    1, 2, 4, 7: sum = src1 + imm; //I
    3: sum = imm; //U
    5, 6: sum = src1 + imm; //S
    8: sum = src1 + src2;  //R
    default: sum = 0;
  endcase
  if(control == 1 || control == 6) begin
    case(sum[1:0])
      0:mask = 4'b0001;
      1:mask = 4'b0010;
      2:mask = 4'b0100;
      3:mask = 4'b1000;
      default: mask = 0;
    endcase
  end

end



endmodule
