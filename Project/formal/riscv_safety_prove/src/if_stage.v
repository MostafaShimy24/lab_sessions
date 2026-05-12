//==============================================================================
// if_stage.v — Instruction Fetch Stage
//------------------------------------------------------------------------------
// Project : ELCT1005 PROJ02 — Pipelined RISC-V CPU with Conv-PE
//
// Responsibilities:
//   1. Hold and update the Program Counter (PC) register
//   2. Select the next PC via a 3-way mux:
//        pc_src = 2'b00  ->  PC + 4          (sequential, default)
//        pc_src = 2'b01  ->  branch_target   (taken branch from EX)
//        pc_src = 2'b10  ->  jump_target     (JAL / JALR from EX)
//   3. Drive imem with the current PC (fetch address)
//   4. Output a PC-delay register (pc_if_o) aligned with imem's registered
//      instruction output so the IF/ID pipeline register in riscv_top.v
//      receives a matched (PC, instruction) pair.
//   5. Honour stall (Conv-PE busy) and flush (branch/jump taken) controls.
//
// Timing note — synchronous imem:
//   imem registers its output on the rising edge, so the instruction word
//   arriving at instr_i in cycle N was requested by the address driven in
//   cycle N-1.  To keep (PC, instruction) aligned at the IF/ID boundary we
//   maintain pc_if_r, a one-cycle-delayed copy of pc_reg.  riscv_top.v
//   latches both pc_if_o and instr_i into the IF/ID pipeline register on
//   the same rising edge.
//
// Stall behaviour (conv_busy):
//   Both pc_reg and pc_if_r are frozen — the same address keeps driving imem
//   so the same instruction word re-appears next cycle and is re-latched into
//   the IF/ID register.
//
// Flush behaviour (branch / JAL / JALR taken):
//   pc_reg is loaded with the target address.
//   pc_if_r is loaded with PC_NOP (0x00000000) so the IF/ID register latches
//   a NOP-aligned PC, and instr_i will carry the NOP that imem outputs when
//   addressed at 0 (imem initialises all locations to NOP).
//   The flush of the ID/EX register (to hold a bubble/NOP) is handled in
//   riscv_top.v — not here.
//
// Ports:
//   Inputs:
//     clk, rst_n        — global clock and active-low synchronous reset
//     stall_i           — freeze PC when Conv-PE is BUSY
//     flush_i           — invalidate current fetch (branch/jump taken)
//     pc_src_i [1:0]    — next-PC select (see above)
//     branch_target_i   — branch target from EX stage
//     jump_target_i     — JAL/JALR target from EX stage
//     instr_i [31:0]    — registered instruction word from imem
//   Outputs:
//     pc_fetch_o [31:0] — PC driven to imem address port (current pc_reg)
//     pc_if_o    [31:0] — PC aligned with instr_i (one-cycle delayed)
//     pc_plus4_o [31:0] — PC+4 (forwarded to ID stage for JAL/JALR link)
//==============================================================================
`timescale 1ns / 1ps
`default_nettype none

module if_stage (
    input  wire        clk,
    input  wire        rst_n,

    // Pipeline controls
    input  wire        stall_i,           // freeze (Conv-PE busy)
    input  wire        flush_i,           // invalidate fetch (branch/jump taken)

    // Next-PC select and targets
    input  wire [1:0]  pc_src_i,          // 00=PC+4, 01=branch, 10=jump
    input  wire [31:0] branch_target_i,
    input  wire [31:0] jump_target_i,

    // Instruction word from imem (synchronous / registered output)
    input  wire [31:0] instr_i,

    // Outputs to imem and IF/ID pipeline register
    output wire [31:0] pc_fetch_o,        // -> imem address port
    output wire [31:0] pc_if_o,           // -> IF/ID register (matched to instr)
    output wire [31:0] pc_plus4_o         // -> IF/ID register (link address)
);

    // =========================================================================
    // PC register — drives imem address
    // =========================================================================
    reg [31:0] pc_reg;

    // Next-PC combinational mux
    reg [31:0] next_pc;
    always @* begin
        case (pc_src_i)
            2'b01:   next_pc = branch_target_i;
            2'b10:   next_pc = jump_target_i;
            default: next_pc = pc_reg + 32'd4;   // sequential
        endcase
    end

    always @(posedge clk) begin
        if (!rst_n)
            pc_reg <= 32'h00000000;
        else if (flush_i)
            pc_reg <= next_pc;          // load target, discards in-flight fetch
        else if (!stall_i)
            pc_reg <= next_pc;
        // stall_i=1 and no flush: pc_reg holds (same addr re-driven to imem)
    end

    // =========================================================================
    // PC-delay register — aligns PC with imem's registered instruction output
    // =========================================================================
    localparam PC_NOP = 32'h00000000;   // bubble PC written on flush

    reg [31:0] pc_if_r;

    always @(posedge clk) begin
        if (!rst_n)
            pc_if_r <= PC_NOP;
        else if (flush_i)
            pc_if_r <= PC_NOP;          // bubble: instr_i will be a NOP
        else if (!stall_i)
            pc_if_r <= pc_reg;          // capture the PC that just drove imem
        // stall: pc_if_r holds (IF/ID register will also be frozen in top)
    end

    // =========================================================================
    // Outputs
    // =========================================================================
    assign pc_fetch_o = pc_reg;
    assign pc_if_o    = pc_if_r;
    assign pc_plus4_o = pc_if_r + 32'd4;   // PC+4 for JAL/JALR link value

endmodule

`default_nettype wire