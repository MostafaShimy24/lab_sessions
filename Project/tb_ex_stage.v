//==============================================================================
// tb_ex_stage.v — Self-Checking Testbench for ex_stage
//------------------------------------------------------------------------------
// Tests:
//   TC1  — ALU: operand muxes (rs1/PC/zero) and operand-B (rs2/imm)
//   TC2  — ALU: all 10 operations via alu_op
//   TC3  — Branch comparator: all 6 conditions, taken and not-taken
//   TC4  — Branch target: PC + B-imm, flush asserted when taken
//   TC5  — JAL: jump target = PC + J-imm, is_jump, flush
//   TC6  — JALR: jump target = (rs1+imm)&~1, bit-0 cleared
//   TC7  — LUI: alu_src_a=zero -> result = imm
//   TC8  — AUIPC: alu_src_a=PC -> result = PC + imm
//   TC9  — Conv-PE dispatch: stall asserted, result captured on conv_done
//   TC10 — stall_o deasserted exactly after CONV_LATENCY cycles
//   TC11 — is_jump_o set for JAL and JALR, clear for others
//   TC12 — pass-through signals unchanged
//==============================================================================
`timescale 1ns / 1ps

module tb_ex_stage;

    localparam CLK_PERIOD   = 10;
    localparam CONV_LATENCY = 4;

    // ---- DUT ports ----------------------------------------------------------
    reg         clk, rst_n;
    reg  [31:0] pc_if_i, pc_plus4_i;
    reg  [31:0] rs1_data_i, rs2_data_i;
    reg  [4:0]  rs1_addr_i, rs2_addr_i, rd_addr_i;
    reg  [31:0] imm_i;
    reg  [3:0]  alu_op_i;
    reg  [1:0]  alu_src_a_i;
    reg         alu_src_b_i;
    reg         mem_read_i, mem_write_i;
    reg  [1:0]  mem_size_i;
    reg         mem_sign_ext_i;
    reg  [1:0]  wb_sel_i;
    reg         reg_write_i;
    reg         is_branch_i;
    reg  [2:0]  branch_funct3_i;
    reg         is_jal_i, is_jalr_i;
    reg         conv_start_i, conv_init_i;

    wire [31:0] alu_result_o, conv_result_o;
    wire [31:0] rs2_data_o;
    wire [4:0]  rd_addr_o;
    wire [31:0] pc_plus4_o;
    wire        mem_read_o, mem_write_o;
    wire [1:0]  mem_size_o;
    wire        mem_sign_ext_o;
    wire [1:0]  wb_sel_o;
    wire        reg_write_o, is_jump_o;
    wire [1:0]  pc_src_o;
    wire        flush_o;
    wire [31:0] branch_target_o, jump_target_o;
    wire        stall_o;

    // ---- DUT ----------------------------------------------------------------
    ex_stage #(
        .CONV_LATENCY (CONV_LATENCY),
        .DATA_WIDTH   (32),
        .ACCUM_WIDTH  (32)
    ) dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .pc_if_i          (pc_if_i),
        .pc_plus4_i       (pc_plus4_i),
        .rs1_data_i       (rs1_data_i),
        .rs2_data_i       (rs2_data_i),
        .rs1_addr_i       (rs1_addr_i),
        .rs2_addr_i       (rs2_addr_i),
        .rd_addr_i        (rd_addr_i),
        .imm_i            (imm_i),
        .alu_op_i         (alu_op_i),
        .alu_src_a_i      (alu_src_a_i),
        .alu_src_b_i      (alu_src_b_i),
        .mem_read_i       (mem_read_i),
        .mem_write_i      (mem_write_i),
        .mem_size_i       (mem_size_i),
        .mem_sign_ext_i   (mem_sign_ext_i),
        .wb_sel_i         (wb_sel_i),
        .reg_write_i      (reg_write_i),
        .is_branch_i      (is_branch_i),
        .branch_funct3_i  (branch_funct3_i),
        .is_jal_i         (is_jal_i),
        .is_jalr_i        (is_jalr_i),
        .conv_start_i     (conv_start_i),
        .conv_init_i      (conv_init_i),
        .alu_result_o     (alu_result_o),
        .conv_result_o    (conv_result_o),
        .rs2_data_o       (rs2_data_o),
        .rd_addr_o        (rd_addr_o),
        .pc_plus4_o       (pc_plus4_o),
        .mem_read_o       (mem_read_o),
        .mem_write_o      (mem_write_o),
        .mem_size_o       (mem_size_o),
        .mem_sign_ext_o   (mem_sign_ext_o),
        .wb_sel_o         (wb_sel_o),
        .reg_write_o      (reg_write_o),
        .is_jump_o        (is_jump_o),
        .pc_src_o         (pc_src_o),
        .flush_o          (flush_o),
        .branch_target_o  (branch_target_o),
        .jump_target_o    (jump_target_o),
        .stall_o          (stall_o)
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
                $display("  FAIL  %-48s  got=0x%08h  exp=0x%08h", lbl, got, exp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Set all inputs to safe defaults
    task reset_inputs;
        begin
            pc_if_i         = 32'h100;
            pc_plus4_i      = 32'h104;
            rs1_data_i      = 32'd0;
            rs2_data_i      = 32'd0;
            rs1_addr_i      = 5'd1;
            rs2_addr_i      = 5'd2;
            rd_addr_i       = 5'd3;
            imm_i           = 32'd0;
            alu_op_i        = 4'b0000;  // ADD
            alu_src_a_i     = 2'b00;    // rs1
            alu_src_b_i     = 1'b0;     // rs2
            mem_read_i      = 1'b0;
            mem_write_i     = 1'b0;
            mem_size_i      = 2'b10;
            mem_sign_ext_i  = 1'b1;
            wb_sel_i        = 2'b00;
            reg_write_i     = 1'b1;
            is_branch_i     = 1'b0;
            branch_funct3_i = 3'b000;
            is_jal_i        = 1'b0;
            is_jalr_i       = 1'b0;
            conv_start_i    = 1'b0;
            conv_init_i     = 1'b0;
        end
    endtask

    integer busy_cnt;
    reg [31:0] r;

    // =========================================================================
    initial begin
        $dumpfile("tb_ex_stage.vcd");
        $dumpvars(0, tb_ex_stage);
        pass_count = 0; fail_count = 0;
        reset_inputs;
        rst_n = 0;
        repeat(3) @(posedge clk);
        @(negedge clk); rst_n = 1;
        @(negedge clk);

        // =====================================================================
        // TC1 — Operand muxes
        // =====================================================================
        $display("\n=== TC1: Operand muxes ===");
        // src_a=rs1, src_b=rs2  ->  ADD: 10+5=15
        reset_inputs;
        rs1_data_i=32'd10; rs2_data_i=32'd5;
        alu_src_a_i=2'b00; alu_src_b_i=1'b0; alu_op_i=4'b0000; #2;
        chk(alu_result_o, 32'd15, "src_a=rs1, src_b=rs2: 10+5=15");

        // src_a=PC, src_b=imm  ->  AUIPC: PC+imm
        pc_if_i=32'h200; imm_i=32'h1000;
        alu_src_a_i=2'b01; alu_src_b_i=1'b1; #2;
        chk(alu_result_o, 32'h1200, "src_a=PC, src_b=imm: 0x200+0x1000");

        // src_a=zero, src_b=imm  ->  LUI: 0+imm
        imm_i=32'hABCDE000;
        alu_src_a_i=2'b10; alu_src_b_i=1'b1; #2;
        chk(alu_result_o, 32'hABCDE000, "src_a=zero, src_b=imm (LUI)");

        // =====================================================================
        // TC2 — ALU operations
        // =====================================================================
        $display("\n=== TC2: ALU operations ===");
        reset_inputs;
        alu_src_a_i=2'b00; alu_src_b_i=1'b0;
        rs1_data_i=32'hF0F0F0F0; rs2_data_i=32'h0F0F0F0F;

        alu_op_i=4'b0000; #2; chk(alu_result_o, 32'hFFFFFFFF, "ADD");
        alu_op_i=4'b0001; #2; chk(alu_result_o, 32'hE1E1E1E1, "SUB");
        alu_op_i=4'b1000; #2; chk(alu_result_o, 32'hFFFFFFFF, "OR");
        alu_op_i=4'b1001; #2; chk(alu_result_o, 32'h00000000, "AND");
        alu_op_i=4'b0101; #2; chk(alu_result_o, 32'hFFFFFFFF, "XOR");

        rs1_data_i=32'h00000001; rs2_data_i=32'd8;
        alu_op_i=4'b0010; #2; chk(alu_result_o, 32'h00000100, "SLL: 1<<8");
        alu_op_i=4'b0110; rs1_data_i=32'hFF000000; #2;
        chk(alu_result_o, 32'h00FF0000, "SRL: logical >>8");
        alu_op_i=4'b0111; #2;
        chk(alu_result_o, 32'hFFFF0000, "SRA: arith >>8 (sign bit preserved)");

        rs1_data_i=32'd3; rs2_data_i=32'd5;
        alu_op_i=4'b0011; #2; chk(alu_result_o, 32'd1, "SLT: 3<5 signed");
        alu_op_i=4'b0100; #2; chk(alu_result_o, 32'd1, "SLTU: 3<5 unsigned");

        // =====================================================================
        // TC3 — Branch comparator: all 6 conditions
        // =====================================================================
        $display("\n=== TC3: Branch comparator ===");
        reset_inputs; is_branch_i=1'b1;

        // BEQ: equal -> taken
        rs1_data_i=32'd7; rs2_data_i=32'd7;
        branch_funct3_i=3'b000; #2;
        chk(flush_o,          1,          "BEQ equal: flush=1");
        chk(pc_src_o,         2'b01,      "BEQ equal: pc_src=branch");

        // BEQ: not equal -> not taken
        rs2_data_i=32'd8; #2;
        chk(flush_o, 0, "BEQ not-equal: flush=0");

        // BNE: not equal -> taken
        branch_funct3_i=3'b001; #2;
        chk(flush_o, 1, "BNE not-equal: flush=1");

        // BLT: signed 3 < 5 -> taken
        rs1_data_i=32'd3; rs2_data_i=32'd5;
        branch_funct3_i=3'b100; #2;
        chk(flush_o, 1, "BLT: 3<5 signed, taken");

        // BLT: signed -1 < 1 -> taken
        rs1_data_i=32'hFFFFFFFF; rs2_data_i=32'd1;
        branch_funct3_i=3'b100; #2;
        chk(flush_o, 1, "BLT: -1<1 signed, taken");

        // BLT: 0xFFFFFFFF < 1 unsigned -> not taken (BGE would be taken)
        branch_funct3_i=3'b101; #2;
        chk(flush_o, 0, "BGE: -1>=1 signed, NOT taken");

        // BLTU: 1 < 0xFFFFFFFF unsigned -> taken
        rs1_data_i=32'd1; rs2_data_i=32'hFFFFFFFF;
        branch_funct3_i=3'b110; #2;
        chk(flush_o, 1, "BLTU: 1<0xFFFF unsigned, taken");

        // BGEU: 0xFFFF >= 1 unsigned -> taken
        rs1_data_i=32'hFFFFFFFF; rs2_data_i=32'd1;
        branch_funct3_i=3'b111; #2;
        chk(flush_o, 1, "BGEU: 0xFFFF>=1 unsigned, taken");

        // =====================================================================
        // TC4 — Branch target calculation
        // =====================================================================
        $display("\n=== TC4: Branch target ===");
        reset_inputs; is_branch_i=1'b1;
        pc_if_i=32'h200; imm_i=32'h40;   // branch offset +64
        rs1_data_i=32'd5; rs2_data_i=32'd5;
        branch_funct3_i=3'b000; #2;       // BEQ taken
        chk(branch_target_o, 32'h240, "branch target: 0x200+0x40=0x240");
        chk(pc_src_o,        2'b01,   "pc_src=branch on taken BEQ");

        // Negative branch offset: PC + (-8)
        imm_i=32'hFFFFFFF8; #2;
        chk(branch_target_o, 32'h1F8, "branch target: 0x200-8=0x1F8");

        // =====================================================================
        // TC5 — JAL
        // =====================================================================
        $display("\n=== TC5: JAL ===");
        reset_inputs;
        pc_if_i=32'h300; imm_i=32'h100;  // JAL offset +256
        is_jal_i=1'b1; #2;
        chk(jump_target_o, 32'h400,  "JAL target: 0x300+0x100=0x400");
        chk(pc_src_o,      2'b10,    "JAL: pc_src=jump");
        chk(flush_o,       1,        "JAL: flush=1");
        chk(is_jump_o,     1,        "JAL: is_jump=1");

        // =====================================================================
        // TC6 — JALR (bit-0 clearing)
        // =====================================================================
        $display("\n=== TC6: JALR ===");
        reset_inputs;
        rs1_data_i=32'h100; imm_i=32'h5;  // rs1+imm = 0x105, bit0 cleared -> 0x104
        is_jalr_i=1'b1; #2;
        chk(jump_target_o, 32'h104, "JALR target: (0x100+5)&~1 = 0x104");
        chk(pc_src_o,      2'b10,   "JALR: pc_src=jump");
        chk(is_jump_o,     1,       "JALR: is_jump=1");

        // Even address stays even
        rs1_data_i=32'h200; imm_i=32'h10; #2;
        chk(jump_target_o, 32'h210, "JALR target: (0x200+0x10)&~1=0x210");

        // =====================================================================
        // TC7 — LUI: result = imm (src_a=zero)
        // =====================================================================
        $display("\n=== TC7: LUI ===");
        reset_inputs;
        alu_src_a_i=2'b10; alu_src_b_i=1'b1; imm_i=32'hDEAD0000; #2;
        chk(alu_result_o, 32'hDEAD0000, "LUI: result = imm");

        // =====================================================================
        // TC8 — AUIPC: result = PC + imm (src_a=PC)
        // =====================================================================
        $display("\n=== TC8: AUIPC ===");
        reset_inputs;
        pc_if_i=32'h400; imm_i=32'h00010000;
        alu_src_a_i=2'b01; alu_src_b_i=1'b1; #2;
        chk(alu_result_o, 32'h00010400, "AUIPC: 0x400+0x10000=0x10400");

        // =====================================================================
        // TC9 — Conv-PE dispatch and stall
        // =====================================================================
        $display("\n=== TC9: Conv-PE dispatch and stall ===");
        reset_inputs;
        rs1_data_i=32'd6; rs2_data_i=32'd7;  // 6*7=42
        @(negedge clk);
        conv_start_i=1'b1; conv_init_i=1'b1;
        @(negedge clk); conv_start_i=1'b0;

        // Count stall cycles
        busy_cnt = 0;
        while (stall_o) begin busy_cnt=busy_cnt+1; @(negedge clk); end

        chk(busy_cnt,      CONV_LATENCY, "conv stall cycles == CONV_LATENCY");
        chk(conv_result_o, 32'd42,       "conv result: 6*7=42");
        chk(stall_o,       0,            "stall deasserted after DONE");

        // =====================================================================
        // TC10 — Stall does not fire without conv_start
        // =====================================================================
        $display("\n=== TC10: No stall without conv_start ===");
        reset_inputs; #2;
        chk(stall_o, 0, "stall=0 when conv_start=0");

        // =====================================================================
        // TC11 — is_jump_o
        // =====================================================================
        $display("\n=== TC11: is_jump_o ===");
        reset_inputs; is_jal_i=1'b1;  #2; chk(is_jump_o, 1, "JAL:  is_jump=1");
        reset_inputs; is_jalr_i=1'b1; #2; chk(is_jump_o, 1, "JALR: is_jump=1");
        reset_inputs;                  #2; chk(is_jump_o, 0, "R-type: is_jump=0");
        reset_inputs; is_branch_i=1'b1; rs1_data_i=rs2_data_i;
        branch_funct3_i=3'b000; #2;
        chk(is_jump_o, 0, "BEQ taken: is_jump=0 (not a jump)");

        // =====================================================================
        // TC12 — Pass-through signals
        // =====================================================================
        $display("\n=== TC12: Pass-through signals ===");
        reset_inputs;
        mem_read_i=1'b1; mem_write_i=1'b0; mem_size_i=2'b01;
        mem_sign_ext_i=1'b0; wb_sel_i=2'b01; reg_write_i=1'b1;
        rd_addr_i=5'd15; pc_plus4_i=32'h508;
        rs2_data_i=32'hCAFEBEEF; #2;
        chk(mem_read_o,     1,           "mem_read pass-through");
        chk(mem_write_o,    0,           "mem_write pass-through");
        chk(mem_size_o,     2'b01,       "mem_size pass-through");
        chk(mem_sign_ext_o, 0,           "mem_sign_ext pass-through");
        chk(wb_sel_o,       2'b01,       "wb_sel pass-through");
        chk(reg_write_o,    1,           "reg_write pass-through");
        chk(rd_addr_o,      5'd15,       "rd_addr pass-through");
        chk(pc_plus4_o,     32'h508,     "pc_plus4 pass-through");
        chk(rs2_data_o,     32'hCAFEBEEF,"rs2_data pass-through (store data)");

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

    initial begin #100000; $display("WATCHDOG TIMEOUT"); $finish; end

endmodule