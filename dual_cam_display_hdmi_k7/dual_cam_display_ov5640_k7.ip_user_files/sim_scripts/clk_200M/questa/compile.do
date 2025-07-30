vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xil_defaultlib

vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xil_defaultlib -64 "+incdir+../../../ipstatic" \
"../../../../dual_cam_display_ov5640_k7.srcs/sources_1/ip/clk_200M/clk_200M_clk_wiz.v" \
"../../../../dual_cam_display_ov5640_k7.srcs/sources_1/ip/clk_200M/clk_200M.v" \


vlog -work xil_defaultlib \
"glbl.v"

