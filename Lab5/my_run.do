vlib work
vlog -sv fifo.sv
vlog -sv my_interface.sv
vlog -sv my_pkg.sv
vlog -sv top.sv
vsim -voptargs=+acc top
add wave -r /*
run 500ns