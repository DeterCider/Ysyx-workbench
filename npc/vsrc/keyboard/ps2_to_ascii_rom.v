module ps2_to_ascii_rom (
    input  wire [7:0] scancode,   // PS/2 通码（Set 2）
    input  wire       shift,      // 1: 大写 / 符号上档
    output reg  [7:0] ascii,      // ASCII 码
    output reg        valid       // 1: 当前键码有效
);

    always @(*) begin
        case ({shift, scancode})
            // ========== 字母（shift=0 小写，shift=1 大写） ==========
            {1'b0, 8'h1C}: begin ascii = "a"; valid = 1; end // A
            {1'b1, 8'h1C}: begin ascii = "A"; valid = 1; end
            {1'b0, 8'h32}: begin ascii = "b"; valid = 1; end // B
            {1'b1, 8'h32}: begin ascii = "B"; valid = 1; end
            {1'b0, 8'h21}: begin ascii = "c"; valid = 1; end // C
            {1'b1, 8'h21}: begin ascii = "C"; valid = 1; end
            {1'b0, 8'h23}: begin ascii = "d"; valid = 1; end // D
            {1'b1, 8'h23}: begin ascii = "D"; valid = 1; end
            {1'b0, 8'h24}: begin ascii = "e"; valid = 1; end // E
            {1'b1, 8'h24}: begin ascii = "E"; valid = 1; end
            {1'b0, 8'h2B}: begin ascii = "f"; valid = 1; end // F
            {1'b1, 8'h2B}: begin ascii = "F"; valid = 1; end
            {1'b0, 8'h34}: begin ascii = "g"; valid = 1; end // G
            {1'b1, 8'h34}: begin ascii = "G"; valid = 1; end
            {1'b0, 8'h33}: begin ascii = "h"; valid = 1; end // H
            {1'b1, 8'h33}: begin ascii = "H"; valid = 1; end
            {1'b0, 8'h43}: begin ascii = "i"; valid = 1; end // I
            {1'b1, 8'h43}: begin ascii = "I"; valid = 1; end
            {1'b0, 8'h3B}: begin ascii = "j"; valid = 1; end // J
            {1'b1, 8'h3B}: begin ascii = "J"; valid = 1; end
            {1'b0, 8'h42}: begin ascii = "k"; valid = 1; end // K
            {1'b1, 8'h42}: begin ascii = "K"; valid = 1; end
            {1'b0, 8'h4B}: begin ascii = "l"; valid = 1; end // L
            {1'b1, 8'h4B}: begin ascii = "L"; valid = 1; end
            {1'b0, 8'h3A}: begin ascii = "m"; valid = 1; end // M
            {1'b1, 8'h3A}: begin ascii = "M"; valid = 1; end
            {1'b0, 8'h31}: begin ascii = "n"; valid = 1; end // N
            {1'b1, 8'h31}: begin ascii = "N"; valid = 1; end
            {1'b0, 8'h44}: begin ascii = "o"; valid = 1; end // O
            {1'b1, 8'h44}: begin ascii = "O"; valid = 1; end
            {1'b0, 8'h4D}: begin ascii = "p"; valid = 1; end // P
            {1'b1, 8'h4D}: begin ascii = "P"; valid = 1; end
            {1'b0, 8'h15}: begin ascii = "q"; valid = 1; end // Q
            {1'b1, 8'h15}: begin ascii = "Q"; valid = 1; end
            {1'b0, 8'h2D}: begin ascii = "r"; valid = 1; end // R
            {1'b1, 8'h2D}: begin ascii = "R"; valid = 1; end
            {1'b0, 8'h1B}: begin ascii = "s"; valid = 1; end // S
            {1'b1, 8'h1B}: begin ascii = "S"; valid = 1; end
            {1'b0, 8'h2C}: begin ascii = "t"; valid = 1; end // T
            {1'b1, 8'h2C}: begin ascii = "T"; valid = 1; end
            {1'b0, 8'h3C}: begin ascii = "u"; valid = 1; end // U
            {1'b1, 8'h3C}: begin ascii = "U"; valid = 1; end
            {1'b0, 8'h2A}: begin ascii = "v"; valid = 1; end // V
            {1'b1, 8'h2A}: begin ascii = "V"; valid = 1; end
            {1'b0, 8'h1D}: begin ascii = "w"; valid = 1; end // W
            {1'b1, 8'h1D}: begin ascii = "W"; valid = 1; end
            {1'b0, 8'h22}: begin ascii = "x"; valid = 1; end // X
            {1'b1, 8'h22}: begin ascii = "X"; valid = 1; end
            {1'b0, 8'h35}: begin ascii = "y"; valid = 1; end // Y
            {1'b1, 8'h35}: begin ascii = "Y"; valid = 1; end
            {1'b0, 8'h1A}: begin ascii = "z"; valid = 1; end // Z
            {1'b1, 8'h1A}: begin ascii = "Z"; valid = 1; end

            // ========== 数字（不随 shift 改变，按需可扩展 !@#$...） ==========
            {1'b0, 8'h16}: begin ascii = "1"; valid = 1; end
            {1'b1, 8'h16}: begin ascii = "1"; valid = 1; end
            {1'b0, 8'h1E}: begin ascii = "2"; valid = 1; end
            {1'b1, 8'h1E}: begin ascii = "2"; valid = 1; end
            {1'b0, 8'h26}: begin ascii = "3"; valid = 1; end
            {1'b1, 8'h26}: begin ascii = "3"; valid = 1; end
            {1'b0, 8'h25}: begin ascii = "4"; valid = 1; end
            {1'b1, 8'h25}: begin ascii = "4"; valid = 1; end
            {1'b0, 8'h2E}: begin ascii = "5"; valid = 1; end
            {1'b1, 8'h2E}: begin ascii = "5"; valid = 1; end
            {1'b0, 8'h36}: begin ascii = "6"; valid = 1; end
            {1'b1, 8'h36}: begin ascii = "6"; valid = 1; end
            {1'b0, 8'h3D}: begin ascii = "7"; valid = 1; end
            {1'b1, 8'h3D}: begin ascii = "7"; valid = 1; end
            {1'b0, 8'h3E}: begin ascii = "8"; valid = 1; end
            {1'b1, 8'h3E}: begin ascii = "8"; valid = 1; end
            {1'b0, 8'h46}: begin ascii = "9"; valid = 1; end
            {1'b1, 8'h46}: begin ascii = "9"; valid = 1; end
            {1'b0, 8'h45}: begin ascii = "0"; valid = 1; end
            {1'b1, 8'h45}: begin ascii = "0"; valid = 1; end

            // ========== 常用控制键与符号 ==========
            {1'b0, 8'h29}: begin ascii = " "; valid = 1; end // 空格
            {1'b1, 8'h29}: begin ascii = " "; valid = 1; end
            {1'b0, 8'h5A}: begin ascii = 8'd10; valid = 1; end // Enter（换行 LF）
            {1'b1, 8'h5A}: begin ascii = 8'd10; valid = 1; end
            {1'b0, 8'h66}: begin ascii = 8'd8 ; valid = 1; end // Backspace
            {1'b1, 8'h66}: begin ascii = 8'd8 ; valid = 1; end
            {1'b0, 8'h0D}: begin ascii = 8'd9 ; valid = 1; end // Tab
            {1'b1, 8'h0D}: begin ascii = 8'd9 ; valid = 1; end
            {1'b0, 8'h76}: begin ascii = 8'd27; valid = 1; end // Esc
            {1'b1, 8'h76}: begin ascii = 8'd27; valid = 1; end

            {1'b0, 8'h4E}: begin ascii = "-"; valid = 1; end
            {1'b1, 8'h4E}: begin ascii = "-"; valid = 1; end
            {1'b0, 8'h55}: begin ascii = "="; valid = 1; end
            {1'b1, 8'h55}: begin ascii = "="; valid = 1; end
            {1'b0, 8'h54}: begin ascii = "["; valid = 1; end
            {1'b1, 8'h54}: begin ascii = "["; valid = 1; end
            {1'b0, 8'h5B}: begin ascii = "]"; valid = 1; end
            {1'b1, 8'h5B}: begin ascii = "]"; valid = 1; end
            {1'b0, 8'h4C}: begin ascii = ";"; valid = 1; end
            {1'b1, 8'h4C}: begin ascii = ";"; valid = 1; end
            {1'b0, 8'h52}: begin ascii = "'"; valid = 1; end
            {1'b1, 8'h52}: begin ascii = "'"; valid = 1; end
            {1'b0, 8'h41}: begin ascii = ","; valid = 1; end
            {1'b1, 8'h41}: begin ascii = ","; valid = 1; end
            {1'b0, 8'h49}: begin ascii = "."; valid = 1; end
            {1'b1, 8'h49}: begin ascii = "."; valid = 1; end
            {1'b0, 8'h4A}: begin ascii = "/"; valid = 1; end
            {1'b1, 8'h4A}: begin ascii = "/"; valid = 1; end

            default: begin ascii = 0; valid = 0; end
        endcase
    end

endmodule
