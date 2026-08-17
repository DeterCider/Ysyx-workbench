// tb_wbu.v — WBU 回写与跳转逻辑测试台
`include "ctrl_defs.v"
module tb;
  reg [31:0] src1, src2, sum, mem_data, next_PC;
  reg [1:0] wb_src;
  reg is_branch, is_jal, is_jalr;
  reg [2:0] br_type;
  wire [31:0] result, pcjump;
  integer errors;

  WBU wbu(.src1(src1), .src2(src2), .sum(sum), .mem_data(mem_data), .next_PC(next_PC),
          .wb_src(wb_src), .is_branch(is_branch), .is_jal(is_jal), .is_jalr(is_jalr),
          .br_type(br_type), .result(result), .pcjump(pcjump));

  task c(input [31:0] s1, s2, sm, md, np,
         input [1:0] wb, input ib, ij, ijr, input [2:0] bt,
         input [31:0] er, ep);
    begin
      src1 = s1; src2 = s2; sum = sm; mem_data = md; next_PC = np;
      wb_src = wb; is_branch = ib; is_jal = ij; is_jalr = ijr; br_type = bt;
      #1;
      if (result !== er || pcjump !== ep) begin
        errors = errors + 1;
        $display("FAIL result=%08h exp=%08h pcjump=%08h exp=%08h", result, er, pcjump, ep);
      end else $display("PASS result=%08h pcjump=%08h", result, pcjump);
    end
  endtask

  initial begin
    errors = 0;
    // ---- 回写三选一: 0=sum 1=mem 2=PC+4 ----
    c(0,0,32'hA5,32'h5A,32'h1004, 2'd0, 0,0,0, `BR_EQ, 32'hA5,  32'h1004);
    c(0,0,32'hA5,32'h5A,32'h1004, 2'd1, 0,0,0, `BR_EQ, 32'h5A,  32'h1004);
    c(0,0,32'hA5,32'h5A,32'h1004, 2'd2, 0,0,0, `BR_EQ, 32'h1004, 32'h1004);
    // ---- 分支: 条件成立跳 sum, 否则 next_PC (result=sum 是 wb_src=0 的组合输出, 虽不回写) ----
    c(32'h1,32'h1,32'h2000,0,32'h1004, 2'd0, 1,0,0, `BR_EQ,  32'h2000, 32'h2000); // EQ 相等→跳
    c(32'h1,32'h2,32'h2000,0,32'h1004, 2'd0, 1,0,0, `BR_EQ,  32'h2000, 32'h1004); // EQ 不等→顺序
    c(32'h1,32'h2,32'h2000,0,32'h1004, 2'd0, 1,0,0, `BR_NE,  32'h2000, 32'h2000); // NE
    c(32'hFFFFFFF8,32'h1,32'h2000,0,32'h1004, 2'd0, 1,0,0, `BR_LT, 32'h2000, 32'h2000); // 有符号 -8<1→跳
    c(32'h8,32'h1,32'h2000,0,32'h1004, 2'd0, 1,0,0, `BR_LT,  32'h2000, 32'h1004); // 8<1 否→顺序
    c(32'hFFFFFFF8,32'h1,32'h2000,0,32'h1004, 2'd0, 1,0,0, `BR_LTU, 32'h2000, 32'h1004); // 无符号 FFFFFFF8>1→顺序
    c(32'hFFFFFFF8,32'h1,32'h2000,0,32'h1004, 2'd0, 1,0,0, `BR_GE, 32'h2000, 32'h1004); // 有符号 -8>=1 否→顺序
    c(32'hFFFFFFF8,32'h1,32'h2000,0,32'h1004, 2'd0, 1,0,0, `BR_GEU, 32'h2000, 32'h2000); // 无符号 FFFFFFF8>=1→跳
    // ---- jal: pcjump=sum (不取整); jalr: pcjump=sum&~1 ----
    c(0,0,32'h80001000,0,32'h1004, 2'd2, 0,1,0, `BR_EQ, 32'h1004, 32'h80001000);
    c(0,0,32'h80001001,0,32'h1004, 2'd2, 0,0,1, `BR_EQ, 32'h1004, 32'h80001000); // jalr 清 bit0
    if (errors == 0) $display("== WBU ALL PASS =="); else $display("== %0d FAIL ==", errors);
    $finish;
  end
endmodule
