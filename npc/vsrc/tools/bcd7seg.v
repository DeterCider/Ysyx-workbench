module bcd7seg(
  input  [3:0] b,
  input sign,
  output reg [6:0] h
);

always @(*)begin
  if(sign) begin
    if(|b) h = 7'b0000001;
    else h = 0;
  end
  else begin
    case(b)
      4'd0 : h = 7'b1111110; // 0
      4'd1 : h = 7'b0110000; // 1
      4'd2 : h = 7'b1101101; // 2
      4'd3 : h = 7'b1111001; // 3
      4'd4 : h = 7'b0110011; // 4
      4'd5 : h = 7'b1011011; // 5
      4'd6 : h = 7'b1011111; // 6
      4'd7 : h = 7'b1110000; // 7
      4'd8 : h = 7'b1111111; // 8
      4'd9 : h = 7'b1111011; // 9
      4'd10: h = 7'b1110111; // A
      4'd11: h = 7'b0011111; // b
      4'd12: h = 7'b1001110; // C
      4'd13: h = 7'b0111101; // d
      4'd14: h = 7'b1001111; // E
      4'd15: h = 7'b1000111; // F
      default: h = 7'b0000000; // 全灭
    endcase
  end
  h = ~h;
end


endmodule
