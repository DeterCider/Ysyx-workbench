module IDU(
  input [31:0] inst,
  output [3:0] rs1,
  output [3:0] rs2,
  output [3:0] rd,
  output reg [3:0] control,
  output reg [31:0] imm,
  output reg wen_reg,
  output reg wen_mem,
  output reg wen_pc,
  output reg ren_mem,
  output reg halt
);

wire [31:0] immI, immU, immS;
assign rs1 = inst[18:15];
assign rs2 = inst[23:20];
assign rd = inst[10:7];
assign immI = {{20{inst[31]}}, inst[31:20]};
assign immU = {inst[31:12], 12'd0};
assign immS = {{20{inst[31]}}, inst[31:25], inst[11:7]};

always @(*) begin
  wen_reg = 0;
  wen_mem = 0;
  wen_pc = 0;
  ren_mem = 0;
  halt = 0;
  casez(inst)
    32'b???????_?????_?????_100_?????_00000_11: begin
      //lbu
      imm = immI;
      control = 1;
      wen_reg = 1;
      ren_mem = 1;
    end
    32'b???????_?????_?????_010_?????_00000_11: begin
      //lw
      imm = immI;
      control = 2;
      wen_reg = 1;
      ren_mem = 1;
    end
    32'b???????_?????_?????_???_?????_01101_11: begin
      //lui
      imm = immU;
      control = 3;
      wen_reg = 1;
    end
    32'b???????_?????_?????_000_?????_11001_11: begin
      //jalr
      imm = immI;
      control = 4;
      wen_pc = 1;
      wen_reg = 1;
    end
    32'b???????_?????_?????_010_?????_01000_11: begin
      //sw
      imm = immS;
      control = 5;
      wen_mem = 1;
    end
    32'b???????_?????_?????_000_?????_01000_11: begin
      //sb
      imm = immS;
      control = 6;
      wen_mem = 1;
    end
    32'b???????_?????_?????_000_?????_00100_11: begin
      //addi
      imm = immI;
      control = 7;
      wen_reg = 1;
    end
    32'b0000000_?????_?????_000_?????_01100_11: begin
      //add
      imm = 0;
      control = 8;
      wen_reg = 1;
    end
    32'h00100073: begin
      halt = 1;
    end
    default: begin
      imm = 0;
      control = 0;
    end
  endcase
end


endmodule
