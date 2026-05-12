//==============================================================================
// conv_pe.v — Convolution Processing Element (Multi-Cycle MAC Unit)
//------------------------------------------------------------------------------
// Project : ELCT1005 PROJ02 — Pipelined RISC-V CPU with Conv-PE
// Replaces : Lab Week 1 verified black-box (re-implemented generically here)
//
// Function:
//   Performs one multiply-accumulate (MAC) step per custom-0 instruction:
//     init=0  →  acc ← acc + (operand_a × operand_b)   [accumulating MAC]
//     init=1  →  acc ←        operand_a × operand_b    [initialising MAC]
//   The result (current accumulator value) is written back to RD through
//   the WB 3:1 mux after CONV_LATENCY cycles.
//
// Parameters:
//   DATA_WIDTH    Width of each input operand (default 32).
//                 Operands are typically INT8/INT16 values sign- or zero-
//                 extended to DATA_WIDTH by preceding LB/LBU/LH/LHU/LW.
//   ACCUM_WIDTH   Width of the internal accumulator and conv_result output
//                 (default 32). Must be ≥ DATA_WIDTH. Overflow wraps modulo
//                 2^ACCUM_WIDTH (no saturation — document in project report).
//   CONV_LATENCY  Number of BUSY cycles per MAC instruction (default 4).
//                 Carried into the Phase 1 formal properties (CONV_STALL_COUNT,
//                 CONV_RESULT_STABLE). Must be ≥ 1.
//
// FSM (3 states — formally proven by CONV_FSM property in Phase 1):
//   IDLE  (2'b00) → waits for conv_start
//   BUSY  (2'b01) → counts CONV_LATENCY cycles, asserts conv_busy (stall)
//   DONE  (2'b10) → one-cycle pulse: asserts conv_done, latches result,
//                   returns to IDLE next cycle
//
// Pipeline interface:
//   conv_start  : single-cycle dispatch pulse from EX decode (opcode==custom-0)
//   init        : funct7[0] from the instruction word
//   operand_a   : RS1 value from ID/EX register (feature-map element)
//   operand_b   : RS2 value from ID/EX register (weight element)
//   conv_busy   : high during BUSY → freezes all pipeline stages
//   conv_done   : one-cycle high in DONE → EX/MEM register captures conv_result
//   conv_result : current accumulator value (valid when conv_done is high)
//   conv_status : raw FSM state for monitoring / formal properties
//
// Implementation notes:
//   - All resets are synchronous (active-low rst_n) — project-wide rule.
//   - No combinational paths from operands to outputs (fully registered MAC).
//   - The multiplier is registered at the start of BUSY, giving synthesis
//     freedom to pipeline the multiply across the CONV_LATENCY cycles.
//   - Overflow wraps modulo 2^ACCUM_WIDTH — project report must document this.
//   - No memory port: operands come from the register file exactly like ALU.
//==============================================================================
`timescale 1ns / 1ps
`default_nettype none

module conv_pe #(
    parameter integer DATA_WIDTH   = 32,   // operand width (INT8/16/32 extended)
    parameter integer ACCUM_WIDTH  = 32,   // accumulator / result width
    parameter integer CONV_LATENCY = 4     // busy cycles per MAC (≥ 1)
) (
    input  wire                    clk,
    input  wire                    rst_n,       // active-low synchronous reset

    // Dispatch interface (from EX stage decode)
    input  wire                    conv_start,  // 1-cycle high when custom-0 issued
    input  wire                    init,        // funct7[0]: 1=init MAC, 0=accum MAC

    // Operands (from ID/EX pipeline register)
    input  wire [DATA_WIDTH-1:0]   operand_a,   // RS1 — feature-map element
    input  wire [DATA_WIDTH-1:0]   operand_b,   // RS2 — weight element

    // Status & result
    output wire                    conv_busy,   // stall all pipeline stages
    output wire                    conv_done,   // 1-cycle pulse: result is valid
    output wire [ACCUM_WIDTH-1:0]  conv_result, // accumulator → WB mux
    output wire [1:0]              conv_status  // raw FSM state for formal props
);

    // =========================================================================
    // FSM state encoding
    // =========================================================================
    localparam [1:0] IDLE = 2'b00,
                     BUSY = 2'b01,
                     DONE = 2'b10;

    // =========================================================================
    // Internal registers
    // =========================================================================
    reg [1:0]              state_r;          // FSM state
    reg [ACCUM_WIDTH-1:0]  accum_r;          // running accumulator
    reg [ACCUM_WIDTH-1:0]  result_r;         // held result (stable through DONE)

    // Latency counter — counts up from 0 to CONV_LATENCY-1
    // Width is log2(CONV_LATENCY)+1 to avoid overflow for any parameter value
    localparam CTR_W = $clog2(CONV_LATENCY + 1) + 1;
    reg [CTR_W-1:0] cnt_r;

    // Registered copies of operands captured at the start of BUSY — isolates
    // the MAC from combinational glitch on operand_a/b after ID/EX moves on.
    reg [DATA_WIDTH-1:0]   op_a_r;
    reg [DATA_WIDTH-1:0]   op_b_r;
    reg                    init_r;           // registered init flag

    // =========================================================================
    // MAC compute — registered product, accumulates into accum_r.
    // Using ACCUM_WIDTH-wide multiply (lower ACCUM_WIDTH bits of the product).
    // Overflow wraps modulo 2^ACCUM_WIDTH — document in project report.
    // =========================================================================
    wire [ACCUM_WIDTH-1:0] product;
    assign product = op_a_r[ACCUM_WIDTH-1:0] * op_b_r[ACCUM_WIDTH-1:0];

    // =========================================================================
    // FSM + datapath — single synchronous always block
    // =========================================================================
    always @(posedge clk) begin
        if (!rst_n) begin
            // ---- Synchronous reset -------------------------------------------
            state_r  <= IDLE;
            accum_r  <= {ACCUM_WIDTH{1'b0}};
            result_r <= {ACCUM_WIDTH{1'b0}};
            cnt_r    <= {CTR_W{1'b0}};
            op_a_r   <= {DATA_WIDTH{1'b0}};
            op_b_r   <= {DATA_WIDTH{1'b0}};
            init_r   <= 1'b0;
        end else begin
            case (state_r)

                // ---- IDLE ---------------------------------------------------
                // Wait for a dispatch pulse. On conv_start, capture operands
                // and transition to BUSY.
                IDLE: begin
                    if (conv_start) begin
                        op_a_r  <= operand_a;
                        op_b_r  <= operand_b;
                        init_r  <= init;
                        cnt_r   <= {CTR_W{1'b0}};
                        state_r <= BUSY;
                    end
                end

                // ---- BUSY ---------------------------------------------------
                // Assert conv_busy (stall) for exactly CONV_LATENCY cycles.
                // On the last cycle compute the MAC result and move to DONE.
                BUSY: begin
                    if (cnt_r == {{(CTR_W-1){1'b0}}, 1'b1} * (CONV_LATENCY - 1)) begin
                        // Final busy cycle — compute and latch result
                        if (init_r)
                            result_r <= product;                  // init:  acc = a*b
                        else
                            result_r <= accum_r + product;        // accum: acc += a*b

                        state_r <= DONE;
                    end else begin
                        cnt_r <= cnt_r + 1'b1;
                    end
                end

                // ---- DONE ---------------------------------------------------
                // Single-cycle pulse: conv_done is high, result is stable.
                // Update the persistent accumulator and return to IDLE.
                DONE: begin
                    accum_r <= result_r;   // keep accumulator updated
                    state_r <= IDLE;
                end

                // ---- Default (unreachable — CONV_FSM formal prop proves this)
                default: state_r <= IDLE;

            endcase
        end
    end

    // =========================================================================
    // Output assignments (combinational from state register)
    // =========================================================================
    assign conv_busy   = (state_r == BUSY);
    assign conv_done   = (state_r == DONE);
    assign conv_result = result_r;          // stable from DONE until next conv_start
    assign conv_status = state_r;

endmodule

`default_nettype wire