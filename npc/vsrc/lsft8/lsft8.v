module lsft8(
  input clk,
  input rst,
  output reg [13:0] led
);

reg [7:0] num;

always @(posedge clk) begin
  if(rst) begin
    num <= 8'd1;
  end
  else begin
    num[7] <= num[4] ^ num[3] ^ num[2] ^ num[0];
    for(int i = 6; i >= 0; i--) num[i] <= num[i+1];
  end
end

bcd7seg light0(num[3:0], 1'd0, led[6:0]);
bcd7seg light1(num[7:4], 1'd0, led[13:7]);

endmodule
