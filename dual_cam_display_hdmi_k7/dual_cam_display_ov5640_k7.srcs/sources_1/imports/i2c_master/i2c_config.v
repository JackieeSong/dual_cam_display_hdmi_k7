//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//  Author: meisq                                                               //
//          msq@qq.com                                                          //
//          ALINX(shanghai) Technology Co.,Ltd                                  //
//          heijin                                                              //
//     WEB: http://www.alinx.cn/                                                //
//     BBS: http://www.heijin.org/                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
// Copyright (c) 2017,ALINX(shanghai) Technology Co.,Ltd                        //
//                    All rights reserved                                       //
//                                                                              //
// This source file may be used and distributed without restriction provided    //
// that this copyright statement is not removed from the file and that any      //
// derivative work contains the original copyright notice and the associated    //
// disclaimer.                                                                  //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////

//================================================================================
//  Revision History:
//  Date          By            Revision    Change Description
//--------------------------------------------------------------------------------
//  2017/7/19     meisq          1.0         Original
//*******************************************************************************/

//IIC信息配置
module i2c_config(
	input              rst,					//复位信号
	input              clk,					//输入时钟
	input[15:0]        clk_div_cnt,			//分频计数值
	input              i2c_addr_2byte,  	//输入地址1位2位标志信号
	output reg[9:0]    lut_index,			//配置信息地址查找表
	input[7:0]         lut_dev_addr,		//输入32位数据解析输入
	input[15:0]        lut_reg_addr,		//16位
	input[7:0]         lut_reg_data,		//8位
	output reg         error,
	output             done,
	inout              i2c_scl,				//inout时钟线
	inout              i2c_sda				//inout数据线
);	
wire scl_pad_i;								//IO输入
wire scl_pad_o;								//IO输出
wire scl_padoen_o;							//三态门输出控制
	
wire sda_pad_i;								//IO输入
wire sda_pad_o;								//IO输出
wire sda_padoen_o;							//三态门输出控制

assign sda_pad_i = i2c_sda;					//IO输入	
assign i2c_sda = ~sda_padoen_o ? sda_pad_o : 1'bz;	//IO输出控制：sda_padoen_o==1 输出为高阻态 sda_padoen_o==0 输出 sda_pad_o
assign scl_pad_i = i2c_scl;					//IO输入	
assign i2c_scl = ~scl_padoen_o ? scl_pad_o : 1'bz;  //IO输出控制：scl_padoen_o==1 输出为高阻态 scl_padoen_o==0 输出 scl_pad_o

reg i2c_read_req;			  				//IIC读请求
wire i2c_read_req_ack;						//IIC读应答
reg i2c_write_req;							//IIC写请求
wire i2c_write_req_ack; 					//IIC写应答
wire[7:0] i2c_slave_dev_addr;				//从机地址
wire[15:0] i2c_slave_reg_addr;				//从机地址
wire[7:0] i2c_write_data;					//IIC写数据
wire[7:0] i2c_read_data;					//IIC读数据
	
wire err;									//IIC状态
reg[2:0] state;								//IIC状态

localparam S_IDLE             =  0;
localparam S_WR_I2C_CHECK     =  1;
localparam S_WR_I2C           =  2;
localparam S_WR_I2C_DONE      =  3;


assign done = (state == S_WR_I2C_DONE);	   	//IIC读写完成
assign i2c_slave_dev_addr = lut_dev_addr;  	//IIC地址
assign i2c_slave_reg_addr = lut_reg_addr;  	//IIC地址
assign i2c_write_data  = lut_reg_data;     	//IIC数据


always@(posedge clk or posedge rst) begin
	if(rst) begin
		state <= S_IDLE;
		error <= 1'b0;
		lut_index <= 8'd0;
	end
	else 
		case(state)
			S_IDLE:										//空闲状态
			begin
				state <= S_WR_I2C_CHECK;				//直接进入IIC检查状态
				error <= 1'b0;
				lut_index <= 8'd0;						//配置信息地址查找表赋值0
			end
			S_WR_I2C_CHECK:							    //IIC检查状态
			begin
				if(i2c_slave_dev_addr != 8'hff) 		//从机设备地址
				begin
					i2c_write_req <= 1'b1;				//写请求
					state <= S_WR_I2C;					//进入写IIC状态
				end
				else
				begin
					state <= S_WR_I2C_DONE;				//读写完成状态
				end
			end
			S_WR_I2C:
			begin
				if(i2c_write_req_ack)				    //收到应答
				begin
					error <= err ? 1'b1 : error; 		//读写是否有错
					lut_index <= lut_index + 8'd1;  	//查找表地址加1
					i2c_write_req <= 1'b0;				//
					state <= S_WR_I2C_CHECK;			//
				end
			end
			S_WR_I2C_DONE:
			begin
				state <= S_WR_I2C_DONE;
			end
			default:
				state <= S_IDLE;
		endcase
end


i2c_master_top i2c_master_top_m0
(
	.rst			   (rst		  			),
	.clk			   (clk		  			),
	.clk_div_cnt	   (clk_div_cnt 		),
	// I2C signals
	// i2c clock line
	.scl_pad_i		   (scl_pad_i	  		), // SCL-line input
	.scl_pad_o		   (scl_pad_o	  		), // SCL-line output (always 1'b0)
	.scl_padoen_o	   (scl_padoen_o		), // SCL-line output enable (active low)
	// i2c data line   
	.sda_pad_i		   (sda_pad_i	  		), // SDA-line input
	.sda_pad_o		   (sda_pad_o	  		), // SDA-line output (always 1'b0)
	.sda_padoen_o	   (sda_padoen_o		), // SDA-line output enable (active low)
	
	.i2c_read_req	   (i2c_read_req		),
	.i2c_addr_2byte	   (i2c_addr_2byte		),
	.i2c_read_req_ack  (i2c_read_req_ack	),
	.i2c_write_req	   (i2c_write_req		),
	.i2c_write_req_ack (i2c_write_req_ack	),
	.i2c_slave_dev_addr(i2c_slave_dev_addr	),
	.i2c_slave_reg_addr(i2c_slave_reg_addr	),
	.i2c_write_data    (i2c_write_data		),
	.i2c_read_data     (i2c_read_data		),
	.error			   (err					)
);
endmodule