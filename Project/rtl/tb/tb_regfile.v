//==============================================================================
// tb_regfile.v — Self-Checking Directed Testbench for regfile
//------------------------------------------------------------------------------
// Tests:
//   TC1 — Reset: all registers read 0 after rst_n de-asserted
//   TC2 — x0 hardwired to 0: write non-zero to x0, read back must be 0
//   TC3 — Basic write / read: write unique value to every register x1–x31
//   TC4 — Both read ports simultaneously: rs1 and rs2 read different regs
//   TC5 — Write enable gate: we=0 must not change register contents
//   TC6 — Async read same cycle as write: read port sees OLD value
//          (write is synchronous — new value visible one cycle later)
//   TC7 — Synchronous reset clears all: write to several regs, assert
//          rst_n=0 for one cycle, all registers must return to 0
//   TC8 — Write port priority: two consecutive writes to the same register,
//          second write wins
//==============================================================================
`timescale 1ns / 1ps

module tb_regfile;

    localparam CLK_PERIOD = 10;

    // ---- DUT ports ----------------------------------------------------------
    reg        clk, rst_n, we;
    reg  [4:0] rs1_addr, rs2_addr, rd_addr;
    reg  [31:0] rd_data;
    wire [31:0] rs1_data, rs2_data;

    // ---- DUT ----------------------------------------------------------------
    regfile dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .rs1_addr (rs1_addr),
        .rs2_addr (rs2_addr),
        .rs1_data (rs1_data),
        .rs2_data (rs2_data),
        .we       (we),
        .rd_addr  (rd_addr),
        .rd_data  (rd_data)
    );

    // ---- Clock --------------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ---- Helpers ------------------------------------------------------------
    integer pass_count, fail_count;

    task check;
        input [31:0] got;
        input [31:0] expected;
        input [255:0] label;
        begin
            if (got === expected) begin
                $display("  PASS  %-45s  got=0x%08h", label, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL  %-45s  got=0x%08h  exp=0x%08h",
                         label, got, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Write one register and wait one cycle for the write to land
    task write_reg;
        input [4:0]  addr;
        input [31:0] data;
        begin
            @(negedge clk);
            we      = 1'b1;
            rd_addr = addr;
            rd_data = data;
            @(negedge clk);
            we      = 1'b0;
            rd_addr = 5'd0;
            rd_data = 32'h0;
        end
    endtask

    // Read register via rs1 port (combinational — valid immediately)
    task read_rs1;
        input  [4:0]  addr;
        output [31:0] data;
        begin
            rs1_addr = addr;
            #1;                 // tiny delta so combinational output settles
            data = rs1_data;
        end
    endtask

    // Read register via rs2 port
    task read_rs2;
        input  [4:0]  addr;
        output [31:0] data;
        begin
            rs2_addr = addr;
            #1;
            data = rs2_data;
        end
    endtask

    // =========================================================================
    integer i;
    reg [31:0] r1, r2;

    initial begin
        $dumpfile("tb_regfile.vcd");
        $dumpvars(0, tb_regfile);

        pass_count = 0;
        fail_count = 0;

        // Default inputs
        rst_n    = 1'b0;
        we       = 1'b0;
        rs1_addr = 5'd0;
        rs2_addr = 5'd0;
        rd_addr  = 5'd0;
        rd_data  = 32'h0;

        // =====================================================================
        // TC1 — Reset: every register reads 0
        // =====================================================================
        $display("\n=== TC1: Reset — all registers read 0 ===");
        repeat(3) @(posedge clk);
        for (i = 0; i < 32; i = i + 1) begin
            read_rs1(i[4:0], r1);
            check(r1, 32'h0, "xi = 0 during reset");
        end

        // Release reset
        @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);

        // =====================================================================
        // TC2 — x0 is hardwired to 0
        // =====================================================================
        $display("\n=== TC2: x0 hardwired to 0 ===");
        // Attempt write to x0
        @(negedge clk);
        we = 1'b1; rd_addr = 5'd0; rd_data = 32'hDEADBEEF;
        @(negedge clk);
        we = 1'b0;

        read_rs1(5'd0, r1);
        check(r1, 32'h0, "x0 rs1 = 0 after write attempt");
        read_rs2(5'd0, r2);
        check(r2, 32'h0, "x0 rs2 = 0 after write attempt");

        // =====================================================================
        // TC3 — Write unique value to every register x1–x31, then read back
        // =====================================================================
        $display("\n=== TC3: Write/read all registers x1–x31 ===");
        for (i = 1; i <= 31; i = i + 1)
            write_reg(i[4:0], 32'hA0000000 | i);   // unique pattern per reg

        for (i = 1; i <= 31; i = i + 1) begin
            read_rs1(i[4:0], r1);
            check(r1, 32'hA0000000 | i, "xi write/read via rs1");
        end

        // =====================================================================
        // TC4 — Both read ports simultaneously, different registers
        // =====================================================================
        $display("\n=== TC4: Dual read port — rs1 and rs2 simultaneously ===");
        // x5 = 0xAAAAAAAA, x17 = 0xBBBBBBBB
        write_reg(5'd5,  32'hAAAAAAAA);
        write_reg(5'd17, 32'hBBBBBBBB);

        rs1_addr = 5'd5;
        rs2_addr = 5'd17;
        #1;
        check(rs1_data, 32'hAAAAAAAA, "rs1 port reads x5 = 0xAAAAAAAA");
        check(rs2_data, 32'hBBBBBBBB, "rs2 port reads x17 = 0xBBBBBBBB");

        // Swap addresses
        rs1_addr = 5'd17;
        rs2_addr = 5'd5;
        #1;
        check(rs1_data, 32'hBBBBBBBB, "rs1 port reads x17 = 0xBBBBBBBB");
        check(rs2_data, 32'hAAAAAAAA, "rs2 port reads x5 = 0xAAAAAAAA");

        // =====================================================================
        // TC5 — Write enable gate: we=0 must not change register
        // =====================================================================
        $display("\n=== TC5: we=0 does not write ===");
        write_reg(5'd10, 32'h12345678);     // establish known value

        @(negedge clk);
        we = 1'b0; rd_addr = 5'd10; rd_data = 32'hDEADBEEF;  // we=0
        @(negedge clk);
        we = 1'b0;

        read_rs1(5'd10, r1);
        check(r1, 32'h12345678, "x10 unchanged when we=0");

        // =====================================================================
        // TC6 — Async read sees OLD value in same cycle as write
        // =====================================================================
        $display("\n=== TC6: Async read sees old value same cycle as write ===");
        write_reg(5'd7, 32'hCAFECAFE);      // known value in x7

        @(negedge clk);
        // Start write of new value — read port checked BEFORE rising edge lands
        we = 1'b1; rd_addr = 5'd7; rd_data = 32'h11111111;
        rs1_addr = 5'd7;
        #1;  // combinational settle — write hasn't clocked in yet
        check(rs1_data, 32'hCAFECAFE, "rs1 sees OLD value same cycle as write");

        // After the rising edge the new value should be visible
        @(negedge clk);
        we = 1'b0;
        read_rs1(5'd7, r1);
        check(r1, 32'h11111111, "rs1 sees NEW value one cycle after write");

        // =====================================================================
        // TC7 — Synchronous reset clears all registers
        // =====================================================================
        $display("\n=== TC7: Synchronous reset clears all registers ===");
        // Write non-zero to several registers
        write_reg(5'd1,  32'hFFFFFFFF);
        write_reg(5'd15, 32'h55555555);
        write_reg(5'd31, 32'h12345678);

        // Assert reset for one cycle
        @(negedge clk);
        rst_n = 1'b0;
        @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);

        for (i = 1; i <= 31; i = i + 1) begin
            read_rs1(i[4:0], r1);
            check(r1, 32'h0, "xi = 0 after reset");
        end

        // =====================================================================
        // TC8 — Two consecutive writes to the same register, second wins
        // =====================================================================
        $display("\n=== TC8: Two consecutive writes — second wins ===");
        write_reg(5'd20, 32'h11111111);
        write_reg(5'd20, 32'h22222222);

        read_rs1(5'd20, r1);
        check(r1, 32'h22222222, "x20 = second write value 0x22222222");

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

    initial begin
        #(CLK_PERIOD * 5000);
        $display("WATCHDOG TIMEOUT");
        $finish;
    end

endmodule