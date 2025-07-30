module cmos_8_16bit(
	input              rst,
	input              pclk,
	input 		[7 :0]   pdata_i,	//CMOS下来的8bit数据 RGB565
	input              de_i,	//data_en_input
	output reg[15:0]   pdata_o,	//经过转换后的16bit数据
	output reg         de_o		//data_en_output
);

reg[7:0] pdata_i_d0;
reg[11:0] x_cnt;
always@(posedge pclk) begin
	pdata_i_d0 <= pdata_i;
end

always@(posedge pclk ) begin
	if(rst)
		x_cnt <= 12'd0;
	else if(de_i)
		x_cnt <= x_cnt + 12'd1;
	else
		x_cnt <= 12'd0;
end

//x_cnt -> 0 1 0 1 0 1
always@(posedge pclk ) begin
	if(rst)
		de_o <= 1'b0;
	else if(de_i && x_cnt[0])	//代表两个时钟周期记一次，即2个字节一个周期
		de_o <= 1'b1;
	else
		de_o <= 1'b0;
end

always@(posedge pclk )begin
	if(rst)
		pdata_o <= 16'd0;
	else if(de_i && x_cnt[0])
		pdata_o <= {pdata_i_d0,pdata_i};
	else
		pdata_o <= 16'd0;
end

endmodule 
