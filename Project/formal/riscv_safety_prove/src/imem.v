//==============================================================================
// imem.v — Instruction Memory
//------------------------------------------------------------------------------
// Project : ELCT1005 PROJ02 — Pipelined RISC-V CPU with Conv-PE
// Spec    : 4 KB, Harvard architecture, synchronous read (registered output),
//           32-bit word-addressed. Pre-loaded from a hex file at simulation
//           start via $readmemh. Uninitialised locations default to NOP
//           (ADDI x0, x0, 0 = 32'h00000013).
//
// Notes for students:
//   - This file is provided as a working starting point and is NOT locked.
//     You may modify it to suit your pipeline interface, change depth, add
//     a reset, register the address, etc. Document any changes in the report.
//   - Synchronous read = rising-edge registered output. The instruction is
//     valid one cycle after the address is presented. This is what Phase 0's
//     IF stage assumes (PC presented in cycle N -> instr available in cycle N+1).
//   - Word-addressed: addr[1:0] are ignored; addr[11:2] indexes the array.
//   - The HEX_FILE define lets you swap programs without recompiling all RTL.
//------------------------------------------------------------------------------
// Ports (per project specification):
//   clk           1-bit, rising edge
//   addr[31:0]    byte address (lower 2 bits ignored)
//   instr[31:0]   32-bit registered output (synchronous read)
//==============================================================================
`timescale 1ns / 1ps
`default_nettype none

module imem #(
    parameter integer DEPTH_WORDS = 1024,           // 1024 words = 4 KB
    parameter integer ADDR_WIDTH  = 12,             // log2(DEPTH_WORDS*4) = 12 bits
    parameter         HEX_FILE    = "program.hex",  // override at instantiation
    parameter [31:0]  NOP_DEFAULT = 32'h00000013    // ADDI x0, x0, 0
) (
    input  wire        clk,
    input  wire [31:0] addr,
    output reg  [31:0] instr
);

    // -------------------------------------------------------------------------
    // Storage. Plain reg array so Yosys infers FFs / standard-cell memory
    // depending on the synthesis script. Avoid vendor RAM primitives so the
    // scan chain inserted in Phase 4 (DFT) can reach every state bit.
    // -------------------------------------------------------------------------
    reg [31:0] mem [0:DEPTH_WORDS-1];

    // -------------------------------------------------------------------------
    // Initialisation. All locations default to NOP so that an unprogrammed
    // imem still produces well-defined behaviour (the pipeline keeps advancing
    // PC by 4 with no architectural side effects). The hex file, if present,
    // overwrites the front of the array.
    // -------------------------------------------------------------------------
    integer i;
    initial begin
        for (i = 0; i < DEPTH_WORDS; i = i + 1) begin
            mem[i] = NOP_DEFAULT;
        end
        // $readmemh quietly does nothing if the file is missing in some
        // simulators; in Icarus and QuestaSim it warns. Either way the NOP
        // default above guarantees a safe boot.
        $readmemh(HEX_FILE, mem);
    end

    // -------------------------------------------------------------------------
    // Address decode. Word index = addr[ADDR_WIDTH-1:2]. Byte address bits
    // [1:0] are ignored per the specification; aligned-PC enforcement lives
    // in the IF stage, not in imem.
    // -------------------------------------------------------------------------
    wire [ADDR_WIDTH-3:0] word_index = addr[ADDR_WIDTH-1:2];

    // -------------------------------------------------------------------------
    // Synchronous read. Output is registered on the rising edge of clk,
    // exactly as specified. No reset on the output register: power-up value
    // is whatever the FF resolves to in simulation, but the IF stage will
    // overwrite it on the very first cycle. If your design needs a known
    // value at t=0, add a synchronous reset here (matches the project rule
    // that all resets are synchronous).
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        instr <= mem[word_index];
    end

endmodule

`default_nettype wire
