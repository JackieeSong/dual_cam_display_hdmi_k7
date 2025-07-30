//////////////////////////////////////////////////////////////////////////////////
//  Cross clock domain data reading frame with FIFO interface                   //
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

`timescale 1ns/1ps
module frame_fifo_read2
#
(
	parameter MEM_DATA_BITS          = 32,
	parameter ADDR_BITS              = 23,
	parameter BUSRT_BITS             = 10,
	parameter FIFO_DEPTH             = 256,
	parameter BURST_SIZE             = 128
)               
(
	input                            rst,                  
	input                            mem_clk,                    // external memory controller user interface clock
	output reg                       rd_burst_req,               // to external memory controller,send out a burst read request  
	output reg[BUSRT_BITS - 1:0]     rd_burst_len,               // to external memory controller,data length of the burst read request, not bytes 
	output reg[ADDR_BITS - 1:0]      rd_burst_addr,              // to external memory controller,base address of the burst read request
	input                            rd_burst_data_valid,        // from external memory controller,read request data valid    
	input                            rd_burst_finish,            // from external memory controller,burst read finish
	input                            read_req,                   // data read module read request,keep '1' until read_req_ack = '1'
	output reg                       read_req_ack,               // data read module read request response
	output                           read_finish,                // data read module read request finish
	input[ADDR_BITS - 1:0]           read_addr_0,                // data read module read request base address 0, used when read_addr_index = 0
	input[ADDR_BITS - 1:0]           read_addr_1,                // data read module read request base address 1, used when read_addr_index = 1
	input[ADDR_BITS - 1:0]           read_addr_2,                // data read module read request base address 1, used when read_addr_index = 2
	input[ADDR_BITS - 1:0]           read_addr_3,                // data read module read request base address 1, used when read_addr_index = 3
	input[1:0]                       read_addr_index,            // select valid base address from read_addr_0 read_addr_1 read_addr_2 read_addr_3
	input[ADDR_BITS - 1:0]           read_len,                   // data read module read request data length
	output reg                       fifo_aclr,                  // to fifo asynchronous clear
	input[15:0]                      wrusedw                     // from fifo write used words
);
localparam ONE                       = 256'd1;                   //256 bit '1'   you can use ONE[n-1:0] for n bit '1'
localparam ZERO                      = 256'd0;                   //256 bit '0'
//read state machine code
localparam S_IDLE                    = 0;                        //idle state,waiting for frame read
localparam S_ACK                     = 1;                        //read request response
localparam S_CHECK_FIFO              = 2;                        //check the FIFO status, ensure that there is enough space to burst read
localparam S_READ_BURST              = 3;                        //begin a burst read
localparam S_READ_BURST_END          = 4;                        //a burst read complete
localparam S_END                     = 5;                        //a frame of data is read to complete

reg                                  read_req_d0;                //asynchronous read request, synchronize to 'mem_clk' clock domain,first beat
reg                                  read_req_d1;                //second
reg                                  read_req_d2;                //third,Why do you need 3 ? Here's the design habit
reg[ADDR_BITS - 1:0]                 read_len_d0;                //asynchronous read_len(read data length), synchronize to 'mem_clk' clock domain first
reg[ADDR_BITS - 1:0]                 read_len_d1;                //second
reg[ADDR_BITS - 1:0]                 read_len_latch;             //lock read data length
reg[ADDR_BITS - 1:0]                 read_cnt;                   //read data counter

reg[1:0]                             read_addr_index_d0;         //synchronize to 'mem_clk' clock domain first
reg[1:0]                             read_addr_index_d1;         //synchronize to 'mem_clk' clock domain second

assign read_finish = (curr_state == S_END) ? 1'b1 : 1'b0;             //read finish at state 'S_END'
always@(posedge mem_clk or posedge rst)
begin
	if(rst == 1'b1)
	begin
		read_req_d0    <=  1'b0;
		read_req_d1    <=  1'b0;
		read_req_d2    <=  1'b0;
		read_len_d0    <=  ZERO[ADDR_BITS - 1:0];               //equivalent to read_len_d0 <= 0;
		read_len_d1    <=  ZERO[ADDR_BITS - 1:0];               //equivalent to read_len_d1 <= 0;
		read_addr_index_d0 <= 2'b00;
		read_addr_index_d1 <= 2'b00;
	end
	else
	begin
		read_req_d0    <=  read_req;
		read_req_d1    <=  read_req_d0;
		read_req_d2    <=  read_req_d1;     
		read_len_d0    <=  read_len;
		read_len_d1    <=  read_len_d0; 
		read_addr_index_d0 <= read_addr_index;
		read_addr_index_d1 <= read_addr_index_d0;
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
				if(read_req_d2 == 1'b1)begin
					next_state = S_ACK;
				end
				else begin 
					next_state = S_IDLE;
				end 				
			end
			S_ACK:begin
				if(read_req_d2 == 1'b0) begin
					next_state = S_CHECK_FIFO;
				end
				else begin
					next_state = S_ACK;
				end
			end
			S_CHECK_FIFO: begin
				//if there is a read request at this time, enter the 'S_ACK' state
				if(read_req_d2 == 1'b1) begin
					next_state = S_ACK;
				end
				else if(wrusedw < (FIFO_DEPTH - BURST_SIZE))begin
					next_state = S_READ_BURST;
				end
				else begin
					next_state = S_CHECK_FIFO;
				end 
			end
			S_READ_BURST: begin 
				if(rd_burst_finish == 1'b1) begin
					next_state = S_READ_BURST_END;
				end  
				else begin 
					next_state = S_READ_BURST;
				end 
			end
			S_READ_BURST_END: begin
				if(read_req_d2 == 1'b1) begin
					next_state = S_ACK;
				end
				else if(read_cnt < read_len_latch) begin 
					next_state = S_CHECK_FIFO;
				end
				else begin
					next_state = S_END;
				end
			end
			S_END: begin
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
		read_len_latch <= ZERO[ADDR_BITS - 1:0];
	end
	else if(read_req_d2 == 1'b1)begin 
		read_len_latch <= read_len_d1; 
	end 
	else begin
		read_len_latch <= read_len_latch; 
	end 
end 	
	
//第三段 :
always@(posedge mem_clk)begin
	if(rst)begin
		fifo_aclr 	  <= 1'b0;
		read_req_ack  <= 1'b0;
	end
	else if(read_req_d2 == 1'b0)begin 
		fifo_aclr     <= 1'b0;
		read_req_ack  <= 1'b0;
	end 
	else begin	
		fifo_aclr     <= 1'b1;	
		read_req_ack  <= 1'b1;		
	end 
end 		
	

//第三段 :
always@(posedge mem_clk)begin
	if(rst) begin
		rd_burst_addr 	<= ZERO[ADDR_BITS - 1:0];
		rd_burst_req 	<= 1'b0;
		read_cnt 		<= ZERO[ADDR_BITS - 1:0];
		rd_burst_len 	<= ZERO[BUSRT_BITS - 1:0];
	end
	else begin 
		case(curr_state)
			S_IDLE: begin
				rd_burst_req  <= rd_burst_req;
				read_cnt 	  <= read_cnt;
				rd_burst_addr <= rd_burst_addr;
			end
			S_ACK: begin
				if(read_req_d2 == 1'b0)begin
					rd_burst_addr <= rd_burst_addr;
				end
				else begin
					//select valid base address from read_addr_0 read_addr_1 read_addr_2 read_addr_3
					if(read_addr_index_d1 == 2'd0)
						rd_burst_addr <= read_addr_0;
					else if(read_addr_index_d1 == 2'd1)
						rd_burst_addr <= read_addr_1;
					else if(read_addr_index_d1 == 2'd2)
						rd_burst_addr <= read_addr_2;
					else if(read_addr_index_d1 == 2'd3)
						rd_burst_addr <= read_addr_3;

				end
				//read data counter reset, read_cnt <= 0;
				read_cnt <= ZERO[ADDR_BITS - 1:0];
			end
			S_CHECK_FIFO:
			begin
				if(wrusedw < (FIFO_DEPTH - BURST_SIZE))begin
					rd_burst_len <= BURST_SIZE[BUSRT_BITS - 1:0];
					rd_burst_req <= 1'b1;
				end
				else begin
					rd_burst_len <= rd_burst_len;
					rd_burst_req <= rd_burst_req;
				end 
			end
			
			S_READ_BURST: begin
				if(rd_burst_data_valid)
					rd_burst_req <= 1'b0;
				else 
					rd_burst_req <= rd_burst_req;
				//burst finish  
				if(rd_burst_finish == 1'b1)begin
					//read counter + burst length
					read_cnt <= read_cnt + BURST_SIZE[ADDR_BITS - 1:0];
					//the next burst read address is generated
					rd_burst_addr <= rd_burst_addr + BURST_SIZE[ADDR_BITS - 1:0];
				end  
				else  begin 
					read_cnt <= read_cnt;
					rd_burst_addr <= rd_burst_addr;
				end 
			end
			S_READ_BURST_END: begin
				rd_burst_req  <= rd_burst_req;
				read_cnt 	  <= read_cnt;
				rd_burst_addr <= rd_burst_addr;
			end
			S_END:begin
				rd_burst_req  <= rd_burst_req;
				read_cnt 	  <= read_cnt;
				rd_burst_addr <= rd_burst_addr;
			end
			default:begin
				rd_burst_req  <= rd_burst_req;
				read_cnt 	  <= read_cnt;
				rd_burst_addr <= rd_burst_addr;
			end 		
		endcase
	end 	
end
			

endmodule
