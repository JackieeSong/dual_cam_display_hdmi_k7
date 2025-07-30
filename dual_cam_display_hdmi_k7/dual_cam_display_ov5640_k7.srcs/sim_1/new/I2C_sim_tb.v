`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/25 10:56:17
// Design Name: 
// Module Name: I2C_sim_tb
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

`timescale 1ns/1ps
module I2C_sim_tb(

    );

reg sys_clk;
wire cmos2_scl;
wire cmos2_sda;

 I2C_sim inst_I2C_sim (.sys_clk(sys_clk), .cmos2_scl(cmos2_scl), .cmos2_sda(cmos2_sda));

    initial begin
        sys_clk = 0;
    end

always #20 sys_clk = ~sys_clk;

endmodule



