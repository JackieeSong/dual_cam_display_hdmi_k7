############## NET - IOSTANDARD ##################
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]
#############SPI Configurate Setting##################
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
############## clock and reset define##################
create_clock -period 20.000 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS33 [get_ports sys_clk]
set_property PACKAGE_PIN G22 [get_ports sys_clk]

#set_property IOSTANDARD LVCMOS33 [get_ports {rst_n}]
#set_property PACKAGE_PIN F20 [get_ports {rst_n}]
############## HDMI_O###########################
set_property IOSTANDARD TMDS_33 [get_ports tmds_clk_n]

set_property PACKAGE_PIN Y22 [get_ports tmds_clk_p]
set_property IOSTANDARD TMDS_33 [get_ports tmds_clk_p]

set_property IOSTANDARD TMDS_33 [get_ports {tmds_data_n[0]}]

set_property PACKAGE_PIN AF24 [get_ports {tmds_data_p[0]}]
set_property IOSTANDARD TMDS_33 [get_ports {tmds_data_p[0]}]

set_property IOSTANDARD TMDS_33 [get_ports {tmds_data_n[1]}]

set_property PACKAGE_PIN AE23 [get_ports {tmds_data_p[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {tmds_data_p[1]}]

set_property IOSTANDARD TMDS_33 [get_ports {tmds_data_n[2]}]

set_property PACKAGE_PIN AC23 [get_ports {tmds_data_p[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {tmds_data_p[2]}]

set_property PACKAGE_PIN AE22 [get_ports {HDMI_OEN[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {HDMI_OEN[0]}]

### Asynchronous clock domain crossings ###
set_false_path -through [get_pins -filter {NAME =~ */SyncAsync*/oSyncStages*/PRE || NAME =~ */SyncAsync*/oSyncStages*/CLR} -hier]
set_false_path -through [get_pins -filter {NAME =~ *SyncAsync*/oSyncStages_reg[0]/D} -hier]




############################################################
# Ignore paths to resync flops
############################################################
#set_false_path -to [get_pins -filter {REF_PIN_NAME =~ PRE} -of [get_cells -hier -regexp {.*\/syn_block.*}]]
#set_false_path -to [get_pins -filter {REF_PIN_NAME =~ D} -of [get_cells -regexp {.*\/.*syn_block.*}]]


#################AN5642#######################################
#FROM PIN 20 TO PIN 35
set_property PACKAGE_PIN F9 [get_ports cmos1_scl]
set_property PACKAGE_PIN C9 [get_ports cmos1_sda]

set_property PACKAGE_PIN D8 [get_ports {cmos1_db[7]}]
set_property PACKAGE_PIN A9 [get_ports {cmos1_db[6]}]
set_property PACKAGE_PIN G12 [get_ports {cmos1_db[5]}]
set_property PACKAGE_PIN G11 [get_ports {cmos1_db[4]}]
set_property PACKAGE_PIN B9 [get_ports {cmos1_db[3]}]
set_property PACKAGE_PIN A8 [get_ports {cmos1_db[2]}]
set_property PACKAGE_PIN F8 [get_ports {cmos1_db[1]}]
set_property PACKAGE_PIN G14 [get_ports {cmos1_db[0]}]

set_property PACKAGE_PIN H14 [get_ports cmos1_rst_n]
set_property PACKAGE_PIN F13 [get_ports cmos1_pclk]
set_property PACKAGE_PIN F14 [get_ports cmos1_vsync]
set_property PACKAGE_PIN H11 [get_ports cmos1_href]

create_clock -period 10.000 [get_ports cmos1_pclk]



set_property IOSTANDARD LVCMOS33 [get_ports cmos1_scl]
set_property IOSTANDARD LVCMOS33 [get_ports cmos1_sda]

set_property IOSTANDARD LVCMOS33 [get_ports {cmos1_db[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos1_db[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos1_db[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos1_db[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos1_db[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos1_db[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos1_db[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos1_db[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports cmos1_rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports cmos1_pclk]
set_property IOSTANDARD LVCMOS33 [get_ports cmos1_vsync]
set_property IOSTANDARD LVCMOS33 [get_ports cmos1_href]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets cmos1_pclk_IBUF]


# CMOS 2 ports

set_property PACKAGE_PIN C14 [get_ports cmos2_scl]
set_property PACKAGE_PIN B14 [get_ports cmos2_sda]

set_property PACKAGE_PIN D13 [get_ports {cmos2_db[7]}]
set_property PACKAGE_PIN D14 [get_ports {cmos2_db[6]}]
set_property PACKAGE_PIN E12 [get_ports {cmos2_db[5]}]
set_property PACKAGE_PIN C12 [get_ports {cmos2_db[4]}]
set_property PACKAGE_PIN C13 [get_ports {cmos2_db[3]}]
set_property PACKAGE_PIN D10 [get_ports {cmos2_db[2]}]
set_property PACKAGE_PIN D9 [get_ports {cmos2_db[1]}]
set_property PACKAGE_PIN B12 [get_ports {cmos2_db[0]}]

set_property PACKAGE_PIN A14 [get_ports cmos2_rst_n]
set_property PACKAGE_PIN B11 [get_ports cmos2_pclk]
set_property PACKAGE_PIN E10 [get_ports cmos2_vsync]
set_property PACKAGE_PIN D11 [get_ports cmos2_href]

create_clock -period 10.000 [get_ports cmos2_pclk]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets cmos2_pclk_IBUF]



set_property IOSTANDARD LVCMOS33 [get_ports cmos2_scl]
set_property IOSTANDARD LVCMOS33 [get_ports cmos2_sda]

set_property IOSTANDARD LVCMOS33 [get_ports {cmos2_db[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos2_db[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos2_db[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos2_db[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos2_db[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos2_db[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos2_db[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos2_db[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports cmos2_rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports cmos2_pclk]
set_property IOSTANDARD LVCMOS33 [get_ports cmos2_vsync]
set_property IOSTANDARD LVCMOS33 [get_ports cmos2_href]


set_property PULLUP true [get_ports cmos1_scl]
set_property PULLUP true [get_ports cmos1_sda]
set_property PULLUP true [get_ports cmos2_scl]
set_property PULLUP true [get_ports cmos2_sda]

set_false_path -from [get_pins u_ddr3/u_ddr3_mig/u_memc_ui_top_axi/mem_intfc0/ddr_phy_top0/u_ddr_calib_top/init_calib_complete_reg/C] -to [get_pins inst_top_resets/init_calib_complete_syn_inst1/data_sync_reg0/D]
set_false_path -from [get_pins frame_read_m1/frame_fifo_read_m0/fifo_aclr_reg/C] -to [get_pins video_rect_read_data_m1/read_req_reg/D]
set_false_path -from [get_pins frame_read_m0/frame_fifo_read_m0/fifo_aclr_reg/C] -to [get_pins video_rect_read_data_m0/read_req_reg/D]



set_false_path -from [get_clocks cmos1_pclk] -to [get_clocks -of_objects [get_pins u_ddr3/u_ddr3_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]
set_false_path -from [get_clocks cmos2_pclk] -to [get_clocks -of_objects [get_pins u_ddr3/u_ddr3_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]
