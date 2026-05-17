//==============================================================================
// alu.v — RV32I Execute-Stage ALU
//------------------------------------------------------------------------------
// Project : ELCT1005 PROJ02 — Pipelined RISC-V CPU with Conv-PE
// Spec    : Purely combinational (no clock, no reset, no internal state).
//           Result ready within the same cycle operands are presented.
//           Must meet 10 ns timing (100 MHz) for STA closure in Phase 3.
//
// Inputs  (68 bits total):
//   operand_a[31:0]  — from rs1_data (ID/EX pipeline register)
//   operand_b[31:0]  — from rs2_data OR sign-extended immediate (upstream mux)
//   alu_op[3:0]      — decoded by ID stage from funct7 / funct3 / opcode
//
// Outputs (33 bits total):
//   alu_result[31:0] — operation result; feeds EX/MEM register, dmem addr,
//                      and WB result mux
//   zero             — (alu_result == 0); used by branch comparator for
//                      BEQ/BNE and as input to BLT/BGE/BLTU/BGEU logic
//
// alu_op Encoding (per spec):
//   4'b0000 = ADD     4'b0001 = SUB     4'b0010 = SLL
//   4'b0011 = SLT     4'b0100 = SLTU    4'b0101 = XOR
//   4'b0110 = SRL     4'b0111 = SRA     4'b1000 = OR
//   4'b1001 = AND
//   4'b1010–4'b1111  reserved → default to ADD (safe for eff-addr calc)
//
// Notes:
//   - Pure combinational: always @* with a mandatory default assignment
//     to alu_result prevents latch inference (hard fail in Phase 3).
//   - PC adders (PC+4 in IF, PC+branch_offset in EX) are separate dedicated
//     adders in their respective stage files — NOT implemented here.
//   - SLT / SLTU produce a 1-bit result zero-extended to 32 bits, matching
//     the RV32I SLTI/SLTIU/SLT/SLTU semantics.
//   - SLL / SRL / SRA use only the lower 5 bits of operand_b (shamt).
//   - SRA is arithmetic right shift — Verilog >>> on a signed cast.
//==============================================================================
`timescale 1ns / 1ps
`default_nettype none

module alu (
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [3:0]  alu_op,

    output reg  [31:0] alu_result,
    output wire        zero
);

    // -------------------------------------------------------------------------
    // Shift amount — lower 5 bits of operand_b per RV32I spec.
    // -------------------------------------------------------------------------
    wire [4:0] shamt = operand_b[4:0];

    // -------------------------------------------------------------------------
    // Signed views of operands needed for SLT and SRA.
    // -------------------------------------------------------------------------
    wire signed [31:0] signed_a = $signed(operand_a);
    wire signed [31:0] signed_b = $signed(operand_b);

    // -------------------------------------------------------------------------
    // Combinational ALU body.
    // Default assignment at the top of always @* eliminates latch inference.
    // All 10 operations plus a catch-all default for reserved codes.
    // -------------------------------------------------------------------------
    always @* begin
        alu_result = 32'h00000000;          // default — prevents latch

        case (alu_op)
            4'b0000: alu_result = operand_a + operand_b;                    // ADD
            4'b0001: alu_result = operand_a - operand_b;                    // SUB
            4'b0010: alu_result = operand_a << shamt;                       // SLL
            4'b0011: alu_result = (signed_a < signed_b) ? 32'd1 : 32'd0;   // SLT
            4'b0100: alu_result = (operand_a < operand_b) ? 32'd1 : 32'd0; // SLTU
            4'b0101: alu_result = operand_a ^ operand_b;                    // XOR
            4'b0110: alu_result = operand_a >> shamt;                       // SRL
            4'b0111: alu_result = signed_a >>> shamt;                       // SRA
            4'b1000: alu_result = operand_a | operand_b;                    // OR
            4'b1001: alu_result = operand_a & operand_b;                    // AND
            // Reserved codes 4'b1010–4'b1111 → ADD (safe identity for eff-addr calc)
            default: alu_result = operand_a + operand_b;
        endcase
    end

    // -------------------------------------------------------------------------
    // Zero flag — driven combinationally from alu_result.
    // Consumed by the branch comparator in EX stage:
    //   BEQ  : taken if  zero
    //   BNE  : taken if !zero
    //   BLT  : SUB result sign bit (bit 31 of alu_result when alu_op=SUB)
    //   BGE  : zero | ~sign bit
    //   BLTU : carry from unsigned SUB (handled in ex_stage.v comparator)
    //   BGEU : same
    // -------------------------------------------------------------------------
    assign zero = (alu_result == 32'h00000000);

endmodule

`default_nettype wire