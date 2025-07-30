`timescale 1ns/1ps
module frame_fifo_write2
#
(
	parameter MEM_DATA_BITS          = 32,
	parameter ADDR_BITS              = 23,
	parameter BUSRT_BITS             = 10,
	parameter BURST_SIZE             = 128
)               
(
	input                            rst,                  
	input                            mem_clk,                    // external memory controller user interface clock
	output reg                       wr_burst_req,               // to external memory controller,send out a burst write request  
	output reg[BUSRT_BITS - 1:0]     wr_burst_len,               // to external memory controller,data length of the burst write request, not bytes 
	output reg[ADDR_BITS - 1:0]      wr_burst_addr,              // to external memory controller,base address of the burst write request 
	input                            wr_burst_data_req,          // from external memory controller,write data request ,before data 1 clock 
	input                            wr_burst_finish,            // from external memory controller,burst write finish
	input                            write_req,                  // data write module write request,keep '1' until read_req_ack = '1'
	output reg                       write_req_ack,              // data write module write request response
	output                           write_finish,               // data write module write request finish
	input[ADDR_BITS - 1:0]           write_addr_0,               // data write module write request base address 0, used when write_addr_index = 0
	input[ADDR_BITS - 1:0]           write_addr_1,               // data write module write request base address 1, used when write_addr_index = 1
	input[ADDR_BITS - 1:0]           write_addr_2,               // data write module write request base address 1, used when write_addr_index = 2
	input[ADDR_BITS - 1:0]           write_addr_3,               // data write module write request base address 1, used when write_addr_index = 3
	input[1:0]                       write_addr_index,           // select valid base address from write_addr_0 write_addr_1 write_addr_2 write_addr_3
	input[ADDR_BITS - 1:0]           write_len,                  // data write module write request data length
	output reg                       fifo_aclr,                  // to fifo asynchronous clear
	input[15:0]                      rdusedw                     // from fifo read used words
);
localparam ONE                       = 256'd1;                   //256 bit '1'   you can use ONE[n-1:0] for n bit '1'
localparam ZERO                      = 256'd0;                   //256 bit '0'
//write state machine code
localparam S_IDLE                    = 0;                        //idle state,waiting for write
localparam S_ACK                     = 1;                        //written request response
localparam S_CHECK_FIFO              = 2;                        //check the FIFO status, ensure that there is enough space to burst write
localparam S_WRITE_BURST             = 3;                        //begin a burst write
localparam S_WRITE_BURST_END         = 4;                        //a burst write complete
localparam S_END                     = 5;                        //a frame of data is written to complete

reg                                 write_req_d0;                //asynchronous write request, synchronize to 'mem_clk' clock domain,first beat
reg                                 write_req_d1;                //the second
reg                                 write_req_d2;                //third,Why do you need 3 ? Here's the design habit
reg[ADDR_BITS - 1:0]                write_len_d0;                //asynchronous write_len(write data length), synchronize to 'mem_clk' clock domain first
reg[ADDR_BITS - 1:0]                write_len_d1;                //second
reg[ADDR_BITS - 1:0]                write_len_latch;             //lock write data length
reg[ADDR_BITS - 1:0]                write_cnt;                   //write data counter
reg[1:0]                            write_addr_index_d0;
reg[1:0]                            write_addr_index_d1;


assign write_finish = (curr_state == S_END) ? 1'b1 : 1'b0;            //write finish at state 'S_END'

always@(posedge mem_clk or posedge rst)
begin
	if(rst == 1'b1)
	begin
		write_req_d0    <=  1'b0;
		write_req_d1    <=  1'b0;
		write_req_d2    <=  1'b0;
		write_len_d0    <=  ZERO[ADDR_BITS - 1:0];              //equivalent to write_len_d0 <= 0;
		write_len_d1    <=  ZERO[ADDR_BITS - 1:0];              //equivalent to write_len_d1 <= 0;
		write_addr_index_d0    <=  2'b00;
		write_addr_index_d1    <=  2'b00;
	end
	else
	begin
		write_req_d0    <=  write_req;
		write_req_d1    <=  write_req_d0;
		write_req_d2    <=  write_req_d1;
		write_len_d0    <=  write_len;
		write_len_d1    <=  write_len_d0;
		write_addr_index_d0 <= write_addr_index;
		write_addr_index_d1 <= write_addr_index_d0;
	end 
end

reg[3:0]                            curr_state;                       //state machine
reg[3:0]                            next_state;                       //state machine

//第一段 :状态转移
always @(posedge mem_clk)begin
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
			S_IDLE:begin
				if(write_req_d2 == 1'b1)begin
					next_state = S_ACK;
				end
				else begin 
					next_state = S_IDLE;
				end 
			end
			S_ACK: begin
				if(write_req_d2 == 1'b0) begin
					next_state = S_CHECK_FIFO;
				end
				else begin
					next_state = S_ACK;                   
				end
			end
			S_CHECK_FIFO:begin
				if(write_req_d2 == 1'b1) begin
					next_state = S_ACK;
				end
				else if(rdusedw >= BURST_SIZE)begin
					next_state = S_WRITE_BURST;
				end
				else begin 
					next_state = S_CHECK_FIFO;
				end 
			end
			
			S_WRITE_BURST: begin
				if(wr_burst_finish == 1'b1) begin
					next_state = S_WRITE_BURST_END;
				end   
				else begin 
					next_state = S_WRITE_BURST;
				end 
			end
			S_WRITE_BURST_END: begin
				if(write_req_d2 == 1'b1)	begin
					next_state = S_ACK;
				end
				else if(write_cnt < write_len_latch)begin
					next_state = S_CHECK_FIFO;
				end
				else begin
					next_state = S_END;
				end
			end
			S_END:
			begin
				next_state = S_IDLE;
			end
			default:
				next_state = S_IDLE;
		endcase
	end
end 

//第三段 :
always@(posedge mem_clk)begin
	if(rst)begin
		write_len_latch <= ZERO[ADDR_BITS - 1:0];
	end
	else if(write_req_d2 == 1'b1)begin 
		write_len_latch <= write_len_d1; 
	end 
	else begin
		write_len_latch <= write_len_latch; 
	end 
end 	
	
//第三段 :
always@(posedge mem_clk)begin
	if(rst)begin
		fifo_aclr 	  <= 1'b0;
		write_req_ack <= 1'b0;
	end
	else if(write_req_d2 == 1'b0)begin 
		fifo_aclr     <= 1'b0;
		write_req_ack <= 1'b0;
	end 
	else begin
		write_req_ack <= 1'b1;
		fifo_aclr     <= 1'b1;		
	end 
end 		
	
	
//第三段 :
always@(posedge mem_clk)begin
	if(rst)begin
		wr_burst_addr 	<= ZERO[ADDR_BITS - 1:0];
		wr_burst_req 	<= 1'b0;
		write_cnt 		<= ZERO[ADDR_BITS - 1:0];
		wr_burst_len 	<= ZERO[BUSRT_BITS - 1:0];
	end
	else
		case(curr_state)
			S_IDLE:begin
				//write_req_ack <= 1'b0;
				wr_burst_req  <= wr_burst_req ;
				write_cnt     <= write_cnt    ;
				wr_burst_addr <= wr_burst_addr;
			end
			S_ACK:begin
				//after write request revocation(write_req_d2 == '0'),goto 'S_CHECK_FIFO',write_req_ack goto '0'
				if(write_req_d2 == 1'b0)begin
					wr_burst_addr <= wr_burst_addr;     
				end
				else begin
					//select valid base address from write_addr_0 write_addr_1 write_addr_2 write_addr_3
					if(write_addr_index_d1 == 2'd0)
						wr_burst_addr <= write_addr_0;
					else if(write_addr_index_d1 == 2'd1)
						wr_burst_addr <= write_addr_1;
					else if(write_addr_index_d1 == 2'd2)
						wr_burst_addr <= write_addr_2;
					else if(write_addr_index_d1 == 2'd3)
						wr_burst_addr <= write_addr_3;                   
				end
				//write data counter reset, write_cnt <= 0;
				write_cnt <= ZERO[ADDR_BITS - 1:0];
			end
			S_CHECK_FIFO:
			begin
				if(rdusedw >= BURST_SIZE)begin
					wr_burst_len <= BURST_SIZE[BUSRT_BITS - 1:0];
					wr_burst_req <= 1'b1;
				end
				else begin 
					wr_burst_len <= wr_burst_len;
					wr_burst_req <= wr_burst_req;
				end
			end
			
			S_WRITE_BURST: begin
				if(wr_burst_finish == 1'b1)begin
					wr_burst_req <= 1'b0;
					write_cnt <= write_cnt + BURST_SIZE[ADDR_BITS - 1:0];
					wr_burst_addr <= wr_burst_addr + BURST_SIZE[ADDR_BITS - 1:0];
				end 
				else begin
					wr_burst_req  <= wr_burst_req ;
					write_cnt     <= write_cnt    ;
					wr_burst_addr <= wr_burst_addr;
				end 
			end
			S_WRITE_BURST_END: begin
				wr_burst_req  <= wr_burst_req ;
				write_cnt     <= write_cnt    ;
				wr_burst_addr <= wr_burst_addr;
			end
			S_END: begin
				wr_burst_req  <= wr_burst_req ;
				write_cnt     <= write_cnt    ;
				wr_burst_addr <= wr_burst_addr;
			end
			default:begin 
				wr_burst_req  <= wr_burst_req ;
				write_cnt     <= write_cnt    ;
				wr_burst_addr <= wr_burst_addr;
			end
		endcase
end

		

endmodule
