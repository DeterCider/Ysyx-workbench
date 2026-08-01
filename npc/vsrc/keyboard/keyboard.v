module keyboard(
  input clk, reset, ps2_clk, ps2_data,
  output reg [6:0] led0, led1, led2, led3, led4, led5,
  output light
);
  reg [9:0] buffer;        // ps2_data bits
  reg [3:0] count;  // count ps2_data bits
  reg [2:0] ps2_clk_sync;
  reg [7:0] history, selected, shift;
  reg [7:0] count_num;
  always @(posedge clk) begin
      ps2_clk_sync <=  {ps2_clk_sync[1:0],ps2_clk};
  end

  wire sampling = ps2_clk_sync[2] & ~ps2_clk_sync[1];
  // start bit, stop bit, odd parit
  wire vis = ((~buffer[0]) && ps2_data && (^buffer[9:1]));
  wire frame_done = sampling && (count == 4'd10) && vis;


  always @(posedge clk) begin
      if (reset) begin // reset
          count <= 0;
          history <= 0;
          selected <= 0;
          shift <= 0;
          count_num <= 0;
      end
      else begin
          if (sampling) begin
            if (count == 4'd10) begin
              if (vis) begin      // odd  parity
                $display("receive %x", buffer[8:1]);
                history <= buffer[8:1];
              end
              count <= 0;     // for next
            end else begin
              buffer[count] <= ps2_data;  // store ps2_data
              count <= count + 3'b1;
            end
          end
          if (history == 8'hf0 && frame_done) begin
            if (buffer[8:1] == 8'h12 || buffer[8:1] == 8'h59) begin
              shift <= 0;
              if(selected == 8'h12 || selected == 8'h59) selected <= 0;
            end
            else begin
              if(shift != 0) selected <= shift;
              else selected <= 0;
            end
          end
          else if(frame_done) begin
            if (buffer[8:1] == 8'h12 || buffer[8:1] == 8'h59) begin
              if(shift == 0) count_num <= count_num + 1;
              shift <= buffer[8:1];
              if(selected == 0) selected <= buffer[8:1];
            end
            else if(buffer[8:1] != 8'hF0) begin
              if(selected != buffer[8:1]) count_num <= count_num + 1;
              selected <= buffer[8:1];
            end
          end
      end
  end
  //always @(*) begin
  //  if(resetn == 0) begin
  //    selected = 0;
  //    shift = 0;
  //  end
  //  if (history[1] == 8'hf0) begin
  //    if (history[0] == 8'h12 || history[0] == 8'h59) shift = 0;
  //    else selected = 0;
  //  end
  //  else if(vis) begin
  //   if (buffer[8:1] == 8'h12 || buffer[8:1] == 8'h59) shift = 1;
  //    else selected = buffer[8:1];
  //  end
  //end
  wire [7:0] infer;
  assign light = |shift;
  ps2_to_ascii_rom rom (
    .scancode(selected),
    .shift   (|shift),
    .ascii   (infer),
    .valid   ()
  );
  bcd7seg lcdseg0 (
    .b   (selected[3:0]),
    .sign(0),
    .h   (led0)
  );
  bcd7seg lcdseg1 (
    .b   (selected[7:4]),
    .sign(0),
    .h   (led1)
  );
  bcd7seg lcdseg2 (
    .b   (infer[3:0]),
    .sign(0),
    .h   (led2)
  );
  bcd7seg lcdseg3 (
    .b   (infer[7:4]),
    .sign(0),
    .h   (led3)
  );
  bcd7seg lcdseg4 (
    .b   (count_num[3:0]),
    .sign(0),
    .h   (led4)
  );
  bcd7seg lcdseg5 (
    .b   (count_num[7:4]),
    .sign(0),
    .h   (led5)
  );
endmodule
