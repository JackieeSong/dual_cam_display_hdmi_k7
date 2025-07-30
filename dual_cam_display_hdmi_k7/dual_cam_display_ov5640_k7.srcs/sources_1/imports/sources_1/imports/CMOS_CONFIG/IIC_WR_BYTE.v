`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/25 16:43:27
// Design Name: FJ
// Module Name: IIC_WRITE_BYTE
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
//	IIC读写控制模块 *注意点
// 	1 ——>	读写发送自带STAR
// 	2 ——>	读写完成自带STOP
//	3 ——>	写完成后未检测到写使能或者读使能将自动发送STOP结束写过程
//	4 ——>	写完成后检测到写使能将重新加载数据跳转到写数据过程
//	5 ——>	写完成后检测到读使能将跳转到读数据过程
//	6 ——>	读完成后未检测到写使能或者读使能将自动发送STOP结束读过程
//	7 ——>	读完成后检测到写使能将重新加载数据跳转到写数据过程
//	8 ——>	读完成后检测到读使能将跳转到读数据过程
//	9 ——>	读写完成都会输出完成标志
//	10——>	读写配置结束将输出配置完成标志
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module IIC_WR_BYTE(
	//输入时钟 复位
	input  wire       clk,		 		//输入时钟
	input  wire       rst,		 		//复位信号
	//输出控制信息				        
	output reg 		  finish, 	 		//操作完成
	//写数据				            
	input  wire       write_en,	 		//写使能
	input  wire       write_ack,	 	//写应答
	output reg		  write_ok,	 		//写完成
	input  wire [7:0] write_byte,		//写数据
	//读数据			                
	input  wire       read_en,	 		//读使能
	input  wire       read_ack,	 		//读应答
	output reg		  read_ok,	 		//读完成
	output reg  [7:0] read_byte, 		//读数据
	//输出IIC接口	
	output  wire      i2c_scl,		 	//inout时钟线
	inout   wire      i2c_sda		 	//inout数据线
    );	

    	//数据收发标志
	reg		 send_flag;		//发送标志
	reg		 rece_flag;		//接收标志
	//数据收发控制寄存器
	reg [7:0]state_count;	//收发计数器
	reg	[7:0]send_byte_reg;	//发送字节
	reg	[7:0]rece_byte_reg;	//接收字节	                                 
	//输出IIC接口				
	reg	  	 	  i2c_sdaen; 			//输出使能
	reg	  	  	  i2c_scl_o; 			//inout时钟线
	wire	  	  i2c_sda_i; 			//inout数据线
	reg	  	 	  i2c_sda_o;	 		//inout数据线
	
	assign		  i2c_sda_i= i2c_sdaen?1'bZ:i2c_sda;
	assign		  i2c_sda  = i2c_sdaen?i2c_sda_o:1'bZ;
	assign		  i2c_scl  = i2c_scl_o;
	
	//发送计数器                             
	reg		  count_en;					//时钟分频计数器使能
	reg  [7:0]count_clk;				//时钟分频计数寄存器	
	//发送控制标志	                    
	wire star_sda;						//发送数据
	wire stop_sda;						//结束数据
	wire star_scl;						//发送时钟
	wire stop_scl;						//结束时钟
	wire half_sda;						//数据中心
	
	//时钟计数器
	always @(posedge clk)begin 
		if(rst)begin
			count_clk<=8'd0;			    //计数器清零
		end                             
		else if(count_en) begin 		//计数器使能
			count_clk<=count_clk+1'b1;	//计数器自增
		end                             
		else begin 						//计数器未使能
			count_clk<=8'd0;				//计数器清零
		end
	end 
	//发送控制标志
	assign star_sda = count_en ? count_clk == 8'd0  :1'b0; //发送数据
	assign stop_sda = count_en ? count_clk == 8'd255:1'b0; //结束数据
	assign star_scl = count_en ? count_clk == 8'd63 :1'b0; //发送时钟
	assign stop_scl = count_en ? count_clk == 8'd191:1'b0; //结束时钟
	assign half_sda = count_en ? count_clk == 8'd127:1'b0; //数据中心
	
	
	
//  //发送控制标志
//  assign star_sda = count_en ? count_clk == 3'd0:1'b0; //发送数据
//  assign stop_sda = count_en ? count_clk == 3'd7:1'b0; //结束数据
//  assign star_scl = count_en ? count_clk == 3'd2:1'b0; //发送时钟
//  assign stop_scl = count_en ? count_clk == 3'd6:1'b0; //结束时钟
//  assign half_sda = count_en ? count_clk == 3'd4:1'b0; //数据中心
	

	//自定义状态机	
	reg [3:0]    CURRENT_STATE;	 	 			//IIC状态
	reg [3:0]    NEXT_STATE;	 	 			//IIC状态
				
	parameter	 IDLE  	= 4'D0;  	 			//空闲状态
	parameter	 START0 = 4'D1;  	 			//发送启动
	parameter	 WRITE  = 4'D2;  	 			//写数据
	parameter	 START1 = 4'D3;  	 			//检测启动
	parameter	 READ   = 4'D4;  	 			//读数据
	parameter	 ACK    = 4'D5;		 			//写应答
	parameter	 STOP  	= 4'D6;  	 			//发送停止
	parameter	 FINISH = 4'D7;		 			//发送完成
	
	parameter	 ACK_0 	= 1'B0;		 			//应答控制
	parameter	 ACK_1 	= 1'B1;		 			//应答控制	
	//写应答控制
	reg	W_ack;
	always @(posedge clk)begin 
		if(rst)begin
			W_ack <= ACK_0;			    //应答
		end
		else if(write_en)begin 			//写使能锁存
			if(write_ack)begin 			//写应答
				W_ack <= ACK_1;			//应答
			end 
			else begin  
				W_ack <= ACK_0;			//应答
			end 
		end
		else begin 
			W_ack <= W_ack;			    //应答
		end 
	end 
	//读应答控制
	reg	R_ack;
	always @(posedge clk)begin 
		if(rst)begin
			R_ack <= ACK_0;			    //应答
		end
		else if(read_en)begin 			//读使能锁存
			if(read_ack)begin 			//读应答
				R_ack <= ACK_1;			//应答
			end 
			else begin  
				R_ack <= ACK_0;			//应答
			end 
		end
		else begin
			R_ack <= R_ack;			    //应答
		end 
	end 
	
	//第一段
	always @(posedge clk)begin 
		if(rst)begin
			CURRENT_STATE <= IDLE;			    //复位状态
		end
		else begin  
			CURRENT_STATE <= NEXT_STATE;		//状态跳转
		end 
	end 

	//第二段
	always @(*)begin 
		if(rst)begin							//复位
			NEXT_STATE = IDLE;					//保持空闲状态
		end	
		else begin 	
			case(CURRENT_STATE)	
				IDLE  :begin 					//空闲状态
					if(write_en)begin 	 		//写使能
						NEXT_STATE = START0;	//检测发送使能
					end 	
					else if(read_en)begin 		//读使能
						NEXT_STATE = START1;	//检测发送使能
					end 	
					else begin 					//发送未使能
						NEXT_STATE = IDLE;		//保持空闲状态
					end	
				end	 			
				START0 :begin				 	//发送使能
					if(stop_sda)begin			//发送STAR完成
						NEXT_STATE = WRITE;	 	//启动写操作
					end
					else begin 
						NEXT_STATE = START0;	//保持发送使能
					end 					
				end
				START1 :begin				 	//发送使能
					if(stop_sda)begin			//发送STAR完成
						NEXT_STATE = READ;	 	//启动读操作
					end
					else begin 
						NEXT_STATE = START1;	//保持发送使能
					end 					
				end			
				WRITE:begin 				  	//发送数据
					if(state_count>=4'd8)begin 	//发送数据完成
						NEXT_STATE = ACK;     	//发送应答
					end                      
					else begin 				   	//发送未完成
						NEXT_STATE = WRITE;	   	//保持发送数据
					end                      
				end 
				READ:begin 				       	//读取数据
					if(state_count>=4'd8)begin 	//发送数据完成
						NEXT_STATE = ACK;     	//发送应答
					end                      
					else begin 				   	//发送未完成
						NEXT_STATE = READ;	   	//保持读取数据
					end                      
				end  			
				ACK	:begin						//发送应答
					if(stop_sda)begin 	 	    //发送使能
						if(write_en)begin 		//启动写使能
							NEXT_STATE = WRITE;	//发送数据
						end 
						else if(read_en)begin 	//启动读使能
							NEXT_STATE = READ;	//读取数据
						end 
						else begin 
							NEXT_STATE = STOP;	//发送STOP
						end 
					end                      
					else begin 				    //应答未完成
						NEXT_STATE = ACK;	    //保持应答
					end    
				end                         
				STOP:begin 					 	//发送STOP
					if(stop_sda)begin 	 	 	//发送使能
						NEXT_STATE = FINISH;	//回到完成
					end                      
					else begin 				 	//发送未完成
						NEXT_STATE = STOP;	 	//保存STOP
					end  
				end                          
				FINISH:begin 				 	//发送完成
					NEXT_STATE = IDLE;		 	//回到空闲
				end 
				default:begin 
					NEXT_STATE = IDLE;			//回到空闲
				end 
			endcase
		end 	
	end 

	
	//第三段	
	always @(posedge clk)begin 
		if(rst)begin
			count_en     <=1'b0;						//时钟计数器
			state_count  <=8'd0;						//收发计数器
			read_byte    <=8'd0;						//IIC接收数据
			send_byte_reg<=8'd0;						//发送字节寄存
			rece_byte_reg<=8'd0;						//接收字节寄存
			//发送控制信号						
			finish    	 <=1'b0;						//操作完成
			read_ok   	 <=1'b0;						//读完成
			write_ok  	 <=1'b0;						//写完成
			//读写标志	 						
			send_flag 	 <=1'b0;						//发送标志
			rece_flag 	 <=1'b0;						//接收标志
			//输出IIC接口						
			i2c_sdaen 	 <=1'b1;						//输出使能
			i2c_scl_o 	 <=1'b1;						//输出时钟
			i2c_sda_o 	 <=1'b1;						//发送数据
		end
		else begin 
			case(CURRENT_STATE)
				IDLE  :begin 				 	  	 //空闲状态
					count_en    <=1'b0;		  		//时钟计数器
					state_count <=8'd0;		  		//收发计数器
					read_byte   <=read_byte;		//IIC接收数据					
					//发送控制信号
					finish    	<=1'b0;				//操作完成
					read_ok   	<=1'b0;              //读完成 
					write_ok  	<=1'b0;              //写完成 
					//读写标志                      
					send_flag 	<=1'b0;              //发送标志 
					rece_flag 	<=1'b0;              //接收标志 
					//输出IIC接口
					i2c_sdaen 	<=1'b1;		         //输出使能
					i2c_scl_o 	<=1'b1;		         //输出时钟
					i2c_sda_o 	<=1'b1;		         //发送数据	
					if(write_en)begin 	 		     //写使能
						send_byte_reg<=write_byte;   //发送字节寄存					
					end 	
					else if(read_en)begin 		     //读使能
						rece_byte_reg<=8'd0;	     	 //接收字节寄存
					end 	
					else begin 					     //发送未使能
						send_byte_reg<=send_byte_reg;//发送字节寄存
						rece_byte_reg<=rece_byte_reg;//接收字节寄存
					end	
				end
				//启动写
				START0 :begin				 		 //发送使能	
					count_en     <=1'b1;		  	 	 //时钟计数器
					state_count  <=8'd0;		  	 	 //收发计数器
					read_byte    <=read_byte;		 //IIC接收数据	
					send_byte_reg<=send_byte_reg;	 //发送字节寄存
					rece_byte_reg<=rece_byte_reg;	 //接收字节寄存					
					//发送控制信号
					finish       <=1'b0;				 //操作完成
					read_ok      <=1'b0;			  	 //读完成 
					write_ok     <=1'b0;			  	 //写完成 
					//读写标志          			  
					send_flag    <=1'b1;			  	 //发送标志 
					rece_flag    <=1'b0;			  	 //接收标志 
					//输出IIC接口			 
					i2c_sdaen 	 <=1'b1;				 //输出使能
					//输出时钟			 
					if(star_scl)begin				 //启动时钟
						i2c_scl_o <=1'b1;			 //时钟拉高
					end
					else if(stop_scl)begin			 //停止时钟
						i2c_scl_o <=1'b0;			 //时钟拉低
					end
					else begin 						 //其他状态
						i2c_scl_o <=i2c_scl_o;		 //时钟保持
					end 
					//输出启动信号START
					if(half_sda)begin				 //数据中心
						i2c_sda_o <=1'b0;			 //发送启动	
					end
					else begin  					 //其他状态
						i2c_sda_o <=i2c_sda_o;	 	 //数据保持
					end  
				end 
				//启动读
				START1 :begin				 		 //发送使能	
					count_en     <=1'b1;		  		 //时钟计数器
					state_count  <=8'd0;		  	 	 //收发计数器
					read_byte    <=read_byte;		 //IIC接收数据	
					send_byte_reg<=send_byte_reg;	 //发送字节寄存
					rece_byte_reg<=rece_byte_reg;	 //接收字节寄存					
					//发送控制信号
					finish    <=1'b0;				 //操作完成
					read_ok   <=1'b0;       		 	 //读完成  
					write_ok  <=1'b0;       		 	 //写完成  
					//读写标志              		 
					send_flag <=1'b0;       			 //发送标志 
					rece_flag <=1'b1;       		 	 //接收标志 
					//输出IIC接口           		
					i2c_sdaen <=1'b1;				 //输出使能
					//输出时钟              		
					if(star_scl)begin				 //启动时钟
						i2c_scl_o <=1'b1;   		 	 //时钟拉高 
					end                     		
					else if(stop_scl)begin  		 //停止时钟
						i2c_scl_o <=1'b0;			 //时钟拉低 
					end                             
					else begin                    	 //其他状态
						i2c_scl_o <=i2c_scl_o;       //时钟保持
					end                             
					//输出数据                      
					if(half_sda)begin				 //数据中心
						i2c_sda_o <=1'b0;			 //发送启动
					end                             
					else begin                       //其他状态
						i2c_sda_o <=i2c_sda_o;	 	 //数据保持
					end  
				end 
				//写操作
				WRITE:begin 				 		 //发送数据
					count_en     <=1'b1;		  		 //时钟计数器
					read_byte    <=read_byte;		 //IIC接收数据	
					rece_byte_reg<=rece_byte_reg;	 //接收字节寄存					
					//发送控制信号	
					finish    	 <=1'b0;				 //操作完成
					read_ok   	 <=1'b0;        	     //读完成   
					write_ok  	 <=1'b0;        	     //写完成   
					//读写标志	                	  
					send_flag 	 <=1'b1;        	     //发送标志  
					rece_flag 	 <=1'b0;        	     //接收标志  
					//输出IIC接口               
					i2c_sdaen 	 <=1'b1;		         //输出使能  
					//输出时钟                  
					if(star_scl)begin           	 //启动时钟
						i2c_scl_o <=1'b1;        	 //时钟拉高  
					end                         
					else if(stop_scl)begin      	 //停止时钟
						i2c_scl_o <=1'b0;        	 //时钟拉低  
					end
					else begin 						 //其他状态
						i2c_scl_o <=i2c_scl_o;  	 //时钟保持
					end 
					//输出数据
					if(star_sda)begin				 //启动数据
						state_count<=state_count;	 //收发计数器保持
						if(state_count<8'd8)			 //发送未完成
							i2c_sda_o <=send_byte_reg[7];//发送数据MSB	
						else 						 //发送未完成
							i2c_sda_o <=W_ack;		 //发送应答	
					end
					else if(stop_sda)begin			 //停止数据
						state_count<=state_count+8'd1;//收发计数器加1
						send_byte_reg<={send_byte_reg[6:0],send_byte_reg[7]};//发送寄存器移位
						i2c_sda_o <=i2c_sda_o;		 //发送数据保持
					end
					else begin 
						state_count<=state_count;	 //收发计数器保持
						i2c_sda_o <=i2c_sda_o;	 	 //发送发送使能
					end  
				end 
				//读操作
				READ :begin 				 		 //发送数据
					count_en     <=1'b1;		  	 	 //时钟计数器
					read_byte    <=read_byte;		 //IIC接收数据	
					send_byte_reg<=send_byte_reg;	 //发送字节寄存				
					//发送控制信号
					finish    	 <=1'b0;				 //操作完成
					read_ok   	 <=1'b0;				 //读完成   
					write_ok  	 <=1'b0;				 //写完成   
					//读写标志	        				
					send_flag 	 <=1'b0;				 //发送标志 
					rece_flag 	 <=1'b1;				 //接收标志   
					//输出时钟                       //输出使能
					if(star_scl)begin				 //启动时钟
						i2c_scl_o <=1'b1;      		 //时钟拉高   
					end                        		
					else if(stop_scl)begin     		 //停止时钟
						i2c_scl_o <=1'b0;      		 //时钟拉低   
					end                        		
					else begin                 		 //其他状态
						i2c_scl_o <=i2c_scl_o; 		 //时钟保持
					end
					
					//输入数据接收数据
					if(half_sda)begin				  //数据中心
						state_count<=state_count;	  //收发计数器保持
						if(state_count<8'd8)			  //收发计数器小于8
							rece_byte_reg[7] <=i2c_sda_i;//接收数据	
						else 						  //接收数据完成
							rece_byte_reg<=rece_byte_reg;//接收寄存保持		
					end 
					else if(stop_sda)begin			  //接收数据完成
						state_count<=state_count+8'd1; //收发计数器加1
						rece_byte_reg<={rece_byte_reg[6:0],rece_byte_reg[7]};//接收寄存器移位
					end
					else begin 						  //其他状态
						state_count<=state_count;	  //收发计数器保持
						rece_byte_reg<=rece_byte_reg; //接收寄存保持				
					end  
					
					//输出数据发送应答
					if(star_sda)begin				  //启动数据
						if(state_count<8'd8)begin     //收发计数器小于8 
							i2c_sdaen <=1'b0;		  //输出不使能	  
							i2c_sda_o <=1'b0;		  //发送数据0	  
						end 						
						else begin  				  //数据接收完成
							i2c_sdaen <=1'b1;		  //输出使能
							i2c_sda_o <=R_ack;		  //发送应答ACK	
						end	
					end
					else if(stop_sda)begin			  //接收数据完成
						i2c_sdaen <=i2c_sdaen;		  //输出使能保持
						i2c_sda_o <=i2c_sda_o;		  //发送数据保持
					end
					else begin 						  //其他状态
						i2c_sdaen <=i2c_sdaen;		  //输出使能保持
						i2c_sda_o <=i2c_sda_o;	 	  //发送数据保持
					end 
				end 
				//应答
				ACK	:begin 
					count_en     <=1'b1;		  	 	  //时钟计数器
					state_count  <=8'd0;		  	 	  //收发计数器
					//发送控制信号
					finish    <=1'b0;				  //完成信号
					//读写标志
					if(send_flag)begin				  //发送数据过程
						write_ok  <=1'b1;			  //写完成标志拉高
					end 
					else begin 						  //接收数据过程
						write_ok  <=1'b0;			  //写完成标志拉低
					end 
					//读写标志
					if(rece_flag)begin				  //接收数据过程
						read_ok   <=1'b1;			  //读完成标志拉高
					end                               
					else begin                        //发送数据过程
						read_ok   <=1'b0;			  //读完成标志拉低
					end 
					//输出IIC接口               
					i2c_sdaen 	 <=i2c_sdaen;		  //输出使能保持 
					//发送数据
					if(write_en)begin 				  //写使能
						send_byte_reg <= write_byte;  //发送数据更新
					end 
					else begin 						  //非写使能
						send_byte_reg <= send_byte_reg;//发送数据保持
					end 
					//接收数据
					read_byte    <=rece_byte_reg;	  //IIC接收数据输出
					rece_byte_reg<=rece_byte_reg;	  //接收字节寄存保持	
					//输出时钟 
					if(star_scl)begin				  //启动时钟
						i2c_scl_o <=1'b1;        	  //时钟拉高   
					end                         	  
					else if(stop_scl)begin      	  //停止时钟
						i2c_scl_o <=1'b0;        	  //时钟拉低   
					end                         	  
					else begin                  	  //其他状态
						i2c_scl_o <=i2c_scl_o;  	  //时钟保持
					end 
					//输出ack数据
					if(star_sda)begin				  //启动数据
						if(send_flag)
						i2c_sda_o <=W_ack;			  //发送应答ACK
						else 
						i2c_sda_o <=R_ack;			  //发送应答ACK
					end                                
					else if(stop_sda)begin            //停止数据0  
						if(send_flag)
						i2c_sda_o <=W_ack;			  //发送应答ACK
						else 
						i2c_sda_o <=R_ack;			  //发送应答ACK
					end                               
					else begin                        //其他状态
						i2c_sda_o <=i2c_sda_o;	 	  //输出保持
					end                             
				end                                 
				//停止使能			                  //接收数据完成
				STOP:begin 					 		  //发送停止
					read_byte    <=read_byte;		  //IIC接收数据保持	
					state_count  <=8'd0;			      //收发计数器
					send_byte_reg<=8'd0;			      //发送字节寄存
					rece_byte_reg<=8'd0;			      //接收字节寄存
					//发送控制信号
					finish       <=1'b0;				  //操作完成
					read_ok      <=1'b0;        		  //读完成 
					write_ok     <=1'b0;        		  //写完成 
					//输出IIC接口
					i2c_sdaen 	 <=1'b1;				  //输出使能
					//发送时钟
					if(star_scl)begin				  //启动时钟
						i2c_scl_o <=1'b1;       		  //时钟拉高  
					end                         		
					else if(stop_scl)begin      	  //停止时钟
						i2c_scl_o <=1'b1;       		  //时钟拉低  
					end                         		
					else begin                  	  //其他状态
						i2c_scl_o <=i2c_scl_o;  	  //时钟保持
					end 
					//发送数据
					if(star_sda)begin				  //启动数据		
						i2c_sda_o <=1'b0;			  //发送STOP	
						count_en  <=1'b1;			  //时钟计数器		  
					end
					else if(half_sda)begin			  //数据中心
						i2c_sda_o <=1'b1;			  //发送STOP
						count_en  <=1'b1;			  //时钟计数器		
					end
					else if(stop_sda)begin			  //关闭数据
						i2c_sda_o <=1'b1;			  //发送STOP
						count_en  <=1'b0;
					end
					else begin						 //其他状态 
						i2c_sda_o <=i2c_sda_o;		 //发送保持
						count_en  <=count_en;		 //时钟计数
					end 
				end  
				//完成
				FINISH:begin 						 //发送完成
					count_en     <=1'b0;				 //时钟计数器
					state_count  <=8'd0;				 //收发计数器
					read_byte    <=read_byte;		 //IIC接收数据	
					send_byte_reg<=8'd0;				 //发送字节寄存
					rece_byte_reg<=8'd0;				 //接收字节寄存
					//发送控制信号				 
					finish    	 <=1'b1;				 //操作完成
					read_ok   	 <=1'b0;				 //读完成 
					write_ok  	 <=1'b0;				 //写完成 
					//输出IIC接口
					i2c_sdaen <=1'b1;				 //输出使能
					i2c_scl_o <=1'b1;				 //输出时钟
					i2c_sda_o <=1'b1;				 //发送数据
				end 
				default:begin 
					count_en     <=1'b0;				 //时钟计数器
					state_count  <=8'd0;				 //收发计数器
					read_byte    <=read_byte;		 //IIC接收数据	
					send_byte_reg<=8'd0;				 //发送字节寄存
					rece_byte_reg<=8'd0;				 //接收字节寄存
					//发送控制信号				 
					finish    	 <=1'b1;				 //操作完成
					read_ok   	 <=1'b0;				 //读完成 
					write_ok  	 <=1'b0;				 //写完成 
					//输出IIC接口
					i2c_sdaen <=1'b1;				 //输出使能
					i2c_scl_o <=1'b1;				 //输出时钟
					i2c_sda_o <=1'b1;				 //发送数据
				end 
			endcase
		end 	
	end 

endmodule



/*
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/25 16:43:27
// Design Name: FJ
// Module Name: IIC_WRITE_BYTE
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
//	IIC读写控制模块 *注意点
// 	1 ——>	读写发送自带STAR
// 	2 ——>	读写完成自带STOP
//	3 ——>	写完成后未检测到写使能或者读使能将自动发送STOP结束写过程
//	4 ——>	写完成后检测到写使能将重新加载数据跳转到写数据过程
//	5 ——>	写完成后检测到读使能将跳转到读数据过程
//	6 ——>	读完成后未检测到写使能或者读使能将自动发送STOP结束读过程
//	7 ——>	读完成后检测到写使能将重新加载数据跳转到写数据过程
//	8 ——>	读完成后检测到读使能将跳转到读数据过程
//	9 ——>	读写完成都会输出完成标志
//	10——>	读写配置结束将输出配置完成标志
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module IIC_WR_BYTE(
	//输入时钟 复位
	input  wire       clk,		 		//输入时钟
	input  wire       rst,		 		//复位信号
	//输出控制信息				        
	output reg 		  finish, 	 		//操作完成
	//写数据				            
	input  wire       write_en,	 		//发送使能
	output reg		  write_ok,	 		//发送完成
	input  wire [7:0] write_byte,		//发送数据
	//读数据			                
	input  wire       read_en,	 		//发送使能
	output reg		  read_ok,	 		//发送完成
	output reg  [7:0] read_byte, 		//发送数据
	//输出IIC接口				        
	output reg		  i2c_sdaen, 		//输出使能
	output reg		  i2c_scl_o, 		//inout时钟线
	input  wire		  i2c_sda_i, 		//inout数据线
	output reg		  i2c_sda_o	 		//inout数据线
    );		                                 

	//发送计数器                             
	reg		  count_en;					//时钟分频计数器使能
	reg  [8:0]count_clk;				//时钟分频计数寄存器	
	//发送控制标志	                    
	wire star_sda;						//发送数据
	wire stop_sda;						//结束数据
	wire star_scl;						//发送时钟
	wire stop_scl;						//结束时钟
	wire half_sda;						//数据中心
	
	//时钟计数器
	always @(posedge clk)begin 
		if(rst)begin
			count_clk<=9'd0;			    //计数器清零
		end                             
		else if(count_en) begin 		//计数器使能
			count_clk<=count_clk+1'b1;	//计数器自增
		end                             
		else begin 						//计数器未使能
			count_clk<=9'd0;				//计数器清零
		end
	end 
	//发送控制标志
	assign star_sda = count_en ? count_clk == 9'd0  :1'b0; //发送数据
	assign stop_sda = count_en ? count_clk == 9'd511:1'b0; //结束数据
	assign star_scl = count_en ? count_clk == 9'd127 :1'b0; //发送时钟
	assign stop_scl = count_en ? count_clk == 9'd383:1'b0; //结束时钟
	assign half_sda = count_en ? count_clk == 9'd255:1'b0; //数据中心
	

	//自定义状态机	
	reg [3:0]    CURRENT_STATE;	 	 			//IIC状态
	reg [3:0]    NEXT_STATE;	 	 			//IIC状态
				
	parameter	 IDLE  	= 4'D0;  	 			//空闲状态
	parameter	 START0 = 4'D1;  	 			//发送启动
	parameter	 WRITE  = 4'D2;  	 			//写数据
	parameter	 START1 = 4'D3;  	 			//检测启动
	parameter	 READ   = 4'D4;  	 			//读数据
	parameter	 NACK   = 4'D5;		 			//写应答
	parameter	 STOP  	= 4'D6;  	 			//发送停止
	parameter	 FINISH = 4'D7;		 			//发送完成
	
	parameter	 ACK 	= 1'B1;		 			//应答控制
		
	//第一段
	always @(posedge clk)begin 
		if(rst)begin
			CURRENT_STATE <= IDLE;			    //复位状态
		end
		else begin  
			CURRENT_STATE <= NEXT_STATE;		//状态跳转
		end 
	end 

	//第二段
	always @(*)begin 
		if(rst)begin							//复位
			NEXT_STATE = IDLE;					//保持空闲状态
		end	
		else begin 	
			case(CURRENT_STATE)	
				IDLE  :begin 					//空闲状态
					if(write_en)begin 	 		//写使能
						NEXT_STATE = START0;	//检测发送使能
					end 	
					else if(read_en)begin 		//读使能
						NEXT_STATE = START1;	//检测发送使能
					end 	
					else begin 					//发送未使能
						NEXT_STATE = IDLE;		//保持空闲状态
					end	
				end	 			
				START0 :begin				 	//发送使能
					if(stop_sda)begin			//发送STAR完成
						NEXT_STATE = WRITE;	 	//启动写操作
					end
					else begin 
						NEXT_STATE = START0;	//保持发送使能
					end 					
				end
				START1 :begin				 	//发送使能
					if(stop_sda)begin			//发送STAR完成
						NEXT_STATE = READ;	 	//启动读操作
					end
					else begin 
						NEXT_STATE = START1;	//保持发送使能
					end 					
				end			
				WRITE:begin 				  	//发送数据
					if(state_count>=4'd8)begin 	//发送数据完成
						NEXT_STATE = NACK;     	//发送应答
					end                      
					else begin 				   	//发送未完成
						NEXT_STATE = WRITE;	   	//保持发送数据
					end                      
				end 
				READ:begin 				       	//读取数据
					if(state_count>=4'd8)begin 	//发送数据完成
						NEXT_STATE = NACK;     	//发送应答
					end                      
					else begin 				   	//发送未完成
						NEXT_STATE = READ;	   	//保持读取数据
					end                      
				end  			
				NACK	:begin					//发送应答
					if(stop_sda)begin 	 	    //发送使能
						if(write_en)begin 		//启动写使能
							NEXT_STATE = WRITE;	//发送数据
						end 
						else if(read_en)begin 	//启动读使能
							NEXT_STATE = READ;	//读取数据
						end 
						else begin 
							NEXT_STATE = STOP;	//发送STOP
						end 
					end                      
					else begin 				    //应答未完成
						NEXT_STATE = NACK;	    //保持应答
					end    
				end                         
				STOP:begin 					 	//发送STOP
					if(stop_sda)begin 	 	 	//发送使能
						NEXT_STATE = FINISH;	//回到完成
					end                      
					else begin 				 	//发送未完成
						NEXT_STATE = STOP;	 	//保存STOP
					end  
				end                          
				FINISH:begin 				 	//发送完成
					NEXT_STATE = IDLE;		 	//回到空闲
				end 
				default:begin 
					NEXT_STATE = IDLE;			//回到空闲
				end 
			endcase
		end 	
	end 
	//数据收发标志
	reg		 send_flag;		//发送标志
	reg		 rece_flag;		//接收标志
	//数据收发控制寄存器
	reg [7:0]state_count;	//收发计数器
	reg	[7:0]send_byte_reg;	//发送字节
	reg	[7:0]rece_byte_reg;	//接收字节
	
	//第三段	
	always @(posedge clk)begin 
		if(rst)begin
			count_en     <=1'b0;						//时钟计数器
			state_count  <=8'd0;						//收发计数器
			read_byte    <=8'd0;						//IIC接收数据
			send_byte_reg<=8'd0;						//发送字节寄存
			rece_byte_reg<=8'd0;						//接收字节寄存
			//发送控制信号						
			finish    	 <=1'b0;						//操作完成
			read_ok   	 <=1'b0;						//读完成
			write_ok  	 <=1'b0;						//写完成
			//读写标志	 						
			send_flag 	 <=1'b0;						//发送标志
			rece_flag 	 <=1'b0;						//接收标志
			//输出IIC接口						
			i2c_sdaen 	 <=1'b1;						//输出使能
			i2c_scl_o 	 <=1'b1;						//输出时钟
			i2c_sda_o 	 <=1'b1;						//发送数据
		end
		else begin 
			case(CURRENT_STATE)
				IDLE  :begin 				 	  	 //空闲状态
					count_en    <=1'b0;		  		//时钟计数器
					state_count <=8'd0;		  		//收发计数器
					read_byte   <=read_byte;		//IIC接收数据					
					//发送控制信号
					finish    	<=1'b0;				//操作完成
					read_ok   	<=1'b0;              //读完成 
					write_ok  	<=1'b0;              //写完成 
					//读写标志                      
					send_flag 	<=1'b0;              //发送标志 
					rece_flag 	<=1'b0;              //接收标志 
					//输出IIC接口
					i2c_sdaen 	<=1'b1;		         //输出使能
					i2c_scl_o 	<=1'b1;		         //输出时钟
					i2c_sda_o 	<=1'b1;		         //发送数据	
					if(write_en)begin 	 		     //写使能
						send_byte_reg<=write_byte;   //发送字节寄存					
					end 	
					else if(read_en)begin 		     //读使能
						rece_byte_reg<=8'd0;	     	 //接收字节寄存
					end 	
					else begin 					     //发送未使能
						send_byte_reg<=send_byte_reg;//发送字节寄存
						rece_byte_reg<=rece_byte_reg;//接收字节寄存
					end	
				end
				//启动写
				START0 :begin				 		 //发送使能	
					count_en     <=1'b1;		  	 	 //时钟计数器
					state_count  <=8'd0;		  	 	 //收发计数器
					read_byte    <=read_byte;		 //IIC接收数据	
					send_byte_reg<=send_byte_reg;	 //发送字节寄存
					rece_byte_reg<=rece_byte_reg;	 //接收字节寄存					
					//发送控制信号
					finish       <=1'b0;				 //操作完成
					read_ok      <=1'b0;			  	 //读完成 
					write_ok     <=1'b0;			  	 //写完成 
					//读写标志          			  
					send_flag    <=1'b1;			  	 //发送标志 
					rece_flag    <=1'b0;			  	 //接收标志 
					//输出IIC接口			 
					i2c_sdaen 	 <=1'b1;				 //输出使能
					//输出时钟			 
					if(star_scl)begin				 //启动时钟
						i2c_scl_o <=1'b1;			 //时钟拉高
					end
					else if(stop_scl)begin			 //停止时钟
						i2c_scl_o <=1'b0;			 //时钟拉低
					end
					else begin 						 //其他状态
						i2c_scl_o <=i2c_scl_o;		 //时钟保持
					end 
					//输出启动信号START
					if(half_sda)begin				 //数据中心
						i2c_sda_o <=1'b0;			 //发送启动	
					end
					else begin  					 //其他状态
						i2c_sda_o <=i2c_sda_o;	 	 //数据保持
					end  
				end 
				//启动读
				START1 :begin				 		 //发送使能	
					count_en     <=1'b1;		  		 //时钟计数器
					state_count  <=8'd0;		  	 	 //收发计数器
					read_byte    <=read_byte;		 //IIC接收数据	
					send_byte_reg<=send_byte_reg;	 //发送字节寄存
					rece_byte_reg<=rece_byte_reg;	 //接收字节寄存					
					//发送控制信号
					finish    <=1'b0;				 //操作完成
					read_ok   <=1'b0;       		 	 //读完成  
					write_ok  <=1'b0;       		 	 //写完成  
					//读写标志              		 
					send_flag <=1'b0;       			 //发送标志 
					rece_flag <=1'b1;       		 	 //接收标志 
					//输出IIC接口           		
					i2c_sdaen <=1'b1;				 //输出使能
					//输出时钟              		
					if(star_scl)begin				 //启动时钟
						i2c_scl_o <=1'b1;   		 	 //时钟拉高 
					end                     		
					else if(stop_scl)begin  		 //停止时钟
						i2c_scl_o <=1'b0;			 //时钟拉低 
					end                             
					else begin                    	 //其他状态
						i2c_scl_o <=i2c_scl_o;       //时钟保持
					end                             
					//输出数据                      
					if(half_sda)begin				 //数据中心
						i2c_sda_o <=1'b0;			 //发送启动
					end                             
					else begin                       //其他状态
						i2c_sda_o <=i2c_sda_o;	 	 //数据保持
					end  
				end 
				//写操作
				WRITE:begin 				 		 //发送数据
					count_en     <=1'b1;		  		 //时钟计数器
					read_byte    <=read_byte;		 //IIC接收数据	
					rece_byte_reg<=rece_byte_reg;	 //接收字节寄存					
					//发送控制信号	
					finish    	 <=1'b0;				 //操作完成
					read_ok   	 <=1'b0;        	     //读完成   
					write_ok  	 <=1'b0;        	     //写完成   
					//读写标志	                	  
					send_flag 	 <=1'b1;        	     //发送标志  
					rece_flag 	 <=1'b0;        	     //接收标志  
					//输出IIC接口               
					i2c_sdaen 	 <=1'b1;		         //输出使能  
					//输出时钟                  
					if(star_scl)begin           	 //启动时钟
						i2c_scl_o <=1'b1;        	 //时钟拉高  
					end                         
					else if(stop_scl)begin      	 //停止时钟
						i2c_scl_o <=1'b0;        	 //时钟拉低  
					end
					else begin 						 //其他状态
						i2c_scl_o <=i2c_scl_o;  	 //时钟保持
					end 
					//输出数据
					if(star_sda)begin				 //启动数据
						state_count<=state_count;	 //收发计数器保持
						if(state_count<8'd8)			 //发送未完成
							i2c_sda_o <=send_byte_reg[7];//发送数据MSB	
						else 						 //发送未完成
							i2c_sda_o <=ACK;		 //发送应答	
					end
					else if(stop_sda)begin			 //停止数据
						state_count<=state_count+8'd1;//收发计数器加1
						send_byte_reg<={send_byte_reg[6:0],send_byte_reg[7]};//发送寄存器移位
						i2c_sda_o <=i2c_sda_o;		 //发送数据保持
					end
					else begin 
						state_count<=state_count;	 //收发计数器保持
						i2c_sda_o <=i2c_sda_o;	 	 //发送发送使能
					end  
				end 
				//读操作
				READ :begin 				 		 //发送数据
					count_en     <=1'b1;		  	 	 //时钟计数器
					read_byte    <=read_byte;		 //IIC接收数据	
					send_byte_reg<=send_byte_reg;	 //发送字节寄存				
					//发送控制信号
					finish    	 <=1'b0;				 //操作完成
					read_ok   	 <=1'b0;				 //读完成   
					write_ok  	 <=1'b0;				 //写完成   
					//读写标志	        				
					send_flag 	 <=1'b0;				 //发送标志 
					rece_flag 	 <=1'b1;				 //接收标志   
					//输出时钟                       //输出使能
					if(star_scl)begin				 //启动时钟
						i2c_scl_o <=1'b1;      		 //时钟拉高   
					end                        		
					else if(stop_scl)begin     		 //停止时钟
						i2c_scl_o <=1'b0;      		 //时钟拉低   
					end                        		
					else begin                 		 //其他状态
						i2c_scl_o <=i2c_scl_o; 		 //时钟保持
					end
					
					//输入数据接收数据
					if(half_sda)begin				  //数据中心
						state_count<=state_count;	  //收发计数器保持
						if(state_count<8'd8)			  //收发计数器小于8
							rece_byte_reg[7] <=i2c_sda_i;//接收数据	
						else 						  //接收数据完成
							rece_byte_reg<=rece_byte_reg;//接收寄存保持		
					end 
					else if(stop_sda)begin			  //接收数据完成
						state_count<=state_count+8'd1; //收发计数器加1
						rece_byte_reg<={rece_byte_reg[6:0],rece_byte_reg[7]};//接收寄存器移位
					end
					else begin 						  //其他状态
						state_count<=state_count;	  //收发计数器保持
						rece_byte_reg<=rece_byte_reg; //接收寄存保持				
					end  
					
					//输出数据发送应答
					if(star_sda)begin				  //启动数据
						if(state_count<8'd8)begin     //收发计数器小于8 
							i2c_sdaen <=1'b0;		  //输出不使能	  
							i2c_sda_o <=1'b0;		  //发送数据0	  
						end 						
						else begin  				  //数据接收完成
							i2c_sdaen <=1'b1;		  //输出使能
							i2c_sda_o <=ACK;		  //发送应答ACK	
						end	
					end
					else if(stop_sda)begin			  //接收数据完成
						i2c_sdaen <=i2c_sdaen;		  //输出使能保持
						i2c_sda_o <=i2c_sda_o;		  //发送数据保持
					end
					else begin 						  //其他状态
						i2c_sdaen <=i2c_sdaen;		  //输出使能保持
						i2c_sda_o <=i2c_sda_o;	 	  //发送数据保持
					end 
				end 
				//应答
				NACK	:begin 
					count_en     <=1'b1;		  	 	  //时钟计数器
					state_count  <=8'd0;		  	 	  //收发计数器
					//发送控制信号
					finish    <=1'b0;				  //完成信号
					//读写标志
					if(send_flag)begin				  //发送数据过程
						write_ok  <=1'b1;			  //写完成标志拉高
					end 
					else begin 						  //接收数据过程
						write_ok  <=1'b0;			  //写完成标志拉低
					end 
					//读写标志
					if(rece_flag)begin				  //接收数据过程
						read_ok   <=1'b1;			  //读完成标志拉高
					end                               
					else begin                        //发送数据过程
						read_ok   <=1'b0;			  //读完成标志拉低
					end 
					//输出IIC接口               
					i2c_sdaen 	 <=i2c_sdaen;		  //输出使能保持 
					//发送数据
					if(write_en)begin 				  //写使能
						send_byte_reg <= write_byte;  //发送数据更新
					end 
					else begin 						  //非写使能
						send_byte_reg <= send_byte_reg;//发送数据保持
					end 
					//接收数据
					read_byte    <=rece_byte_reg;	  //IIC接收数据输出
					rece_byte_reg<=rece_byte_reg;	  //接收字节寄存保持	
					//输出时钟 
					if(star_scl)begin				  //启动时钟
						i2c_scl_o <=1'b1;        	  //时钟拉高   
					end                         	  
					else if(stop_scl)begin      	  //停止时钟
						i2c_scl_o <=1'b0;        	  //时钟拉低   
					end                         	  
					else begin                  	  //其他状态
						i2c_scl_o <=i2c_scl_o;  	  //时钟保持
					end 
					//输出数据
					if(star_sda)begin				  //启动数据
						i2c_sda_o <=ACK;			  //发送应答ACK
					end                                
					else if(stop_sda)begin            //停止数据0  
						i2c_sda_o <=ACK;			  //发送应答ACK
					end                               
					else begin                        //其他状态
						i2c_sda_o <=i2c_sda_o;	 	  //输出保持
					end                             
				end                                 
				//停止使能			                  //接收数据完成
				STOP:begin 					 		  //发送停止
					read_byte    <=read_byte;		  //IIC接收数据保持	
					state_count  <=8'd0;			      //收发计数器
					send_byte_reg<=8'd0;			      //发送字节寄存
					rece_byte_reg<=8'd0;			      //接收字节寄存
					//发送控制信号
					finish       <=1'b0;				  //操作完成
					read_ok      <=1'b0;        		  //读完成 
					write_ok     <=1'b0;        		  //写完成 
					//输出IIC接口
					i2c_sdaen 	 <=1'b1;				  //输出使能
					//发送时钟
					if(star_scl)begin				  //启动时钟
						i2c_scl_o <=1'b1;       		  //时钟拉高  
					end                         		
					else if(stop_scl)begin      	  //停止时钟
						i2c_scl_o <=1'b1;       		  //时钟拉低  
					end                         		
					else begin                  	  //其他状态
						i2c_scl_o <=i2c_scl_o;  	  //时钟保持
					end 
					//发送数据
					if(star_sda)begin				  //启动数据		
						i2c_sda_o <=1'b0;			  //发送STOP	
						count_en  <=1'b1;			  //时钟计数器		  
					end
					else if(half_sda)begin			  //数据中心
						i2c_sda_o <=1'b1;			  //发送STOP
						count_en  <=1'b1;			  //时钟计数器		
					end
					else if(stop_sda)begin			  //关闭数据
						i2c_sda_o <=1'b1;			  //发送STOP
						count_en  <=1'b0;
					end
					else begin						 //其他状态 
						i2c_sda_o <=i2c_sda_o;		 //发送保持
						count_en  <=count_en;		 //时钟计数
					end 
				end  
				//完成
				FINISH:begin 						 //发送完成
					count_en     <=1'b0;				 //时钟计数器
					state_count  <=8'd0;				 //收发计数器
					read_byte    <=read_byte;		 //IIC接收数据	
					send_byte_reg<=8'd0;				 //发送字节寄存
					rece_byte_reg<=8'd0;				 //接收字节寄存
					//发送控制信号				 
					finish    	 <=1'b1;				 //操作完成
					read_ok   	 <=1'b0;				 //读完成 
					write_ok  	 <=1'b0;				 //写完成 
					//输出IIC接口
					i2c_sdaen <=1'b1;				 //输出使能
					i2c_scl_o <=1'b1;				 //输出时钟
					i2c_sda_o <=1'b1;				 //发送数据
				end 
				default:begin 
					count_en     <=1'b0;				 //时钟计数器
					state_count  <=8'd0;				 //收发计数器
					read_byte    <=read_byte;		 //IIC接收数据	
					send_byte_reg<=8'd0;				 //发送字节寄存
					rece_byte_reg<=8'd0;				 //接收字节寄存
					//发送控制信号				 
					finish    	 <=1'b1;				 //操作完成
					read_ok   	 <=1'b0;				 //读完成 
					write_ok  	 <=1'b0;				 //写完成 
					//输出IIC接口
					i2c_sdaen <=1'b1;				 //输出使能
					i2c_scl_o <=1'b1;				 //输出时钟
					i2c_sda_o <=1'b1;				 //发送数据
				end 
			endcase
		end 	
	end 

endmodule


*/








