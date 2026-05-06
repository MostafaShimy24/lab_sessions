//==============================================================================
// seq_mem.sv — SEQ_MEM: Memory Load/Store Verification Sequence
//==============================================================================

class seq_mem extends uvm_sequence #(riscv_instr_item);

    `uvm_object_utils(seq_mem)

    function new(string name = "seq_mem");
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
        `uvm_info("SEQ_MEM", "Starting memory sequence", UVM_MEDIUM)

        // x1 = 0x100 (base address)
        emit_raw(32'h10000093); emit_nops(4);
        // x2 = 0xDEADBEEF via LUI + ADDI
        emit_raw(32'hDEADB137); emit_nops(4);
        emit_raw(32'hEEF10113); emit_nops(4);
        // x3 = 0x1234
        emit_raw(32'h00001237); emit_nops(4);
        emit_raw(32'h23418193); emit_nops(4);
        // x4 = 0xAB
        emit_raw(32'h0AB00213); emit_nops(4);
        // x5 = 0x1FF
        emit_raw(32'h1FF00293); emit_nops(4);
        // x6 = 0x110 (half base)
        emit_raw(32'h11000313); emit_nops(4);
        // x7 = 0x120 (byte base)
        emit_raw(32'h12000393); emit_nops(4);

        // --- Word SW/LW ---
        // SW x2, 0(x1)
        emit_raw({7'b0000000, 5'd2, 5'd1, 3'b010, 5'b00000, 7'b0100011}); emit_nops(4);
        // LW x8, 0(x1)
        emit_raw({12'h000, 5'd1, 3'b010, 5'd8, 7'b0000011}); emit_nops(4);
        // SW x3, 4(x1)
        emit_raw({7'b0000000, 5'd3, 5'd1, 3'b010, 5'b00100, 7'b0100011}); emit_nops(4);
        // LW x9, 4(x1)
        emit_raw({12'h004, 5'd1, 3'b010, 5'd9, 7'b0000011}); emit_nops(4);

        // --- Half SH/LH/LHU ---
        // SH x5, 0(x6)
        emit_raw({7'b0000000, 5'd5, 5'd6, 3'b001, 5'b00000, 7'b0100011}); emit_nops(4);
        // LH x10, 0(x6)
        emit_raw({12'h000, 5'd6, 3'b001, 5'd10, 7'b0000011}); emit_nops(4);
        // LHU x11, 0(x6)
        emit_raw({12'h000, 5'd6, 3'b101, 5'd11, 7'b0000011}); emit_nops(4);

        // --- Byte SB/LB/LBU ---
        // SB x4, 0(x7)
        emit_raw({7'b0000000, 5'd4, 5'd7, 3'b000, 5'b00000, 7'b0100011}); emit_nops(4);
        // LB x15, 0(x7)
        emit_raw({12'h000, 5'd7, 3'b000, 5'd15, 7'b0000011}); emit_nops(4);
        // LBU x16, 0(x7)
        emit_raw({12'h000, 5'd7, 3'b100, 5'd16, 7'b0000011}); emit_nops(4);

        // Terminal loop
        emit_raw(32'h0000006F);
        `uvm_info("SEQ_MEM", "Memory sequence complete", UVM_MEDIUM)
    endtask

endclass : seq_mem
