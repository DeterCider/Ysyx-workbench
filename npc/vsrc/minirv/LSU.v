module LSU(
  input clk,
  input wen,
  input ren,
  input [31:0] addr,
  input [31:0] wdata,
  input [3:0] mask,
  output reg [31:0] odata
);

import "DPI-C" function int unsigned pmem_read(input int unsigned raddr);
import "DPI-C" function void pmem_write(
  input int unsigned waddr, input int unsigned wdata, input byte wmask);
reg [31:0] rdata;
always @(posedge clk) begin
  if (wen) begin // 有写请求时
    pmem_write(addr, wdata << (8*addr[1:0]) , {4'd0, mask});
  end
end

always @(*) begin
  if(ren) begin 
    rdata = pmem_read(addr);
  end
  else rdata = 0;
  case(mask)
    15: odata = rdata;
    default: odata = {24'd0, rdata[8*addr[1:0] +:8]};
  endcase
end

endmodule
