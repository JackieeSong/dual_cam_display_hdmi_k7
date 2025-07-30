vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xil_defaultlib

vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xil_defaultlib -64 \
"../../../ip/afifo_16i_64o_512/sim/afifo_16i_64o_512.v" \


vlog -work xil_defaultlib \
"glbl.v"

