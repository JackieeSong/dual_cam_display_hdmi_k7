// -----------------------------------------------------------------------------
// Copyright (c) 2014-2022 All rights reserved
// -----------------------------------------------------------------------------
// Author : SiChen Gu  thinkchip2018@163.com
// File   : frame_fifo_read_state.v
// Create : 2022-05-05 17:23:19
// Revise : 2022-05-05 17:23:19
// Editor : sublime text4, tab size (4)
// -----------------------------------------------------------------------------

//IIC信息配置
module i2c_config1(
	input              rst,					//复位信号
	input              clk,					//输入时钟
	input[15:0]        clk_div_cnt,			//分频计数值
	input start_config,
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

reg[3:0]   curr_state;                     //state machine
reg[3:0]   next_state;                     //state machine

localparam S_IDLE             =  0;
localparam S_WR_I2C_CHECK     =  1;
localparam S_WR_I2C           =  2;
localparam S_WR_I2C_DONE      =  3;


assign done = (curr_state == S_WR_I2C_DONE);	   	//IIC读写完成
assign i2c_slave_dev_addr = lut_dev_addr;  	//IIC地址
assign i2c_slave_reg_addr = lut_reg_addr;  	//IIC地址
assign i2c_write_data  = lut_reg_data;     	//IIC数据


//第一段 :状态转移
always @(posedge clk)begin
	if(rst)begin 
		curr_state <= S_IDLE;				//保持空闲状态
	end 	
	else begin 
		curr_state <= next_state;			//跳转下一状态
	end
end 
  
//第二段 :状态跳转
always @(*)begin 
	if(rst)begin 
		next_state = S_IDLE;				//保持空闲状态
	end 
	else begin 
		case(curr_state)
			S_IDLE:	begin	
				if(start_config==1'b1)begin								//空闲状态
					next_state = S_WR_I2C_CHECK;				//直接进入IIC检查状态
				end 
				else begin
					next_state = S_IDLE;
				end 
			end
			S_WR_I2C_CHECK:	begin						    //IIC检查状态
				if(i2c_slave_dev_addr == 8'hff) begin		//从机设备地址				
					next_state = S_WR_I2C_DONE ;			//读写完成状态
				end
				else begin				
					next_state = S_WR_I2C;					//进入写IIC状态
				end
			end
			S_WR_I2C:begin
				if(i2c_write_req_ack)begin				    //收到应答				
					next_state = S_WR_I2C_CHECK;			//
				end
				else begin
					next_state = S_WR_I2C;					//
				end 
			end
			S_WR_I2C_DONE: begin
				next_state = S_WR_I2C_DONE;
			end
			default:begin
				next_state = S_IDLE;
			end 
		endcase	
	end 	
end


always@(posedge clk or posedge rst) begin
	if(rst) begin
		i2c_write_req <= 1'b0;				//写请求
		error <= 1'b0;
		lut_index <= 8'd0;
	end
	else begin
		case(curr_state)
			S_IDLE:	begin 								//空闲状态
				i2c_write_req <= 1'b0;					//写请求
				error <= 1'b0;
				lut_index <= 8'd0;						//配置信息地址查找表赋值0
			end
			S_WR_I2C_CHECK:begin							    //IIC检查状态
				if(i2c_slave_dev_addr == 8'hff)begin 		//从机设备地址
					i2c_write_req <= 1'b0;				//写请求
				end
				else begin
					i2c_write_req <= 1'b1;				//写请求
				end
			end
			S_WR_I2C: begin
				if(i2c_write_req_ack) begin 		    //收到应答				
					error <= err ? 1'b1 : error; 		//读写是否有错
					lut_index <= lut_index + 8'd1;  		//查找表地址加1
					i2c_write_req <= 1'b0;				//
				end
			end
			S_WR_I2C_DONE: begin
				i2c_write_req <= 1'b0;				//写请求
				error <= 1'b0;
				lut_index <= 8'd0;
			end
			default:begin
				i2c_write_req <= 1'b0;				//写请求
				error <= 1'b0;
				lut_index <= 8'd0;
			end 
		endcase
	end 	
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