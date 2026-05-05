//==============================================================================
// tb_conv_pe.v — Self-Checking Directed Testbench for conv_pe
//------------------------------------------------------------------------------
// Tests:
//   TC1  — Reset behaviour: all outputs low/zero after rst_n de-asserted
//   TC2  — Init MAC (init=1): acc = a * b, conv_busy for exactly CONV_LATENCY
//           cycles, conv_done for exactly 1 cycle, correct result
//   TC3  — Accumulating MAC (init=0): acc += a * b (chains 3 MACs)
//   TC4  — Re-init mid-sequence (init=1 resets accumulator)
//   TC5  — Back-to-back instructions with NOPs between (pipeline stall model)
//   TC6  — Zero operand: result must be 0 on init, unchanged on accum
//   TC7  — conv_busy deasserted exactly on DONE, not before / not after
//==============================================================================
`timescale 1ns / 1ps

module tb_conv_pe;

    // ---- Parameters (must match DUT instantiation) -------------------------
    localparam DATA_WIDTH   = 32;
    localparam ACCUM_WIDTH  = 32;
    localparam CONV_LATENCY = 4;
    localparam CLK_PERIOD   = 10;   // 10 ns = 100 MHz

    // ---- DUT ports ---------------------------------------------------------
    reg                    clk;
    reg                    rst_n;
    reg                    conv_start;
    reg                    init;
    reg  [DATA_WIDTH-1:0]  operand_a;
    reg  [DATA_WIDTH-1:0]  operand_b;
    wire                   conv_busy;
    wire                   conv_done;
    wire [ACCUM_WIDTH-1:0] conv_result;
    wire [1:0]             conv_status;

    // ---- DUT instantiation -------------------------------------------------
    conv_pe #(
        .DATA_WIDTH   (DATA_WIDTH),
        .ACCUM_WIDTH  (ACCUM_WIDTH),
        .CONV_LATENCY (CONV_LATENCY)
    ) dut (
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

    // ---- Clock generator ---------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ---- Test utilities ----------------------------------------------------
    integer pass_count, fail_count;

    task check;
        input [63:0] got;
        input [63:0] expected;
        input [127:0] label;
        begin
            if (got === expected) begin
                $display("  PASS  %-40s  got=%0d", label, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL  %-40s  got=%0d  expected=%0d", label, got, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Issue one MAC instruction and wait until DONE returns to IDLE.
    // Returns the conv_result captured at conv_done.
    // Also checks that conv_busy lasted exactly CONV_LATENCY cycles.
    task issue_mac;
        input [DATA_WIDTH-1:0]  a;
        input [DATA_WIDTH-1:0]  b;
        input                   i_init;
        output [ACCUM_WIDTH-1:0] result_out;
        integer busy_count;
        begin
            busy_count = 0;
            @(negedge clk);         // set up inputs before rising edge
            conv_start = 1'b1;
            operand_a  = a;
            operand_b  = b;
            init       = i_init;
            @(negedge clk);         // one cycle: conv_start seen, enter BUSY
            conv_start = 1'b0;

            // Count BUSY cycles
            while (conv_busy) begin
                busy_count = busy_count + 1;
                @(negedge clk);
            end

            // Should be in DONE now (conv_busy just went low)
            result_out = conv_result;

            check(busy_count, CONV_LATENCY, "busy_count == CONV_LATENCY");

            @(negedge clk);         // DONE → IDLE transition
        end
    endtask

    // ---- Stimulus ----------------------------------------------------------
    integer i;
    reg [ACCUM_WIDTH-1:0] r;
    reg [ACCUM_WIDTH-1:0] expected_acc;

    initial begin
        $dumpfile("tb_conv_pe.vcd");
        $dumpvars(0, tb_conv_pe);

        pass_count = 0;
        fail_count = 0;

        // Default inputs
        rst_n      = 1'b0;
        conv_start = 1'b0;
        init       = 1'b0;
        operand_a  = 32'h0;
        operand_b  = 32'h0;

        // ---- TC1 Reset -------------------------------------------------------
        $display("\n=== TC1: Reset behaviour ===");
        repeat (3) @(posedge clk);
        #1;
        check(conv_busy,   0, "conv_busy == 0 during reset");
        check(conv_done,   0, "conv_done == 0 during reset");
        check(conv_result, 0, "conv_result == 0 during reset");
        check(conv_status, 2'b00, "conv_status == IDLE during reset");

        @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);
        check(conv_busy,   0, "conv_busy == 0 after reset release");
        check(conv_status, 2'b00, "conv_status == IDLE after reset release");

        // ---- TC2 Init MAC ----------------------------------------------------
        $display("\n=== TC2: Init MAC (init=1), a=5, b=6 => result=30 ===");
        issue_mac(32'd5, 32'd6, 1'b1, r);
        check(r, 32'd30, "init MAC: 5*6 = 30");
        check(conv_done, 0, "conv_done low after DONE→IDLE");
        check(conv_busy, 0, "conv_busy low after DONE→IDLE");

        // ---- TC3 Accumulating MACs ------------------------------------------
        $display("\n=== TC3: Accumulate 3 MACs: 3*4 + 2*5 + 1*7 = 12+10+7 = 29 ===");
        // First MAC initialises (init=1)
        issue_mac(32'd3, 32'd4, 1'b1, r);
        check(r, 32'd12, "accum chain step1: 3*4 = 12");

        // Second MAC accumulates
        issue_mac(32'd2, 32'd5, 1'b0, r);
        check(r, 32'd22, "accum chain step2: 12 + 2*5 = 22");

        // Third MAC accumulates
        issue_mac(32'd1, 32'd7, 1'b0, r);
        check(r, 32'd29, "accum chain step3: 22 + 1*7 = 29");

        // ---- TC4 Re-init mid-sequence ----------------------------------------
        $display("\n=== TC4: Re-init with init=1 clears previous accumulator ===");
        issue_mac(32'd10, 32'd10, 1'b1, r);
        check(r, 32'd100, "re-init: 10*10 = 100 (not 100+29)");

        // ---- TC5 Back-to-back with 0-cycle gap (NOPs handled by pipeline) ---
        $display("\n=== TC5: Two back-to-back MACs ===");
        issue_mac(32'd7, 32'd3, 1'b1, r);
        check(r, 32'd21, "back-to-back step1: 7*3 = 21");
        issue_mac(32'd4, 32'd4, 1'b0, r);
        check(r, 32'd37, "back-to-back step2: 21 + 4*4 = 37");

        // ---- TC6 Zero operand -----------------------------------------------
        $display("\n=== TC6: Zero operand ===");
        issue_mac(32'd0, 32'd99, 1'b1, r);
        check(r, 32'd0, "init with a=0: 0*99 = 0");
        issue_mac(32'd0, 32'd99, 1'b0, r);
        check(r, 32'd0, "accum with a=0: 0 + 0*99 = 0");

        // ---- TC7 conv_done width (exactly 1 cycle) --------------------------
        $display("\n=== TC7: conv_done is exactly 1 cycle wide ===");
        @(negedge clk);
        conv_start = 1'b1;
        operand_a  = 32'd2;
        operand_b  = 32'd3;
        init       = 1'b1;
        @(negedge clk);
        conv_start = 1'b0;

        // Wait until conv_done rises
        while (!conv_done) @(negedge clk);
        check(conv_done, 1, "conv_done asserted");

        @(negedge clk);
        check(conv_done, 0, "conv_done deasserted after 1 cycle");
        check(conv_busy, 0, "conv_busy low after DONE");

        // ---- Final summary ---------------------------------------------------
        $display("\n====================================================");
        $display("  Results: %0d PASS,  %0d FAIL", pass_count, fail_count);
        $display("====================================================\n");

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("FAILURES DETECTED — review output above");

        $finish;
    end

    // Watchdog — abort if stuck
    initial begin
        #(CLK_PERIOD * 2000);
        $display("WATCHDOG TIMEOUT");
        $finish;
    end

endmodule