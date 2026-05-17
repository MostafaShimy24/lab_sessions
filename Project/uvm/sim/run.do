#==============================================================================
# run.do — QuestaSim UVM Simulation with Merged Coverage
#------------------------------------------------------------------------------
# Usage:
#   do run.do
#==============================================================================

#------------------------------------------------------------------------------
# End any active simulation if one exists
#------------------------------------------------------------------------------
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
# Create results directory
#------------------------------------------------------------------------------
file mkdir results

#------------------------------------------------------------------------------
# Backup previous coverage results before overwriting
#------------------------------------------------------------------------------
file mkdir results/backup
set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]

foreach f {
    cov_arith.ucdb
    cov_mem.ucdb
    cov_branch.ucdb
    cov_merged.ucdb
    full_coverage_report.txt
    functional_coverage_report.txt
} {
    if {[file exists results/$f]} {
        quietly catch {file copy -force results/$f results/backup/${timestamp}_$f}
    }
}

#------------------------------------------------------------------------------
# Compile RTL sources with coverage enabled
#------------------------------------------------------------------------------
vlog -timescale 1ns/1ps +acc -cover bcesft \
    ../../rtl/src/alu.v \
    ../../rtl/src/regfile.v \
    ../../rtl/src/conv_pe.v \
    ../../rtl/src/imem.v \
    ../../rtl/src/dmem.v \
    ../../rtl/src/if_stage.v \
    ../../rtl/src/id_stage.v \
    ../../rtl/src/ex_stage.v \
    ../../rtl/src/mem_stage.v \
    ../../rtl/src/wb_stage.v \
    ../../rtl/src/riscv_top.v

#------------------------------------------------------------------------------
# Compile SystemVerilog/UVM TB sources with coverage enabled
# riscv_coverage.sv is included inside riscv_uvm_pkg.sv.
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
puts "============================================================"
puts "Running test_arith"
puts "============================================================"

vsim -coverage -voptargs="+acc" \
    +UVM_TESTNAME=test_arith \
    +UVM_VERBOSITY=UVM_MEDIUM \
    -sv_seed 1 \
    work.tb_top

onfinish stop

run -all
coverage save results/cov_arith.ucdb
quit -sim

#==============================================================================
# Run test_mem
#==============================================================================
puts "============================================================"
puts "Running test_mem"
puts "============================================================"

vsim -coverage -voptargs="+acc" \
    +UVM_TESTNAME=test_mem \
    +UVM_VERBOSITY=UVM_MEDIUM \
    -sv_seed 2 \
    work.tb_top

onfinish stop

run -all
coverage save results/cov_mem.ucdb
quit -sim

#==============================================================================
# Run test_branch
#==============================================================================
puts "============================================================"
puts "Running test_branch"
puts "============================================================"

vsim -coverage -voptargs="+acc" \
    +UVM_TESTNAME=test_branch \
    +UVM_VERBOSITY=UVM_MEDIUM \
    -sv_seed 3 \
    work.tb_top

onfinish stop

# If Questa closes here, replace this with: run 5000ns
run -all

coverage save results/cov_branch.ucdb

# IMPORTANT:
# Do not use quit -sim after the final test.
# Leaving the final simulation loaded keeps the GUI stable.

#==============================================================================
# Merge coverage databases
#==============================================================================
puts "============================================================"
puts "Merging coverage databases"
puts "============================================================"

vcover merge results/cov_merged.ucdb \
    results/cov_arith.ucdb \
    results/cov_mem.ucdb \
    results/cov_branch.ucdb

#==============================================================================
# Generate coverage reports
#==============================================================================
puts "============================================================"
puts "Generating coverage reports"
puts "============================================================"

vcover report results/cov_merged.ucdb \
    -details \
    -all \
    -output results/full_coverage_report.txt

vcover report results/cov_merged.ucdb \
    -cvg \
    -details \
    -output results/functional_coverage_report.txt

puts "============================================================"
puts "Coverage merge completed successfully."
puts "Merged UCDB:              results/cov_merged.ucdb"
puts "Full coverage report:     results/full_coverage_report.txt"
puts "Functional coverage:      results/functional_coverage_report.txt"
puts "Backup folder:            results/backup"
puts "============================================================"