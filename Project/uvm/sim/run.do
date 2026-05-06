#==============================================================================
# run.do — QuestaSim .do Script for Interactive UVM Simulation with Coverage
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

# Optional: delete old coverage database
if {[file exists coverage.ucdb]} {
    file delete coverage.ucdb
}

#------------------------------------------------------------------------------
# Compile RTL sources with coverage enabled
#------------------------------------------------------------------------------
vlog -timescale 1ns/1ps +acc -cover bcesft \
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

#------------------------------------------------------------------------------
# Compile SystemVerilog/UVM TB sources with coverage enabled
# IMPORTANT:
# The coverage file must be compiled after the transaction classes are known.
# If riscv_uvm_pkg.sv already includes riscv_coverage.sv, do NOT compile it again.
#------------------------------------------------------------------------------
vlog -sv -timescale 1ns/1ps +acc -cover bcesft \
    +incdir+../pkg \
    +incdir+.. \
    +incdir+../coverage \
    ../tb/riscv_if.sv \
    ../pkg/riscv_uvm_pkg.sv \
    ../tb/tb_top.sv

#------------------------------------------------------------------------------
# Launch simulation with coverage enabled
#------------------------------------------------------------------------------
vsim -coverage -voptargs="+acc" \
    +UVM_TESTNAME=test_arith \
    +UVM_VERBOSITY=UVM_MEDIUM \
    -sv_seed random \
    work.tb_top

#------------------------------------------------------------------------------
# Add key signals to waveform
#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
# Run simulation
#------------------------------------------------------------------------------
run -all

#------------------------------------------------------------------------------
# Save coverage database
#------------------------------------------------------------------------------
coverage save -onexit coverage.ucdb
coverage save coverage.ucdb

#------------------------------------------------------------------------------
# Open coverage GUI
#------------------------------------------------------------------------------
view coverage
coverage report -details

# Optional: open standalone coverage viewer
# vcover gui coverage.ucdb