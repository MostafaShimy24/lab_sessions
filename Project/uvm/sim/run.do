#==============================================================================
# run.do — QuestaSim .do Script for Interactive UVM Simulation
#==============================================================================
# Usage:
#   do run.do
#==============================================================================

# Create and map work library
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

# Compile RTL sources (Verilog-2001)
vlog -timescale 1ns/1ps +acc \
    ../../alu.v \
    ../../regfile.v \
    ../../conv_pe.v \
    ../../imem.v \
    ../../dmem.v \
    ../../if_stage.v \
    ../../id_stage.v \
    ../../ex_stage.v \
    ../../mem_stage.v \
    ../../wb_stage.v \
    ../../riscv_top.v

# Compile SystemVerilog TB sources
vlog -sv -timescale 1ns/1ps +acc \
    +incdir+../pkg +incdir+.. \
    ../tb/riscv_if.sv \
    ../pkg/riscv_uvm_pkg.sv \
    ../tb/tb_top.sv

# Launch simulation
vsim -voptargs="+acc" \
    +UVM_TESTNAME=test_arith \
    +UVM_VERBOSITY=UVM_MEDIUM \
    -sv_seed random \
    work.tb_top

# Add key signals to waveform
add wave -group "Clock/Reset" /tb_top/clk /tb_top/rst_n

add wave -group "IF Stage"    /tb_top/u_dut/u_if/pc_reg \
                              /tb_top/u_dut/imem_instr \
                              /tb_top/u_dut/flush \
                              /tb_top/u_dut/stall

add wave -group "ID Stage"    /tb_top/u_dut/if_id_instr \
                              /tb_top/u_dut/if_id_pc

add wave -group "EX Stage"    /tb_top/u_dut/u_ex/alu_result \
                              /tb_top/u_dut/u_ex/branch_taken \
                              /tb_top/u_dut/u_ex/conv_busy \
                              /tb_top/u_dut/u_ex/conv_done \
                              /tb_top/u_dut/u_ex/conv_result

add wave -group "WB Stage"    /tb_top/u_dut/wb_we \
                              /tb_top/u_dut/wb_addr \
                              /tb_top/u_dut/wb_data

add wave -group "Conv-PE"     /tb_top/u_dut/u_ex/u_conv_pe/state_r \
                              /tb_top/u_dut/u_ex/u_conv_pe/accum_r \
                              /tb_top/u_dut/u_ex/u_conv_pe/conv_status

# Run simulation
run -all