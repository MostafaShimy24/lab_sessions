//==============================================================================
// riscv_uvm_pkg.sv — UVM Package for RISC-V Verification
//------------------------------------------------------------------------------
// Imports all UVM testbench classes in dependency order.
// The `uvm_analysis_imp_decl macros must come before any class that uses them.
//==============================================================================

package riscv_uvm_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // =========================================================================
    // Analysis port suffix declarations (must precede scoreboard/coverage)
    // =========================================================================
    `uvm_analysis_imp_decl(_wb)
    `uvm_analysis_imp_decl(_store)
    `uvm_analysis_imp_decl(_conv)

    // =========================================================================
    // Transaction items
    // =========================================================================
    `include "../agents/imem_agent/riscv_instr_item.sv"
    `include "../agents/dmem_agent/dmem_txn.sv"

    // =========================================================================
    // Monitors (transaction classes defined in monitor files)
    // =========================================================================
    `include "../monitors/wb_monitor.sv"
    `include "../monitors/dmem_store_monitor.sv"
    `include "../monitors/conv_pe_monitor.sv"

    // =========================================================================
    // Agents
    // =========================================================================
    `include "../agents/imem_agent/imem_sequencer.sv"
    `include "../agents/imem_agent/imem_driver.sv"
    `include "../agents/imem_agent/imem_agent.sv"

    `include "../agents/dmem_agent/dmem_sequencer.sv"
    `include "../agents/dmem_agent/dmem_driver.sv"
    `include "../agents/dmem_agent/dmem_agent.sv"

    // =========================================================================
    // Scoreboard
    // =========================================================================
    `include "../scoreboard/riscv_scoreboard.sv"

    // =========================================================================
    // Coverage
    // =========================================================================
    `include "../coverage/riscv_coverage.sv"

    // =========================================================================
    // Environment
    // =========================================================================
    `include "../env/riscv_env.sv"

    // =========================================================================
    // Sequences
    // =========================================================================
    `include "../sequences/seq_arith.sv"
    `include "../sequences/seq_mem.sv"
    `include "../sequences/seq_branch.sv"

    // =========================================================================
    // Tests
    // =========================================================================
    `include "../tests/riscv_base_test.sv"
    `include "../tests/test_arith.sv"
    `include "../tests/test_mem.sv"
    `include "../tests/test_branch.sv"

endpackage : riscv_uvm_pkg
