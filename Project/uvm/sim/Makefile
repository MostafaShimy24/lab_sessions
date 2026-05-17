#==============================================================================
# Makefile — QuestaSim UVM Simulation for RISC-V CPU
#==============================================================================

# Project paths
RTL_DIR    = ../../rtl/src
UVM_DIR    = ..
TB_DIR     = $(UVM_DIR)/tb
PKG_DIR    = $(UVM_DIR)/pkg

# QuestaSim commands
VLOG       = vlog
VSIM       = vsim
VLIB       = vlib
VMAP       = vmap

# UVM settings
UVM_HOME   ?= $(QUESTA_HOME)/verilog_src/uvm-1.2
UVM_FLAGS  = +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm_pkg.sv

# Compilation flags
VLOG_FLAGS = -sv +acc -timescale 1ns/1ps +incdir+$(PKG_DIR) +incdir+$(UVM_DIR)

# RTL source files (Verilog-2001)
RTL_SRCS = \
    $(RTL_DIR)/alu.v \
    $(RTL_DIR)/regfile.v \
    $(RTL_DIR)/conv_pe.v \
    $(RTL_DIR)/imem.v \
    $(RTL_DIR)/dmem.v \
    $(RTL_DIR)/if_stage.v \
    $(RTL_DIR)/id_stage.v \
    $(RTL_DIR)/ex_stage.v \
    $(RTL_DIR)/mem_stage.v \
    $(RTL_DIR)/wb_stage.v \
    $(RTL_DIR)/riscv_top.v

# SystemVerilog TB files
TB_SRCS = \
    $(TB_DIR)/riscv_if.sv \
    $(PKG_DIR)/riscv_uvm_pkg.sv \
    $(TB_DIR)/tb_top.sv

# Library
WORK = work

#==============================================================================
# Targets
#==============================================================================

.PHONY: all compile test_arith test_mem test_branch regress clean help

all: compile

help:
	@echo "Targets:"
	@echo "  compile      - Compile all RTL + UVM TB sources"
	@echo "  test_arith   - Run SEQ_ARITH test"
	@echo "  test_mem     - Run SEQ_MEM test"
	@echo "  test_branch  - Run SEQ_BRANCH test"
	@echo "  regress      - Run all 3 tests"
	@echo "  clean        - Remove work library and logs"

# Create work library
$(WORK):
	$(VLIB) $(WORK)
	$(VMAP) work $(WORK)

# Compile RTL (Verilog) + TB (SystemVerilog)
compile: $(WORK)
	$(VLOG) $(VLOG_FLAGS) $(RTL_SRCS)
	$(VLOG) $(VLOG_FLAGS) $(TB_SRCS)
	@echo "=== Compilation complete ==="

# Run individual tests
test_arith: compile
	$(VSIM) -c -do "run -all; quit -f" \
		+UVM_TESTNAME=test_arith \
		+UVM_VERBOSITY=UVM_MEDIUM \
		-sv_seed random \
		work.tb_top \
		-l test_arith.log
	@echo "=== test_arith complete — see test_arith.log ==="

test_mem: compile
	$(VSIM) -c -do "run -all; quit -f" \
		+UVM_TESTNAME=test_mem \
		+UVM_VERBOSITY=UVM_MEDIUM \
		-sv_seed random \
		work.tb_top \
		-l test_mem.log
	@echo "=== test_mem complete — see test_mem.log ==="

test_branch: compile
	$(VSIM) -c -do "run -all; quit -f" \
		+UVM_TESTNAME=test_branch \
		+UVM_VERBOSITY=UVM_MEDIUM \
		-sv_seed random \
		work.tb_top \
		-l test_branch.log
	@echo "=== test_branch complete — see test_branch.log ==="

# Regression: run all tests
regress: test_arith test_mem test_branch
	@echo "=== ALL TESTS COMPLETE ==="

# Clean
clean:
	rm -rf $(WORK) transcript *.log *.vcd *.wlf modelsim.ini
