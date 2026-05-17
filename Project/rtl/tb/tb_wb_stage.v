//==============================================================================
// tb_wb_stage.v — Self-Checking Testbench for wb_stage
//------------------------------------------------------------------------------
// Tests:
//   TC1 — wb_sel=00 : ALU result written to rd
//   TC2 — wb_sel=01 : Load data written to rd
//   TC3 — wb_sel=10 : Conv-PE result written to rd
//   TC4 — is_jump=1 : PC+4 written regardless of wb_sel (all 3 values)
//   TC5 — reg_write=0 : wb_we_o deasserted, data still muxed correctly
//   TC6 — rd_addr pass-through : correct address forwarded
//   TC7 — x0 protection : rd_addr=0 passes wb_we=1 (regfile guards x0)
//   TC8 — Boundary values : 0, 0xFFFFFFFF, 0x80000000 through each path
//==============================================================================
`timescale 1ns / 1ps

module tb_wb_stage;

    // ---- DUT ports ----------------------------------------------------------
    reg  [31:0] alu_result_i, load_data_i, conv_result_i, pc_plus4_i;
    reg  [4:0]  rd_addr_i;
    reg  [1:0]  wb_sel_i;
    reg         reg_write_i, is_jump_i;

    wire [4:0]  wb_addr_o;
    wire [31:0] wb_data_o;
    wire        wb_we_o;

    // ---- DUT ----------------------------------------------------------------
    wb_stage dut (
        .alu_result_i  (alu_result_i),
        .load_data_i   (load_data_i),
        .conv_result_i (conv_result_i),
        .pc_plus4_i    (pc_plus4_i),
        .rd_addr_i     (rd_addr_i),
        .wb_sel_i      (wb_sel_i),
        .reg_write_i   (reg_write_i),
        .is_jump_i     (is_jump_i),
        .wb_addr_o     (wb_addr_o),
        .wb_data_o     (wb_data_o),
        .wb_we_o       (wb_we_o)
    );

    // ---- Helpers ------------------------------------------------------------
    integer pass_count, fail_count;

    task chk;
        input [31:0] got, exp;
        input [255:0] lbl;
        begin
            if (got === exp) begin
                $display("  PASS  %-48s  got=0x%08h", lbl, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL  %-48s  got=0x%08h  exp=0x%08h",
                         lbl, got, exp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Apply all inputs, settle 1ns, then check
    task apply;
        input [31:0] alu, ld, conv, pc4;
        input [4:0]  rd;
        input [1:0]  sel;
        input        rw, jmp;
        begin
            alu_result_i  = alu;
            load_data_i   = ld;
            conv_result_i = conv;
            pc_plus4_i    = pc4;
            rd_addr_i     = rd;
            wb_sel_i      = sel;
            reg_write_i   = rw;
            is_jump_i     = jmp;
            #1;
        end
    endtask

    // =========================================================================
    initial begin
        $dumpfile("tb_wb_stage.vcd");
        $dumpvars(0, tb_wb_stage);
        pass_count = 0; fail_count = 0;

        // =====================================================================
        // TC1 — wb_sel=00: ALU result
        // =====================================================================
        $display("\n=== TC1: wb_sel=00 ALU result ===");
        apply(32'hABCD_1234, 32'h1111_1111, 32'h2222_2222, 32'h3333_3333,
              5'd5, 2'b00, 1'b1, 1'b0);
        chk(wb_data_o, 32'hABCD_1234, "wb_data = alu_result");
        chk(wb_we_o,   1,             "wb_we=1");
        chk(wb_addr_o, 5'd5,          "wb_addr=5");

        // =====================================================================
        // TC2 — wb_sel=01: Load data
        // =====================================================================
        $display("\n=== TC2: wb_sel=01 Load data ===");
        apply(32'hABCD_1234, 32'hDEAD_BEEF, 32'h2222_2222, 32'h3333_3333,
              5'd8, 2'b01, 1'b1, 1'b0);
        chk(wb_data_o, 32'hDEAD_BEEF, "wb_data = load_data");
        chk(wb_we_o,   1,             "wb_we=1");

        // =====================================================================
        // TC3 — wb_sel=10: Conv-PE result
        // =====================================================================
        $display("\n=== TC3: wb_sel=10 Conv-PE result ===");
        apply(32'hABCD_1234, 32'hDEAD_BEEF, 32'hCAFE_CAFE, 32'h3333_3333,
              5'd12, 2'b10, 1'b1, 1'b0);
        chk(wb_data_o, 32'hCAFE_CAFE, "wb_data = conv_result");
        chk(wb_we_o,   1,             "wb_we=1");

        // =====================================================================
        // TC4 — is_jump=1: PC+4 overrides all wb_sel values
        // =====================================================================
        $display("\n=== TC4: is_jump=1 overrides wb_sel ===");
        // is_jump overrides wb_sel=00
        apply(32'hAAAA_AAAA, 32'hBBBB_BBBB, 32'hCCCC_CCCC, 32'h0000_0104,
              5'd1, 2'b00, 1'b1, 1'b1);
        chk(wb_data_o, 32'h0000_0104, "is_jump overrides wb_sel=00");

        // is_jump overrides wb_sel=01
        apply(32'hAAAA_AAAA, 32'hBBBB_BBBB, 32'hCCCC_CCCC, 32'h0000_0208,
              5'd1, 2'b01, 1'b1, 1'b1);
        chk(wb_data_o, 32'h0000_0208, "is_jump overrides wb_sel=01");

        // is_jump overrides wb_sel=10
        apply(32'hAAAA_AAAA, 32'hBBBB_BBBB, 32'hCCCC_CCCC, 32'h0000_030C,
              5'd1, 2'b10, 1'b1, 1'b1);
        chk(wb_data_o, 32'h0000_030C, "is_jump overrides wb_sel=10");

        // =====================================================================
        // TC5 — reg_write=0: wb_we_o deasserted
        // =====================================================================
        $display("\n=== TC5: reg_write=0 ===");
        apply(32'hABCD_1234, 32'hDEAD_BEEF, 32'hCAFE_CAFE, 32'h0000_0104,
              5'd9, 2'b00, 1'b0, 1'b0);
        chk(wb_we_o,   0,             "wb_we=0 when reg_write=0");
        chk(wb_data_o, 32'hABCD_1234, "wb_data still muxed (wb_we gates regfile)");

        // reg_write=0 with is_jump
        apply(32'hAAAA_AAAA, 32'hBBBB_BBBB, 32'hCCCC_CCCC, 32'h0000_0104,
              5'd1, 2'b00, 1'b0, 1'b1);
        chk(wb_we_o, 0, "wb_we=0 even with is_jump when reg_write=0");

        // =====================================================================
        // TC6 — rd_addr pass-through
        // =====================================================================
        $display("\n=== TC6: rd_addr pass-through ===");
        apply(32'h0, 32'h0, 32'h0, 32'h0, 5'd31, 2'b00, 1'b1, 1'b0);
        chk(wb_addr_o, 5'd31, "wb_addr=31");

        apply(32'h0, 32'h0, 32'h0, 32'h0, 5'd15, 2'b00, 1'b1, 1'b0);
        chk(wb_addr_o, 5'd15, "wb_addr=15");

        apply(32'h0, 32'h0, 32'h0, 32'h0, 5'd1,  2'b00, 1'b1, 1'b0);
        chk(wb_addr_o, 5'd1,  "wb_addr=1");

        // =====================================================================
        // TC7 — rd_addr=0: wb_we passes through (regfile guards x0)
        // =====================================================================
        $display("\n=== TC7: rd_addr=0 (x0 guard in regfile) ===");
        apply(32'hDEAD_BEEF, 32'h0, 32'h0, 32'h0, 5'd0, 2'b00, 1'b1, 1'b0);
        chk(wb_addr_o, 5'd0,        "wb_addr=0 passed through");
        chk(wb_we_o,   1,           "wb_we=1 (regfile silently ignores x0 write)");
        chk(wb_data_o, 32'hDEAD_BEEF, "wb_data passed (regfile ignores it)");

        // =====================================================================
        // TC8 — Boundary values through each path
        // =====================================================================
        $display("\n=== TC8: Boundary values ===");
        // Zero through ALU path
        apply(32'h0, 32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'hFFFF_FFFF,
              5'd5, 2'b00, 1'b1, 1'b0);
        chk(wb_data_o, 32'h0, "ALU path: zero");

        // 0xFFFFFFFF through load path
        apply(32'h0, 32'hFFFF_FFFF, 32'h0, 32'h0,
              5'd5, 2'b01, 1'b1, 1'b0);
        chk(wb_data_o, 32'hFFFF_FFFF, "Load path: 0xFFFFFFFF");

        // 0x80000000 through conv path
        apply(32'h0, 32'h0, 32'h8000_0000, 32'h0,
              5'd5, 2'b10, 1'b1, 1'b0);
        chk(wb_data_o, 32'h8000_0000, "Conv path: 0x80000000");

        // 0xFFFFFFFF through jump path
        apply(32'h0, 32'h0, 32'h0, 32'hFFFF_FFFC,
              5'd5, 2'b00, 1'b1, 1'b1);
        chk(wb_data_o, 32'hFFFF_FFFC, "Jump path: 0xFFFFFFFC");

        // =====================================================================
        // Summary
        // =====================================================================
        $display("\n============================================");
        $display("  Results: %0d PASS   %0d FAIL", pass_count, fail_count);
        $display("============================================\n");
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("FAILURES DETECTED");

        $finish;
    end

endmodule