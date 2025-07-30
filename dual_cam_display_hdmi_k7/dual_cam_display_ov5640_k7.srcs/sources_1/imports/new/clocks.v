`timescale 1ns / 1ps

module clocks(
    input sys_clk,
           // asynchronous control/resets
   output    reg  glbl_rst,
   output         mmcm_locked,
   // clock outputs
   output       clk_200MHz,
   output       clk_50MHz,
   output       clk_25MHz,
   output       video_clk5x,
   output       video_clk

    );


   wire           clkin1;
   wire           mmcm_rst;
   wire           clkin1_bufg;
   wire           mmcm_locked_int;
   wire           mmcm_locked_sync;
   reg            mmcm_locked_reg = 1;
   reg            mmcm_locked_edge = 1;
   reg [7:0]      reset_count=8'd0;


  // Input buffering
  //------------------------------------
assign clkin1 = sys_clk;

  // route clkin1 through a BUFGCE for the MMCM reset generation logic
  BUFGCE bufg_clkin1 (.I(clkin1), .CE  (1'b1), .O(clkin1_bufg));

always @(posedge clkin1_bufg)
   begin
         if (!(&reset_count)) begin
            reset_count <= reset_count + 1;
            glbl_rst<=1'b1;
         end
         else begin
            reset_count <= reset_count;
            glbl_rst<=1'b0;
         end
    end


  clk_200M clk_ref_m0
   (
    // Clock out ports
    .clk_out1(clk_200MHz    ),     // 输出时钟  200MHz
    .clk_out2(video_clk5x   ),     // 输出时钟  325MHz
    .clk_out3(video_clk     ),     // 输出时钟  75MHz
    .clk_out4(clk_50MHz     ),     // 输出时钟  50MHz
    .clk_out5(clk_25MHz     ),     // 输入时钟  25MHz
    
    .reset   (glbl_rst      ),       // input reset
    .locked  (mmcm_locked   ),     // output locked
    .clk_in1 (clkin1        )      // 输入时钟  50MHz
    );     





endmodule
