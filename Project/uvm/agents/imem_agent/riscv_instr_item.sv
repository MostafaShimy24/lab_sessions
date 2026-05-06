//==============================================================================
// riscv_instr_item.sv — UVM Sequence Item for a Single RV32I Instruction
//------------------------------------------------------------------------------
// Encodes one 32-bit RV32I instruction with constrained-random fields.
// The sequence is responsible for high-level generation logic (NOP insertion,
// register tracking); this item just holds and assembles the instruction word.
//==============================================================================

class riscv_instr_item extends uvm_sequence_item;

    `uvm_object_utils(riscv_instr_item)

    // =========================================================================
    // Instruction fields
    // =========================================================================
    rand bit [6:0]  opcode;
    rand bit [4:0]  rd;
    rand bit [4:0]  rs1;
    rand bit [4:0]  rs2;
    rand bit [2:0]  funct3;
    rand bit [6:0]  funct7;
    rand bit [11:0] imm_i;      // I-type immediate
    rand bit [11:0] imm_s;      // S-type immediate
    rand bit [12:0] imm_b;      // B-type immediate (13 bits, bit[0]=0)
    rand bit [19:0] imm_u;      // U-type upper 20 bits
    rand bit [20:0] imm_j;      // J-type immediate (21 bits, bit[0]=0)

    // Assembled 32-bit instruction word (set by post_randomize or assemble())
    bit [31:0] instr;

    // =========================================================================
    // Opcode constants
    // =========================================================================
    typedef enum bit [6:0] {
        OP_R       = 7'b0110011,
        OP_I_ARITH = 7'b0010011,
        OP_LOAD    = 7'b0000011,
        OP_STORE   = 7'b0100011,
        OP_BRANCH  = 7'b1100011,
        OP_JAL     = 7'b1101111,
        OP_JALR    = 7'b1100111,
        OP_LUI     = 7'b0110111,
        OP_AUIPC   = 7'b0010111,
        OP_FENCE   = 7'b0001111,
        OP_SYSTEM  = 7'b1110011,
        OP_CUSTOM0 = 7'b0001011
    } opcode_e;

    // =========================================================================
    // Constraints
    // =========================================================================

    // Restrict opcode to valid RV32I values
    constraint c_valid_opcode {
        opcode inside {7'b0110011, 7'b0010011, 7'b0000011, 7'b0100011,
                       7'b1100011, 7'b1101111, 7'b1100111, 7'b0110111,
                       7'b0010111, 7'b0001111, 7'b1110011, 7'b0001011};
    }

    // Don't write to x0 (waste)
    constraint c_rd_nonzero {
        !(opcode inside {7'b0100011, 7'b1100011, 7'b0001111, 7'b1110011}) ->
            rd != 5'd0;
    }

    // R-type: valid funct3/funct7 combinations
    constraint c_rtype_fields {
        if (opcode == 7'b0110011) {
            funct3 inside {3'b000, 3'b001, 3'b010, 3'b011,
                           3'b100, 3'b101, 3'b110, 3'b111};
            if (funct3 == 3'b000) funct7 inside {7'b0000000, 7'b0100000};  // ADD/SUB
            if (funct3 == 3'b101) funct7 inside {7'b0000000, 7'b0100000};  // SRL/SRA
            if (funct3 inside {3'b001, 3'b010, 3'b011, 3'b100, 3'b110, 3'b111})
                funct7 == 7'b0000000;
        }
    }

    // I-type arithmetic: valid funct3, and funct7 for shifts
    constraint c_itype_fields {
        if (opcode == 7'b0010011) {
            funct3 inside {3'b000, 3'b001, 3'b010, 3'b011,
                           3'b100, 3'b101, 3'b110, 3'b111};
            if (funct3 == 3'b001) imm_i[11:5] == 7'b0000000;  // SLLI
            if (funct3 == 3'b101) imm_i[11:5] inside {7'b0000000, 7'b0100000}; // SRLI/SRAI
        }
    }

    // Load: valid funct3
    constraint c_load_fields {
        if (opcode == 7'b0000011) {
            funct3 inside {3'b000, 3'b001, 3'b010, 3'b100, 3'b101}; // LB,LH,LW,LBU,LHU
        }
    }

    // Store: valid funct3
    constraint c_store_fields {
        if (opcode == 7'b0100011) {
            funct3 inside {3'b000, 3'b001, 3'b010}; // SB, SH, SW
        }
    }

    // Branch: valid funct3
    constraint c_branch_fields {
        if (opcode == 7'b1100011) {
            funct3 inside {3'b000, 3'b001, 3'b100, 3'b101, 3'b110, 3'b111};
        }
    }

    // B-type immediate: bit[0] always 0
    constraint c_branch_imm_aligned {
        imm_b[0] == 1'b0;
    }

    // J-type immediate: bit[0] always 0
    constraint c_jal_imm_aligned {
        imm_j[0] == 1'b0;
    }

    // Custom-0: funct3 = 0, funct7[6:1] = 0
    constraint c_custom0_fields {
        if (opcode == 7'b0001011) {
            funct3 == 3'b000;
            funct7[6:1] == 6'b000000;   // only funct7[0] = init bit varies
        }
    }

    // =========================================================================
    // Constructor
    // =========================================================================
    function new(string name = "riscv_instr_item");
        super.new(name);
    endfunction

    // =========================================================================
    // Assemble the 32-bit instruction word from fields
    // =========================================================================
    function void assemble();
        case (opcode)
            7'b0110011: begin // R-type
                instr = {funct7, rs2, rs1, funct3, rd, opcode};
            end
            7'b0010011, 7'b0000011, 7'b1100111: begin // I-type
                instr = {imm_i, rs1, funct3, rd, opcode};
            end
            7'b0100011: begin // S-type
                instr = {imm_s[11:5], rs2, rs1, funct3, imm_s[4:0], opcode};
            end
            7'b1100011: begin // B-type
                instr = {imm_b[12], imm_b[10:5], rs2, rs1, funct3,
                         imm_b[4:1], imm_b[11], opcode};
            end
            7'b0110111, 7'b0010111: begin // U-type (LUI, AUIPC)
                instr = {imm_u, rd, opcode};
            end
            7'b1101111: begin // J-type (JAL)
                instr = {imm_j[20], imm_j[10:1], imm_j[11], imm_j[19:12],
                         rd, opcode};
            end
            7'b0001111: begin // FENCE
                instr = 32'h0000000F;
            end
            7'b1110011: begin // SYSTEM (ECALL/EBREAK)
                instr = (imm_i[0]) ? 32'h00100073 : 32'h00000073;
            end
            7'b0001011: begin // custom-0 (Conv-PE) — R-type encoding
                instr = {funct7, rs2, rs1, funct3, rd, opcode};
            end
            default: begin
                instr = 32'h00000013; // NOP
            end
        endcase
    endfunction

    function void post_randomize();
        assemble();
    endfunction

    // =========================================================================
    // Helper: create a NOP instruction
    // =========================================================================
    static function riscv_instr_item create_nop(string name = "nop");
        riscv_instr_item nop_item = new(name);
        nop_item.instr = 32'h00000013;
        nop_item.opcode = 7'b0010011;
        nop_item.rd = 5'd0;
        nop_item.rs1 = 5'd0;
        nop_item.imm_i = 12'd0;
        nop_item.funct3 = 3'b000;
        return nop_item;
    endfunction

    // =========================================================================
    // Helper: create an instruction from a raw 32-bit word
    // =========================================================================
    static function riscv_instr_item create_from_word(bit [31:0] word, string name = "raw");
        riscv_instr_item item = new(name);
        item.instr  = word;
        item.opcode = word[6:0];
        item.rd     = word[11:7];
        item.funct3 = word[14:12];
        item.rs1    = word[19:15];
        item.rs2    = word[24:20];
        item.funct7 = word[31:25];
        item.imm_i  = word[31:20];
        item.imm_s  = {word[31:25], word[11:7]};
        return item;
    endfunction

    // =========================================================================
    // Utility: convert to string for debug
    // =========================================================================
    virtual function string convert2string();
        return $sformatf("instr=0x%08h opcode=%07b rd=%0d rs1=%0d rs2=%0d funct3=%03b funct7=%07b",
                         instr, opcode, rd, rs1, rs2, funct3, funct7);
    endfunction

endclass : riscv_instr_item
