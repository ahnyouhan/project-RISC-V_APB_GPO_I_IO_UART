`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/23 15:02:38
// Design Name: 
// Module Name: tb_mcu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_mcu();
    logic clk;
    logic reset;
    logic [3:0] gpo;

    MCU dut(.*);

    always #5 clk = ~clk;

    initial begin
        #00 clk = 0; reset = 1;
        #10 reset = 0;
    end
endmodule
