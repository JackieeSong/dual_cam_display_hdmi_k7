`timescale 1ns / 1ps

module AXI_MASTER(
  //DDR3 MIG输出 AXI4 时钟 Clock 复位  Reset,
  input         ACLK,			// AXI_CLK
  input         ARESETN,		// AXI_RSTn
  // Master Write Address
  output [0:0]  M_AXI_AWID,		// 写地址ID；[0:0]代表一位位宽
  output [31:0] M_AXI_AWADDR,	// 写地址
  output [7:0]  M_AXI_AWLEN,    // 突发长度:0-255
  output [2:0]  M_AXI_AWSIZE,   // 突发大小:2'b011 //2的size大小字节
  output [1:0]  M_AXI_AWBURST,  // 突发类型:2'b01(Incremental Burst)
  output        M_AXI_AWLOCK,   // 总线lock:2'b00
  output [3:0]  M_AXI_AWCACHE,  // 内存类型:2'b0011
  output [2:0]  M_AXI_AWPROT,   // 保护类型:2'b000
  output [3:0]  M_AXI_AWQOS,    // 质量服务:2'b0000
  output [0:0]  M_AXI_AWUSER,   // 用户自定义:1'd0
  output        M_AXI_AWVALID,  // 写地址有效
  input         M_AXI_AWREADY,  // 写地址从机准备好
  // Master Write Data
  output [63:0] M_AXI_WDATA,	//写数据
  output [7:0]  M_AXI_WSTRB,	//写数据字节选通
  output        M_AXI_WLAST,	//写数据LAST
  output [0:0]  M_AXI_WUSER,	//写数据用户自定义
  output        M_AXI_WVALID,	//写数据有效
  input         M_AXI_WREADY,	//写数据从机准备好
  // Master Write Response
  input [0:0]   M_AXI_BID,		//写应答ID
  input [1:0]   M_AXI_BRESP,	//写应答
  input [0:0]   M_AXI_BUSER,	//写应答用户自定义
  input         M_AXI_BVALID,	//写应答有效
  output        M_AXI_BREADY,	//写应答主机准备好
  // Master Read Address
  output [0:0]  M_AXI_ARID,		//读地址ID
  output [31:0] M_AXI_ARADDR,   //读地址
  output [7:0]  M_AXI_ARLEN,    //突发长度:0-255
  output [2:0]  M_AXI_ARSIZE,   //突发大小:2'b011
  output [1:0]  M_AXI_ARBURST,  //突发类型:2'b01
  output [1:0]  M_AXI_ARLOCK,   //总线lock:2'b00
  output [3:0]  M_AXI_ARCACHE,  //内存类型:2'b0011
  output [2:0]  M_AXI_ARPROT,   //保护类型:2'b000
  output [3:0]  M_AXI_ARQOS,    //质量服务:2'b0000
  output [0:0]  M_AXI_ARUSER,   //用户自定义:1'd0
  output        M_AXI_ARVALID,  //读地址有效
  input         M_AXI_ARREADY,  //读地址从机准备好
  // Master Read Data 
  input [0:0]   M_AXI_RID,		//读数据ID
  input [63:0]  M_AXI_RDATA,		//读数据
  input [1:0]   M_AXI_RRESP,	//读应答
  input         M_AXI_RLAST,    //读数据LAST
  input [0:0]   M_AXI_RUSER,    //读数据用户自定义
  input         M_AXI_RVALID,   //读数据有效
  output        M_AXI_RREADY,   //读数据主机准备好
  //写数据
  input       	WR_START,		//写启动
  input [31:0]	WR_ADRS,		//写DDR首地址
  input [31:0]	WR_LEN, 		//写数据长度
  output      	WR_READY,		//写状态
  output      	WR_FIFO_RE,		//写DDR读FIFO使能
  input [63:0]	WR_FIFO_DATA,	//写DDR读FIFO数据
  output      	WR_DONE,		//写完成
  //读数据                      
  input        	RD_START,				//读启动
  input [31:0] 	RD_ADRS,        //读DDR首地址
  input [31:0] 	RD_LEN,         //读数据长度
  output       	RD_READY,       //读状态
  output       	RD_FIFO_WE,     //读DDR写FIFO使能
  output [63:0]	RD_FIFO_DATA,   //读DDR写FIFO数据
  output       	RD_DONE,        //读完成
  //状态输出
  output [2:0]  WR_STATE,       //写状态
  output [2:0]  RD_STATE        //读状态
);       

	assign WR_STATE = curr_wr_state;
	assign RD_STATE = curr_rd_state;

	parameter  BURAST_WADDR =  32'D2048; //突发地址 256*8byte;256个数据，一个数据8字节
	parameter  BURAST_RADDR =  32'D2048; //突发地址 256*8byte

//AXI写数据   	
	//输出控制信号
	//写地址通道
	assign M_AXI_AWID         = 1'b0;
	assign M_AXI_AWADDR[31:0] = reg_aw_addr[31:0];
	assign M_AXI_AWLEN[7:0]   = reg_w_len[7:0];			//突发长度
	assign M_AXI_AWSIZE[2:0]  = 2'b011;							//突发大小:2'b011 //2的size大小字节
	assign M_AXI_AWBURST[1:0] = 2'b01;
	assign M_AXI_AWLOCK       = 1'b0;
	assign M_AXI_AWCACHE[3:0] = 4'b0011;
	assign M_AXI_AWPROT[2:0]  = 3'b000;
	assign M_AXI_AWQOS[3:0]   = 4'b0000;
	assign M_AXI_AWUSER[0]    = 1'b1;
	assign M_AXI_AWVALID      = reg_awvalid;				//写地址有效	
	//写数据通道
	assign M_AXI_WDATA[63:0]  = WR_FIFO_DATA[63:0];
	assign M_AXI_WSTRB[7:0]   = reg_wvalid ? 8'hFF:8'h00;	//写数据字节选通
	assign M_AXI_WLAST        = reg_wlast;		//写地址有效;
	assign M_AXI_WUSER        = 1;
	assign M_AXI_WVALID       = reg_wvalid;
	assign M_AXI_BREADY       = M_AXI_BVALID;
	//写状态
	//FAST WRITE 	
	//assign WR_FIFO_RE       = reg_wvalid & M_AXI_WREADY;//读FIFO使能

	//读使能标志模式
	//fifo为标准模式，有一个时钟的延时，因此需要使用上述状态进行赋值
	assign WR_FIFO_RE         = reg_awvalid & M_AXI_AWREADY || reg_wvalid & M_AXI_WREADY & !M_AXI_WLAST;//读FIFO使能

	assign WR_READY           = (curr_wr_state == S_WR_IDLE)?1'b1:1'b0;
	assign WR_DONE            = (curr_wr_state == S_WR_DONE)?1'b1:1'b0;
  
	//定义状态机
	reg [2:0]	curr_wr_state;		//当前状态
	reg [2:0]	next_wr_state;		//下一状态
	//写AXI控制
	localparam S_WR_IDLE  = 3'd0;	//空闲状态
	localparam S_WA_WAIT  = 3'd1;	//写地址等待 WA -> Write_Address
	localparam S_WA_START = 3'd2;	//写地址开始
	localparam S_WD_WAIT  = 3'd3;	//写数据等待	WD -> write_data
	localparam S_WD_PROC  = 3'd4;	//写数据 		
	localparam S_WR_WAIT  = 3'd5;	//写数据应答	WR -> write respones
	localparam S_WR_DONE  = 3'd6;	//写数据完成
	

	//写地址控制寄存器
	reg		 	reg_awvalid;		//写地址有效
	reg [31:0]	reg_aw_addr;		//突发写地址
	reg [31:0]	reg_wr_len;			//突发写长度
	//写数据控制寄存器 		
	reg		 	reg_wvalid;			//写数据有效
	reg		 	reg_w_last;			//写完成last
	reg [7:0]	reg_w_len;			//写长度0~255
 
//第一段 :状态转移
always @(posedge ACLK)begin // axi-clk
	if(!ARESETN)begin //axi-reset_n
		curr_wr_state <= S_WR_IDLE;				//保持空闲状态
	end 	
	else begin 
		curr_wr_state <= next_wr_state;			//跳转下一状态
	end
end 
  
//第二段 :状态跳转
always @(*)begin 
	if(!ARESETN)begin 
		next_wr_state = S_WR_IDLE;		//保持空闲状态
	end 
	else begin 
		case(curr_wr_state)
		S_WR_IDLE :begin 
			if(WR_START)begin 					//启动写使能
				next_wr_state = S_WA_WAIT;		//写地址等待
			end 	
			else begin 							//未启动
				next_wr_state = S_WR_IDLE;		//保持空闲
			end 	
		end 	
		S_WA_WAIT :begin 						//写地址等待
			next_wr_state = S_WA_START;	
		end 	
		S_WA_START:begin 						//写地址开始
			if(M_AXI_AWREADY) begin				//写地址准备好
				next_wr_state = S_WD_WAIT;		//写数据等待
			end 	
			else begin 							//写地址未准备好
				next_wr_state = S_WA_START; 	//写地址开始
			end 	
		end		
		S_WD_WAIT :begin 						//写数据等待
			if(M_AXI_WREADY)begin				//写数据准备好
				next_wr_state = S_WD_PROC;		//写数据
			end 
			else begin 
				next_wr_state = S_WD_WAIT;		//写数据等待
			end 				
		end 	
		S_WD_PROC :begin 						//写数据
			if(reg_w_len[7:0] == 8'd0) begin		//写数据长度等于0
				next_wr_state = S_WR_WAIT;		//等待写应答
			end 	
			else begin 							//写数据未完成
				next_wr_state = S_WD_PROC;		//保持写状态
			end 
		end 
		S_WR_WAIT :begin 					 	//写应答
			if(M_AXI_BVALID)begin			 	//写应答
				if(reg_w_last) begin		 	//发送最后一包
					next_wr_state = S_WR_DONE;	//发送完成
				end 
				else begin					  	//发送未完成
					next_wr_state = S_WA_WAIT;	//写地址等到
				end 
			end 
			else begin 						  	//写未应答
				next_wr_state = S_WR_WAIT;	  	//等待写应答
			end 	
		end 
		S_WR_DONE :begin 					  	//写完成
			next_wr_state = S_WR_IDLE;		  	//回到空闲状态
		end 
		default:begin 
			next_wr_state = S_WR_IDLE;		  	//回到空闲状态
		end 
		endcase
	end 
end 
  
//第三段
always @(posedge ACLK)begin 
	if(!ARESETN)begin 
		//写地址
		reg_awvalid    <= 1'b0;					    //写地址有效
		reg_aw_addr	   <= 32'd0;					    //突发写地址
		reg_wr_len 	   <= 32'd0;					    //突发写长度
		//写数据 			                        
		reg_wvalid     <= 1'b0;					    //写数据有效
		reg_w_last     <= 1'b0;					    //写完成last
		reg_w_len	   	 <= 8'd0;					    //写长度0~255		
	end 
	else begin 
	case(curr_wr_state)								//状态转移
		S_WR_IDLE :begin 
			reg_awvalid     <= 1'b0;					//写地址有效
			if(WR_START)begin						//启动发送 
				reg_aw_addr <= WR_ADRS[31:0];		//突发写地址
				reg_wr_len  <= WR_LEN[31:0]-32'd1;	//突发写长度
			end             
			else begin      
				reg_aw_addr <= 32'h0;			    //突发写地址
				reg_wr_len  <= 32'h0;			    //突发写长度
			end 	
			//写数据
			reg_wvalid     	<= 1'b0;					//写数据有效
			reg_w_last      <= 1'b0;					//写完成last
			reg_w_len		<= 8'd0;				    //写长度0~255
		end 
		S_WA_WAIT :begin 							//写A等待
			//写地址
			reg_awvalid    <= 1'b1;					//写地址有效	
			reg_aw_addr	   <= reg_aw_addr;			//突发写地址
			reg_wr_len 	   <= reg_wr_len;			//突发写长度			
			//写数据
			reg_wvalid     	<= 1'b0;					//写数据有效
			if(reg_wr_len[31:11] != 0)begin 			//不可以一次突发完成
				reg_w_len  <= 8'hFF;			    	//写长度255
				reg_w_last <= 1'b0;					//写完成last
			end 	
			else begin  							//最后一次突发
				reg_w_len  <= reg_wr_len[10:3];		//写长度0~255
				reg_w_last <= 1'b1;					//写完成last
			end 
		end 
		S_WA_START:begin 							//写地址开始
			if(M_AXI_AWREADY) begin			//写地址准备好
		  		reg_awvalid <= 1'b0;					//写地址有效valid
			end 
			else begin 								//写地址未准备好
				reg_awvalid <= 1'b1;					//写地址valid
			end 
		end	
		S_WD_WAIT :begin 							//写数据等待
			reg_wr_len[31:11]<= reg_wr_len[31:11] - 21'd1;			
			reg_w_len <= reg_w_len;					//写长度0~255
			if(M_AXI_WREADY)begin					//写准备好
				reg_wvalid  <= 1'b1;					//写数据有效
			end 
			else begin 
				reg_wvalid  <= reg_wvalid;			//写数据有效
			end 			
		end 
		S_WD_PROC :begin 							//写数据
			if(M_AXI_WREADY)begin					//写准备好
				if(reg_w_len == 8'd0) begin			//写完成
					reg_wvalid <= 1'b0;				//写有效拉低
					reg_w_len <= reg_w_len;			//写长度保持
				end 
				else begin							//写数据
					reg_wvalid <= 1'b1;				//写有效拉高
					reg_w_len <= reg_w_len-8'd1;		//写长度自减
				end
			end 
			else begin 								//写未准备好
				reg_wvalid <= reg_wvalid;			//写数据有效保持
				reg_w_len <= reg_w_len;				//写长度保持
			end 	
		end 
		S_WR_WAIT :begin 							//等待写应答
			if(M_AXI_BVALID)begin					//等待写应答
				if(reg_w_last) begin				//写最后一包数据
					reg_aw_addr <= reg_aw_addr;		//写地址保持
				end             
				else begin      					//写一包数据完成
					reg_aw_addr <= reg_aw_addr + BURAST_WADDR;	//写地址递增一次突发长度
				end 
			end 
			else begin 								//等待应答
				reg_aw_addr<= reg_aw_addr;			//写地址保持
			end 
		end 
		S_WR_DONE :begin 							//写完成
			//写地址
			reg_awvalid    <= reg_awvalid; 			//写地址有效
			reg_aw_addr	   <= reg_aw_addr;			//突发写地址
			reg_wr_len 	   <= reg_wr_len ;			//突发写长度
			//写数据 	
			reg_wvalid     <= reg_wvalid;			//写数据有效
			reg_w_last     <= reg_w_last;			//写完成last
			reg_w_len	   <= reg_w_len	;			//写长度0~255	
			end 
		default:begin 								//默认状态
			//写地址
			reg_awvalid    <= 1'b0;					//写地址有效
			reg_aw_addr	   <= 32'd0;					//突发写地址
			reg_wr_len 	   <= 32'd0;					//突发写长度
			//写数据 			
			reg_wvalid     <= 1'b0;					//写数据有效
			reg_w_last     <= 1'b0;					//写完成last
			reg_w_len	   <= 8'd0;					//写长度0~255	
		end 
	endcase
	end 
end 

//发送LAST信号
reg reg_wlast;
always @(posedge ACLK)begin 
	if(!ARESETN)begin 
		reg_wlast <= 1'b0;		//写地址有效	
	end 
	else if(reg_w_len[7:0] == 8'd1)begin 
		reg_wlast <= 1'b1;		//写地址有效
	end 
	else begin
		reg_wlast <= 1'b0;		//写地址有效
	end 
end 
   
   
//AXI读数据   
	// Master Read Address
	assign M_AXI_ARID         = 1'b0;
	assign M_AXI_ARADDR[31:0] = reg_rd_addr[31:0];
	assign M_AXI_ARLEN[7:0]   = reg_r_len[7:0];
	assign M_AXI_ARSIZE[2:0]  = 3'b011;
	assign M_AXI_ARBURST[1:0] = 2'b01;
	assign M_AXI_ARLOCK       = 1'b0;
	assign M_AXI_ARCACHE[3:0] = 4'b0011;
	assign M_AXI_ARPROT[2:0]  = 3'b000;
	assign M_AXI_ARQOS[3:0]   = 4'b0000;
	assign M_AXI_ARUSER[0]    = 1'b1;
	assign M_AXI_ARVALID      = reg_arvalid;
	
	assign M_AXI_RREADY       = M_AXI_RVALID ; //reg_rready
	
	assign RD_READY           = (curr_rd_state == S_RD_IDLE)?1'b1:1'b0;
	assign RD_DONE            = (curr_rd_state == S_RR_DONE)?1'b1:1'b0;
	
	assign RD_FIFO_WE         = M_AXI_RVALID;
	assign RD_FIFO_DATA[63:0] = M_AXI_RDATA[63:0];

	//读控制
	reg [2:0]	curr_rd_state;
	reg [2:0]	next_rd_state;
	
	localparam S_RD_IDLE  = 3'd0;	//空闲状态
	localparam S_RA_WAIT  = 3'd1;	//读地址等待
	localparam S_RA_START = 3'd2;	//读地址开始
	localparam S_RD_WAIT  = 3'd3;	//读数据等待
	localparam S_RD_PROC  = 3'd4;	//读数据
	localparam S_RR_WAIT  = 3'd5;	//读数据应答
	localparam S_RR_DONE  = 3'd6;	//读数据完成
	
	//读地址
	reg		 	reg_arvalid;		//读地址有效
	reg [31:0]	reg_rd_addr;		//突发写地址
	reg [31:0]	reg_rd_len;			//突发写长度
	//读数据   
	reg		    reg_rready;			//写数据有效
	reg		    reg_r_last;			//写完成last
	reg [7:0]	reg_r_len;			//写长度0~255
  
//第一段 
always @(posedge ACLK)begin
	if(!ARESETN)begin 
		curr_rd_state<=S_RD_IDLE;			//保持空闲状态
	end 	                                
	else begin                              
		curr_rd_state<=next_rd_state;       //跳转下一状态
	end                                     
end                                         

//第二段                                    
always @(*)begin                            
	if(!ARESETN)begin                       
		next_rd_state = S_RD_IDLE;          //保持空闲状态
	end                                     
	else begin                              
	case(curr_rd_state)                 
		S_RD_IDLE :begin                    
			if(RD_START)begin 				//启动读使能
				next_rd_state = S_RA_WAIT;	//读地址
			end                             
			else begin 						//未启动
				next_rd_state = S_RD_IDLE;	//保持空闲
			end 
		end 
		S_RA_WAIT :begin 				//读地址等待
			next_rd_state = S_RA_START;
		end 
		S_RA_START:begin 					//读地址开始
			if(M_AXI_ARREADY) begin			//读地址准备好
				next_rd_state = S_RD_WAIT;	//读数据等待
			end 
			else begin 						//读地址未准备好
				next_rd_state = S_RA_START;	//保持读地址开始
			end 
		end	
		S_RD_WAIT :begin 					//读数据等待
			if(M_AXI_RVALID)begin			//读数据有效
				next_rd_state = S_RD_PROC;	//读数据
			end 
			else begin 						//读数据未有效
				next_rd_state = S_RD_WAIT;	//保持读数据等待
			end 	
		end 
		S_RD_PROC :begin 					//读数据
			if(reg_r_len[7:0] == 8'd0) begin	//读数据长度等于0
				next_rd_state = S_RR_WAIT;  //等待读完成
			end                                
			else begin                      //读数据未完成
				next_rd_state = S_RD_PROC;  //保持读状态
			end 
		end 
		S_RR_WAIT :begin 					 //读等待
			if(reg_r_last) begin			 //读最后一包数据
				next_rd_state = S_RR_DONE;	 //读数据完成
			end 
			else begin						 //读数据未完成
				next_rd_state = S_RA_WAIT;	 //读地址等待
			end 
		end 
		S_RR_DONE :begin 					 //读完成
			next_rd_state = S_RD_IDLE;		 //回到空闲状态
		end 
		default:begin 						 //默认状态
			next_rd_state = S_RD_IDLE;		 //回到空闲状态
		end 
	endcase
	end 
end 

//第三段
always @(posedge ACLK)begin 
	if(!ARESETN)begin 
		//读地址
		reg_arvalid    <= 1'b0;						//读地址有效
		reg_rd_addr	   <= 32'd0;						//突发写地址
		reg_rd_len 	   <= 32'd0;						//突发写长度
		//读数据 				
		reg_rready     <= 1'b0;						//读数据准备好
		reg_r_last     <= 1'b0;						//读完成last
		reg_r_len	   <= 8'd0;						//读长度0~255		
	end 	
	else begin 
	case(curr_rd_state)								//状态转移
		S_RD_IDLE :begin 							
			reg_arvalid     <= 1'b0;					//读地址有效
			if(RD_START)begin						//启动发送 
				reg_rd_addr <= RD_ADRS[31:0];		//突发读地址
				reg_rd_len  <= RD_LEN[31:0]-32'd1;	//突发读长度
			end             
			else begin      
				reg_rd_addr <= 32'h0;			    //突发读地址
				reg_rd_len  <= 32'h0;			    //突发读长度
			end 	
			//读数据
			reg_rready      <= 1'b0;				    //读数据准备好
			reg_r_last      <= 1'b0;					//读完成last
			reg_r_len		<= 8'd0;				    //读长度0~255
		end 
		S_RA_WAIT :begin 							//读地址等待
			//读地址
			reg_arvalid    <= 1'b1;					//读地址有效
			reg_rd_addr	   <= reg_rd_addr;			//突发读地址
			reg_rd_len 	   <= reg_rd_len;			//突发读长度
			//读数据
			reg_rready     <= 1'b1;					//读数据准备好
			if(reg_rd_len[31:11] != 0)begin 			//不可以一次突发完成
				reg_r_len  <= 8'hFF;			    	//读长度255
				reg_r_last <= 1'b0;					//读完成last
			end 	
			else begin  							//最后一次突发
				reg_r_len  <= reg_rd_len[10:3];		//读长度0~255
				reg_r_last <= 1'b1;					//读完成last
			end 	
		end 
		S_RA_START:begin 							//读地址开始
			if(M_AXI_ARREADY) begin                 //读地址准备好
		  		reg_arvalid  <= 1'b0;               //读地址valid
			end                                     
			else begin                              //读地址未准备好
				reg_arvalid  <= 1'b1;				//读地址valid
			end 
		end	
		S_RD_WAIT :begin 							//读数据等待
			reg_rd_len[31:11] <= reg_rd_len[31:11] - 21'd1;
			reg_r_len	  <= reg_r_len;				//读长度0~255		
			if(M_AXI_RVALID)begin					//读数据有效
				reg_rready    <= 1'b1;				//读数据准备好
			end 
			else begin 
				reg_rready    <= reg_rready;		//读数据准备好
			end			
		end 
		S_RD_PROC :begin 							//读数据
			if(M_AXI_RVALID)begin					//读数据有效
				if(reg_r_len == 8'd0) begin			//读完成
					reg_rready <= 1'b0;				//读数据准备好
					reg_r_len <= reg_r_len;			//读长度保持
				end 
				else begin							//读数据	
					reg_rready <= 1'b1;	            //读有效拉高
					reg_r_len <= reg_r_len-8'd1;    //读长度自减
				end
			end 
			else begin 								//读数据未有效
				reg_rready <= reg_rready;			//读数据有效
				reg_r_len <= reg_r_len;				//读长度0~255
			end 	
		end 
		S_RR_WAIT :begin 							//等待读应答
			if(reg_r_last) begin					//读最后一包数据
				reg_rd_addr <= reg_rd_addr;			//读地址保持
			end             
			else begin      						//读一包数据完成
				reg_rd_addr <= reg_rd_addr + BURAST_RADDR;	//读地址递增一次突发长度
			end 
		end 
		S_RR_DONE :begin 							//读完成
			//写地址
			reg_arvalid    <= reg_arvalid;			//读地址有效
			reg_rd_addr	   <= reg_rd_addr;			//突发读地址
			reg_rd_len 	   <= reg_rd_len ;			//突发读长度
			//写数据 	
			reg_rready     <= reg_rready;			//读数据有效
			reg_r_last     <= reg_r_last;			//读完成last
			reg_r_len	   <= reg_r_len	;			//读长度0~255		
		end 
		default:begin 
			//写地址
			reg_arvalid    <= 1'b0;					//读地址有效
			reg_rd_addr	   <= 32'd0;					//突发读地址
			reg_rd_len 	   <= 32'd0;					//突发读长度
			//写数据 			
			reg_rready     <= 1'b0;					//读数据有效
			reg_r_last     <= 1'b0;					//读完成last
			reg_r_len	   <= 8'd0;					//读长度0~255			
		end 
		endcase
	end 
end 
endmodule

