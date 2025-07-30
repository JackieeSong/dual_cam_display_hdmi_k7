`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/30 10:28:36
// Design Name: 
// Module Name: IIC_TOP
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


module IIC_TOP(
	//输入时钟 复位
	input   wire      clk,			//输入时钟400k*8
	input   wire      rst,			//复位信号
	//输出控制信息	
	input   wire      start,		//启动配置
	output  wire      done,		 	//配置完成	
	//输出IIC接口		
	output  wire      i2c_scl,		//inout时钟线
	inout   wire      i2c_sda		//inout数据线
    );

	wire 		  finish; 	 		//操作完成
	//写数据				
	wire       	  write_en;	 		//发送使能
	wire		  write_ok;	 		//发送完成
	wire 		  write_ack;
	wire [7:0] 	  write_byte;		//发送数据
	//读数据			
	wire       	  read_en;	 		//发送使能
	wire	  	  read_ok;	 		//发送完成
	wire 		  read_ack;
	wire [7:0] 	  read_byte; 		//发送数据	
	
	wire [9 :0]	  cmos_lut_index;	//查找表地址
	wire [31:0]	  cmos_lut_data;	//查找表数据
	wire [7 :0]	  lut_dev_addr;	 	//输入32位数据解析输入
	wire [15:0]	  lut_reg_addr;	 	//16位
	wire [7 :0]	  lut_reg_data;	 	//8位
	
	assign 	lut_dev_addr = cmos_lut_data[31:24];	 //输入32位数据解析输
	assign 	lut_reg_addr = cmos_lut_data[23: 8];	 //16位
	assign 	lut_reg_data = cmos_lut_data[7 : 0]; //8位	

//OV5640配置寄存器模块
OV5640REG_CONFIG U0(
	.lut_index   (cmos_lut_index),//输入查找表地址编号
	.lut_data    (cmos_lut_data ) //输出配置信息
	);	

//寄存器配置模块	
IIC_CONFIG	U1(
	//输入时钟 复位
	.clk		 (clk			),//输入时钟
	.rst		 (rst			),//复位信号
	.lut_index   (cmos_lut_index),//输入查找表地址编号
	//输入配置信息	  
	.lut_dev_addr(lut_dev_addr	),//OV5640器件地址
	.lut_reg_addr(lut_reg_addr	),//寄存器地址
	.lut_reg_data(lut_reg_data	),//寄存器数据
	//输出控制信息	
	.start		 (start			),//启动配置信号
	.done		 (done			),//配置完成信号
	//输出IIC接口				
	.finish		 (finish		),//操作完成
	//写数据	  				         
	.write_en	 (write_en		),//发送使能
	.write_ok	 (write_ok		),//发送完成
	.write_ack	 (write_ack		),//写应答
	.write_byte	 (write_byte	),//发送数据
	//读数据	  				             
	.read_en	 (read_en		),//发送使能
	.read_ok	 (read_ok		),//发送完成
	.read_ack	 (read_ack		),//读应答
	.read_byte 	 (read_byte		) //发送数据
    );

//字节配置IIC模块	
IIC_WR_BYTE	U2(
	//输入时钟 复位
	.clk		 (clk			),//输入时钟
	.rst		 (rst			),//复位信号
	//输出控制信息
	.finish		 (finish		),//操作完成
	//写数据	 			
	.write_en	 (write_en		),//发送使能
	.write_ok	 (write_ok		),//发送完成
	.write_ack	 (write_ack		),//写应答
	.write_byte	 (write_byte	),//发送数据
	//读数据	 		
	.read_en	 (read_en		),//发送使能
	.read_ok	 (read_ok		),//发送完成
	.read_ack	 (read_ack		),//读应答
	.read_byte	 (read_byte		),//发送数据
	//输出IIC接口				         
	.i2c_scl	 (i2c_scl	 	),//inout时钟线
	.i2c_sda	 (i2c_sda	 	) //inout数据线
    );
	
endmodule
