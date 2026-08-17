module RegisterFile #(ADDR_WIDTH = 1, DATA_WIDTH = 1) (
  input clk,
  input wen,
  input [DATA_WIDTH-1:0] wdata,
  input [ADDR_WIDTH-1:0] waddr,
  input [ADDR_WIDTH-1:0] rs1,
  input [ADDR_WIDTH-1:0] rs2,
  input [ADDR_WIDTH-1:0] caddr,
  output [DATA_WIDTH-1:0] src1,
  output [DATA_WIDTH-1:0] src2,
  output [DATA_WIDTH-1:0] check
);
  reg [DATA_WIDTH-1:0] rf [2**ADDR_WIDTH-1:0];
  integer i;
  initial begin
      for (i = 0; i < 2**ADDR_WIDTH; i = i + 1) begin
          rf[i] = 0;
      end
  end
  always @(posedge clk) begin
    if (wen) rf[waddr] <= wdata;
    rf[0] <= 0;
  end
  assign src1 = rf[rs1];
  assign src2 = rf[rs2];
  assign check = rf[caddr];

  export "DPI-C" c_rtl_update_reg = function rtl_update_reg;
  function void rtl_update_reg(output int unsigned vals[2**ADDR_WIDTH-1:0]);
    for(int j = 0; j < 2**ADDR_WIDTH; j++) begin
        vals[j] = rf[j];
    end
  endfunction

endmodule
