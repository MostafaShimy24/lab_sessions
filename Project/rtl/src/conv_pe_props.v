//==============================================================================
// conv_pe_props.v — Standalone Conv-PE Formal Properties (Appendix A)
//------------------------------------------------------------------------------
// Week 1 re-run. All assertions + cover in one module, bound to conv_pe.
//==============================================================================
`timescale 1ns/1ps

module conv_pe_props #(
    parameter integer DATA_WIDTH   = 32,
    parameter integer ACCUM_WIDTH  = 32,
    parameter integer CONV_LATENCY = 4
) (
    input wire                   clk,
    input wire                   rst_n,
    input wire                   conv_start,
    input wire                   init,
    input wire [DATA_WIDTH-1:0]  operand_a,
    input wire [DATA_WIDTH-1:0]  operand_b,
    input wire                   conv_busy,
    input wire                   conv_done,
    input wire [ACCUM_WIDTH-1:0] conv_result,
    input wire [1:0]             conv_status
);
    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] BUSY = 2'b01;
    localparam [1:0] DONE = 2'b10;

    // Busy counter
    localparam CTR_W = 4;
    reg [CTR_W-1:0] busy_cnt;

    always @(posedge clk) begin
        if (!rst_n)
            busy_cnt <= {CTR_W{1'b0}};
        else if (conv_start && conv_status == IDLE)
            busy_cnt <= {CTR_W{1'b0}};
        else if (conv_busy)
            busy_cnt <= busy_cnt + 1'b1;
    end

    // ── All assertions in one block ───────────────────────────────────────────
    always @(posedge clk) begin
        if (rst_n) begin

            // FSM state validity
            FSM_LEGAL:           assert (conv_status != 2'b11);

            // Output signals match FSM state
            BUSY_SIGNAL:         assert (conv_busy == (conv_status == BUSY));
            DONE_SIGNAL:         assert (conv_done == (conv_status == DONE));

            // Transition rules: IDLE->BUSY->DONE->IDLE only
            CONV_FSM_IDLE_ENTRY: assert (
                (conv_status == IDLE && $past(conv_status) != IDLE) ?
                    ($past(conv_status) == DONE) : 1'b1
            );
            CONV_FSM_BUSY_ENTRY: assert (
                (conv_status == BUSY && $past(conv_status) != BUSY) ?
                    ($past(conv_status) == IDLE) : 1'b1
            );
            CONV_FSM_DONE_ENTRY: assert (
                (conv_status == DONE) ?
                    ($past(conv_status) == BUSY) : 1'b1
            );
            CONV_FSM_DONE_EXIT:  assert (
                ($past(conv_status) == DONE) ?
                    (conv_status == IDLE) : 1'b1
            );

            // Exactly CONV_LATENCY stall cycles per MAC
            STALL_COUNT: assert (
                conv_done ? (busy_cnt == CONV_LATENCY[CTR_W-1:0]) : 1'b1
            );

            // Result stable after done
            RESULT_STABLE: assert (
                ($past(conv_status) == DONE) ?
                    (conv_result == $past(conv_result)) : 1'b1
            );

        end
    end

    // ── Assume rst_n releases early for cover witness ─────────────────────────
    always @(posedge clk) begin
        RST_RELEASES: assume ($past(rst_n,2) || rst_n);
    end

    // ── Cover: conv_done reachable (produces VCD witness trace) ───────────────
    always @(posedge clk) begin
        if (rst_n) begin
            CONV_TERMINATES: cover (conv_done);
        end
    end

endmodule

//==============================================================================
// Bind to conv_pe
//==============================================================================
bind conv_pe conv_pe_props #(
    .DATA_WIDTH   (DATA_WIDTH),
    .ACCUM_WIDTH  (ACCUM_WIDTH),
    .CONV_LATENCY (CONV_LATENCY)
) u_props (
    .clk         (clk),
    .rst_n       (rst_n),
    .conv_start  (conv_start),
    .init        (init),
    .operand_a   (operand_a),
    .operand_b   (operand_b),
    .conv_busy   (conv_busy),
    .conv_done   (conv_done),
    .conv_result (conv_result),
    .conv_status (conv_status)
);