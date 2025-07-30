`timescale 1ns / 1ps

module dual_cam_display(
    input                       sys_clk,                    
    //input                       rst_n,                 
    
    //cam1
    inout                       cmos1_scl,          //cmos i2c clock
    inout                       cmos1_sda,          //cmos i2c data
    input                       cmos1_vsync,        //cmos vsync
    input                       cmos1_href,         //cmos hsync refrence,data valid
    input                       cmos1_pclk,         //cmos pxiel clock
    input   [7:0]               cmos1_db,           //cmos data
    output                      cmos1_rst_n,        //cmos reset
    
    //cam2
    inout                       cmos2_scl,          //cmos i2c clock
    inout                       cmos2_sda,          //cmos i2c data
    input                       cmos2_vsync,        //cmos vsync
    input                       cmos2_href,         //cmos hsync refrence,data valid
    input                       cmos2_pclk,         //cmos pxiel clock
    input   [7:0]               cmos2_db,           //cmos data
    output                      cmos2_rst_n,        //cmos reset
    
    output wire [13:0]          ddr3_addr,
    output wire [2:0]           ddr3_ba,
    output wire                 ddr3_cas_n,
    output wire [0:0]           ddr3_ck_n,
    output wire [0:0]           ddr3_ck_p,
    output wire [0:0]           ddr3_cke,
    output wire                 ddr3_ras_n,
    output wire                 ddr3_reset_n,
    output wire                 ddr3_we_n,
    inout  wire [31:0]          ddr3_dq,
    inout  wire [3:0]           ddr3_dqs_n,
    inout  wire [3:0]           ddr3_dqs_p,
    output wire [0:0]           ddr3_cs_n,
    output wire [3:0]           ddr3_dm,
    output wire [0:0]           ddr3_odt,

    //HDMI output       
     output                      tmds_clk_p,                
     output                      tmds_clk_n,                //
     output[2:0]                 tmds_data_p,       //rgb
     output[2:0]                 tmds_data_n,       //rgb
     output [0:0]                HDMI_OEN                   //HDMIÊ¹ÄÜ
    );


parameter MEM_DATA_BITS          = 64;           //external memory user interface data width
parameter ADDR_BITS              = 25;           //external memory user interface address width
parameter BUSRT_BITS             = 10;           //external memory user interface burst width
parameter WRITE_DATA_BITS        = 16;

wire clk_25MHz;
wire glbl_rst;
wire                            clk_200MHz;
wire                            clk_50MHz;
wire                            video_clk;                 //video pixel clock
wire                            video_clk5x;
wire                            ui_clk;
wire                            init_calib_complete;

wire[1:0]                       ch0_read_addr_index;
wire[1:0]                       ch1_read_addr_index;
wire mmcm_locked;
wire mem_rst;
wire video_rst;

    //burst write req
    wire                              wr_burst_req;
    wire [BUSRT_BITS - 1:0]           wr_burst_len;
    wire [ADDR_BITS - 1:0]            wr_burst_addr;
    wire                              wr_burst_data_req;
    wire [MEM_DATA_BITS - 1:0]        wr_burst_data;
    wire                              wr_burst_finish;

    //burst read req
    wire                         rd_burst_req;
    wire  [BUSRT_BITS-1:0]       rd_burst_len;
    wire  [ADDR_BITS-1:0]        rd_burst_addr;
    wire                         rd_burst_data_valid;
    wire  [MEM_DATA_BITS-1:0]    rd_burst_data;
    wire                         rd_burst_finish;

    clocks inst_clocks
        (
            .sys_clk     (sys_clk),
            .glbl_rst    (glbl_rst),
            .mmcm_locked (mmcm_locked),
            .clk_200MHz  (clk_200MHz),
            .clk_50MHz   (clk_50MHz),
            .clk_25MHz   (clk_25MHz),
            .video_clk5x (video_clk5x),
            .video_clk   (video_clk)
        );

    top_resets inst_top_resets
        (
            .video_clk           (video_clk),
            .mem_clk             (ui_clk),
            .init_calib_complete (init_calib_complete),
            .mmcm_locked         (mmcm_locked),
            .mem_rst             (mem_rst),
            .video_rst           (video_rst)

        );
    image_capture #(
            .MEM_DATA_BITS(MEM_DATA_BITS),
            .ADDR_BITS(ADDR_BITS),
            .BUSRT_BITS(BUSRT_BITS),
            .WRITE_DATA_BITS(WRITE_DATA_BITS)
        ) inst_image_capture (
            .clk_25MHz           (clk_25MHz),
            .clk_50MHz           (clk_50MHz),
            .ui_clk              (ui_clk),
            .reset               (mem_rst),
            .cmos1_scl           (cmos1_scl),
            .cmos1_sda           (cmos1_sda),
            .cmos1_vsync         (cmos1_vsync),
            .cmos1_href          (cmos1_href),
            .cmos1_pclk          (cmos1_pclk),
            .cmos1_db            (cmos1_db),
            .cmos1_rst_n         (cmos1_rst_n),
            .cmos2_scl           (cmos2_scl),
            .cmos2_sda           (cmos2_sda),
            .cmos2_vsync         (cmos2_vsync),
            .cmos2_href          (cmos2_href),
            .cmos2_pclk          (cmos2_pclk),
            .cmos2_db            (cmos2_db),
            .cmos2_rst_n         (cmos2_rst_n),
            .wr_burst_req        (wr_burst_req),
            .wr_burst_len        (wr_burst_len),
            .wr_burst_addr       (wr_burst_addr),
            .wr_burst_data_req   (wr_burst_data_req),
            .wr_burst_data       (wr_burst_data),
            .wr_burst_finish     (wr_burst_finish),
            .ch0_read_addr_index (ch0_read_addr_index),
            .ch1_read_addr_index (ch1_read_addr_index)
        );


    memory_control #(
            .MEM_DATA_BITS(MEM_DATA_BITS),
            .ADDR_BITS(ADDR_BITS),
            .BUSRT_BITS(BUSRT_BITS),
            .WRITE_DATA_BITS(WRITE_DATA_BITS)
        ) inst_memory_control (
            .clk_200MHz          (clk_200MHz),
            .mmcm_locked         (mmcm_locked),
            .ui_clk_o            (ui_clk),
            .ui_clk_sync_rst_o   (ui_clk_sync_rst_o),
            .wr_burst_req        (wr_burst_req),
            .wr_burst_len        (wr_burst_len),
            .wr_burst_addr       (wr_burst_addr),
            .wr_burst_data_req   (wr_burst_data_req),
            .wr_burst_data       (wr_burst_data),
            .wr_burst_finish     (wr_burst_finish),
            .rd_burst_req        (rd_burst_req),
            .rd_burst_len        (rd_burst_len),
            .rd_burst_addr       (rd_burst_addr),
            .rd_burst_data_valid (rd_burst_data_valid),
            .rd_burst_data       (rd_burst_data),
            .rd_burst_finish     (rd_burst_finish),
            .ddr3_addr           (ddr3_addr),
            .ddr3_ba             (ddr3_ba),
            .ddr3_cas_n          (ddr3_cas_n),
            .ddr3_ck_n           (ddr3_ck_n),
            .ddr3_ck_p           (ddr3_ck_p),
            .ddr3_cke            (ddr3_cke),
            .ddr3_ras_n          (ddr3_ras_n),
            .ddr3_reset_n        (ddr3_reset_n),
            .ddr3_we_n           (ddr3_we_n),
            .ddr3_dq             (ddr3_dq),
            .ddr3_dqs_n          (ddr3_dqs_n),
            .ddr3_dqs_p          (ddr3_dqs_p),
            .ddr3_cs_n           (ddr3_cs_n),
            .ddr3_dm             (ddr3_dm),
            .ddr3_odt            (ddr3_odt),
            .init_calib_complete (init_calib_complete)
        );

    display_control #(
            .MEM_DATA_BITS(MEM_DATA_BITS),
            .ADDR_BITS(ADDR_BITS),
            .BUSRT_BITS(BUSRT_BITS),
            .WRITE_DATA_BITS(WRITE_DATA_BITS)
        ) inst_display_control (
            .ui_clk              (ui_clk),
            .video_clk           (video_clk),
            .video_clk5x         (video_clk5x),
            .mem_rst             (mem_rst),
            .video_rst           (video_rst),
            .rd_burst_req        (rd_burst_req),
            .rd_burst_len        (rd_burst_len),
            .rd_burst_addr       (rd_burst_addr),
            .rd_burst_data_valid (rd_burst_data_valid),
            .rd_burst_data       (rd_burst_data),
            .rd_burst_finish     (rd_burst_finish),
            .ch0_read_addr_index (ch0_read_addr_index),
            .ch1_read_addr_index (ch1_read_addr_index),
            .tmds_clk_p          (tmds_clk_p),
            .tmds_clk_n          (tmds_clk_n),
            .tmds_data_p         (tmds_data_p),
            .tmds_data_n         (tmds_data_n),
            .HDMI_OEN            (HDMI_OEN)
        );



endmodule
