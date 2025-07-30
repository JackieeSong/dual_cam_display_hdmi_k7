`timescale 1ns / 1ps

module channel_capture
#(
	parameter MEM_DATA_BITS          = 64,
	parameter WRITE_DATA_BITS        = 16,
	parameter ADDR_BITS              = 25,
	parameter BUSRT_BITS             = 10
)
(
	input			 clk_50MHz,						 //ʱ?
	input			 rst,								 //??λ???
	input  			 ui_clk,							 //MIG???ʱ?
	input 			 clk_25MHz,

	//IIC	????
	inout      		cmos_scl,    		 	 //cmos i2c clock
	inout      		cmos_sda,    		 	 //cmos i2c data
	input           cmos_vsync,        //cmos vsync
	input           cmos_href,         //cmos hsync refrence,data valid
	input           cmos_pclk,         //cmos pxiel clock
	input   [7:0]   cmos_db,           //cmos data
	output          cmos_rst_n,        //cmos reset
	output			cmos_config_done,
	
	//??ݷ????????????
	output 	[1:0]   read_addr_index,
	
	output                           wr_burst_req,               // to external memory controller,send out a burst write request
	output[BUSRT_BITS - 1:0]         wr_burst_len,               // to external memory controller,data length of the burst write request, not bytes
	output[ADDR_BITS - 1:0]          wr_burst_addr,              // to external memory controller,base address of the burst write request 
	input                            wr_burst_data_req,          // from external memory controller,write data request ,before data 1 clock
	output[MEM_DATA_BITS - 1:0]      wr_burst_data,              // to external memory controller,write data
	input                            wr_burst_finish,            // from external memory controller,burst write finish
	output                           write_finish,               // data write module write request finish
	input[ADDR_BITS - 1:0]           write_addr_0,               // data write module write request base address 0, used when write_addr_index = 0
	input[ADDR_BITS - 1:0]           write_addr_1,               // data write module write request base address 1, used when write_addr_index = 1
	input[ADDR_BITS - 1:0]           write_addr_2,               // data write module write request base address 1, used when write_addr_index = 2
	input[ADDR_BITS - 1:0]           write_addr_3,               // data write module write request base address 1, used when write_addr_index = 3
	input[ADDR_BITS - 1:0]           write_len                  // data write module write request data length
  );
    
    
wire[15:0]                        cmos_16bit_data;
wire                              cmos_16bit_wr;
wire[9:0]                         cmos_lut_index;
wire[31:0]                        cmos_lut_data;
                                  
wire                              write_en;
wire[15:0]                        write_data;
wire                              write_req;
wire                              write_req_ack;
wire[1:0]                         write_addr_index;

wire   write_clk ;
wire vsync;
wire usr_vsync;
wire usr_hsync;
wire usr_de;
wire [23:0] usr_rgb;
wire rst_pclk;
reg rst_pclk_syn;
wire rst_50Mhz;
reg rst_50Mhz_syn;
reg config_rest;
wire start;

//








//CMOS0???16Bit??ݽ????GB565
assign write_clk = cmos_pclk;
assign vsync=cmos_vsync  ;
assign write_en   = cmos_16bit_wr;
assign write_data = {cmos_16bit_data[4:0],cmos_16bit_data[10:5],cmos_16bit_data[15:11]};
//wire cmos_rstn;
//assign cmos_rst_n =1'b1;
/*
assign write_clk = clk_25MHz;
assign vsync=usr_vsync  ;
assign write_en   = usr_de;
assign write_data = {usr_rgb[23:19],usr_rgb[15:10],usr_rgb[7:3]};
sensor_data_gen sensor_data_gen_inst(
	.clk(clk_25MHz),
	.rgb(usr_rgb),
	.de (usr_de),
	.vsync(usr_vsync),
	.hsync(usr_hsync)
	);
*/

`define	I2C_CONFIG1
//`define	I2C_CONFIG2

`ifdef  I2C_CONFIG1
	// CMOS reset
	CMOS_OV5640RST U0(
		.clk			(clk_25MHz		),
		.rst			(rst		    ),			
		.cmos_rst		(cmos_rst_n		),
	    .cmos_start	    (start			) 
		);
		
		//I2C master controller
		i2c_config_state i2c_config_m0(
			.rst            	(rst              ),//复位信号
			.clk            	(clk_50MHz           ),//系统时钟
			.clk_div_cnt    	(16'd99              ),//计数器分频
			.start_config		(start               ),
			.i2c_addr_2byte 	(1'b1                ),//地址控制
			.lut_index      	(cmos_lut_index      ),//配置寄存器查找表
			.lut_dev_addr   	(cmos_lut_data[31:24]),//配置信息解析
			.lut_reg_addr   	(cmos_lut_data[23:8] ),//配置信息解析
			.lut_reg_data   	(cmos_lut_data[7:0]  ),//配置信息解析
			.error          	(                    ),//配置状态信息
			.done           	(                    ),//配置完成信息
			.i2c_scl        	(cmos_scl            ),//IIC时钟线
			.i2c_sda        	(cmos_sda            ) //IIC数据线
		);

		//configure look-up table
		lut_ov5640_rgb565_640_480 lut_ov5640_m0(
			.lut_index      	(cmos_lut_index      ),//输入查找表地址编号
			.lut_data       	(cmos_lut_data       ) //输出配置信息
		);
		    
`endif

wire	    start;			 	  //启动配置
wire	    done;			 	  //配置完成

`ifdef  I2C_CONFIG2

	//配置复位启动接口
	CMOS_OV5640RST U0(
		//输入时钟 复位
		.clk			(clk_25MHz		),//输入时钟400k*8
		.rst			(rst		),//复位信号	
		//输出控制信息			
		.cmos_rst		(cmos_rst_n		),//启动复位	
	    .cmos_start	(start			) //启动配置
		);
		
	//IIC数据配置		
	IIC_TOP U1(	
		//输入时钟 复位	
		.clk			(clk_25MHz		),//输入时钟400k*8
		.rst			(rst		),//复位信号	
		//输出控制信息			
		.start		(start			),//启动配置
		.done		(done			),//配置完成
		//输出IIC接口						
		.i2c_scl		(cmos_scl		),//inout时钟线
		.i2c_sda		(cmos_sda		) //inout数据线
	    );
		    
`endif

    
//CMOS sensor 8bit data is converted to 16bit data
cmos_8_16bit cmos_8_16bit_m0(
	.rst      			     (rst        ),//复位信号
	.pclk     			     (write_clk           ),//COMSpxiel clock
	.pdata_i  			     (cmos_db             ),//COMS输出数据
	.de_i     			     (cmos_href           ),//cmos hsync refrence,data valid
	.pdata_o  			     (cmos_16bit_data     ),//输出16bit数据输出
	.de_o     			     (cmos_16bit_wr       ) //数据输出有效信号
); 
 


//CMOS sensor writes the request and generates the read and write address index
cmos_write_req_gen cmos_write_req_gen_m0(
	.rst                 (rst           ),//复位
	.pclk                (write_clk       		),//
	.cmos_vsync          (vsync      		     ),//
	.write_req           (write_req       		),//写请求
	.write_addr_index    (write_addr_index		),//写地址
	.read_addr_index     (read_addr_index 		),//读地址
	.write_req_ack       (write_req_ack   		) //写请求应答
);

//对位接口配置
frame_write frame_write_m0
(
	.rst                 (rst                  ),
	.mem_clk             (ui_clk               ),
	.wr_burst_req        (wr_burst_req         ),
	.wr_burst_len        (wr_burst_len         ),
	.wr_burst_addr       (wr_burst_addr        ),
	.wr_burst_data_req   (wr_burst_data_req    ),
	.wr_burst_data       (wr_burst_data        ),
	.wr_burst_finish     (wr_burst_finish      ),
	
	.write_clk           (write_clk            ),
	.write_req           (write_req            ),
	.write_req_ack       (write_req_ack        ),
	.write_finish        (write_finish         ),
	.write_addr_0        (write_addr_0         ),
	.write_addr_1        (write_addr_1         ),
	.write_addr_2        (write_addr_2         ),
	.write_addr_3        (write_addr_3         ),
	.write_addr_index    (write_addr_index     ),
	.write_len           (write_len            ),
	.write_en            (write_en             ),
	.write_data          (write_data           )
);
      
endmodule
