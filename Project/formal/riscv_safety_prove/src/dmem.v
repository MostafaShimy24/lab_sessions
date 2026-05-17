//==============================================================================
// dmem.v — Data Memory (holds general data, CNN weights, and feature-map tile)
//------------------------------------------------------------------------------
// Project : ELCT1005 PROJ02 — Pipelined RISC-V CPU with Conv-PE
// Spec    : 4 KB, Harvard architecture.
//           Synchronous write, asynchronous combinational read.
//           Supports byte (SB / LB / LBU), half-word (SH / LH / LHU), and
//           full-word (SW / LW) accesses.
//
// Notes for students:
//   - This file is provided as a working starting point and is NOT locked.
//     You may modify it to suit your pipeline interface, change depth, add
//     additional initialisation regions for weights vs feature-map tiles, etc.
//
//   - Conv-PE interaction: the document spec says the Conv-PE owns the dmem
//     read port while it is BUSY. dmem itself takes a single raddr; the
//     2:1 mux selecting between the EX-stage effective address and the
//     Conv-PE's internal read pointer lives in the MEM stage wrapper
//     (mem_stage.v), driven by conv_busy. This module does not need to
//     know about the Conv-PE at all.
//
//   - Suggested layout (you decide the exact split, document it in the
//     project report):
//        0x0000 - 0x07FF   general data / stack
//        0x0800 - 0x0BFF   CNN kernel weights
//        0x0C00 - 0x0FFF   input feature-map tile
//
//   - DFT / scan: implemented as a flat reg array, not a vendor RAM
//     primitive, so every bit becomes a scan flop in Phase 4.
//------------------------------------------------------------------------------
// Ports (per project specification):
//   Write side (synchronous, used by SB / SH / SW in MEM stage):
//     clk           1-bit, rising edge
//     we            1-bit write enable (active high)
//     wsize[1:0]    00 = byte, 01 = half-word, 10 = word, 11 = reserved
//     waddr[31:0]   byte address
//     wdata[31:0]   write data, right-justified (low byte / low half / full word)
//
//   Read side (asynchronous combinational, used by LB/LH/LW/LBU/LHU and Conv-PE):
//     raddr[31:0]   byte address
//     rsize[1:0]    00 = byte, 01 = half-word, 10 = word, 11 = reserved
//     sign_ext      1 = sign-extend (LB / LH), 0 = zero-extend (LBU / LHU)
//                   For word reads (rsize=10) sign_ext is don't-care.
//     rdata[31:0]   read data, sign- or zero-extended into 32 bits
//==============================================================================
`timescale 1ns / 1ps
`default_nettype none

module dmem #(
    parameter integer DEPTH_BYTES = 4096,           // 4 KB
    parameter integer ADDR_WIDTH  = 12,             // log2(DEPTH_BYTES) = 12
    parameter         HEX_FILE    = "data.hex",     // optional pre-load
    parameter [31:0]  ZERO_FILL   = 32'h00000000    // power-up word value
) (
    // Clock
    input  wire        clk,

    // Write port
    input  wire        we,
    input  wire [1:0]  wsize,
    input  wire [31:0] waddr,
    input  wire [31:0] wdata,

    // Read port (combinational)
    input  wire [31:0] raddr,
    input  wire [1:0]  rsize,
    input  wire        sign_ext,
    output reg  [31:0] rdata
);

    // -------------------------------------------------------------------------
    // Storage organised as bytes for clean SB / SH / SW support without
    // read-modify-write quirks. Word reads gather four bytes; halfword reads
    // gather two; byte reads are direct.
    // -------------------------------------------------------------------------
    reg [7:0] mem [0:DEPTH_BYTES-1];

    // Sub-ranges of the address used as indices
    wire [ADDR_WIDTH-1:0] w_idx = waddr[ADDR_WIDTH-1:0];
    wire [ADDR_WIDTH-1:0] r_idx = raddr[ADDR_WIDTH-1:0];

    // -------------------------------------------------------------------------
    // Initialisation. Default all bytes to zero, then optionally load a hex
    // file. Note: $readmemh on a byte array expects one byte per line in the
    // hex file. Students who prefer word-organised hex files should provide a
    // word-array version of this module instead (one of the documented
    // permitted modifications).
    // -------------------------------------------------------------------------
    integer i;
    initial begin
        for (i = 0; i < DEPTH_BYTES; i = i + 1) begin
            mem[i] = 8'h00;
        end
        $readmemh(HEX_FILE, mem);
        // Touch ZERO_FILL just to keep lint quiet if students do not use it.
        // synthesis_translate_off
        if (ZERO_FILL !== 32'h00000000) begin
            // Optional: word-fill pattern. Off by default.
        end
        // synthesis_translate_on
    end

    // =========================================================================
    // SYNCHRONOUS WRITE
    //   wsize = 00: write the low byte of wdata to mem[w_idx]
    //   wsize = 01: write the low halfword (wdata[15:0]) to mem[w_idx +: 2]
    //   wsize = 10: write the full word (wdata[31:0]) to mem[w_idx +: 4]
    // The MEM stage is responsible for presenting an aligned address; this
    // module does not check alignment (matches the original spec, which
    // delegates alignment to the pipeline).
    // =========================================================================
    always @(posedge clk) begin
        if (we) begin
            case (wsize)
                2'b00: begin // SB
                    mem[w_idx] <= wdata[7:0];
                end
                2'b01: begin // SH (little-endian: low byte at lower address)
                    mem[w_idx + 0] <= wdata[7:0];
                    mem[w_idx + 1] <= wdata[15:8];
                end
                2'b10: begin // SW
                    mem[w_idx + 0] <= wdata[7:0];
                    mem[w_idx + 1] <= wdata[15:8];
                    mem[w_idx + 2] <= wdata[23:16];
                    mem[w_idx + 3] <= wdata[31:24];
                end
                default: begin
                    // wsize = 11 is reserved / illegal. Do nothing; the
                    // covergroup in Phase 2 will not exercise this case.
                end
            endcase
        end
    end

    // =========================================================================
    // ASYNCHRONOUS COMBINATIONAL READ
    //   rsize = 00, sign_ext = 1 -> LB
    //   rsize = 00, sign_ext = 0 -> LBU
    //   rsize = 01, sign_ext = 1 -> LH
    //   rsize = 01, sign_ext = 0 -> LHU
    //   rsize = 10                -> LW (sign_ext don't-care)
    //
    // CRITICAL: a default assignment to rdata at the top of the always block
    // prevents latch inference. Phase 3 treats inferred latches as a hard
    // fail.
    // =========================================================================
    wire [7:0]  rd_byte = mem[r_idx];
    wire [15:0] rd_half = { mem[r_idx + 1], mem[r_idx + 0] };
    wire [31:0] rd_word = { mem[r_idx + 3], mem[r_idx + 2],
                            mem[r_idx + 1], mem[r_idx + 0] };

    always @* begin
        rdata = 32'h00000000;       // default — kills latch inference
        case (rsize)
            2'b00: begin // byte
                rdata = sign_ext ? {{24{rd_byte[7]}},  rd_byte}     // LB
                                 : {24'b0,            rd_byte};    // LBU
            end
            2'b01: begin // halfword
                rdata = sign_ext ? {{16{rd_half[15]}}, rd_half}     // LH
                                 : {16'b0,            rd_half};    // LHU
            end
            2'b10: begin // word
                rdata = rd_word;                                    // LW
            end
            default: begin
                rdata = 32'h00000000;                               // reserved
            end
        endcase
    end

endmodule

`default_nettype wire
