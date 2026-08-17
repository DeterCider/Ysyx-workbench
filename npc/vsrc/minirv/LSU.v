`include "ctrl_defs.v"
module LSU(
  input clk,
  input wen,
  input ren,
  input [31:0] addr,
  input [31:0] wdata,
  input [1:0] mem_size,
  input mem_sign,
  output reg [31:0] odata
);

import "DPI-C" function int unsigned pmem_read(input int unsigned raddr);
import "DPI-C" function void pmem_write(
  input int unsigned waddr, input int unsigned wdata, input byte wmask);

//ren为0时惰性求值
wire [31:0] rdata = (ren)? pmem_read(addr): 0;
wire [31:0] sh = rdata >> {addr[1:0], 3'b0};
wire [31:0] byte_c = {{24{sh[7]  & mem_sign}}, sh[7:0]};
wire [31:0] half_c = {{16{sh[15] & mem_sign}}, sh[15:0]};
wire [31:0] word_c = sh;

assign odata = (mem_size == `MEM_1B) ? byte_c :
               (mem_size == `MEM_2B) ? half_c : word_c;

wire [3:0] mask = ((mem_size == `MEM_1B)? 4'b0001:
                  (mem_size == `MEM_2B)? 4'b0011: 4'b1111) << addr[1:0];

always @(posedge clk) begin
  if (wen) begin // 有写请求时
    pmem_write(addr, wdata << {addr[1:0], 3'b0} , {4'd0, mask});
  end
end

endmodule
