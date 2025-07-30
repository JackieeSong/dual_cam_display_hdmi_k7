`timescale 1ns/1ps
module frame_fifo_write_state
#
(
	parameter MEM_DATA_BITS          = 6'd32,
	parameter ADDR_BITS              = 5'd23,
	parameter BUSRT_BITS             = 4'd10,
	parameter BURST_SIZE             = 8'd128
)               
(
	input                            rst,                  
	input                            mem_clk,                    // external memory controller user interface clock
	output reg                       wr_burst_req,               // to external memory controller,send out a burst write request  
	output reg[BUSRT_BITS - 1:0]     wr_burst_len,               // to external memory controller,data length of the burst write request, not bytes 
	output reg[ADDR_BITS - 1:0]      wr_burst_addr,              // to external memory controller,base address of the burst write request 
	input                            wr_burst_data_req,          // from external memory controller,write data request ,before data 1 clock 
	input                            wr_burst_finish,            // from external memory controller,burst write finish
	// when a new image arrived, a write_req signal generated
	input                            write_req,                  // data write module write request,keep '1' until read_req_ack = '1'
	output reg                       write_req_ack,              // data write module write request response
	output                           write_finish,               // data write module write request finish
	input[ADDR_BITS - 1:0]           write_addr_0,               // data write module write request base address 0, used when write_addr_index = 0
	input[ADDR_BITS - 1:0]           write_addr_1,               // data write module write request base address 1, used when write_addr_index = 1
	input[ADDR_BITS - 1:0]           write_addr_2,               // data write module write request base address 1, used when write_addr_index = 2
	input[ADDR_BITS - 1:0]           write_addr_3,               // data write module write request base address 1, used when write_addr_index = 3
	input[1:0]                       write_addr_index,           // select valid base address from write_addr_0 write_addr_1 write_addr_2 write_addr_3
	input[ADDR_BITS - 1:0]           write_len,                  // data write module write request data length
	output reg                       fifo_aclr,                  // to fifo asynchronous clear // fifo异步清除
	input[8:0]                       rdusedw                     // from fifo read used words
);
localparam ONE                       = 256'd1;                   //256 bit '1'   you can use ONE[n-1:0] for n bit '1'
localparam ZERO                      = 256'd0;                   //256 bit '0'
//write state machine code
localparam S_IDLE                    = 3'd0;                        //idle state,waiting for write
localparam S_ACK                     = 3'd1;                        //written request response
localparam S_CHECK_FIFO              = 3'd2;                        //check the FIFO status, ensure that there is enough space to burst write
localparam S_WRITE_BURST             = 3'd3;                        //begin a burst write
localparam S_WRITE_BURST_DATA_REQ    = 3'd4;						// the real state tx burst data
localparam S_WRITE_BURST_END         = 3'd5;                        //a burst write complete
localparam S_END                     = 3'd6;                        //a frame of data is written to complete

reg [2:0] current_state;
reg [2:0] next_state;

//reg                               write_req_d0;                //asynchronous write request, synchronize to 'mem_clk' clock domain,first beat
wire                                write_req_d1;                //the second
reg                                 write_req_d2;                //third,Why do you need 3 ? Here's the design habit
reg[ADDR_BITS - 1:0]                write_len_d0;                //asynchronous write_len(write data length), synchronize to 'mem_clk' clock domain first
reg[ADDR_BITS - 1:0]                write_len_d1;                //second
reg[ADDR_BITS - 1:0]                write_len_latch;             //lock write data length
reg[ADDR_BITS - 1:0]                write_cnt;                   //write data counter
reg[1:0]                            write_addr_index_d0;
reg[1:0]                            write_addr_index_d1;


assign write_finish = (current_state == S_END) ? 1'b1 : 1'b0;            //write finish at state 'S_END'
always@(posedge mem_clk or posedge rst)
begin
	if(rst == 1'b1)
	begin
		write_len_d0    <=  ZERO[ADDR_BITS - 1:0];              //equivalent to write_len_d0 <= 0;
		write_len_d1    <=  ZERO[ADDR_BITS - 1:0];              //equivalent to write_len_d1 <= 0;
		write_addr_index_d0    <=  2'b00;
		write_addr_index_d1    <=  2'b00;
	end
	else
	begin
		write_len_d0    <=  write_len;	//以下打了两拍
		write_len_d1    <=  write_len_d0;
		write_addr_index_d0 <= write_addr_index;
		write_addr_index_d1 <= write_addr_index_d0;
	end 
end

//延时write_req，跨时钟域的单Bit信号
syn_block write_req_syn_inst (
     .clk              (mem_clk),
     .data_in          (write_req),
     .data_out         (write_req_d1)
  );

always@(posedge mem_clk )
begin
	if(rst == 1'b1)begin
		write_req_d2    <=  1'b0;
	end
	else begin
		write_req_d2    <=  write_req_d1;	//write_req_d2延迟6拍，write_req_syn_inst中5拍
	end 
end


//FSM3-1
always @(posedge mem_clk ) begin
	if (rst) begin
		// reset
		current_state<=S_IDLE;
	end
	else  begin
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
		case(current_state)
			S_IDLE:begin
				if(write_req_d2==1'b1)begin 
					next_state = S_ACK;
				end 
				else begin
					next_state = S_IDLE;
				end 
			end 
			S_ACK: begin
				if(write_req_d2==1'b0)begin
					next_state = S_CHECK_FIFO;
				end 
				else begin
					next_state = S_ACK;
				end 
			end
			S_CHECK_FIFO: begin
				if(write_req_d2==1'b1)begin //如果有新的请求，立马跳入新的请求去
					next_state =S_ACK;
				end 
				//if there are enough data in FIFO for a burst, then a burst write request can be done, goto burst write state
				else if(rdusedw>=BURST_SIZE)begin //BURST_SIZE与FIFO里面的数据作比较
					next_state = S_WRITE_BURST;
				end 
				else begin
					next_state = S_CHECK_FIFO;
				end 
			end 
			S_WRITE_BURST: begin
				if(wr_burst_data_req)begin
					next_state = S_WRITE_BURST_DATA_REQ;
				end 
				else begin
					next_state =S_WRITE_BURST;
				end 
			end 
			S_WRITE_BURST_DATA_REQ: begin
				if(wr_burst_finish)begin
					next_state = S_WRITE_BURST_END;
				end 
				else begin
					next_state =S_WRITE_BURST_DATA_REQ;
				end 
			end 
			S_WRITE_BURST_END: begin
				//if there is a new write request at this time, enter the 'S_ACK' state
				if(write_req_d2==1'b1)begin
					next_state = S_ACK;
				end
				//if the write counter value is less than the frame length, continue writing,
				//otherwise the writing is complete
				else if(write_cnt<write_len_latch)begin
					next_state = S_CHECK_FIFO;
				end  
				else begin
					next_state = S_END;
				end 
			end 
			S_END: begin
				next_state = S_IDLE;
			end 
			default: begin
				next_state = S_IDLE;
			end 
		endcase
	end
end

//FSM3-3

always @(posedge mem_clk ) begin
	if (rst) begin
		// reset
		fifo_aclr <= 1'b0;
		write_req_ack<= 1'b0;
	end
	else if (current_state==S_ACK) begin
		fifo_aclr<=1'b1;// when a new frame arrived, reset the data FIFO to clear the data in fifo 
		write_req_ack<=1'b1;//handshake for a new frame write .
	end
	else begin
			fifo_aclr<=1'b0;
			write_req_ack<=1'b0;
	end 
end

//latch write length which equal to the size of the new picture
always @(posedge mem_clk ) begin
	if (rst) begin
		// reset
		write_len_latch <= ZERO[ADDR_BITS - 1:0];
	end
	else if (current_state==S_ACK) begin
		if(write_req_d2==1'b1)begin
			write_len_latch<=write_len_d1;
		end 
		else begin
			write_len_latch<=write_len_latch;
		end 
		
	end
end

always @(posedge mem_clk ) begin
	if (rst) begin
		// reset
		wr_burst_addr <= ZERO[ADDR_BITS - 1:0];
	end
	else if (current_state==S_ACK) begin//latch the first address of an DDR block
		if(write_addr_index_d1 == 2'd0)begin
			wr_burst_addr <= write_addr_0;
		end 
		else if(write_addr_index_d1 == 2'd1)begin
			wr_burst_addr <= write_addr_1;
		end 
		else if(write_addr_index_d1 == 2'd2)begin
			wr_burst_addr <= write_addr_2;
		end
		else begin
			wr_burst_addr <= write_addr_3;
		end 	
	end
	else if(current_state==S_WRITE_BURST_END)begin// update the burst address to generate the next burst address after a burst.
		wr_burst_addr <= wr_burst_addr + BURST_SIZE[ADDR_BITS - 1:0];	//位宽为[7:0]，64bit的位宽，深度为256
	end 
	else begin
		wr_burst_addr<=wr_burst_addr;
	end 
end

always @(posedge mem_clk ) begin
	if (rst) begin
		// reset
		write_cnt <= ZERO[ADDR_BITS - 1:0];
	end
	else if (current_state==S_ACK) begin
		write_cnt <= ZERO[ADDR_BITS - 1:0];		
	end
	else if(current_state==S_WRITE_BURST_END)begin
		write_cnt <= write_cnt + BURST_SIZE[ADDR_BITS - 1:0];
	end 
	else begin
		write_cnt<=write_cnt;
	end 
end

always @(posedge mem_clk ) begin
	if (rst) begin
		// reset
		wr_burst_req <= 1'b0;
	end
	else if (current_state==S_WRITE_BURST) begin
		wr_burst_req<=1'b1;		
	end
	else begin
		wr_burst_req<=1'b0;
	end 
end

always @(posedge mem_clk ) begin
	if (rst) begin
		// reset
		wr_burst_len <= ZERO[BUSRT_BITS - 1:0];
	end
	else if (current_state==S_CHECK_FIFO) begin
		wr_burst_len <= BURST_SIZE[BUSRT_BITS - 1:0]; //BUSRT_BITS=4'd10
	end
	else begin
		wr_burst_len<=wr_burst_len;
	end 
end

endmodule
