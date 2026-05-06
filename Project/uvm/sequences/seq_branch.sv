//==============================================================================
// seq_branch.sv — SEQ_BRANCH: Branch Verification Sequence
//------------------------------------------------------------------------------
// Tests all 6 RV32I branch types (BEQ, BNE, BLT, BGE, BLTU, BGEU),
// each both taken and not-taken. A marker register is written at the
// branch target to confirm taken execution.
//==============================================================================

class seq_branch extends uvm_sequence #(riscv_instr_item);

    `uvm_object_utils(seq_branch)

    function new(string name = "seq_branch");
        super.new(name);
    endfunction

    task emit_nops(int count = 4);
        riscv_instr_item nop;
        repeat (count) begin
            nop = riscv_instr_item::create_nop("nop");
            start_item(nop);
            finish_item(nop);
        end
    endtask

    task emit_raw(bit [31:0] word);
        riscv_instr_item item;
        item = riscv_instr_item::create_from_word(word, "raw");
        start_item(item);
        finish_item(item);
    endtask

    virtual task body();
        `uvm_info("SEQ_BRANCH", "Starting branch sequence", UVM_MEDIUM)

        // =================================================================
        // Setup: Initialise operand registers
        // =================================================================
        // x1 = 5
        emit_raw(32'h00500093); emit_nops(4);
        // x2 = 5 (equal to x1 for BEQ)
        emit_raw(32'h00500113); emit_nops(4);
        // x3 = 10 (different from x1 for BNE)
        emit_raw(32'h00A00193); emit_nops(4);
        // x4 = -5 (for signed comparisons)
        emit_raw(32'hFFB00213); emit_nops(4);
        // x5 = 0xFFFFFFFB (unsigned large, same bit pattern as -5)
        // Already set by x4 above, same register
        // x30 = 0 (clear marker)
        emit_raw(32'h00000F13); emit_nops(4);
        // x31 = 0 (clear marker)
        emit_raw(32'h00000F93); emit_nops(4);

        // =================================================================
        // Test 1: BEQ taken (x1 == x2, both = 5)
        // Branch offset = +20 bytes (skip 5 instructions = 5*4 = 20)
        // B-type encoding for offset 20: imm[12|10:5]=0000001, imm[4:1|11]=01000
        // =================================================================
        `uvm_info("SEQ_BRANCH", "BEQ taken test", UVM_MEDIUM)
        // BEQ x1, x2, +20
        emit_raw({1'b0, 6'b000001, 5'd2, 5'd1, 3'b000, 4'b0100, 1'b0, 7'b1100011});
        emit_nops(4);
        // This should be skipped (BEQ taken):
        emit_raw(32'hBAD00F13); // ADDI x30, x0, BAD (marker = overwritten if NOT taken)
        // Branch target lands here:
        emit_raw(32'h01100F13); // ADDI x30, x0, 0x11 (marker = 0x11 if taken)
        emit_nops(4);

        // =================================================================
        // Test 2: BEQ not-taken (x1 != x3)
        // =================================================================
        `uvm_info("SEQ_BRANCH", "BEQ not-taken test", UVM_MEDIUM)
        // Clear x30
        emit_raw(32'h00000F13); emit_nops(4);
        // BEQ x1, x3, +20 (should NOT be taken since 5 != 10)
        emit_raw({1'b0, 6'b000001, 5'd3, 5'd1, 3'b000, 4'b0100, 1'b0, 7'b1100011});
        emit_nops(4);
        // This SHOULD execute (not taken):
        emit_raw(32'h02200F13); // ADDI x30, x0, 0x22
        // Target (should be skipped):
        emit_raw(32'hBAD00F13); // overwritten if erroneously taken
        emit_nops(4);

        // =================================================================
        // Test 3: BNE taken (x1 != x3)
        // =================================================================
        `uvm_info("SEQ_BRANCH", "BNE taken test", UVM_MEDIUM)
        emit_raw(32'h00000F93); emit_nops(4); // clear x31
        // BNE x1, x3, +20
        emit_raw({1'b0, 6'b000001, 5'd3, 5'd1, 3'b001, 4'b0100, 1'b0, 7'b1100011});
        emit_nops(4);
        emit_raw(32'hBAD00F93); // skipped
        emit_raw(32'h03300F93); // target: x31 = 0x33
        emit_nops(4);

        // =================================================================
        // Test 4: BNE not-taken (x1 == x2)
        // =================================================================
        `uvm_info("SEQ_BRANCH", "BNE not-taken test", UVM_MEDIUM)
        emit_raw(32'h00000F13); emit_nops(4); // clear x30
        // BNE x1, x2, +20 (should NOT be taken since 5 == 5)
        emit_raw({1'b0, 6'b000001, 5'd2, 5'd1, 3'b001, 4'b0100, 1'b0, 7'b1100011});
        emit_nops(4);
        emit_raw(32'h04400F13); // NOT taken: x30 = 0x44
        emit_raw(32'hBAD00F13); // target skipped
        emit_nops(4);

        // =================================================================
        // Test 5: BLT taken (x4=-5 < x1=5, signed)
        // =================================================================
        `uvm_info("SEQ_BRANCH", "BLT taken test", UVM_MEDIUM)
        emit_raw(32'h00000F93); emit_nops(4);
        // BLT x4, x1, +20
        emit_raw({1'b0, 6'b000001, 5'd1, 5'd4, 3'b100, 4'b0100, 1'b0, 7'b1100011});
        emit_nops(4);
        emit_raw(32'hBAD00F93); // skipped
        emit_raw(32'h05500F93); // target: x31 = 0x55
        emit_nops(4);

        // =================================================================
        // Test 6: BLT not-taken (x1=5 >= x4=-5)
        // =================================================================
        `uvm_info("SEQ_BRANCH", "BLT not-taken test", UVM_MEDIUM)
        emit_raw(32'h00000F13); emit_nops(4);
        // BLT x1, x4, +20 (5 < -5? NO)
        emit_raw({1'b0, 6'b000001, 5'd4, 5'd1, 3'b100, 4'b0100, 1'b0, 7'b1100011});
        emit_nops(4);
        emit_raw(32'h06600F13); // NOT taken: x30 = 0x66
        emit_raw(32'hBAD00F13);
        emit_nops(4);

        // =================================================================
        // Test 7: BGE taken (x1=5 >= x4=-5, signed)
        // =================================================================
        `uvm_info("SEQ_BRANCH", "BGE taken test", UVM_MEDIUM)
        emit_raw(32'h00000F93); emit_nops(4);
        // BGE x1, x4, +20
        emit_raw({1'b0, 6'b000001, 5'd4, 5'd1, 3'b101, 4'b0100, 1'b0, 7'b1100011});
        emit_nops(4);
        emit_raw(32'hBAD00F93);
        emit_raw(32'h07700F93); // target: x31 = 0x77
        emit_nops(4);

        // =================================================================
        // Test 8: BGE not-taken (x4=-5 < x1=5)
        // =================================================================
        `uvm_info("SEQ_BRANCH", "BGE not-taken test", UVM_MEDIUM)
        emit_raw(32'h00000F13); emit_nops(4);
        // BGE x4, x1, +20 (-5 >= 5? NO)
        emit_raw({1'b0, 6'b000001, 5'd1, 5'd4, 3'b101, 4'b0100, 1'b0, 7'b1100011});
        emit_nops(4);
        emit_raw(32'h08800F13); // NOT taken: x30 = 0x88
        emit_raw(32'hBAD00F13);
        emit_nops(4);

        // =================================================================
        // Test 9: BLTU taken (x1=5 < x4=0xFFFFFFFB, unsigned)
        // =================================================================
        `uvm_info("SEQ_BRANCH", "BLTU taken test", UVM_MEDIUM)
        emit_raw(32'h00000F93); emit_nops(4);
        // BLTU x1, x4, +20 (5 < 0xFFFFFFFB unsigned? YES)
        emit_raw({1'b0, 6'b000001, 5'd4, 5'd1, 3'b110, 4'b0100, 1'b0, 7'b1100011});
        emit_nops(4);
        emit_raw(32'hBAD00F93);
        emit_raw(32'h09900F93); // target: x31 = 0x99
        emit_nops(4);

        // =================================================================
        // Test 10: BLTU not-taken (x4=0xFFFFFFFB > x1=5, unsigned)
        // =================================================================
        `uvm_info("SEQ_BRANCH", "BLTU not-taken test", UVM_MEDIUM)
        emit_raw(32'h00000F13); emit_nops(4);
        // BLTU x4, x1, +20 (0xFFFFFFFB < 5? NO)
        emit_raw({1'b0, 6'b000001, 5'd1, 5'd4, 3'b110, 4'b0100, 1'b0, 7'b1100011});
        emit_nops(4);
        emit_raw(32'h0AA00F13); // NOT taken: x30 = 0xAA
        emit_raw(32'hBAD00F13);
        emit_nops(4);

        // =================================================================
        // Test 11: BGEU taken (x4=0xFFFFFFFB >= x1=5, unsigned)
        // =================================================================
        `uvm_info("SEQ_BRANCH", "BGEU taken test", UVM_MEDIUM)
        emit_raw(32'h00000F93); emit_nops(4);
        // BGEU x4, x1, +20
        emit_raw({1'b0, 6'b000001, 5'd1, 5'd4, 3'b111, 4'b0100, 1'b0, 7'b1100011});
        emit_nops(4);
        emit_raw(32'hBAD00F93);
        emit_raw(32'h0BB00F93); // target: x31 = 0xBB
        emit_nops(4);

        // =================================================================
        // Test 12: BGEU not-taken (x1=5 < x4=0xFFFFFFFB, unsigned)
        // =================================================================
        `uvm_info("SEQ_BRANCH", "BGEU not-taken test", UVM_MEDIUM)
        emit_raw(32'h00000F13); emit_nops(4);
        // BGEU x1, x4, +20 (5 >= 0xFFFFFFFB? NO)
        emit_raw({1'b0, 6'b000001, 5'd4, 5'd1, 3'b111, 4'b0100, 1'b0, 7'b1100011});
        emit_nops(4);
        emit_raw(32'h0CC00F13); // NOT taken: x30 = 0xCC
        emit_raw(32'hBAD00F13);
        emit_nops(4);

        // Terminal loop
        emit_raw(32'h0000006F);
        `uvm_info("SEQ_BRANCH", "Branch sequence complete", UVM_MEDIUM)
    endtask

endclass : seq_branch
