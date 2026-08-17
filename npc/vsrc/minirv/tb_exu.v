// tb_exu.v — 验证用户版 EXU 的关键行为
`include "ctrl_defs.v"
module tb;
  reg [31:0] src1, src2, imm;
  reg [`CTRL_NUM-1:0] control;
  wire [3:0] mask;
  wire [31:0] sum;
  integer errors;

  EXU exu(.src1(src1), .src2(src2), .imm(imm), .control(control), .sum(sum), .mask(mask));

  task t(input [31:0] s1, input [31:0] s2, input [31:0] im, input [4:0] alu, input [31:0] exp);
    begin
      src1 = s1; src2 = s2; imm = im;
      control = {`BR_EQ, 2'd0, 1'b0, `MEM_4B, 1'b0, alu, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0,1'b1};
      #1;
      if (sum !== exp) begin
        errors = errors + 1;
        $display("FAIL alu=%0d src1=%08h src2=%08h imm=%08h sum=%08h exp=%08h", alu, s1, s2, im, sum, exp);
      end else $display("PASS alu=%0d sum=%08h", alu, sum);
    end
  endtask

  initial begin
    errors = 0;
    // addi 语义: src1+imm (src2 字段是垃圾寄存器值 0x99)
    t(32'h10, 32'h99, 32'h05, `ALU_ADD, 32'h15);
    // add 语义: src1+src2
    t(32'h10, 32'h05, 32'h99, `ALU_ADD, 32'h15);
    // mul: 3*4=12 (mul_tmp 是声明初始化, 只算一次 → 应为 x)
    t(32'h3, 32'h4, 32'h0, `ALU_MUL, 32'd12);
    // sra: 算术右移 0x80000000>>>5 = 0xFC000000 (无符号 >>> 会得到 0x04000000)
    t(32'h80000000, 32'h5, 32'h0, `ALU_SRA, 32'hFC000000);
    // srl: 逻辑右移
    t(32'h80000000, 32'h5, 32'h0, `ALU_SRL, 32'h04000000);
    // div 除零 → 0xFFFFFFFF
    t(32'h10, 32'h0, 32'h0, `ALU_DIV, 32'hFFFFFFFF);
    // div 溢出 INT_MIN/-1 → 规范要求 INT_MIN
    t(32'h80000000, 32'hFFFFFFFF, 32'h0, `ALU_DIV, 32'h80000000);
    // rem 除零 → src1
    t(32'h10, 32'h0, 32'h0, `ALU_REM, 32'h10);
    // slli 语义: 移位量在 imm (src2 字段=imm 位)
    t(32'h1, 32'h99, 32'h05, `ALU_SLL, 32'h20);
    if (errors == 0) $display("== ALL PASS =="); else $display("== %0d FAIL ==", errors);
    $finish;
  end
endmodule
