module minirv(
  input clk,
  output [31:0] Pcout,
  output halt,
  output [31:0] check
);
  wire [3:0] rs1, rs2, rd, control, mask;
  wire [31:0] inst, src1, src2, imm, sum, w_data, r_mem_data;
  wire wen_reg, wen_mem, wen_pc, ren_mem;
  reg [31:0] PC;

initial begin
    PC = 32'h8000_0000;
end
  import "DPI-C" function int unsigned pmem_read(input int unsigned raddr);
  assign inst = pmem_read(PC);
 
  RegisterFile #(
    .ADDR_WIDTH(4),
    .DATA_WIDTH(32)
   ) registerFile (
    .clk  (clk),
    .wen  (wen_reg),
    .wdata(w_data),
    .waddr(rd),
    .caddr(10),
    .rs1  (rs1),
    .rs2  (rs2),
    .src1 (src1),
    .src2 (src2),
    .check(check)
  );

  IDU idu (
    .inst(inst),
    .rs1 (rs1),
    .rs2 (rs2),
    .rd  (rd),
    .imm (imm),
    .control(control),
    .wen_reg(wen_reg),
    .wen_mem(wen_mem),
    .wen_pc(wen_pc),
    .ren_mem(ren_mem),
    .halt(halt)
  );

  EXU exu (
     .src1   (src1),
     .src2   (src2),
     .imm    (imm),
     .control(control),
     .sum    (sum),
     .mask   (mask)
   ); 

  //sum可直通addr
  //暂时只有src2写入内存
  LSU lsu (
    .clk  (clk),
    .wen  (wen_mem),
    .ren  (ren_mem),
    .addr (sum),
    .wdata(src2),
    .mask (mask),
    .odata(r_mem_data)
  );

  WBU wbu (
    .PC      (PC),
    .sum     (sum),
    .mem_data(r_mem_data),
    .control (control),
    .result  (w_data)
  );

  always @(posedge clk) begin
    //$display("[%0t] PC=0x%h", $time, PC);
    //$display("  Decode: rs1=%0d rs2=%0d rd=%0d control=%b mask=%b",
    //        rs1, rs2, rd, control, mask);
    //$display("  Src: src1=0x%h src2=0x%h imm=0x%h",
    //         src1, src2, imm);
    //$display("  Exec: sum=0x%h w_data=0x%h r_mem=0x%h",
    //         sum, w_data, r_mem_data);
    //$display("  Enables: wen_reg=%b wen_mem=%b wen_pc=%b",
    //         wen_reg, wen_mem, wen_pc);
    //$display("------------------------");
    if(wen_pc) PC <= (sum & ~(1));
    else PC <= PC+4;
  end

assign Pcout = PC;
endmodule
