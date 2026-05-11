//==============================================================================
// mem_stage.v — Memory Access Stage
//------------------------------------------------------------------------------
// Project : ELCT1005 PROJ02 — Pipelined RISC-V CPU with Conv-PE
//
// Responsibilities:
//   1. Drive dmem write port for SB / SH / SW (synchronous write)
//   2. Drive dmem read port for LB / LH / LW / LBU / LHU (async read)
//   3. Pass through ALU result, Conv-PE result, and all WB control signals
//      to the MEM/WB pipeline register
//
// dmem is instantiated here. Its write port is clocked; read port is
// combinational — load data is available in the same cycle the address
// is presented (no extra latency before the MEM/WB register captures it).
//
// Note: the Conv-PE has NO memory port — it reads operands directly from
// the register file via the ID/EX register. The dmem note in dmem.v about
// a "Conv-PE read pointer mux" does not apply to this implementation since
// the spec states the Conv-PE is a pure register-file consumer.
//
// Ports (inputs from EX/MEM pipeline register):
//   clk, rst_n          — forwarded to dmem
//   alu_result_i        — effective address for loads/stores; ALU WB value
//   rs2_data_i          — store data (from rs2)
//   conv_result_i       — Conv-PE accumulator (pass-through to WB)
//   rd_addr_i           — destination register (pass-through)
//   pc_plus4_i          — link address for JAL/JALR (pass-through)
//   mem_read_i          — load enable
//   mem_write_i         — store enable → dmem we
//   mem_size_i[1:0]     — 00=byte, 01=half, 10=word
//   mem_sign_ext_i      — 1=sign-extend (LB/LH), 0=zero-extend (LBU/LHU)
//   wb_sel_i[1:0]       — 00=ALU, 01=mem, 10=conv (pass-through)
//   reg_write_i         — register write enable (pass-through)
//   is_jump_i           — JAL/JALR: WB writes pc_plus4 (pass-through)
//
// Ports (outputs to MEM/WB pipeline register):
//   alu_result_o        — ALU result (WB value for R/I-type, address for debug)
//   load_data_o         — data read from dmem (valid when wb_sel==01)
//   conv_result_o       — Conv-PE result (pass-through)
//   rd_addr_o           — destination register (pass-through)
//   pc_plus4_o          — link address (pass-through)
//   wb_sel_o            — WB mux select (pass-through)
//   reg_write_o         — register write enable (pass-through)
//   is_jump_o           — JAL/JALR flag (pass-through)
//==============================================================================
`timescale 1ns / 1ps
`default_nettype none

module mem_stage #(
    parameter integer ACCUM_WIDTH = 32,
    parameter         DMEM_HEX   = "data.hex"
) (
    input  wire        clk,
    input  wire        rst_n,

    // From EX/MEM pipeline register
    input  wire [31:0] alu_result_i,
    input  wire [31:0] rs2_data_i,
    input  wire [ACCUM_WIDTH-1:0] conv_result_i,
    input  wire [4:0]  rd_addr_i,
    input  wire [31:0] pc_plus4_i,
    input  wire        mem_read_i,
    input  wire        mem_write_i,
    input  wire [1:0]  mem_size_i,
    input  wire        mem_sign_ext_i,
    input  wire [1:0]  wb_sel_i,
    input  wire        reg_write_i,
    input  wire        is_jump_i,

    // To MEM/WB pipeline register
    output wire [31:0] alu_result_o,
    output wire [31:0] load_data_o,
    output wire [ACCUM_WIDTH-1:0] conv_result_o,
    output wire [4:0]  rd_addr_o,
    output wire [31:0] pc_plus4_o,
    output wire [1:0]  wb_sel_o,
    output wire        reg_write_o,
    output wire        is_jump_o
);

    // =========================================================================
    // dmem instantiation
    // =========================================================================
    wire [31:0] load_data;

    dmem #(
        .DEPTH_BYTES (1),
        .ADDR_WIDTH  (1),
        .HEX_FILE    (DMEM_HEX)
    ) u_dmem (
        .clk      (clk),
        // Write port — active only on store instructions
        .we       (mem_write_i),
        .wsize    (mem_size_i),
        .waddr    (alu_result_i),
        .wdata    (rs2_data_i),
        // Read port — combinational, active on load instructions
        .raddr    (alu_result_i),
        .rsize    (mem_size_i),
        .sign_ext (mem_sign_ext_i),
        .rdata    (load_data)
    );

    // =========================================================================
    // Output assignments — all combinational / pass-through
    // =========================================================================
    assign alu_result_o  = alu_result_i;
    // Gate load_data: only meaningful when mem_read is asserted.
    // Passing it through unconditionally is safe — wb_sel controls which
    // value is actually written to the register file in WB.
    assign load_data_o   = load_data;
    assign conv_result_o = conv_result_i;
    assign rd_addr_o     = rd_addr_i;
    assign pc_plus4_o    = pc_plus4_i;
    assign wb_sel_o      = wb_sel_i;
    assign reg_write_o   = reg_write_i;
    assign is_jump_o     = is_jump_i;

endmodule

`default_nettype wire