`timescale 1ns / 1ps

module top_resets(
    input           video_clk,
    input           mem_clk,
    input           init_calib_complete,
    input           mmcm_locked,

    output reg      mem_rst,
    output reg      video_rst
   

    );
wire init_calib_complete_syn;
wire mmcm_locked_syn;

wire init_calib_complete_syn_video;
wire mmcm_locked_syn_video;

wire init_calib_complete_syn_pixl;
wire mmcm_locked_syn_pixl;

syn_block init_calib_complete_syn_inst (
     .clk              (mem_clk),
     .data_in          (init_calib_complete),
     .data_out         (init_calib_complete_syn)
  );

syn_block mmcm_locked_syn_inst (
     .clk              (mem_clk),
     .data_in          (mmcm_locked),
     .data_out         (mmcm_locked_syn)
  );

always @(posedge mem_clk ) begin
    if (!init_calib_complete_syn || !mmcm_locked_syn) begin
        mem_rst<=1'b1;
    end
    else begin
        mem_rst<=1'b0;
    end
end


syn_block init_calib_complete_syn_inst1 (
     .clk              (video_clk),
     .data_in          (init_calib_complete),
     .data_out         (init_calib_complete_syn_video)
  );

syn_block mmcm_locked_syn_inst1 (
     .clk              (video_clk),
     .data_in          (mmcm_locked),
     .data_out         (mmcm_locked_syn_video)
  );

always @(posedge video_clk ) begin
    if (!init_calib_complete_syn_video || !mmcm_locked_syn_video) begin
        video_rst<=1'b1;
    end
    else begin
        video_rst<=1'b0;
    end
end





endmodule
