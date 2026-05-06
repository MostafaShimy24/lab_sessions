//==============================================================================
// riscv_uvm_pkg.sv ? UVM Package for RISC-V Verification
//------------------------------------------------------------------------------
// Imports all UVM testbench classes in dependency order.
// The `uvm_analysis_imp_decl macros must come before any class that uses them.
//==============================================================================

package riscv_uvm_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // =========================================================================
    // Analysis implementation suffix declarations
    // Must appear before any class that uses:
    //   uvm_analysis_imp_wb
    //   uvm_analysis_imp_store
    //   uvm_analysis_imp_conv
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
    // Monitors
    // These files define monitor classes and may also define:
    //   wb_txn
    //   store_txn
    //   conv_txn
    // Therefore, they must be included before scoreboard and coverage.
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
    // Depends on wb_txn, store_txn/dmem_store_txn, and conv_txn.
    // =========================================================================
    `include "../scoreboard/riscv_scoreboard.sv"

    // =========================================================================
    // Coverage
    // Depends on:
    //   wb_txn
    //   conv_txn
    //   uvm_analysis_imp_conv
    // Must be included after monitor transaction types are known.
    // =========================================================================
    `include "../coverage/riscv_coverage.sv"

    // =========================================================================
    // Environment
    // Depends on agents, scoreboard, and coverage.
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
