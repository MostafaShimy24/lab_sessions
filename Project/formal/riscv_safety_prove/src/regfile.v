//==============================================================================
// regfile.v — RV32I Integer Register File
//------------------------------------------------------------------------------
// Project : ELCT1005 PROJ02 — Pipelined RISC-V CPU with Conv-PE
// Spec    : 32 general-purpose registers (x0–x31), each 32 bits wide.
//           x0 is hardwired to zero — reads always return 0, writes silently
//           ignored. Total architectural state: 31 × 32 = 992 bits.
//
// Ports:
//   Read port A (async/combinational — ID stage):
//     rs1_addr[4:0]  -> rs1_data[31:0]
//   Read port B (async/combinational — ID stage):
//     rs2_addr[4:0]  -> rs2_data[31:0]
//   Write port (synchronous, rising edge — WB stage):
//     clk, rst_n, we, rd_addr[4:0], rd_data[31:0]
//
// Implementation:
//   FF array with two combinational read muxes. NO memory primitive
//   ($readmemh / synchronous-read RAM) — must synthesise to standard-cell
//   flip-flops so all 992 state bits appear on the scan chain (Phase 4 DFT).
//
// Formal properties (Phase 1):
//   X0_SAFE — write-enable to x0 with non-zero data must never occur.
//             Enforced both by the write guard below AND the Phase 1 SBY
//             property in riscv_props.v.
//==============================================================================
`timescale 1ns / 1ps
`default_nettype none

module regfile (
    input  wire        clk,
    input  wire        rst_n,       // active-low synchronous reset

    // Read port A (combinational)
    input  wire [4:0]  rs1_addr,
    output wire [31:0] rs1_data,

    // Read port B (combinational)
    input  wire [4:0]  rs2_addr,
    output wire [31:0] rs2_data,

    // Write port (synchronous)
    input  wire        we,
    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_data
);

    // -------------------------------------------------------------------------
    // Storage — 32 × 32-bit flip-flop array.
    // regs[0] is never written (x0 guard below) and reads return 0 via the
    // combinational mux, so its power-up value is irrelevant. Keeping it in
    // the array avoids width-mismatch complexity; Yosys will optimise it away.
    // -------------------------------------------------------------------------
    reg [31:0] regs [1:31];  // x1–x31 only; x0 handled separately

    // -------------------------------------------------------------------------
    // Synchronous write with synchronous reset.
    //   - rst_n = 0  → clear every register to 0 on the next rising edge.
    //   - we = 1 AND rd_addr != 0 → write rd_data to regs[rd_addr].
    //   - Writes to rd_addr == 0 are silently ignored (X0_SAFE guarantee).
    // -------------------------------------------------------------------------
    integer idx;
    always @(posedge clk) begin
        if (!rst_n) begin
            for (idx = 1; idx <= 31; idx = idx + 1)
                regs[idx] <= 32'h00000000;
        end else if (we && (rd_addr != 5'd0)) begin
            regs[rd_addr] <= rd_data;
        end
    end

    // -------------------------------------------------------------------------
    // Asynchronous combinational reads.
    //   x0 always returns 0 regardless of the array content.
    //   x1–x31 return the current FF value directly (no clock edge needed).
    // -------------------------------------------------------------------------
    assign rs1_data = (rs1_addr == 5'd0) ? 32'h00000000 : regs[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'h00000000 : regs[rs2_addr];

endmodule

`default_nettype wire