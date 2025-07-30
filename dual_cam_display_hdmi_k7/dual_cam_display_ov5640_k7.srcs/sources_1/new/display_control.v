`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// Design Name: 
// Module Name: display_control
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module display_control#(
    parameter MEM_DATA_BITS          = 64,
    parameter ADDR_BITS              = 25,
    parameter BUSRT_BITS             = 10,
    parameter WRITE_DATA_BITS        = 16
)
(
    input                           ui_clk,
    input                           video_clk,
    input                           video_clk5x,
    input                           mem_rst,
    input                           video_rst,
    //burst req
    output                          rd_burst_req,
    output   [BUSRT_BITS-1:0]       rd_burst_len,
    output   [ADDR_BITS-1:0]        rd_burst_addr,
    input                           rd_burst_data_valid,
    input    [MEM_DATA_BITS-1:0]    rd_burst_data,
    input                           rd_burst_finish ,
    input    [1:0]                  ch0_read_addr_index,
    input    [1:0]                  ch1_read_addr_index,
    //hdmi ports
    output                          tmds_clk_p,                
    output                          tmds_clk_n,                //
    output   [2:0]                  tmds_data_p,       //rgb
    output   [2:0]                  tmds_data_n,       //rgb
    output   [0:0]                  HDMI_OEN                   //HDMI
    );



wire                            ch0_rd_burst_finish;
wire                            ch0_rd_burst_req;
wire[BUSRT_BITS - 1:0]          ch0_rd_burst_len;
wire[ADDR_BITS - 1:0]           ch0_rd_burst_addr;
wire                            ch0_rd_burst_data_valid;
wire[MEM_DATA_BITS - 1 : 0]     ch0_rd_burst_data;

wire                            ch1_rd_burst_finish;
wire                            ch1_rd_burst_req;
wire[BUSRT_BITS - 1:0]          ch1_rd_burst_len;
wire[ADDR_BITS - 1:0]           ch1_rd_burst_addr;
wire                            ch1_rd_burst_data_valid;
wire[MEM_DATA_BITS - 1 : 0]     ch1_rd_burst_data;


wire                            ch0_read_req;
wire                            ch0_read_req_ack;
wire                            ch0_read_en;
wire[15:0]                      ch0_read_data;

wire                            ch1_read_req;
wire                            ch1_read_req_ack;
wire                            ch1_read_en;
wire[15:0]                      ch1_read_data;


wire                            color_bar_hs;
wire                            color_bar_vs;
wire                            color_bar_de;
wire[7:0]                       color_bar_r;
wire[7:0]                       color_bar_g;
wire[7:0]                       color_bar_b;
           
wire                            v0_hs;
wire                            v0_vs;
wire                            v0_de;
wire[23:0]                      v0_data;

wire                            hs;
wire                            vs;
wire                            de;
wire[15:0]                      vout_data;

wire                            hdmi_hs;
wire                            hdmi_vs;
wire                            hdmi_de;
wire[7:0]                       hdmi_r;
wire[7:0]                       hdmi_g;
wire[7:0]                       hdmi_b;


assign hdmi_hs     = hs;
assign hdmi_vs     = vs;
assign hdmi_de     = de;


assign hdmi_r      = {vout_data[15:11],3'd0};
assign hdmi_g      = {vout_data[10: 5],2'd0};
assign hdmi_b      = {vout_data[4 : 0],3'd0};

//
assign HDMI_OEN    = 1'b1;

//video output timing generator 
color_bar color_bar_m0(
    .clk             (video_clk                 ),
    .rst             (video_rst                 ),
    .hs              (color_bar_hs              ),
    .vs              (color_bar_vs              ),
    .de              (color_bar_de              ),
    .rgb_r           (color_bar_r               ),
    .rgb_g           (color_bar_g               ),
    .rgb_b           (color_bar_b               )
);

//generate a frame read data request
video_rect_read_data video_rect_read_data_m0
(
    .video_clk         (video_clk                ),
    .rst               (video_rst                ),
    .video_left_offset (12'd0                    ),
    .video_top_offset  (12'd0                    ),
    .video_width       (12'd640                  ),
    .video_height      (12'd480                  ),
    .read_req          (ch0_read_req             ),
    .read_req_ack      (ch0_read_req_ack         ),
    .read_en           (ch0_read_en              ),
    .read_data         (ch0_read_data            ),
    .timing_hs         (color_bar_hs             ),
    .timing_vs         (color_bar_vs             ),
    .timing_de         (color_bar_de             ),
    .timing_data       ({color_bar_r[4:0],color_bar_g[5:0],color_bar_b[4:0]}),
    .hs                (v0_hs                    ),
    .vs                (v0_vs                    ),
    .de                (v0_de                    ),
    .vout_data         (v0_data                  )
);

video_rect_read_data video_rect_read_data_m1
(
    .video_clk         (video_clk                ),
    .rst               (video_rst                ),
    .video_left_offset (12'd640                  ),
    .video_top_offset  (12'd0                    ),
    .video_width       (12'd640                  ),
    .video_height      (12'd480                  ),
    .read_req          (ch1_read_req             ),
    .read_req_ack      (ch1_read_req_ack         ),
    .read_en           (ch1_read_en              ),
    .read_data         (ch1_read_data            ),
    .timing_hs         (v0_hs                    ),
    .timing_vs         (v0_vs                    ),
    .timing_de         (v0_de                    ),
    .timing_data       (v0_data                  ),
    .hs                (hs                       ),
    .vs                (vs                       ),
    .de                (de                       ),
    .vout_data         (vout_data                )
);
//video frame data read-write control
(*Keep_hierarchy = "yes"*)frame_read frame_read_m0
(
    .rst                 (mem_rst                   ),
    .mem_clk             (ui_clk                   ),
    .rd_burst_req        (ch0_rd_burst_req         ),
    .rd_burst_len        (ch0_rd_burst_len         ),
    .rd_burst_addr       (ch0_rd_burst_addr        ),
    .rd_burst_data_valid (ch0_rd_burst_data_valid  ),
    .rd_burst_data       (ch0_rd_burst_data        ),
    .rd_burst_finish     (ch0_rd_burst_finish      ),
    .read_clk            (video_clk                ),
    .read_req            (ch0_read_req             ),
    .read_req_ack        (ch0_read_req_ack         ),
    .read_finish         (                         ),
    .read_addr_0         (25'd0                    ), //The first frame address is 0
    .read_addr_1         (25'd2073600              ), //The second frame address is 25'd2073600 ,large enough address space for one frame of video
    .read_addr_2         (25'd4147200              ),
    .read_addr_3         (25'd6220800              ),
    .read_addr_index     (ch0_read_addr_index      ),
    .read_len            (25'd196608               ),//frame size  1024 * 768 * 16 / 64
    .read_en             (ch0_read_en              ),
    .read_data           (ch0_read_data            )
);

(*Keep_hierarchy = "yes"*)frame_read frame_read_m1
(
    .rst                        (mem_rst                  ),
    .mem_clk                    (ui_clk                   ),
    .rd_burst_req               (ch1_rd_burst_req         ),
    .rd_burst_len               (ch1_rd_burst_len         ),
    .rd_burst_addr              (ch1_rd_burst_addr        ),
    .rd_burst_data_valid        (ch1_rd_burst_data_valid  ),
    .rd_burst_data              (ch1_rd_burst_data        ),
    .rd_burst_finish            (ch1_rd_burst_finish      ),
    .read_clk                   (video_clk                ),
    .read_req                   (ch1_read_req             ),
    .read_req_ack               (ch1_read_req_ack         ),
    .read_finish                (                         ),
    .read_addr_0                (25'd8294400              ), //The first frame address is 0
    .read_addr_1                (25'd10368000             ), //The second frame address is 25'd2073600 ,large enough address space for one frame of video
    .read_addr_2                (25'd12441600             ),
    .read_addr_3                (25'd14515200             ),
    .read_addr_index            (ch1_read_addr_index      ),
    .read_len                   (25'd196608               ),//frame size  1024 * 768 * 16 / 64
    .read_en                    (ch1_read_en              ),
    .read_data                  (ch1_read_data            )
);



mem_read_arbi 
#(
    .MEM_DATA_BITS               (MEM_DATA_BITS),
    .ADDR_BITS                   (ADDR_BITS    ),
    .BUSRT_BITS                  (BUSRT_BITS   )
)
mem_read_arbi_m0
(
    .rst_n                        (~mem_rst),
    .mem_clk                      (ui_clk),
    .ch0_rd_burst_req             (ch0_rd_burst_req),
    .ch0_rd_burst_len             (ch0_rd_burst_len),
    .ch0_rd_burst_addr            (ch0_rd_burst_addr),
    .ch0_rd_burst_data_valid      (ch0_rd_burst_data_valid),
    .ch0_rd_burst_data            (ch0_rd_burst_data),
    .ch0_rd_burst_finish          (ch0_rd_burst_finish),
    
    .ch1_rd_burst_req             (ch1_rd_burst_req),
    .ch1_rd_burst_len             (ch1_rd_burst_len),
    .ch1_rd_burst_addr            (ch1_rd_burst_addr),
    .ch1_rd_burst_data_valid      (ch1_rd_burst_data_valid),
    .ch1_rd_burst_data            (ch1_rd_burst_data),
    .ch1_rd_burst_finish          (ch1_rd_burst_finish),
    
    .rd_burst_req                 (rd_burst_req),
    .rd_burst_len                 (rd_burst_len),
    .rd_burst_addr                (rd_burst_addr),
    .rd_burst_data_valid          (rd_burst_data_valid),
    .rd_burst_data                (rd_burst_data),
    .rd_burst_finish              (rd_burst_finish) 
);







rgb2dvi_0 hdmi_inst (
  .TMDS_Clk_p                 (tmds_clk_p     ),
  .TMDS_Clk_n                 (tmds_clk_n     ),
  .TMDS_Data_p                (tmds_data_p    ),
  .TMDS_Data_n                (tmds_data_n    ),
  .aRst                       (1'b0           ),                // input wire aRst
  .vid_pData                  ({hdmi_r,hdmi_b,hdmi_g}),      // input wire [23 : 0] vid_pData
  .vid_pVDE                   (hdmi_de        ),        // input wire vid_pVDE
  .vid_pHSync                 (hdmi_hs        ),    // input wire vid_pHSync
  .vid_pVSync                 (hdmi_vs        ),    // input wire vid_pVSync
  .PixelClk                   (video_clk      ),        // input wire PixelClk
  .SerialClk                  (video_clk5x    )      // input wire SerialClk
);





endmodule
