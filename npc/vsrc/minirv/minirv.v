`include "ctrl_defs.v"
module minirv(
  input clk,
  output [31:0] Pcout,
  output halt,
  output illegal,
  output [31:0] check
);
  wire [3:0] rs1, rs2, rd;
  wire [31:0] inst, src1, src2, imm, sum, w_data, r_mem_data;
  wire [`CTRL_NUM-1:0] control;
  reg [31:0] PC;
  wire [31:0] PcJump;

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
    .wen  (control[`CTRL_WEN_REG]),
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
    .control(control)
  );

  EXU exu (
     .src1   (src1),
     .src2   (src2),
     .imm    (imm),
     .pc     (PC),
     .control(control),
     .sum    (sum)
   );

  //sum可直通addr
  LSU lsu (
    .clk     (clk),
    .wen     (control[`CTRL_WEN_MEM]),
    .ren     (control[`CTRL_REN_MEM]),
    .addr    (sum),
    .wdata   (src2),
    .mem_size(control[`CTRL_MEM_SIZE +: 2]),
    .mem_sign(control[`CTRL_MEM_SIGN]),
    .odata   (r_mem_data)
  );

  WBU wbu (
    .src1    (src1),
    .src2    (src2),
    .next_PC (PC+4),
    .sum     (sum),
    .mem_data(r_mem_data),
    .wb_src  (control[`CTRL_WB_SRC +: 2]),
    .is_branch(control[`CTRL_IS_BRANCH]),
    .is_jal  (control[`CTRL_IS_JAL]),
    .is_jalr (control[`CTRL_IS_JALR]),
    .br_type (control[`CTRL_BR_TYPE +: 3]),
    .result  (w_data),
    .pcjump  (PcJump)
  );

  assign halt = control[`CTRL_HALT];
  assign illegal = control[`CTRL_ILLEGAL];
  assign Pcout = PC;

  always @(posedge clk) begin
    //$display("[%0t] PC=0x%h", $time, PC);
    //$display("  Decode: rs1=%0d rs2=%0d rd=%0d control=%b mask=%b",
    //        rs1, rs2, rd, control, mask);
    //$display("  Src: src1=0x%h src2=0x%h imm=0x%h",
    //         src1, src2, imm);
    //$display("  Exec: sum=0x%h w_data=0x%h r_mem=0x%h",
    //         sum, w_data, r_mem_data);
    //$display("  Enables: wen_reg=%b wen_mem=%b wen_pc=%b",
    //         control[`CTRL_WEN_REG], control[`CTRL_WEN_MEM], wen_pc);
    //$display("------------------------");
    if(illegal) PC <= PC;
    else PC <= PcJump;
  end

endmodule
