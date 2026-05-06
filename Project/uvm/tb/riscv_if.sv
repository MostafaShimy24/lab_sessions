//==============================================================================
// riscv_if.sv — Virtual Interface for Hierarchical Backdoor Access
//------------------------------------------------------------------------------
// Bundles clk and rst_n signals for the UVM environment. Agents and monitors
// use cross-module references (XMR) via `tb_top` to access internal DUT
// signals (imem.mem[], dmem.mem[], regfile.regs[], pipeline registers).
//==============================================================================

interface riscv_if (
    input logic clk,
    input logic rst_n
);

    // =========================================================================
    // Clock-edge helpers for monitors
    // =========================================================================
    clocking mon_cb @(posedge clk);
        default input #1step;
    endclocking

endinterface : riscv_if
