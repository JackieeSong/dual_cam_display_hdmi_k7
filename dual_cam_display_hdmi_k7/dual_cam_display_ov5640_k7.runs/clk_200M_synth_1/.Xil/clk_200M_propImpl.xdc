set_property SRC_FILE_INFO {cfile:e:/education/no12/week12/dual_cam_display_ov5640_k7/dual_cam_display_ov5640_k7.srcs/sources_1/ip/clk_200M/clk_200M.xdc rfile:../../../dual_cam_display_ov5640_k7.srcs/sources_1/ip/clk_200M/clk_200M.xdc id:1 order:EARLY scoped_inst:inst} [current_design]
current_instance inst
set_property src_info {type:SCOPED_XDC file:1 line:57 export:INPUT save:INPUT read:READ} [current_design]
set_input_jitter [get_clocks -of_objects [get_ports clk_in1]] 0.2
