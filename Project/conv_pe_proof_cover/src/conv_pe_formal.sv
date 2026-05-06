//==============================================================================
// conv_pe_formal.sv — Standalone Conv-PE Formal Properties (Appendix A)
//------------------------------------------------------------------------------
// Week 1 re-run. 9 assertions + CONV_TERMINATES cover on conv_pe in isolation.
//==============================================================================
`timescale 1ns/1ps

module conv_pe_formal #(
    parameter integer DATA_WIDTH   = 32,
    parameter integer ACCUM_WIDTH  = 32,
    parameter integer CONV_LATENCY = 4
)(
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
    localparam [1:0] IDLE=2'b00,BUSY=2'b01,DONE=2'b10;
    localparam CTR_W = 4;

    reg [CTR_W-1:0] busy_cnt;
    always @(posedge clk) begin
        if (!rst_n)                               busy_cnt<={CTR_W{1'b0}};
        else if (conv_start && conv_status==IDLE) busy_cnt<={CTR_W{1'b0}};
        else if (conv_busy)                       busy_cnt<=busy_cnt+1'b1;
    end

    reg seen_start;
    always @(posedge clk) begin
        if (!rst_n)        seen_start<=1'b0;
        else if (conv_start) seen_start<=1'b1;
    end

    // Assumptions
    always @(posedge clk) begin if($past(rst_n)) assume(rst_n); end
    always @(posedge clk) begin if(rst_n) assume(rst_n); end
    always @(posedge clk) begin
        if(rst_n && conv_status==IDLE && !seen_start) assume(conv_start);
    end

    // Assertions
    always @(posedge clk) begin
        if (rst_n) begin
            FSM_LEGAL:           assert(conv_status != 2'b11);
            BUSY_SIGNAL:         assert(conv_busy == (conv_status==BUSY));
            DONE_SIGNAL:         assert(conv_done == (conv_status==DONE));
            STALL_COUNT:         assert(conv_done?(busy_cnt==CONV_LATENCY[CTR_W-1:0]):1'b1);
            CONV_FSM_IDLE_ENTRY: assert(
                (conv_status==IDLE&&$past(conv_status)!=IDLE)?($past(conv_status)==DONE):1'b1);
            CONV_FSM_BUSY_ENTRY: assert(
                (conv_status==BUSY&&$past(conv_status)!=BUSY)?($past(conv_status)==IDLE):1'b1);
            CONV_FSM_DONE_ENTRY: assert(
                (conv_status==DONE)?($past(conv_status)==BUSY):1'b1);
            CONV_FSM_DONE_EXIT:  assert(
                ($past(conv_status)==DONE)?(conv_status==IDLE):1'b1);
            RESULT_STABLE:       assert(
                ($past(conv_status)==DONE)?(conv_result==$past(conv_result)):1'b1);
        end
    end

    // Cover
    always @(posedge clk) begin
        if (rst_n) CONV_TERMINATES: cover(seen_start && conv_done);
    end
endmodule

bind conv_pe conv_pe_formal #(
    .DATA_WIDTH(DATA_WIDTH),.ACCUM_WIDTH(ACCUM_WIDTH),.CONV_LATENCY(CONV_LATENCY)
) u_formal (
    .clk(clk),.rst_n(rst_n),.conv_start(conv_start),.init(init),
    .operand_a(operand_a),.operand_b(operand_b),
    .conv_busy(conv_busy),.conv_done(conv_done),
    .conv_result(conv_result),.conv_status(conv_status)
);