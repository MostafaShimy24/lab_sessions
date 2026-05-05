//==============================================================================
// tb_alu.v — Self-Checking Directed Testbench for alu
//------------------------------------------------------------------------------
// Tests:
//   TC1  — ADD  : normal, overflow wrap, zero result
//   TC2  — SUB  : normal, underflow wrap, result = 0
//   TC3  — AND  : normal, all-zeros, all-ones mask
//   TC4  — OR   : normal, identity (OR with 0), all-ones
//   TC5  — XOR  : normal, self-XOR = 0, all-ones
//   TC6  — SLL  : shift by 0, 1, 16, 31
//   TC7  — SRL  : logical right shift (MSB filled with 0)
//   TC8  — SRA  : arithmetic right shift (MSB filled with sign bit)
//   TC9  — SLT  : signed less-than  (positive, negative, equal, boundary)
//   TC10 — SLTU : unsigned less-than (boundary, wrap-around values)
//   TC11 — Zero flag : asserted only when result == 0
//   TC12 — Reserved alu_op codes default to ADD
//   TC13 — Boundary values: 0, 1, -1, INT_MAX, INT_MIN, 0xFFFFFFFF
//==============================================================================
`timescale 1ns / 1ps

module tb_alu;

    // ---- DUT ports ----------------------------------------------------------
    reg  [31:0] operand_a;
    reg  [31:0] operand_b;
    reg  [3:0]  alu_op;
    wire [31:0] alu_result;
    wire        zero;

    // ---- ALU op codes (matching alu.v encoding) -----------------------------
    localparam ADD  = 4'b0000;
    localparam SUB  = 4'b0001;
    localparam SLL  = 4'b0010;
    localparam SLT  = 4'b0011;
    localparam SLTU = 4'b0100;
    localparam XOR  = 4'b0101;
    localparam SRL  = 4'b0110;
    localparam SRA  = 4'b0111;
    localparam OR   = 4'b1000;
    localparam AND  = 4'b1001;

    // ---- Boundary constants -------------------------------------------------
    localparam ZERO    = 32'h00000000;
    localparam ONE     = 32'h00000001;
    localparam NEG_ONE = 32'hFFFFFFFF;
    localparam INT_MAX = 32'h7FFFFFFF;   //  2147483647
    localparam INT_MIN = 32'h80000000;   // -2147483648

    // ---- DUT ----------------------------------------------------------------
    alu dut (
        .operand_a  (operand_a),
        .operand_b  (operand_b),
        .alu_op     (alu_op),
        .alu_result (alu_result),
        .zero       (zero)
    );

    // ---- Helpers ------------------------------------------------------------
    integer pass_count, fail_count;

    // Check result and zero flag together
    task check;
        input [31:0] exp_result;
        input        exp_zero;
        input [255:0] label;
        begin
            if (alu_result === exp_result && zero === exp_zero) begin
                $display("  PASS  %-50s  result=0x%08h  zero=%b",
                         label, alu_result, zero);
                pass_count = pass_count + 1;
            end else begin
                if (alu_result !== exp_result)
                    $display("  FAIL  %-50s  result=0x%08h  exp=0x%08h",
                             label, alu_result, exp_result);
                if (zero !== exp_zero)
                    $display("  FAIL  %-50s  zero=%b  exp=%b",
                             label, zero, exp_zero);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Apply operands + op, let combinational settle (#1), then check
    task apply;
        input [31:0] a, b;
        input [3:0]  op;
        input [31:0] exp_result;
        input        exp_zero;
        input [255:0] label;
        begin
            operand_a = a;
            operand_b = b;
            alu_op    = op;
            #1;
            check(exp_result, exp_zero, label);
        end
    endtask

    // =========================================================================
    initial begin
        $dumpfile("tb_alu.vcd");
        $dumpvars(0, tb_alu);
        pass_count = 0;
        fail_count = 0;
        operand_a = 0; operand_b = 0; alu_op = ADD;

        // =====================================================================
        // TC1 — ADD
        // =====================================================================
        $display("\n=== TC1: ADD ===");
        apply(32'd15,    32'd10,    ADD, 32'd25,           0, "15 + 10 = 25");
        apply(INT_MAX,   ONE,       ADD, INT_MIN,          0, "INT_MAX + 1 wraps to INT_MIN");
        apply(NEG_ONE,   ONE,       ADD, ZERO,             1, "0xFFFFFFFF + 1 = 0 (zero flag)");
        apply(ZERO,      ZERO,      ADD, ZERO,             1, "0 + 0 = 0 (zero flag)");
        apply(32'hABCD,  32'h1234,  ADD, 32'hBE01,        0, "0xABCD + 0x1234");

        // =====================================================================
        // TC2 — SUB
        // =====================================================================
        $display("\n=== TC2: SUB ===");
        apply(32'd20,    32'd7,     SUB, 32'd13,           0, "20 - 7 = 13");
        apply(ZERO,      ONE,       SUB, NEG_ONE,          0, "0 - 1 = 0xFFFFFFFF (wrap)");
        apply(32'd42,    32'd42,    SUB, ZERO,             1, "42 - 42 = 0 (zero flag)");
        apply(INT_MIN,   ONE,       SUB, INT_MAX,          0, "INT_MIN - 1 wraps to INT_MAX");
        apply(NEG_ONE,   NEG_ONE,   SUB, ZERO,             1, "0xFFFFFFFF - 0xFFFFFFFF = 0");

        // =====================================================================
        // TC3 — AND
        // =====================================================================
        $display("\n=== TC3: AND ===");
        apply(32'hFF00FF00, 32'h0F0F0F0F, AND, 32'h0F000F00, 0, "0xFF00FF00 & 0x0F0F0F0F");
        apply(NEG_ONE,   32'hABCDEF01, AND, 32'hABCDEF01, 0, "all-ones mask = identity");
        apply(32'hDEAD,  ZERO,      AND, ZERO,             1, "AND with 0 = 0 (zero flag)");
        apply(NEG_ONE,   NEG_ONE,   AND, NEG_ONE,          0, "0xFFFFFFFF & 0xFFFFFFFF");

        // =====================================================================
        // TC4 — OR
        // =====================================================================
        $display("\n=== TC4: OR ===");
        apply(32'hF0F0F0F0, 32'h0F0F0F0F, OR, NEG_ONE,    0, "OR gives all-ones");
        apply(32'hABCD,  ZERO,      OR,  32'hABCD,        0, "OR with 0 = identity");
        apply(ZERO,      ZERO,      OR,  ZERO,             1, "0 OR 0 = 0 (zero flag)");
        apply(32'h1234,  32'h5678,  OR,  32'h567C,        0, "0x1234 | 0x5678");

        // =====================================================================
        // TC5 — XOR
        // =====================================================================
        $display("\n=== TC5: XOR ===");
        apply(32'hAAAAAAAA, 32'h55555555, XOR, NEG_ONE,   0, "alternating XOR = all-ones");
        apply(32'hDEADBEEF, 32'hDEADBEEF, XOR, ZERO,     1, "self-XOR = 0 (zero flag)");
        apply(32'hABCD,  ZERO,      XOR, 32'hABCD,        0, "XOR with 0 = identity");
        apply(NEG_ONE,   NEG_ONE,   XOR, ZERO,             1, "0xFFFF XOR 0xFFFF = 0");

        // =====================================================================
        // TC6 — SLL (logical left shift)
        // =====================================================================
        $display("\n=== TC6: SLL ===");
        apply(32'h00000001, 32'd0,  SLL, 32'h00000001,    0, "1 << 0 = 1");
        apply(32'h00000001, 32'd1,  SLL, 32'h00000002,    0, "1 << 1 = 2");
        apply(32'h00000001, 32'd16, SLL, 32'h00010000,    0, "1 << 16");
        apply(32'h00000001, 32'd31, SLL, 32'h80000000,    0, "1 << 31 = INT_MIN");
        apply(32'hFFFFFFFF, 32'd1,  SLL, 32'hFFFFFFFE,    0, "0xFFFFFFFF << 1");
        apply(32'hFFFFFFFF, 32'd31, SLL, 32'h80000000,    0, "0xFFFFFFFF << 31");
        // Only lower 5 bits of b used as shamt
        apply(32'h00000001, 32'd32, SLL, 32'h00000001,    0, "shamt=32 -> lower5=0, no shift");

        // =====================================================================
        // TC7 — SRL (logical right shift — zero-fills MSB)
        // =====================================================================
        $display("\n=== TC7: SRL ===");
        apply(32'h80000000, 32'd1,  SRL, 32'h40000000,    0, "0x80000000 >> 1 = 0x40000000 (logical)");
        apply(32'hFFFFFFFF, 32'd4,  SRL, 32'h0FFFFFFF,    0, "0xFFFFFFFF >> 4");
        apply(32'hFFFFFFFF, 32'd31, SRL, 32'h00000001,    0, "0xFFFFFFFF >> 31 = 1");
        apply(32'h00000008, 32'd3,  SRL, 32'h00000001,    0, "8 >> 3 = 1");
        apply(32'hFFFFFFFF, 32'd32, SRL, NEG_ONE,         0, "shamt=32 -> lower5=0, no shift");

        // =====================================================================
        // TC8 — SRA (arithmetic right shift — sign-fills MSB)
        // =====================================================================
        $display("\n=== TC8: SRA ===");
        apply(32'h80000000, 32'd1,  SRA, 32'hC0000000,    0, "0x80000000 >>> 1 = 0xC0000000 (arithmetic)");
        apply(32'hFFFFFFFF, 32'd1,  SRA, NEG_ONE,         0, "-1 >>> 1 = -1 (sign preserved)");
        apply(32'hFFFFFFFF, 32'd31, SRA, NEG_ONE,         0, "-1 >>> 31 = -1");
        apply(32'h7FFFFFFF, 32'd1,  SRA, 32'h3FFFFFFF,    0, "INT_MAX >>> 1 (positive, zero-fills)");
        apply(32'h00000008, 32'd3,  SRA, 32'h00000001,    0, "8 >>> 3 = 1");
        apply(32'hF0000000, 32'd4,  SRA, 32'hFF000000,    0, "0xF0000000 >>> 4 = 0xFF000000");

        // =====================================================================
        // TC9 — SLT (signed less-than)
        // =====================================================================
        $display("\n=== TC9: SLT (signed) ===");
        apply(32'd3,     32'd5,     SLT, 32'd1,           0, "3 < 5 (signed) = 1");
        apply(32'd5,     32'd3,     SLT, 32'd0,           1, "5 < 3 (signed) = 0 (zero flag)");
        apply(32'd5,     32'd5,     SLT, 32'd0,           1, "5 < 5 (signed) = 0 (zero flag)");
        apply(NEG_ONE,   ONE,       SLT, 32'd1,           0, "-1 < 1 (signed) = 1");
        apply(ONE,       NEG_ONE,   SLT, 32'd0,           1, "1 < -1 (signed) = 0");
        apply(INT_MIN,   INT_MAX,   SLT, 32'd1,           0, "INT_MIN < INT_MAX = 1");
        apply(INT_MAX,   INT_MIN,   SLT, 32'd0,           1, "INT_MAX < INT_MIN = 0");
        apply(NEG_ONE,   NEG_ONE,   SLT, 32'd0,           1, "-1 < -1 = 0 (equal)");

        // =====================================================================
        // TC10 — SLTU (unsigned less-than)
        // =====================================================================
        $display("\n=== TC10: SLTU (unsigned) ===");
        apply(32'd3,     32'd5,     SLTU, 32'd1,          0, "3 < 5 (unsigned) = 1");
        apply(32'd5,     32'd3,     SLTU, 32'd0,          1, "5 < 3 (unsigned) = 0");
        apply(ZERO,      ONE,       SLTU, 32'd1,          0, "0 < 1 (unsigned) = 1");
        apply(NEG_ONE,   ONE,       SLTU, 32'd0,          1, "0xFFFFFFFF < 1 (unsigned) = 0");
        apply(ONE,       NEG_ONE,   SLTU, 32'd1,          0, "1 < 0xFFFFFFFF (unsigned) = 1");
        apply(INT_MIN,   INT_MAX,   SLTU, 32'd0,          1, "0x80000000 < 0x7FFFFFFF (unsigned) = 0");
        apply(INT_MAX,   INT_MIN,   SLTU, 32'd1,          0, "0x7FFFFFFF < 0x80000000 (unsigned) = 1");
        apply(NEG_ONE,   NEG_ONE,   SLTU, 32'd0,          1, "0xFFFF < 0xFFFF = 0 (equal)");

        // =====================================================================
        // TC11 — Zero flag independent verification
        // =====================================================================
        $display("\n=== TC11: Zero flag ===");
        apply(ZERO,      ZERO,      ADD,  ZERO, 1, "zero=1 when result=0 (ADD)");
        apply(32'd1,     ZERO,      ADD,  ONE,  0, "zero=0 when result!=0 (ADD)");
        apply(32'd5,     32'd5,     SUB,  ZERO, 1, "zero=1 when result=0 (SUB)");
        apply(NEG_ONE,   NEG_ONE,   XOR,  ZERO, 1, "zero=1 when result=0 (XOR)");
        apply(32'hABCD,  32'hABCD,  AND,  32'hABCD, 0, "zero=0 (AND non-zero)");

        // =====================================================================
        // TC12 — Reserved alu_op codes default to ADD
        // =====================================================================
        $display("\n=== TC12: Reserved opcodes default to ADD ===");
        apply(32'd10, 32'd5, 4'b1010, 32'd15, 0, "reserved 1010 -> ADD: 10+5=15");
        apply(32'd10, 32'd5, 4'b1011, 32'd15, 0, "reserved 1011 -> ADD");
        apply(32'd10, 32'd5, 4'b1100, 32'd15, 0, "reserved 1100 -> ADD");
        apply(32'd10, 32'd5, 4'b1101, 32'd15, 0, "reserved 1101 -> ADD");
        apply(32'd10, 32'd5, 4'b1110, 32'd15, 0, "reserved 1110 -> ADD");
        apply(32'd10, 32'd5, 4'b1111, 32'd15, 0, "reserved 1111 -> ADD");

        // =====================================================================
        // TC13 — Boundary value sweep across all ops
        // =====================================================================
        $display("\n=== TC13: Boundary values ===");
        // ADD boundaries
        apply(ZERO,    ZERO,    ADD, ZERO,             1, "ADD: 0+0=0");
        apply(INT_MAX, ZERO,    ADD, INT_MAX,           0, "ADD: INT_MAX+0=INT_MAX");
        apply(INT_MIN, ZERO,    ADD, INT_MIN,           0, "ADD: INT_MIN+0=INT_MIN");
        apply(NEG_ONE, ZERO,    ADD, NEG_ONE,           0, "ADD: 0xFFFF+0=0xFFFF");
        // SUB boundaries
        apply(ZERO,    ZERO,    SUB, ZERO,              1, "SUB: 0-0=0");
        apply(INT_MIN, INT_MIN, SUB, ZERO,              1, "SUB: INT_MIN-INT_MIN=0");
        // Shift boundary: shamt=0 and shamt=31
        apply(32'hABCDEF12, 32'd0,  SLL, 32'hABCDEF12, 0, "SLL shamt=0 no change");
        apply(32'hABCDEF12, 32'd31, SLL, 32'h00000000,  1, "SLL shamt=31");
        apply(32'hABCDEF12, 32'd0,  SRL, 32'hABCDEF12, 0, "SRL shamt=0 no change");
        apply(32'hABCDEF12, 32'd31, SRL, 32'h00000001,  0, "SRL shamt=31 = MSB only");
        apply(INT_MIN,      32'd31, SRA, NEG_ONE,        0, "SRA: INT_MIN>>>31 = 0xFFFFFFFF");
        apply(INT_MAX,      32'd31, SRA, ZERO,           1, "SRA: INT_MAX>>>31 = 0");

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

endmodule