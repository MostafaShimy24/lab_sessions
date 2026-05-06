//==============================================================================
// seq_arith.sv — SEQ_ARITH: Randomised Arithmetic Sequence (200+ instructions)
//------------------------------------------------------------------------------
// Generates a constrained-random sequence of R-type and I-type arithmetic
// instructions (including LUI, AUIPC, and Conv-PE custom-0) with 4 NOP
// spacers between every pair of dependent instructions.
//
// Strategy:
//   1. Initialise x1–x8 with diverse values (including ALU boundary values)
//   2. Generate 200+ random arithmetic instructions using those registers
//   3. Include Conv-PE init + accumulate pairs
//   4. Terminate with self-loop (JAL x0, 0)
//==============================================================================

class seq_arith extends uvm_sequence #(riscv_instr_item);

    `uvm_object_utils(seq_arith)

    // Number of arithmetic instructions (excluding NOPs and init)
    rand int unsigned num_arith_instrs;

    constraint c_num_instrs {
        num_arith_instrs inside {[200:250]};
    }

    function new(string name = "seq_arith");
        super.new(name);
    endfunction

    // =========================================================================
    // Helper: emit 4 NOPs for pipeline hazard spacing
    // =========================================================================
    task emit_nops(int count = 4);
        riscv_instr_item nop;
        repeat (count) begin
            nop = riscv_instr_item::create_nop("nop");
            start_item(nop);
            finish_item(nop);
        end
    endtask

    // =========================================================================
    // Helper: emit a raw 32-bit instruction word
    // =========================================================================
    task emit_raw(bit [31:0] word);
        riscv_instr_item item;
        item = riscv_instr_item::create_from_word(word, "raw");
        start_item(item);
        finish_item(item);
    endtask

    // =========================================================================
    // Body
    // =========================================================================
    virtual task body();
        riscv_instr_item item;
        int i;

        `uvm_info("SEQ_ARITH", $sformatf("Generating %0d arithmetic instructions", num_arith_instrs), UVM_MEDIUM)

        // -----------------------------------------------------------------
        // Phase 1: Initialise registers x1–x8 with diverse values
        // Including ALU boundary values: 0, 1, -1, 0x7FFFFFFF, 0x80000000
        // -----------------------------------------------------------------
        // x1 = 0
        emit_raw(32'h00000093);  // ADDI x1, x0, 0
        emit_nops(4);

        // x2 = 1
        emit_raw(32'h00100113);  // ADDI x2, x0, 1
        emit_nops(4);

        // x3 = -1 (0xFFFFFFFF)
        emit_raw(32'hFFF00193);  // ADDI x3, x0, -1
        emit_nops(4);

        // x4 = 5
        emit_raw(32'h00500213);  // ADDI x4, x0, 5
        emit_nops(4);

        // x5 = 10
        emit_raw(32'h00A00293);  // ADDI x5, x0, 10
        emit_nops(4);

        // x6 = 0x7FFFFFFF (max positive) using LUI + ADDI
        emit_raw(32'h80000337);  // LUI x6, 0x80000 (x6 = 0x80000000)
        emit_nops(4);
        emit_raw(32'hFFF30313);  // ADDI x6, x6, -1 (x6 = 0x7FFFFFFF)
        emit_nops(4);

        // x7 = 0x80000000 (min negative) using LUI
        emit_raw(32'h800003B7);  // LUI x7, 0x80000 (x7 = 0x80000000)
        emit_nops(4);

        // x8 = 42
        emit_raw(32'h02A00413);  // ADDI x8, x0, 42
        emit_nops(4);

        // -----------------------------------------------------------------
        // Phase 2: Generate random arithmetic instructions
        // -----------------------------------------------------------------
        for (i = 0; i < num_arith_instrs; i++) begin
            item = riscv_instr_item::type_id::create($sformatf("arith_%0d", i));

            // Constrain to arithmetic opcodes only
            assert(item.randomize() with {
                opcode inside {7'b0110011, 7'b0010011, 7'b0110111, 7'b0010111};
                // Use initialised source registers
                rs1 inside {[1:8]};
                rs2 inside {[1:8]};
                // Write to x9–x31 to avoid clobbering source regs
                rd inside {[9:31]};
            }) else `uvm_error("SEQ_ARITH", "Randomization failed")

            start_item(item);
            finish_item(item);
            emit_nops(4);
        end

        // -----------------------------------------------------------------
        // Phase 3: Conv-PE instructions (init + accumulate)
        // -----------------------------------------------------------------
        `uvm_info("SEQ_ARITH", "Adding Conv-PE custom-0 instructions", UVM_MEDIUM)

        // Load operands for Conv-PE: use x4=5, x5=10
        // Conv-PE INIT: acc = x4 * x5 = 50, funct7[0]=1
        // Encoding: funct7=0000001, rs2=x5, rs1=x4, funct3=000, rd=x9, opcode=0001011
        emit_raw({7'b0000001, 5'd5, 5'd4, 3'b000, 5'd9, 7'b0001011});
        emit_nops(8); // Extra NOPs for Conv-PE latency

        // Conv-PE ACC: acc = acc + x2 * x8 = 50 + 1*42 = 92, funct7[0]=0
        emit_raw({7'b0000000, 5'd8, 5'd2, 3'b000, 5'd10, 7'b0001011});
        emit_nops(8);

        // -----------------------------------------------------------------
        // Phase 4: Terminal self-loop
        // -----------------------------------------------------------------
        emit_raw(32'h0000006F);  // JAL x0, 0 (infinite loop)

        `uvm_info("SEQ_ARITH", "Sequence complete", UVM_MEDIUM)
    endtask

endclass : seq_arith
