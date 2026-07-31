module Encoder8to3(
  input [7:0] hot,
  input en,
  output [6:0] led
);

reg [2:0] code;
wire [3:0] code_wire;
assign code_wire = {1'b0, code};
bcd7seg light(code_wire, 0, led);
integer i;
always @(*) begin
  if(en) begin
    code = 0;
    for(i = 0; i < 8; i++)
      if(hot[i]) code = i[2:0]; 
  end
  else begin
    code = 0;
  end
end

endmodule
