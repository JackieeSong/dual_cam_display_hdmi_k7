//IIC信息配置
module i2c_config_state(
	input              rst,						//复位信号
	input              clk,						//输入时钟
	input[15:0]        clk_div_cnt,		//分频计数值
	input 			   start_config,
	input              i2c_addr_2byte,//输入地址1位2位标志信号
	output reg[9:0]    lut_index,			//配置信息地址查找表
	input[7:0]         lut_dev_addr,	//输入器件地址
	input[15:0]        lut_reg_addr,	//16位
	input[7:0]         lut_reg_data,	//8位
	output reg         error,
	output             done,
	inout              i2c_scl,				//inout时钟线
	inout              i2c_sda				//inout数据线
);
wire scl_pad_i;										//IO输入
wire scl_pad_o;										//IO输出
wire scl_padoen_o;									//三态门输出控制
                      							
wire sda_pad_i;										//IO输入
wire sda_pad_o;										//IO输出
wire sda_padoen_o;									//三态门输出控制


reg i2c_read_req;			  						//IIC读请求
wire i2c_read_req_ack;								//IIC读应答
reg i2c_write_req;									//IIC写请求
wire i2c_write_req_ack; 							//IIC写应答
wire[7:0] i2c_slave_dev_addr;						//从机地址
wire[15:0] i2c_slave_reg_addr;						//从机地址
wire[7:0] i2c_write_data;							//IIC写数据
wire[7:0] i2c_read_data;							//IIC读数据

wire err;													//IIC状态
reg [2 :0]start_reg;   			 //发送完成
reg [2 :0]write_ok_reg;			 //发送完成

wire start_flag;
	//数据缓存
	always @(posedge clk)begin 
		if(rst)begin
			start_reg  <=3'd0;
		end
		else begin  
			start_reg  <={start_reg[1:0],start_config};	//与CMOS_RST中的coms_start连接，判断该信号上升沿
		end 
	end 
	
	assign start_flag    = !start_reg   [2] & start_reg   [1];	//两拍信号的上升沿

localparam S_IDLE             =  3'd0;
localparam S_I2C_WR_CHECK     =  3'd1;
localparam S_I2C_WR_REQ       =  3'd2;
localparam S_WAIT_I2C_WR	  =  3'd3;
localparam S_I2C_WR_DONE	  =  3'd4;
localparam S_I2C_CONFIG_DONE  =  3'd5;

reg [2:0] current_state;
reg [2:0] next_state;

assign sda_pad_i = i2c_sda;	
//assign		 sda_pad_i= sda_padoen_o?1'bZ:i2c_sda;
											//IO输入	
assign i2c_sda = ~sda_padoen_o ? sda_pad_o : 1'bz;	//IO输出控制：sda_padoen_o==1 输出为高阻态 sda_padoen_o==0 输出 sda_pad_o
assign scl_pad_i = i2c_scl;													//IO输入	
assign i2c_scl = ~scl_padoen_o ? scl_pad_o : 1'bz;  //IO输出控制：scl_padoen_o==1 输出为高阻态 scl_padoen_o==0 输出 scl_pad_o
//assign i2c_scl = scl_pad_o; 
assign done = (current_state == S_I2C_CONFIG_DONE);	   //IIC读写完成
assign i2c_slave_dev_addr  = lut_dev_addr; //IIC地址
assign i2c_slave_reg_addr = lut_reg_addr;  //IIC地址
assign i2c_write_data  = lut_reg_data;     //IIC数据


//FSM3-1
always @(posedge clk ) begin
	if (rst) begin
		// reset
		current_state<=S_IDLE;
	end
	else begin
		current_state<=next_state;
	end
end
//FSM3-2
always @(*) begin
	if (rst) begin
		// reset
		next_state = S_IDLE;
	end
	else  begin
		case (current_state) 
			 S_IDLE:begin
				if(start_flag)begin
					next_state = S_I2C_WR_CHECK;
				end 
				else begin
					next_state = S_IDLE;
				end 
			 	
			 end 
			 S_I2C_WR_CHECK: begin
			 	if(i2c_slave_dev_addr != 8'hff) begin//the last +1 reg
			 		next_state = S_I2C_WR_REQ;
			 	end 
			 	else begin
			 		next_state =S_I2C_CONFIG_DONE;
			 	end 
			 end 
			 S_I2C_WR_REQ: begin
			 	next_state =S_WAIT_I2C_WR;
			 end 
			 S_WAIT_I2C_WR: begin
			 	if(i2c_write_req_ack)begin
			 		next_state = S_I2C_WR_DONE;
			 	end 
			 	else begin
			 		next_state = S_WAIT_I2C_WR;
			 	end 
			 end 
			 S_I2C_WR_DONE: begin
			 	next_state = S_I2C_WR_CHECK;
			 end 
			 S_I2C_CONFIG_DONE: begin
			 	next_state = S_I2C_CONFIG_DONE;
			 end 
		    default:begin
		    	next_state =S_IDLE;
		    end 	           
		endcase
	end
end
//FSM3-3

always @(posedge clk ) begin
	if (rst) begin
		// reset
		i2c_write_req <= 1'b0;	
	end
	else if (current_state==S_I2C_WR_REQ) begin
		i2c_write_req <= 1'b1;	
	end
	else if(current_state==S_I2C_WR_DONE)begin
		i2c_write_req <= 1'b0;	
	end 
	else begin
		// i2c_write_req <= 1'b0;
		i2c_write_req <= i2c_write_req;
	end 
end

//1
always @(posedge clk ) begin //1.激活index,根据index进行lut_data索引，将lut_data的数据根据I2C协议写进ov5640
	if (rst) begin
		// reset
		lut_index <= 8'd0;
	end
	else if(current_state==S_I2C_WR_DONE)begin
		lut_index <= lut_index + 8'd1; //update the register index for next I2C write.
	end 
	else begin
		lut_index <= lut_index;
	end 
end

always @(posedge clk ) begin
	if (rst) begin
		// reset
		error <= 1'b0;
	end
	else if(current_state==S_I2C_WR_DONE)begin
		error <= err ? 1'b1 : 0; 
	end 
	else begin
		error <= 1'b0;
	end 
end

i2c_master_top i2c_master_top_m0
(
	.rst(rst),
	.clk(clk),
	.clk_div_cnt(clk_div_cnt),
	
	// I2C signals
	// i2c clock line
	.scl_pad_i(scl_pad_i),       		// SCL-line input
	.scl_pad_o(scl_pad_o),       		// SCL-line output (always 1'b0)
	.scl_padoen_o(scl_padoen_o),    // SCL-line output enable (active low)

	// i2c data line
	.sda_pad_i(sda_pad_i),       		// SDA-line input
	.sda_pad_o(sda_pad_o),      		// SDA-line output (always 1'b0)
	.sda_padoen_o(sda_padoen_o),    // SDA-line output enable (active low)
	
	.i2c_read_req(i2c_read_req),
	.i2c_addr_2byte(i2c_addr_2byte),
	.i2c_read_req_ack(i2c_read_req_ack),
	.i2c_write_req(i2c_write_req),
	.i2c_write_req_ack(i2c_write_req_ack),
	.i2c_slave_dev_addr(i2c_slave_dev_addr),
	.i2c_slave_reg_addr(i2c_slave_reg_addr),
	.i2c_write_data(i2c_write_data),
	.i2c_read_data(i2c_read_data),
	.error(err)
);
endmodule