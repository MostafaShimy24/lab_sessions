//==============================================================================
// tb_if_stage.v — Self-Checking Testbench for if_stage
//------------------------------------------------------------------------------
// Tests:
//   TC1 — Reset: PC starts at 0x00000000 after reset
//   TC2 — Sequential fetch: PC increments by 4 each cycle
//   TC3 — pc_plus4_o tracks pc_if_o + 4
//   TC4 — Branch taken: PC jumps to branch_target, bubble inserted
//   TC5 — Jump taken (JAL/JALR): PC jumps to jump_target, bubble inserted
//   TC6 — Stall: PC and pc_if frozen while stall_i=1
//   TC7 — Flush during stall: flush overrides stall, loads target
//   TC8 — pc_fetch_o and pc_if_o are one cycle apart (alignment check)
//==============================================================================
`timescale 1ns / 1ps

module tb_if_stage;

    localparam CLK_PERIOD = 10;

    // ---- DUT ports ----------------------------------------------------------
    reg         clk, rst_n, stall_i, flush_i;
    reg  [1:0]  pc_src_i;
    reg  [31:0] branch_target_i, jump_target_i;
    reg  [31:0] instr_i;           // driven by test (models imem registered output)

    wire [31:0] pc_fetch_o;
    wire [31:0] pc_if_o;
    wire [31:0] pc_plus4_o;

    // ---- DUT ----------------------------------------------------------------
    if_stage dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .stall_i          (stall_i),
        .flush_i          (flush_i),
        .pc_src_i         (pc_src_i),
        .branch_target_i  (branch_target_i),
        .jump_target_i    (jump_target_i),
        .instr_i          (instr_i),
        .pc_fetch_o       (pc_fetch_o),
        .pc_if_o          (pc_if_o),
        .pc_plus4_o       (pc_plus4_o)
    );

    // ---- Clock --------------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ---- Helpers ------------------------------------------------------------
    integer pass_count, fail_count;

    task check32;
        input [31:0] got;
        input [31:0] expected;
        input [255:0] label;
        begin
            if (got === expected) begin
                $display("  PASS  %-48s  got=0x%08h", label, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL  %-48s  got=0x%08h  exp=0x%08h",
                         label, got, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Advance one cycle with current settings, then sample outputs
    task tick;
        begin
            @(posedge clk); #1;
        end
    endtask

    // =========================================================================
    initial begin
        $dumpfile("tb_if_stage.vcd");
        $dumpvars(0, tb_if_stage);
        pass_count = 0; fail_count = 0;

        // Default inputs
        rst_n           = 1'b0;
        stall_i         = 1'b0;
        flush_i         = 1'b0;
        pc_src_i        = 2'b00;
        branch_target_i = 32'h0000_0000;
        jump_target_i   = 32'h0000_0000;
        instr_i         = 32'h0000_0013;   // NOP

        // =====================================================================
        // TC1 — Reset
        // =====================================================================
        $display("\n=== TC1: Reset ===");
        repeat(2) @(posedge clk); #1;
        check32(pc_fetch_o, 32'h0000_0000, "pc_fetch_o = 0 during reset");
        check32(pc_if_o,    32'h0000_0000, "pc_if_o    = 0 during reset");

        // Release reset
        @(negedge clk); rst_n = 1'b1;

        // =====================================================================
        // TC2 — Sequential fetch: PC+4 every cycle
        // =====================================================================
        $display("\n=== TC2: Sequential fetch ===");
        // After reset release, PC = 0 fetching addr 0
        // Each tick: pc_fetch_o advances by 4
        tick; check32(pc_fetch_o, 32'h0000_0004, "pc_fetch after 1 tick = 0x4");
        tick; check32(pc_fetch_o, 32'h0000_0008, "pc_fetch after 2 ticks = 0x8");
        tick; check32(pc_fetch_o, 32'h0000_000C, "pc_fetch after 3 ticks = 0xC");

        // pc_if_o lags pc_fetch_o by one cycle
        // After 3 ticks: pc_fetch=0xC, pc_if should be 0x8
        check32(pc_if_o,    32'h0000_0008, "pc_if_o lags pc_fetch by 1 cycle");

        // =====================================================================
        // TC3 — pc_plus4_o = pc_if_o + 4
        // =====================================================================
        $display("\n=== TC3: pc_plus4_o = pc_if_o + 4 ===");
        // Currently pc_if_o = 0x8, so pc_plus4_o should be 0xC
        check32(pc_plus4_o, pc_if_o + 32'd4, "pc_plus4_o = pc_if_o + 4");
        tick;
        check32(pc_plus4_o, pc_if_o + 32'd4, "pc_plus4_o = pc_if_o + 4 (next)");

        // =====================================================================
        // TC4 — Branch taken: pc_src=01
        // =====================================================================
        $display("\n=== TC4: Branch taken (pc_src=2'b01) ===");
        // Record pc_fetch before branch
        @(negedge clk);
        pc_src_i        = 2'b01;
        flush_i         = 1'b1;
        branch_target_i = 32'h0000_0100;   // branch to 0x100

        @(posedge clk); #1;
        // PC should now be 0x100
        check32(pc_fetch_o, 32'h0000_0100, "pc_fetch jumps to branch target 0x100");
        // pc_if should have been flushed to NOP PC
        check32(pc_if_o,    32'h0000_0000, "pc_if_o = bubble PC after flush");

        // Clear branch controls
        @(negedge clk);
        pc_src_i = 2'b00;
        flush_i  = 1'b0;

        // Next tick: sequential from 0x100
        tick; check32(pc_fetch_o, 32'h0000_0104, "sequential from 0x100+4");

        // =====================================================================
        // TC5 — Jump taken: pc_src=10
        // =====================================================================
        $display("\n=== TC5: Jump taken (pc_src=2'b10) ===");
        @(negedge clk);
        pc_src_i      = 2'b10;
        flush_i       = 1'b1;
        jump_target_i = 32'h0000_0200;

        @(posedge clk); #1;
        check32(pc_fetch_o, 32'h0000_0200, "pc_fetch jumps to jump target 0x200");
        check32(pc_if_o,    32'h0000_0000, "pc_if_o = bubble after jump flush");

        @(negedge clk);
        pc_src_i = 2'b00;
        flush_i  = 1'b0;

        tick; check32(pc_fetch_o, 32'h0000_0204, "sequential from 0x200+4");

        // =====================================================================
        // TC6 — Stall: PC and pc_if frozen
        // =====================================================================
        $display("\n=== TC6: Stall freezes PC ===");
        // Let pipeline settle to known state
        repeat(2) tick;
        @(negedge clk);
        begin : stall_test
            reg [31:0] frozen_fetch, frozen_if;
            frozen_fetch = pc_fetch_o;
            frozen_if    = pc_if_o;

            stall_i = 1'b1;
            // Three stall cycles — PC must not move
            tick; check32(pc_fetch_o, frozen_fetch, "pc_fetch frozen cycle 1");
            tick; check32(pc_fetch_o, frozen_fetch, "pc_fetch frozen cycle 2");
            tick; check32(pc_fetch_o, frozen_fetch, "pc_fetch frozen cycle 3");
            check32(pc_if_o, frozen_if, "pc_if_o frozen during stall");

            stall_i = 1'b0;
            tick; check32(pc_fetch_o, frozen_fetch + 32'd4, "pc_fetch resumes after stall");
        end

        // =====================================================================
        // TC7 — Flush overrides stall
        // =====================================================================
        $display("\n=== TC7: Flush overrides stall ===");
        @(negedge clk);
        stall_i         = 1'b1;
        flush_i         = 1'b1;
        pc_src_i        = 2'b01;
        branch_target_i = 32'h0000_0400;

        @(posedge clk); #1;
        check32(pc_fetch_o, 32'h0000_0400, "flush overrides stall: PC=0x400");
        check32(pc_if_o,    32'h0000_0000, "bubble inserted after flush+stall");

        @(negedge clk);
        stall_i  = 1'b0;
        flush_i  = 1'b0;
        pc_src_i = 2'b00;

        // =====================================================================
        // TC8 — pc_fetch and pc_if alignment (one-cycle gap)
        // =====================================================================
        $display("\n=== TC8: pc_fetch and pc_if are one cycle apart ===");
        // Start from clean state
        @(negedge clk); rst_n = 1'b0;
        repeat(2) @(posedge clk);
        @(negedge clk); rst_n = 1'b1;

        begin : align_test
            reg [31:0] fetch0, fetch1, if0, if1;

            @(posedge clk); #1;
            fetch0 = pc_fetch_o;   // should be 0x4 (first cycle after reset)
            if0    = pc_if_o;      // should be 0x0 (one behind)

            tick;
            fetch1 = pc_fetch_o;   // 0x8
            if1    = pc_if_o;      // 0x4 = previous fetch0

            check32(if1, fetch0, "pc_if_o(N+1) == pc_fetch_o(N)");
        end

        // =====================================================================
        // Summary
        // =====================================================================
        $display("\n============================================");
        $display("  Results: %0d PASS   %0d FAIL", pass_count, fail_count);
        $display("============================================\n");
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("FAILURES DETECTED — review output above");

        $finish;
    end

    initial begin #50000; $display("WATCHDOG TIMEOUT"); $finish; end

endmodule