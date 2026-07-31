module sumCPU(
  input clk,
  output reg [6:0] led0, led1,
  output stop
);

reg [7:0] PC = 0,r[3:0] = {0, 0, 0, 0}, show;
reg [7:0] mem[7:0] = {8'b01100000,
                      8'b11010001,
                      8'b00101001, 
                      8'b00010111,
                      8'b10110001,
                      8'b10100000,
                      8'b10010000,
                      8'b10001010
};
reg stop1 = 0;
wire [7:0] ir;
assign ir = mem[PC[2:0]];

always @(posedge clk) begin
  if(!stop1) begin
    case (ir[7:6])
      2'b10: begin
        r[ir[5:4]] <= {4'b0, ir[3:0]};
        PC <= PC + 1;
      end
      2'b00: begin
        r[ir[5:4]] <= r[ir[3:2]] + r[ir[1:0]];
        PC <= PC + 1;
      end
      2'b11: begin
        if(r[0] != r[ir[1:0]]) PC <= {4'b0, ir[5:2]};
        else PC <= PC + 1;
      end
      2'b01: begin
        show <= r[ir[5:4]];
        stop1 <= 1;
      end
    endcase
  end
end

bcd7seg my_seg (
  .b   (show[3:0]),
  .sign(0),
  .h   (led0)
);

bcd7seg my_seg2 (
  .b   (show[7:4]),
  .sign(0),
  .h   (led1)
);

assign stop = stop1;




endmodule
