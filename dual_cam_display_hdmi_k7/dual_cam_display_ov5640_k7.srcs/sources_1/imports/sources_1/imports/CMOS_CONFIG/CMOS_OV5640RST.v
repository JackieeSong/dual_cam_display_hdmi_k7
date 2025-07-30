`timescale 1ns / 1ps

//上电之后，进行ov5640的复位
module CMOS_OV5640RST(
	//输入时钟 复位
	input   wire      clk,			 	//输入时钟400k*8
	input   wire      rst,			 	//复位信号	
	//输出控制信息		
	output  reg       cmos_rst,		 	//启动复位
	output  reg       cmos_start		//启动配置
    );
	
//	parameter COUNT_HAF = 32'D40;
//	parameter COUNT_MAX = 32'D80;
	
	parameter COUNT_HAF = 32'D40000;
	parameter COUNT_MAX = 32'D80000;
	
	//配置计数器
	reg [31:0]count;
	//输出复位计数器
	always @(posedge clk)begin
		if(rst)begin 
			count<=32'D0;
		end 
		else if(count<=COUNT_MAX)begin
			count<=count+32'D1;
		end 
		else begin 
			count<=count;
		end 
	end 
	
	//输出复位
	always @(posedge clk)begin
		if(rst)begin 
			cmos_rst<=1'b0;
		end
		else if(count<=COUNT_HAF) begin
			cmos_rst<=1'b0;
		end   		
		else begin 
			cmos_rst<=1'b1;
		end 
	end 
	
	//输出启动
	always @(posedge clk)begin
		if(rst)begin 
			cmos_start<=1'b0;
		end
		else if(count<=COUNT_MAX) begin
			cmos_start<=1'b0;
		end   		
		else begin 
			cmos_start<=1'b1;
		end 
	end 
	
endmodule
