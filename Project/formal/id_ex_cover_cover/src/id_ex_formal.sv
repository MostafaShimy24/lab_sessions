//==============================================================================
// id_ex_formal.sv — Liveness Cover Properties (Phase 1)
//==============================================================================

`timescale 1ns/1ps

module id_ex_formal #(
    parameter integer CONV_LATENCY = 4,
    parameter integer DATA_WIDTH   = 32,
    parameter integer ACCUM_WIDTH  = 32
)(
    input wire        clk,
    input wire        rst_n,

    input wire        ex_reg_write,
    input wire [4:0]  ex_rd_addr,

    input wire        conv_done,
    input wire        conv_start_pulse,

    input wire        stall,
    input wire        flush,

    input wire        instr_in_id,
    input wire [31:0] instr_i
);

    // =========================================================================
    // LOCAL CONSTANTS
    // =========================================================================
    localparam [31:0] NOP        = 32'h00000013;
    localparam [31:0] ADDI_X1    = 32'h00100093;
    localparam [31:0] CONV_INIT  = 32'h0220818b;

    // =========================================================================
    // CYCLE COUNTER
    // =========================================================================
    reg [5:0] cycle_count;

    always @(posedge clk) begin
        if (!rst_n)
            cycle_count <= 6'd0;
        else
            cycle_count <= cycle_count + 6'd1;
    end

    // =========================================================================
    // HISTORY FLAGS
    // =========================================================================
    reg seen_instr;

    always @(posedge clk) begin
        if (!rst_n)
            seen_instr <= 1'b0;
        else if (instr_in_id)
            seen_instr <= 1'b1;
    end

    reg seen_conv_start;

    always @(posedge clk) begin
        if (!rst_n)
            seen_conv_start <= 1'b0;
        else if (conv_start_pulse)
            seen_conv_start <= 1'b1;
    end

    // =========================================================================
    // ASSUMPTIONS
    // =========================================================================

    // Hold reset low for first 2 cycles
    always @(posedge clk) begin
        if (cycle_count < 6'd2)
            assume(!rst_n);
        else
            assume(rst_n);
    end

    // Controlled instruction stream
    always @(posedge clk) begin

        if (rst_n && !seen_instr)
            assume(instr_i == ADDI_X1);

        else if (rst_n && seen_instr && !seen_conv_start)
            assume(instr_i == CONV_INIT);

        else if (rst_n)
            assume(instr_i == NOP);

    end

    // =========================================================================
    // COVER PROPERTIES
    // =========================================================================

    // -------------------------------------------------------------------------
    // P7: INSTR_PROGRESS
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst_n) begin
            cover(
                seen_instr &&
                ex_reg_write &&
                (ex_rd_addr != 5'd0) &&
                (cycle_count >= 6'd6)
            );
        end
    end

    // -------------------------------------------------------------------------
    // P8: CONV_TERMINATES
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst_n) begin
            cover(
                seen_conv_start &&
                conv_done &&
                (cycle_count >= (CONV_LATENCY + 6))
            );
        end
    end


`ifdef FORMAL

id_ex_formal #(
    .CONV_LATENCY(CONV_LATENCY),
    .DATA_WIDTH(DATA_WIDTH),
    .ACCUM_WIDTH(ACCUM_WIDTH)
) u_formal (

    .clk(clk),
    .rst_n(rst_n),

    .ex_reg_write(ex_reg_write),
    .ex_rd_addr(ex_rd_addr),

    .conv_done(conv_done),
    .conv_start_pulse(conv_start_pulse),

    .stall(stall),
    .flush(flush),

    .instr_in_id(instr_in_id),
    .instr_i(instr_i)
);

`endif

endmodule

