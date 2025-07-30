`timescale 1ns / 1ps

module image_capture#(
    parameter MEM_DATA_BITS          = 64,
    parameter ADDR_BITS              = 25,
    parameter BUSRT_BITS             = 10,
    parameter WRITE_DATA_BITS        = 16
)


(
    input                                clk_25MHz,
    input                                clk_50MHz,
    input                                ui_clk,
    input                                reset,
    //cmos1 port         
    inout                                cmos1_scl,          //cmos i2c clock
    inout                                cmos1_sda,          //cmos i2c data
    input                                cmos1_vsync,        //cmos vsync
    input                                cmos1_href,         //cmos hsync refrence,data valid
    input                                cmos1_pclk,         //cmos pxiel clock
    input   [7:0]                        cmos1_db,           //cmos data
    output                               cmos1_rst_n,        //cmos reset
             
    //cmos2 port         
    inout                                cmos2_scl,          //cmos i2c clock
    inout                                cmos2_sda,          //cmos i2c data
    input                                cmos2_vsync,        //cmos vsync
    input                                cmos2_href,         //cmos hsync refrence,data valid
    input                                cmos2_pclk,         //cmos pxiel clock
    input   [7:0]                        cmos2_db,           //cmos data
    output                               cmos2_rst_n,        //cmos reset


    output                               wr_burst_req,
    output  [BUSRT_BITS - 1:0]           wr_burst_len,
    output  [ADDR_BITS - 1:0]            wr_burst_addr,
    input                                wr_burst_data_req,
    output  [MEM_DATA_BITS - 1:0]        wr_burst_data,
    input                                wr_burst_finish,
    output  [1:0]                        ch0_read_addr_index,
    output  [1:0]                        ch1_read_addr_index  

    );




wire                            ch0_wr_burst_data_req;
wire                            ch0_wr_burst_finish;
wire                            ch0_wr_burst_req;
wire[BUSRT_BITS - 1:0]          ch0_wr_burst_len;
wire[ADDR_BITS - 1:0]           ch0_wr_burst_addr;
wire[MEM_DATA_BITS - 1 : 0]     ch0_wr_burst_data;


wire                            ch1_wr_burst_data_req;
wire                            ch1_wr_burst_finish;
wire                            ch1_wr_burst_req;
wire[BUSRT_BITS - 1:0]          ch1_wr_burst_len;
wire[ADDR_BITS - 1:0]           ch1_wr_burst_addr;
wire[MEM_DATA_BITS - 1 : 0]     ch1_wr_burst_data;




//*Keep_hierarchy = "yes"* 抓信号用
(*Keep_hierarchy = "yes"*)channel_capture
#(
    .MEM_DATA_BITS       (MEM_DATA_BITS  ),
    .WRITE_DATA_BITS     (WRITE_DATA_BITS),
    .ADDR_BITS           (ADDR_BITS          ),
    .BUSRT_BITS          (BUSRT_BITS     )
)
channel1_capture
(
    .rst                   (reset                       ),
    .ui_clk                (ui_clk                      ),
    .clk_50MHz             (clk_50MHz                   ),             
    .clk_25MHz             (clk_25MHz                   ),

    .cmos_scl              (cmos1_scl                   ),            //cmos i2c clock
    .cmos_sda              (cmos1_sda                   ),            //cmos i2c data
    .cmos_vsync            (cmos1_vsync                 ),        //cmos vsync
    .cmos_href             (cmos1_href                  ),        //cmos hsync refrence,data valid
    .cmos_pclk             (cmos1_pclk                  ),        //cmos pxiel clock
    .cmos_db               (cmos1_db                    ),        //cmos data
    .cmos_rst_n            (cmos1_rst_n                 ),        //cmos reset
    .cmos_config_done      (cmos1_config_done           ),
    
    .read_addr_index       (ch0_read_addr_index         ),
    .wr_burst_req          (ch0_wr_burst_req            ),
    .wr_burst_len          (ch0_wr_burst_len            ),
    .wr_burst_addr         (ch0_wr_burst_addr           ),
    .wr_burst_data_req     (ch0_wr_burst_data_req       ),
    .wr_burst_data         (ch0_wr_burst_data           ),
    .wr_burst_finish       (ch0_wr_burst_finish         ),
    .write_finish          (                            ),
    .write_addr_0          (25'd0                       ),
    .write_addr_1          (25'd2073600                 ),  //大于两幅图像的大小,字节 640*480*4 < 2073600
    .write_addr_2          (25'd4147200                 ),
    .write_addr_3          (25'd6220800                 ),
    .write_len             (25'd196608                  )   //1024*768
  );


(*Keep_hierarchy = "yes"*)channel_capture //保持，不要进行模块的优化
#(
    .MEM_DATA_BITS       (MEM_DATA_BITS  ),
    .WRITE_DATA_BITS     (WRITE_DATA_BITS),
    .ADDR_BITS           (ADDR_BITS      ),
    .BUSRT_BITS          (BUSRT_BITS     )
)
channel2_capture
(
    .rst                   (reset                       ),
    .ui_clk                (ui_clk                      ),
    .clk_50MHz             (clk_50MHz                   ),                        //Ê±ÖÓ
    .clk_25MHz             (clk_25MHz                   ),

    .cmos_scl              (cmos2_scl                   ),            //cmos i2c clock
    .cmos_sda              (cmos2_sda                   ),            //cmos i2c data
    .cmos_vsync            (cmos2_vsync                 ),        //cmos vsync
    .cmos_href             (cmos2_href                  ),        //cmos hsync refrence,data valid
    .cmos_pclk             (cmos2_pclk                  ),        //cmos pxiel clock
    .cmos_db               (cmos2_db                    ),        //cmos data
    .cmos_rst_n            (cmos2_rst_n                 ),        //cmos reset
    .cmos_config_done      (cmos2_config_done           ),
    .read_addr_index       (ch1_read_addr_index         ),
    .wr_burst_req          (ch1_wr_burst_req            ),
    .wr_burst_len          (ch1_wr_burst_len            ),
    .wr_burst_addr         (ch1_wr_burst_addr           ),
    .wr_burst_data_req     (ch1_wr_burst_data_req       ),
    .wr_burst_data         (ch1_wr_burst_data           ),
    .wr_burst_finish       (ch1_wr_burst_finish         ),
    .write_finish          (                            ),
    .write_addr_0          (25'd8294400                 ),
    .write_addr_1          (25'd10368000                ),
    .write_addr_2          (25'd12441600                ),
    .write_addr_3          (25'd14515200                ),
    .write_len             (25'd196608                  )
  );

mem_write_arbi
#(
    .MEM_DATA_BITS               (MEM_DATA_BITS         ),
    .ADDR_BITS                   (ADDR_BITS             ),
    .BUSRT_BITS                  (BUSRT_BITS            )
)
mem_write_arbi_m0(
    .rst_n                       (~reset                ),
    .mem_clk                     (ui_clk                ),
    
    .ch0_wr_burst_req            (ch0_wr_burst_req      ),
    .ch0_wr_burst_len            (ch0_wr_burst_len      ),
    .ch0_wr_burst_addr           (ch0_wr_burst_addr     ),
    .ch0_wr_burst_data_req       (ch0_wr_burst_data_req ),
    .ch0_wr_burst_data           (ch0_wr_burst_data     ),
    .ch0_wr_burst_finish         (ch0_wr_burst_finish   ),
    
    .ch1_wr_burst_req            (ch1_wr_burst_req      ),
    .ch1_wr_burst_len            (ch1_wr_burst_len      ),
    .ch1_wr_burst_addr           (ch1_wr_burst_addr     ),
    .ch1_wr_burst_data_req       (ch1_wr_burst_data_req ),
    .ch1_wr_burst_data           (ch1_wr_burst_data     ),
    .ch1_wr_burst_finish         (ch1_wr_burst_finish   ),
    
    .wr_burst_req                (wr_burst_req          ),
    .wr_burst_len                (wr_burst_len          ),
    .wr_burst_addr               (wr_burst_addr         ),
    .wr_burst_data_req           (wr_burst_data_req     ),
    .wr_burst_data               (wr_burst_data         ),
    .wr_burst_finish             (wr_burst_finish       )  
);
endmodule
