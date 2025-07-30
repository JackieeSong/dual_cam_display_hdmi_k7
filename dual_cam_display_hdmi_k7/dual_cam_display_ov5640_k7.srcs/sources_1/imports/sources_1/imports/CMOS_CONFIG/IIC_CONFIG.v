`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/30 10:27:42
// Design Name: 
// Module Name: IIC_CONFIG
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


module IIC_CONFIG(
	//输入时钟 复位
	input  wire       clk,			 //输入时钟
	input  wire       rst,			 //复位信号
	output reg[9:0]   lut_index,	 //配置信息地址查找表
	//输入配置信息	  
	input  wire	[7 :0]lut_dev_addr,  //输入32位数据解析输入
	input  wire [15:0]lut_reg_addr,  //16位
	input  wire [7 :0]lut_reg_data,  //8位
	//输出控制信息	
	input   wire      start,		 //复位信号
	output  reg       done,		 	 //复位信号
	//输出IIC接口				
	input wire 		  finish, 	 	 //操作完成
	//写数据				         
	output reg        write_en,	 	 //发送使能
	input  wire		  write_ok,	 	 //发送完成
	output reg        write_ack,	 	 //发送使能
	output reg  [7:0] write_byte,	 //发送数据
	//读数据			             
	output wire       read_en,	 	 //发送使能
	input  wire		  read_ok,	 	 //发送完成
	output wire       read_ack,	 	 //发送使能
	input  wire [7:0] read_byte 	 //发送数据
    );

	
	reg	[7 :0]dev_addr_reg;			 //输入32位数据解析输入
	reg [15:0]reg_addr_reg;			 //16位
	reg [7 :0]reg_data_reg;			 //8位
				 
    reg [2 :0]start_reg;   			 //发送完成
    reg [2 :0]write_ok_reg;			 //发送完成

	wire start_flag;
	wire write_ok_flag;
	wire stop_comfig;
	reg [7:0]write_count;	
	//数据缓存
	always @(posedge clk)begin 
		if(rst)begin
			start_reg  <=3'd0;
			write_ok_reg<=3'd0;	
		end
		else begin  
			start_reg  <={start_reg[1:0],start};
			write_ok_reg<={write_ok_reg[1:0],write_ok};
		end 
	end 
	
	assign start_flag    = !start_reg   [2] & start_reg   [1];	//上升沿
	assign write_ok_flag = !write_ok_reg[2] & write_ok_reg[1];	//上升沿
	assign stop_comfig = lut_dev_addr == 8'hFF;
	//读配置此处不进行读操作
	assign read_en = 0;
	assign read_ack= 0;

	//状态机寄存器
	reg [3:0]    CURRENT_STATE;	 	 	//IIC状态
	reg [3:0]    NEXT_STATE;	 	 	//IIC状态
	//                               	
	parameter	 IDLE  	= 4'D0;  	 	//空闲状态
	parameter	 START  = 4'D1;  	 	//发送启动
	parameter	 CONFIG = 4'D2;  	 	//写数据
	parameter	 DONE   = 4'D3;  	 	//写数据
	parameter	 FINISH = 4'D4;		 	//发送完成
		
	
//第一段	
always @(posedge clk)begin 	
	if(rst)begin	
		CURRENT_STATE <= IDLE;		 	//保持空闲状态
	end	
	else begin  	
		CURRENT_STATE <= NEXT_STATE; 	//状态转移
	end 
end 

//第二段
always @(*)begin 
	if(rst)begin						//复位
		NEXT_STATE = IDLE;				//保持空闲状态
	end
	else begin 
		case(CURRENT_STATE)
		IDLE  :begin 
			if(start_flag)begin			//启动配置
				NEXT_STATE = START;		//跳转到启动
			end
			else begin 					//未启动配置
				NEXT_STATE = IDLE;		//保持空闲状态
			end 
		end 
		START :begin 					//启动配置
			if(stop_comfig)begin 		//停止配置
				NEXT_STATE = FINISH;	//回到完成
			end 
			else begin 					//启动配置
				NEXT_STATE = CONFIG;	//启动配置
			end 
		end 
		CONFIG:begin 
			if(write_count>=8'd4)begin 	//发送字节完成
				NEXT_STATE = DONE;		//回到启动状态
			end 
			else begin 					//写数据未完成
				NEXT_STATE = CONFIG;	//保持配置状态
			end 
		end 
		DONE:begin 
			if(finish)begin 			//发送字节完成
				NEXT_STATE = START;		//回到空闲状态
			end 
			else begin 
				NEXT_STATE = DONE;		//回到空闲状态
			end 
		end 
		FINISH:begin 					//配置结束
			NEXT_STATE = IDLE;			//回到空闲状态			
		end 
		default:begin 					//默认
			NEXT_STATE = IDLE;			//保持空闲
		end 
		endcase		
	end 
end 	


//第三段
always @(posedge clk)begin 
	if(rst)begin						//复位
		dev_addr_reg <= 8'd0;			
		reg_addr_reg <= 16'd0;			
		reg_data_reg <= 8'd0;			
		lut_index	 <= 9'd0;			
		//写使能		
		write_en	<= 1'd0;	 			//发送使能
		write_ack	<= 1'b0;	 			//发送应答
		write_byte	<= 8'd0;
		//配置完成	   
		done		<= 1'd0;				
		write_count	<= 8'd0;				
	end
	else begin 
		case(CURRENT_STATE)
		IDLE  :begin 
			dev_addr_reg <= 8'd0;
			reg_addr_reg <= 16'd0;
			reg_data_reg <= 8'd0;
			lut_index 	 <= 9'd0;			
			//写使能
			write_en	<= 1'd0;	 		//发送使能
			write_ack	<= 1'b0;	 		//发送应答
			write_byte	<= 8'd0;
			//配置完成	   
			done		<= 1'd0;
			write_count	<= 8'd0;
		end 
		START :begin 	
			dev_addr_reg <= lut_dev_addr;
			reg_addr_reg <= lut_reg_addr;
			reg_data_reg <= lut_reg_data;
			lut_index 	 <= lut_index 	;
			//写使能
			write_en    <= 1'd0;
			write_ack   <= 1'b0;	 		//发送应答
			write_byte  <= 8'd0;
			//配置完成	 
			done	    <= 1'd0;
			write_count <= 8'd0;
		end 
		CONFIG:begin 
			done<=1'd0;
			if(write_ok_flag)begin 
				write_count<=write_count+8'd1;
			end 
			else begin 
				write_count<=write_count;
			end 
			case(write_count)
				8'd0:begin 
					write_en<=1'd1;
					write_ack<=	1'b1;	 //发送使能
					write_byte<=dev_addr_reg[7:0];
				end 
				8'd1:begin 
					write_en<=1'd1;
					write_ack<=	1'b1;	 //发送使能
					write_byte<=reg_addr_reg[15:8];
				end 
				8'd2:begin 
					write_en<=1'd1;
					write_ack<=	1'b1;	 //发送使能
					write_byte<=reg_addr_reg[7:0];
				end 
				8'd3:begin 
					write_en<=1'd1;
					write_ack<=	1'b1;	 //发送使能
					write_byte<=reg_data_reg[7:0];
				end
				8'd4:begin 
					write_en<=1'd0;
					write_ack<=	1'b0;	 //发送使能
					lut_index <= lut_index +9'd1;
				end 
				default:begin 
					write_en<=1'd0;
					write_ack<=	1'b0;	 //发送使能
					write_byte<=write_byte;
					lut_index <= lut_index;
				end 
			endcase
		end
		DONE:begin 
			dev_addr_reg <= 8'd0;
			reg_addr_reg <= 16'd0;
			reg_data_reg <= 8'd0;
			lut_index <= lut_index;
			
			done<=1'd1;
			write_en<=1'd0;
			write_byte<=8'd0;
			write_count<=8'd0; 
		end 
		FINISH:begin 
			dev_addr_reg <= 8'd0;
			reg_addr_reg <= 16'd0;
			reg_data_reg <= 8'd0;
			lut_index <= lut_index;
			
			done<=1'd1;
			write_en<=1'd0;
			write_byte<=8'd0;
			write_count<=8'd0;
		end 
		default:begin 
			dev_addr_reg <= 8'd0;
			reg_addr_reg <= 16'd0;
			reg_data_reg <= 8'd0;
			
			done<=1'd1;
			write_en<=1'd0;
			write_byte<=8'd0;
			write_count<=8'd0;
		end 
		endcase		
	end 
end 	
	
	
endmodule










