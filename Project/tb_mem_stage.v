//==============================================================================
// tb_mem_stage.v — Self-Checking Testbench for mem_stage
//------------------------------------------------------------------------------
// Tests:
//   TC1  — SW then LW  : store word, read back full 32 bits
//   TC2  — SH then LH  : store halfword, sign-extended read
//   TC3  — SH then LHU : store halfword, zero-extended read
//   TC4  — SB then LB  : store byte, sign-extended read (negative value)
//   TC5  — SB then LBU : store byte, zero-extended read
//   TC6  — Multiple addresses: writes to 3 separate addresses, read all back
//   TC7  — mem_write=0 does not overwrite existing data
//   TC8  — mem_read=0 does not affect pass-through (wb_sel guards WB)
//   TC9  — Pass-through: alu_result, conv_result, rd_addr, pc_plus4,
//           wb_sel, reg_write, is_jump all unchanged
//   TC10 — Byte addressing: SW at 0x00, SB at 0x04; verify no overlap
//==============================================================================
`timescale 1ns / 1ps

module tb_mem_stage;

    localparam CLK_PERIOD  = 10;
    localparam ACCUM_WIDTH = 32;

    // ---- DUT ports ----------------------------------------------------------
    reg         clk, rst_n;
    reg  [31:0] alu_result_i, rs2_data_i;
    reg  [31:0] conv_result_i;
    reg  [4:0]  rd_addr_i;
    reg  [31:0] pc_plus4_i;
    reg         mem_read_i, mem_write_i;
    reg  [1:0]  mem_size_i;
    reg         mem_sign_ext_i;
    reg  [1:0]  wb_sel_i;
    reg         reg_write_i, is_jump_i;

    wire [31:0] alu_result_o, load_data_o;
    wire [31:0] conv_result_o;
    wire [4:0]  rd_addr_o;
    wire [31:0] pc_plus4_o;
    wire [1:0]  wb_sel_o;
    wire        reg_write_o, is_jump_o;

    // ---- DUT ----------------------------------------------------------------
    mem_stage #(
        .ACCUM_WIDTH (ACCUM_WIDTH),
        .DMEM_HEX    ("data.hex")
    ) dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .alu_result_i  (alu_result_i),
        .rs2_data_i    (rs2_data_i),
        .conv_result_i (conv_result_i),
        .rd_addr_i     (rd_addr_i),
        .pc_plus4_i    (pc_plus4_i),
        .mem_read_i    (mem_read_i),
        .mem_write_i   (mem_write_i),
        .mem_size_i    (mem_size_i),
        .mem_sign_ext_i(mem_sign_ext_i),
        .wb_sel_i      (wb_sel_i),
        .reg_write_i   (reg_write_i),
        .is_jump_i     (is_jump_i),
        .alu_result_o  (alu_result_o),
        .load_data_o   (load_data_o),
        .conv_result_o (conv_result_o),
        .rd_addr_o     (rd_addr_o),
        .pc_plus4_o    (pc_plus4_o),
        .wb_sel_o      (wb_sel_o),
        .reg_write_o   (reg_write_o),
        .is_jump_o     (is_jump_o)
    );

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

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

    // Issue one synchronous write (one clock cycle)
    task do_store;
        input [31:0] addr, data;
        input [1:0]  size;
        begin
            @(negedge clk);
            alu_result_i = addr;
            rs2_data_i   = data;
            mem_write_i  = 1'b1;
            mem_read_i   = 1'b0;
            mem_size_i   = size;
            @(negedge clk);
            mem_write_i  = 1'b0;
        end
    endtask

    // Set up a combinational read (async — valid after #1 settle)
    task do_load;
        input [31:0] addr;
        input [1:0]  size;
        input        sign_ext;
        begin
            alu_result_i  = addr;
            mem_read_i    = 1'b1;
            mem_write_i   = 1'b0;
            mem_size_i    = size;
            mem_sign_ext_i= sign_ext;
            #1;   // combinational settle
        end
    endtask

    // Default safe input values
    task reset_inputs;
        begin
            alu_result_i  = 32'h0;
            rs2_data_i    = 32'h0;
            conv_result_i = 32'hCAFE_0000;
            rd_addr_i     = 5'd7;
            pc_plus4_i    = 32'h0000_0204;
            mem_read_i    = 1'b0;
            mem_write_i   = 1'b0;
            mem_size_i    = 2'b10;
            mem_sign_ext_i= 1'b1;
            wb_sel_i      = 2'b00;
            reg_write_i   = 1'b1;
            is_jump_i     = 1'b0;
        end
    endtask

    // =========================================================================
    initial begin
        $dumpfile("tb_mem_stage.vcd");
        $dumpvars(0, tb_mem_stage);
        pass_count = 0; fail_count = 0;
        reset_inputs;
        rst_n = 0;
        repeat(3) @(posedge clk);
        @(negedge clk); rst_n = 1;
        @(negedge clk);

        // =====================================================================
        // TC1 — SW then LW
        // =====================================================================
        $display("\n=== TC1: SW then LW ===");
        do_store(32'h10, 32'hDEAD_BEEF, 2'b10);  // SW
        do_load (32'h10, 2'b10, 1'b1);            // LW
        chk(load_data_o, 32'hDEAD_BEEF, "LW: read back 0xDEADBEEF");

        do_store(32'h14, 32'hCAFE_1234, 2'b10);
        do_load (32'h14, 2'b10, 1'b1);
        chk(load_data_o, 32'hCAFE_1234, "LW: read back 0xCAFE1234");

        // =====================================================================
        // TC2 — SH then LH (sign-extended)
        // =====================================================================
        $display("\n=== TC2: SH then LH (signed) ===");
        // Store 0x8ABC (negative when sign-extended to 32 bits)
        do_store(32'h20, 32'h0000_8ABC, 2'b01);
        do_load (32'h20, 2'b01, 1'b1);            // LH — sign extend
        chk(load_data_o, 32'hFFFF_8ABC, "LH: 0x8ABC sign-extended");

        // Store 0x1234 (positive)
        do_store(32'h22, 32'h0000_1234, 2'b01);
        do_load (32'h22, 2'b01, 1'b1);
        chk(load_data_o, 32'h0000_1234, "LH: 0x1234 positive");

        // =====================================================================
        // TC3 — SH then LHU (zero-extended)
        // =====================================================================
        $display("\n=== TC3: SH then LHU (unsigned) ===");
        do_store(32'h30, 32'h0000_FEDC, 2'b01);
        do_load (32'h30, 2'b01, 1'b0);            // LHU — zero extend
        chk(load_data_o, 32'h0000_FEDC, "LHU: 0xFEDC zero-extended");

        // =====================================================================
        // TC4 — SB then LB (sign-extended, negative byte)
        // =====================================================================
        $display("\n=== TC4: SB then LB (signed) ===");
        // Store 0xFF (-1 as signed byte)
        do_store(32'h40, 32'h0000_00FF, 2'b00);
        do_load (32'h40, 2'b00, 1'b1);            // LB — sign extend
        chk(load_data_o, 32'hFFFF_FFFF, "LB: 0xFF sign-extended to -1");

        // Store 0x7F (+127)
        do_store(32'h41, 32'h0000_007F, 2'b00);
        do_load (32'h41, 2'b00, 1'b1);
        chk(load_data_o, 32'h0000_007F, "LB: 0x7F positive");

        // =====================================================================
        // TC5 — SB then LBU (zero-extended)
        // =====================================================================
        $display("\n=== TC5: SB then LBU (unsigned) ===");
        do_store(32'h50, 32'h0000_00AB, 2'b00);
        do_load (32'h50, 2'b00, 1'b0);            // LBU — zero extend
        chk(load_data_o, 32'h0000_00AB, "LBU: 0xAB zero-extended");

        // =====================================================================
        // TC6 — Multiple addresses
        // =====================================================================
        $display("\n=== TC6: Multiple addresses ===");
        do_store(32'h60, 32'hAAAA_AAAA, 2'b10);
        do_store(32'h64, 32'hBBBB_BBBB, 2'b10);
        do_store(32'h68, 32'hCCCC_CCCC, 2'b10);

        do_load(32'h60, 2'b10, 1'b1); chk(load_data_o, 32'hAAAA_AAAA, "addr 0x60");
        do_load(32'h64, 2'b10, 1'b1); chk(load_data_o, 32'hBBBB_BBBB, "addr 0x64");
        do_load(32'h68, 2'b10, 1'b1); chk(load_data_o, 32'hCCCC_CCCC, "addr 0x68");

        // =====================================================================
        // TC7 — mem_write=0 does not overwrite
        // =====================================================================
        $display("\n=== TC7: mem_write=0 does not overwrite ===");
        do_store(32'h70, 32'h1234_5678, 2'b10);   // initial write

        // Attempt write with mem_write=0
        @(negedge clk);
        alu_result_i = 32'h70;
        rs2_data_i   = 32'hDEAD_DEAD;
        mem_write_i  = 1'b0;
        @(negedge clk);

        do_load(32'h70, 2'b10, 1'b1);
        chk(load_data_o, 32'h1234_5678, "mem_write=0 did not overwrite");

        // =====================================================================
        // TC8 — Byte addressing: SW at 0x00, SB at 0x04, no overlap
        // =====================================================================
        $display("\n=== TC8: Byte addressing, no overlap ===");
        do_store(32'h80, 32'hDEAD_BEEF, 2'b10);   // SW at 0x80
        do_store(32'h84, 32'h0000_00CC, 2'b00);   // SB at 0x84

        do_load(32'h80, 2'b10, 1'b1);
        chk(load_data_o, 32'hDEAD_BEEF, "SW at 0x80 intact after SB at 0x84");

        do_load(32'h84, 2'b00, 1'b0);
        chk(load_data_o, 32'h0000_00CC, "SB at 0x84 = 0xCC");

        // =====================================================================
        // TC9 — Pass-through signals
        // =====================================================================
        $display("\n=== TC9: Pass-through signals ===");
        reset_inputs;
        alu_result_i  = 32'hABCD_1234;
        conv_result_i = 32'hFACE_CAFE;
        rd_addr_i     = 5'd19;
        pc_plus4_i    = 32'h0000_0308;
        wb_sel_i      = 2'b10;
        reg_write_i   = 1'b1;
        is_jump_i     = 1'b1;
        #2;
        chk(alu_result_o,  32'hABCD_1234, "alu_result pass-through");
        chk(conv_result_o, 32'hFACE_CAFE, "conv_result pass-through");
        chk(rd_addr_o,     32'd19,         "rd_addr pass-through");
        chk(pc_plus4_o,    32'h0000_0308,  "pc_plus4 pass-through");
        chk(wb_sel_o,      32'h2,          "wb_sel pass-through");
        chk(reg_write_o,   32'h1,          "reg_write pass-through");
        chk(is_jump_o,     32'h1,          "is_jump pass-through");

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

    initial begin #50000; $display("WATCHDOG TIMEOUT"); $finish; end

endmodule