module MultiAlu(
  input cge,
  input [3:0] A,
  input [3:0] B,
  output [6:0] seg,
  output [6:0] seg1,
  output reg overflow,
  output reg cout
);

reg [3:0] C;
reg [2:0] sel;

initial begin
  sel = 3'd0;
end

always @(posedge cge) begin
  if(cge) sel = sel + 1;
  else sel = sel;
end

wire [3:0] sum = A+((~B) + 1'd1);

wire [3:0] sum2, sum3;
reg co1, ov1, co2, ov2;
f_add f_add1 (
  .a       (A),
  .b       (B),
  .sum     (sum2),
  .cout    (co1),
  .overflow(ov1)
);
f_add f_add2 (
  .a       (A),
  .b       ((~B)+1),
  .sum     (sum3),
  .cout    (co2),
  .overflow(ov2)
);


always @(*) begin
  case(sel)
    3'b000: begin
      overflow = ov1;
      cout = co1;
      C = sum2; 
    end
    3'b001: begin
      overflow = ov2;
      cout = co2;
      C = sum3;
    end
    default: begin
      overflow = 0;
      cout = 0;
    end
  endcase
  case(sel)
    3'b010: C = ~A;
    3'b011: C = A & B ;
    3'b100: C = A | B;
    3'b101: C = A ^ B;
    3'b110: begin
      if(A[3] > B[3]) C = 4'd1;
      else if(A[3] < B[3]) C = 4'd0;
      else C = {3'd0, sum[3]};
    end
    3'b111: C = (A == B)? 4'd1: 4'd0;
    default: C = C;
  endcase
end

wire [6:0] in_seg0, in_seg1;
wire [3:0] neg;
assign neg = (~C)+1;
bcd7seg bcd (
  .b   ({1'd0, C[2:0]}),
  .sign(0),
  .h   (in_seg0)
);
bcd7seg bcd1 (
  .b   ({1'd0, neg[2:0]}),
  .sign(0),
  .h   (in_seg1)
);
bcd7seg bcd2 (
  .b   ({3'd0, C[3]}),
  .sign(1),
  .h   (seg1)
);

assign seg = (C[3])? in_seg1: in_seg0;

endmodule

module f_add(input [3:0] a, input [3:0] b, output [3:0] sum, output cout, output overflow);

wire c0, c1, c2;
add1 f1 (
  .a   (a[0]),
  .b   (b[0]),
  .cin (0),
  .sum (sum[0]),
  .cout(c0)
);
add1 f2 (
  .a   (a[1]),
  .b   (b[1]),
  .cin (c0),
  .sum (sum[1]),
  .cout(c1)
);
add1 f3 (
  .a   (a[2]),
  .b   (b[2]),
  .cin (c1),
  .sum (sum[2]),
  .cout(c2)
);
add1 f4 (
  .a   (a[3]),
  .b   (b[3]),
  .cin (c2),
  .sum (sum[3]),
  .cout(cout)
);

assign overflow = c2 ^ cout;


endmodule






module add1 ( input a, input b, input cin,   output sum, output cout );
	wire icout, a2;
    assign a2 = cin ^ a;
    assign icout = (a & cin) & 1;
    assign sum = a2 ^ b;
    assign cout = ((a2 & b) & 1) | icout;
endmodule
