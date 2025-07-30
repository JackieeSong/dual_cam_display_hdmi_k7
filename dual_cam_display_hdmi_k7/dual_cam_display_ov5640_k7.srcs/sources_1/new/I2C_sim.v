`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/25 10:40:36
// Design Name: 
// Module Name: I2C_sim
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


module I2C_sim(
    input sys_clk,
    inout                       cmos2_scl,          //cmos i2c clock
    inout                       cmos2_sda          //cmos i2c data
    );


wire                            clk_200MHz;
wire                            clk_50MHz;
wire clk_25MHz;
wire glbl_rst;
wire                            video_clk;                 //video pixel clock
wire                            video_clk5x;


wire   write_clk ;
wire vsync;
wire usr_vsync;
wire usr_hsync;
wire usr_de;
wire [23:0] usr_rgb;
wire rst_pclk;
reg rst_pclk_syn;
wire rst_50Mhz;
reg rst_50Mhz_syn;
reg config_rest;
wire mmcm_locked;

wire[15:0]                        cmos_16bit_data;
wire                              cmos_16bit_wr;
wire[9:0]                         cmos_lut_index;
wire[31:0]                        cmos_lut_data;

wire rst;
wire start;
assign rst = ~mmcm_locked;
    clocks inst_clocks
        (
            .sys_clk     (sys_clk),
            .glbl_rst    (glbl_rst),
            .mmcm_locked (mmcm_locked),
            .clk_200MHz  (clk_200MHz),
            .clk_50MHz   (clk_50MHz),
            .clk_25MHz   (clk_25MHz),
            .video_clk5x (video_clk5x),
            .video_clk   (video_clk)
        );






syn_block reset_syn2 (
     .clk              (clk_50MHz),
     .data_in          (rst),
     .data_out         (rst_50Mhz)
  );

always @(posedge clk_50MHz ) begin
     rst_50Mhz_syn<=rst_50Mhz;
end



//上电复位，产生一个拉低摄像头的复位信号
    cmos_reset_gen inst_cmos_reset_gen (
        .clk(clk_50MHz), 
        .reset(rst_50Mhz_syn), 
        .camera_rstn(cmos_rstn)
        );


always @(posedge clk_50MHz ) begin
     config_rest<=rst_50Mhz_syn | ~cmos_rstn;
end

    CMOS_OV5640RST U0(
        .clk            (clk_25MHz      ),
        .rst            (rst            ),          
        .cmos_rst       (cmos_rst_n     ),
        .cmos_start     (start          ) 
        );

        //I2C master controller
        i2c_config_state i2c_config_m0(
            .rst                (rst              ),//??位???
            .clk                (clk_25MHz           ),//系统时?
            .clk_div_cnt        (16'd99              ),//???????
            .start_config       (start               ),
            .i2c_addr_2byte     (1'b1                ),//??????
            .lut_index          (cmos_lut_index      ),//???拇????冶?
            .lut_dev_addr       (cmos_lut_data[31:24]),//???息???
            .lut_reg_addr       (cmos_lut_data[23:8] ),//???息???
            .lut_reg_data       (cmos_lut_data[7:0]  ),//???息???
            .error              (                    ),//??状态?息
            .done               (                    ),//???????
            .i2c_scl            (cmos_scl            ),//IIC时??
            .i2c_sda            (cmos_sda            ) //IIC????
        );


//configure look-up table
lut_ov5640_rgb565_640_480 lut_ov5640_m0(
    .lut_index              (cmos_lut_index       ),//输入查找表地址编号
    .lut_data               (cmos_lut_data        ) //输出配置信息
);


    IIC_TOP U1( 
        //??ʱ? ??λ  
        .clk            (clk_25MHz      ),//??ʱ?400k*8
        .rst            (rst        ),//??λ???  
        //????????          
        .start      (start          ),//?????
        .done       (done           ),//?????
        //???IIC?ӿ?                     
        .i2c_scl        (cmos_scl1       ),//inoutʱ??
        .i2c_sda        (cmos_sda1       ) //inout????
        );
endmodule
