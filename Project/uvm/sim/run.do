#==============================================================================
# run.do ? QuestaSim .do Script for UVM Simulation with Merged Coverage
#==============================================================================
# Usage:
#   do run.do
#==============================================================================

quietly catch {quit -sim}

#------------------------------------------------------------------------------
# Clean and create work library
#------------------------------------------------------------------------------
if {[file exists work]} {
    quietly catch {vdel -lib work -all}
}

vlib work
vmap work work

#------------------------------------------------------------------------------
# Create results directory and delete old coverage outputs
#------------------------------------------------------------------------------
file mkdir results

quietly catch {file delete results/cov_arith.ucdb}
quietly catch {file delete results/cov_mem.ucdb}
quietly catch {file delete results/cov_branch.ucdb}
quietly catch {file delete results/cov_merged.ucdb}
quietly catch {file delete results/full_coverage_report.txt}
quietly catch {file delete results/functional_coverage_report.txt}

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
# Note: riscv_coverage.sv is included inside riscv_uvm_pkg.sv.
# Do NOT compile riscv_coverage.sv separately.
#------------------------------------------------------------------------------
vlog -sv -timescale 1ns/1ps +acc -cover bcesft \
    +incdir+../pkg \
    +incdir+.. \
    +incdir+../coverage \
    ../tb/riscv_if.sv \
    ../pkg/riscv_uvm_pkg.sv \
    ../tb/tb_top.sv

#==============================================================================
# Run test_arith
#==============================================================================
vsim -coverage -voptargs="+acc" \
    +UVM_TESTNAME=test_arith \
    +UVM_VERBOSITY=UVM_MEDIUM \
    -sv_seed 1 \
    work.tb_top

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

run -all
coverage save results/cov_arith.ucdb
quit -sim

#==============================================================================
# Run test_mem
#==============================================================================
vsim -coverage -voptargs="+acc" \
    +UVM_TESTNAME=test_mem \
    +UVM_VERBOSITY=UVM_MEDIUM \
    -sv_seed 2 \
    work.tb_top

run -all
coverage save results/cov_mem.ucdb
quit -sim

#==============================================================================
# Run test_branch
#==============================================================================
vsim -coverage -voptargs="+acc" \
    +UVM_TESTNAME=test_branch \
    +UVM_VERBOSITY=UVM_MEDIUM \
    -sv_seed 3 \
    work.tb_top

run -all
coverage save results/cov_branch.ucdb
quit -sim

#==============================================================================
# Merge coverage databases
#==============================================================================
vcover merge results/cov_merged.ucdb \
    results/cov_arith.ucdb \
    results/cov_mem.ucdb \
    results/cov_branch.ucdb

#==============================================================================
# Generate coverage reports
#==============================================================================
vcover report results/cov_merged.ucdb \
    -details \
    -all \
    -output results/full_coverage_report.txt

vcover report results/cov_merged.ucdb \
    -cvg \
    -details \
    -output results/functional_coverage_report.txt

#==============================================================================
# Open merged coverage database in Questa
#==============================================================================
coverage open results/cov_merged.ucdb

puts "============================================================"
puts "Coverage merge completed successfully."
puts "Merged UCDB:              results/cov_merged.ucdb"
puts "Full coverage report:     results/full_coverage_report.txt"
puts "Functional coverage:      results/functional_coverage_report.txt"
puts "============================================================"