//==============================================================================
// tb_id_stage.v — Self-Checking Directed Testbench for id_stage
//------------------------------------------------------------------------------
// Tests (one per RV32I instruction class + Conv-PE):
//   TC1  — R-type arithmetic  : ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
//   TC2  — I-type arithmetic  : ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
//   TC3  — Loads              : LB, LH, LW, LBU, LHU
//   TC4  — Stores             : SB, SH, SW
//   TC5  — Branches           : BEQ, BNE, BLT, BGE, BLTU, BGEU
//   TC6  — JAL
//   TC7  — JALR
//   TC8  — LUI
//   TC9  — AUIPC
//   TC10 — FENCE / ECALL / EBREAK (NOP behaviour)
//   TC11 — Custom-0 (Conv-PE) : conv_start, conv_init
//   TC12 — Immediate encoding correctness for all formats
//   TC13 — Register file write-back via wb_ port, read-back via rs1/rs2
//==============================================================================
`timescale 1ns / 1ps

module tb_id_stage;

    localparam CLK_PERIOD = 10;

    // ---- DUT ports ----------------------------------------------------------
    reg         clk, rst_n;
    reg  [31:0] pc_if_i, pc_plus4_i, instr_i;
    reg         wb_we_i;
    reg  [4:0]  wb_addr_i;
    reg  [31:0] wb_data_i;

    wire [31:0] pc_if_o, pc_plus4_o;
    wire [31:0] rs1_data_o, rs2_data_o;
    wire [4:0]  rs1_addr_o, rs2_addr_o, rd_addr_o;
    wire [31:0] imm_o;
    wire [3:0]  alu_op_o;
    wire [1:0]  alu_src_a_o;
    wire        alu_src_b_o;
    wire        mem_read_o, mem_write_o;
    wire [1:0]  mem_size_o;
    wire        mem_sign_ext_o;
    wire [1:0]  wb_sel_o;
    wire        reg_write_o;
    wire        is_branch_o;
    wire [2:0]  branch_funct3_o;
    wire        is_jal_o, is_jalr_o;
    wire        conv_start_o, conv_init_o;

    // ---- DUT ----------------------------------------------------------------
    id_stage dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .pc_if_i        (pc_if_i),
        .pc_plus4_i     (pc_plus4_i),
        .instr_i        (instr_i),
        .wb_we_i        (wb_we_i),
        .wb_addr_i      (wb_addr_i),
        .wb_data_i      (wb_data_i),
        .pc_if_o        (pc_if_o),
        .pc_plus4_o     (pc_plus4_o),
        .rs1_data_o     (rs1_data_o),
        .rs2_data_o     (rs2_data_o),
        .rs1_addr_o     (rs1_addr_o),
        .rs2_addr_o     (rs2_addr_o),
        .rd_addr_o      (rd_addr_o),
        .imm_o          (imm_o),
        .alu_op_o       (alu_op_o),
        .alu_src_a_o    (alu_src_a_o),
        .alu_src_b_o    (alu_src_b_o),
        .mem_read_o     (mem_read_o),
        .mem_write_o    (mem_write_o),
        .mem_size_o     (mem_size_o),
        .mem_sign_ext_o (mem_sign_ext_o),
        .wb_sel_o       (wb_sel_o),
        .reg_write_o    (reg_write_o),
        .is_branch_o    (is_branch_o),
        .branch_funct3_o(branch_funct3_o),
        .is_jal_o       (is_jal_o),
        .is_jalr_o      (is_jalr_o),
        .conv_start_o   (conv_start_o),
        .conv_init_o    (conv_init_o)
    );

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ---- Helpers ------------------------------------------------------------
    integer pass_count, fail_count;

    task chk;
        input [31:0] got;
        input [31:0] exp;
        input [255:0] lbl;
        begin
            if (got === exp) begin
                $display("    PASS  %-44s  got=0x%0h", lbl, got);
                pass_count = pass_count + 1;
            end else begin
                $display("    FAIL  %-44s  got=0x%0h  exp=0x%0h", lbl, got, exp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Present instruction, let combinational settle, check
    task present;
        input [31:0] instr;
        input [31:0] pc;
        begin
            instr_i   = instr;
            pc_if_i   = pc;
            pc_plus4_i = pc + 4;
            #2;   // combinational settle
        end
    endtask

    // Write a value into regfile via WB port, wait one cycle
    task wb_write;
        input [4:0]  addr;
        input [31:0] data;
        begin
            @(negedge clk);
            wb_we_i   = 1'b1;
            wb_addr_i = addr;
            wb_data_i = data;
            @(negedge clk);
            wb_we_i   = 1'b0;
        end
    endtask

    // RV32I instruction encoders
    // R-type: funct7 | rs2 | rs1 | funct3 | rd | opcode
    function [31:0] enc_r;
        input [6:0] f7; input [4:0] rs2,rs1; input [2:0] f3;
        input [4:0] rd; input [6:0] op;
        enc_r = {f7, rs2, rs1, f3, rd, op};
    endfunction

    // I-type: imm[11:0] | rs1 | funct3 | rd | opcode
    function [31:0] enc_i;
        input [11:0] imm; input [4:0] rs1; input [2:0] f3;
        input [4:0] rd;   input [6:0] op;
        enc_i = {imm, rs1, f3, rd, op};
    endfunction

    // S-type: imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode
    function [31:0] enc_s;
        input [11:0] imm; input [4:0] rs2,rs1; input [2:0] f3;
        input [6:0] op;
        enc_s = {imm[11:5], rs2, rs1, f3, imm[4:0], op};
    endfunction

    // B-type: imm[12|10:5] | rs2 | rs1 | funct3 | imm[4:1|11] | opcode
    function [31:0] enc_b;
        input [12:0] imm; input [4:0] rs2,rs1; input [2:0] f3;
        input [6:0] op;
        enc_b = {imm[12], imm[10:5], rs2, rs1, f3, imm[4:1], imm[11], op};
    endfunction

    // U-type: imm[31:12] | rd | opcode
    function [31:0] enc_u;
        input [19:0] imm; input [4:0] rd; input [6:0] op;
        enc_u = {imm, rd, op};
    endfunction

    // J-type: imm[20|10:1|11|19:12] | rd | opcode
    function [31:0] enc_j;
        input [20:0] imm; input [4:0] rd; input [6:0] op;
        enc_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, op};
    endfunction

    // ALU op codes
    localparam ALU_ADD=4'b0000, ALU_SUB=4'b0001, ALU_SLL=4'b0010,
               ALU_SLT=4'b0011, ALU_SLTU=4'b0100, ALU_XOR=4'b0101,
               ALU_SRL=4'b0110, ALU_SRA=4'b0111,
               ALU_OR =4'b1000, ALU_AND =4'b1001;

    // Opcode constants
    localparam OP_R=7'h33, OP_I=7'h13, OP_LOAD=7'h03, OP_STORE=7'h23,
               OP_BR=7'h63, OP_JAL=7'h6F, OP_JALR=7'h67,
               OP_LUI=7'h37, OP_AUIPC=7'h17,
               OP_FENCE=7'h0F, OP_SYS=7'h73, OP_CUSTOM0=7'h0B;

    // =========================================================================
    initial begin
        $dumpfile("tb_id_stage.vcd");
        $dumpvars(0, tb_id_stage);
        pass_count = 0; fail_count = 0;

        rst_n     = 0; wb_we_i = 0;
        instr_i   = 32'h00000013;   // NOP
        pc_if_i   = 0; pc_plus4_i = 4;
        wb_addr_i = 0; wb_data_i = 0;
        repeat(3) @(posedge clk);
        @(negedge clk); rst_n = 1;
        @(negedge clk);

        // =====================================================================
        // TC1 — R-type arithmetic
        // =====================================================================
        $display("\n=== TC1: R-type arithmetic ===");
        // ADD x1, x2, x3  (funct7=0, funct3=000)
        present(enc_r(7'h00,3,2,3'b000,1,OP_R), 32'h100);
        chk(alu_op_o,     ALU_ADD, "ADD: alu_op=ADD");
        chk(alu_src_a_o,  0,       "ADD: src_a=rs1");
        chk(alu_src_b_o,  0,       "ADD: src_b=rs2");
        chk(reg_write_o,  1,       "ADD: reg_write=1");
        chk(wb_sel_o,     0,       "ADD: wb_sel=ALU");

        // SUB x1, x2, x3  (funct7=0x20, funct3=000)
        present(enc_r(7'h20,3,2,3'b000,1,OP_R), 32'h100);
        chk(alu_op_o, ALU_SUB, "SUB: alu_op=SUB");

        // SLL
        present(enc_r(7'h00,3,2,3'b001,1,OP_R), 32'h100);
        chk(alu_op_o, ALU_SLL, "SLL: alu_op=SLL");

        // SLT
        present(enc_r(7'h00,3,2,3'b010,1,OP_R), 32'h100);
        chk(alu_op_o, ALU_SLT, "SLT: alu_op=SLT");

        // SLTU
        present(enc_r(7'h00,3,2,3'b011,1,OP_R), 32'h100);
        chk(alu_op_o, ALU_SLTU, "SLTU: alu_op=SLTU");

        // XOR
        present(enc_r(7'h00,3,2,3'b100,1,OP_R), 32'h100);
        chk(alu_op_o, ALU_XOR, "XOR: alu_op=XOR");

        // SRL (funct7=0)
        present(enc_r(7'h00,3,2,3'b101,1,OP_R), 32'h100);
        chk(alu_op_o, ALU_SRL, "SRL: alu_op=SRL");

        // SRA (funct7=0x20)
        present(enc_r(7'h20,3,2,3'b101,1,OP_R), 32'h100);
        chk(alu_op_o, ALU_SRA, "SRA: alu_op=SRA");

        // OR
        present(enc_r(7'h00,3,2,3'b110,1,OP_R), 32'h100);
        chk(alu_op_o, ALU_OR, "OR: alu_op=OR");

        // AND
        present(enc_r(7'h00,3,2,3'b111,1,OP_R), 32'h100);
        chk(alu_op_o, ALU_AND, "AND: alu_op=AND");

        // =====================================================================
        // TC2 — I-type arithmetic
        // =====================================================================
        $display("\n=== TC2: I-type arithmetic ===");
        // ADDI x1, x2, 100
        present(enc_i(12'd100, 2, 3'b000, 1, OP_I), 32'h100);
        chk(alu_op_o,    ALU_ADD, "ADDI: alu_op=ADD");
        chk(alu_src_b_o, 1,       "ADDI: src_b=imm");
        chk(imm_o,       32'd100, "ADDI: imm=100");
        chk(reg_write_o, 1,       "ADDI: reg_write=1");

        // SLTI
        present(enc_i(12'd50, 2, 3'b010, 1, OP_I), 32'h100);
        chk(alu_op_o, ALU_SLT,  "SLTI: alu_op=SLT");

        // SLTIU
        present(enc_i(12'd50, 2, 3'b011, 1, OP_I), 32'h100);
        chk(alu_op_o, ALU_SLTU, "SLTIU: alu_op=SLTU");

        // XORI
        present(enc_i(12'hFFF, 2, 3'b100, 1, OP_I), 32'h100);
        chk(alu_op_o, ALU_XOR, "XORI: alu_op=XOR");

        // ORI
        present(enc_i(12'hF0F, 2, 3'b110, 1, OP_I), 32'h100);
        chk(alu_op_o, ALU_OR,  "ORI: alu_op=OR");

        // ANDI
        present(enc_i(12'h0FF, 2, 3'b111, 1, OP_I), 32'h100);
        chk(alu_op_o, ALU_AND, "ANDI: alu_op=AND");

        // SLLI (funct7=0)
        present(enc_i(12'b000000_00101, 2, 3'b001, 1, OP_I), 32'h100);
        chk(alu_op_o, ALU_SLL, "SLLI: alu_op=SLL");

        // SRLI (funct7=0)
        present(enc_i(12'b000000_00011, 2, 3'b101, 1, OP_I), 32'h100);
        chk(alu_op_o, ALU_SRL, "SRLI: alu_op=SRL");

        // SRAI (funct7=0x20 -> imm[11:5]=0100000)
        present(enc_i(12'b0100000_00011, 2, 3'b101, 1, OP_I), 32'h100);
        chk(alu_op_o, ALU_SRA, "SRAI: alu_op=SRA");

        // =====================================================================
        // TC3 — Loads
        // =====================================================================
        $display("\n=== TC3: Loads ===");
        // LB x1, 4(x2)
        present(enc_i(12'd4, 2, 3'b000, 1, OP_LOAD), 32'h100);
        chk(mem_read_o,    1,       "LB: mem_read=1");
        chk(mem_write_o,   0,       "LB: mem_write=0");
        chk(mem_size_o,    2'b00,   "LB: size=byte");
        chk(mem_sign_ext_o,1,       "LB: sign_ext=1");
        chk(wb_sel_o,      2'b01,   "LB: wb_sel=mem");
        chk(reg_write_o,   1,       "LB: reg_write=1");

        // LH
        present(enc_i(12'd4, 2, 3'b001, 1, OP_LOAD), 32'h100);
        chk(mem_size_o,    2'b01,   "LH: size=half");
        chk(mem_sign_ext_o,1,       "LH: sign_ext=1");

        // LW
        present(enc_i(12'd4, 2, 3'b010, 1, OP_LOAD), 32'h100);
        chk(mem_size_o,    2'b10,   "LW: size=word");

        // LBU (unsigned)
        present(enc_i(12'd4, 2, 3'b100, 1, OP_LOAD), 32'h100);
        chk(mem_size_o,    2'b00,   "LBU: size=byte");
        chk(mem_sign_ext_o,0,       "LBU: sign_ext=0");

        // LHU (unsigned)
        present(enc_i(12'd4, 2, 3'b101, 1, OP_LOAD), 32'h100);
        chk(mem_size_o,    2'b01,   "LHU: size=half");
        chk(mem_sign_ext_o,0,       "LHU: sign_ext=0");

        // =====================================================================
        // TC4 — Stores
        // =====================================================================
        $display("\n=== TC4: Stores ===");
        // SW x3, 8(x2)
        present(enc_s(12'd8, 3, 2, 3'b010, OP_STORE), 32'h100);
        chk(mem_write_o,  1,      "SW: mem_write=1");
        chk(mem_read_o,   0,      "SW: mem_read=0");
        chk(mem_size_o,   2'b10,  "SW: size=word");
        chk(reg_write_o,  0,      "SW: reg_write=0");
        chk(alu_src_b_o,  1,      "SW: src_b=imm (S-type)");

        // SH
        present(enc_s(12'd8, 3, 2, 3'b001, OP_STORE), 32'h100);
        chk(mem_size_o, 2'b01, "SH: size=half");

        // SB
        present(enc_s(12'd8, 3, 2, 3'b000, OP_STORE), 32'h100);
        chk(mem_size_o, 2'b00, "SB: size=byte");

        // =====================================================================
        // TC5 — Branches
        // =====================================================================
        $display("\n=== TC5: Branches ===");
        // BEQ x1, x2, +8
        present(enc_b(13'd8, 2, 1, 3'b000, OP_BR), 32'h100);
        chk(is_branch_o,     1,      "BEQ: is_branch=1");
        chk(branch_funct3_o, 3'b000, "BEQ: funct3=000");
        chk(mem_read_o,      0,      "BEQ: mem_read=0");
        chk(reg_write_o,     0,      "BEQ: reg_write=0");
        chk(alu_src_b_o,     0,      "BEQ: src_b=rs2");

        // BNE
        present(enc_b(13'd8, 2, 1, 3'b001, OP_BR), 32'h100);
        chk(branch_funct3_o, 3'b001, "BNE: funct3=001");

        // BLT
        present(enc_b(13'd8, 2, 1, 3'b100, OP_BR), 32'h100);
        chk(branch_funct3_o, 3'b100, "BLT: funct3=100");

        // BGE
        present(enc_b(13'd8, 2, 1, 3'b101, OP_BR), 32'h100);
        chk(branch_funct3_o, 3'b101, "BGE: funct3=101");

        // BLTU
        present(enc_b(13'd8, 2, 1, 3'b110, OP_BR), 32'h100);
        chk(branch_funct3_o, 3'b110, "BLTU: funct3=110");

        // BGEU
        present(enc_b(13'd8, 2, 1, 3'b111, OP_BR), 32'h100);
        chk(branch_funct3_o, 3'b111, "BGEU: funct3=111");

        // =====================================================================
        // TC6 — JAL
        // =====================================================================
        $display("\n=== TC6: JAL ===");
        // JAL x1, +100
        present(enc_j(21'd100, 1, OP_JAL), 32'h200);
        chk(is_jal_o,    1,      "JAL: is_jal=1");
        chk(is_jalr_o,   0,      "JAL: is_jalr=0");
        chk(reg_write_o, 1,      "JAL: reg_write=1");
        chk(wb_sel_o,    2'b00,  "JAL: wb_sel=ALU (PC+4)");
        chk(rd_addr_o,   5'd1,   "JAL: rd=x1");

        // =====================================================================
        // TC7 — JALR
        // =====================================================================
        $display("\n=== TC7: JALR ===");
        // JALR x1, x2, 4
        present(enc_i(12'd4, 2, 3'b000, 1, OP_JALR), 32'h200);
        chk(is_jalr_o,   1,      "JALR: is_jalr=1");
        chk(is_jal_o,    0,      "JALR: is_jal=0");
        chk(reg_write_o, 1,      "JALR: reg_write=1");
        chk(alu_src_b_o, 1,      "JALR: src_b=imm");

        // =====================================================================
        // TC8 — LUI
        // =====================================================================
        $display("\n=== TC8: LUI ===");
        // LUI x1, 0xABCDE
        present(enc_u(20'hABCDE, 1, OP_LUI), 32'h300);
        chk(alu_src_a_o, 2'b10,        "LUI: src_a=zero");
        chk(alu_src_b_o, 1,            "LUI: src_b=imm");
        chk(imm_o,       32'hABCDE000, "LUI: imm correctly placed");
        chk(reg_write_o, 1,            "LUI: reg_write=1");

        // =====================================================================
        // TC9 — AUIPC
        // =====================================================================
        $display("\n=== TC9: AUIPC ===");
        // AUIPC x1, 0x10000  at PC=0x300
        present(enc_u(20'h10000, 1, OP_AUIPC), 32'h300);
        chk(alu_src_a_o, 2'b01,        "AUIPC: src_a=PC");
        chk(alu_src_b_o, 1,            "AUIPC: src_b=imm");
        chk(imm_o,       32'h10000000, "AUIPC: imm correctly placed");
        chk(pc_if_o,     32'h300,      "AUIPC: pc pass-through");
        chk(reg_write_o, 1,            "AUIPC: reg_write=1");

        // =====================================================================
        // TC10 — FENCE / ECALL / EBREAK (NOP behaviour)
        // =====================================================================
        $display("\n=== TC10: FENCE/ECALL/EBREAK (NOP) ===");
        // FENCE
        present(32'h0000000F, 32'h400);
        chk(reg_write_o, 0, "FENCE: reg_write=0");
        chk(mem_read_o,  0, "FENCE: mem_read=0");
        chk(mem_write_o, 0, "FENCE: mem_write=0");

        // ECALL
        present(32'h00000073, 32'h400);
        chk(reg_write_o, 0, "ECALL: reg_write=0");
        chk(mem_write_o, 0, "ECALL: mem_write=0");

        // EBREAK
        present(32'h00100073, 32'h400);
        chk(reg_write_o, 0, "EBREAK: reg_write=0");

        // =====================================================================
        // TC11 — Custom-0 (Conv-PE)
        // =====================================================================
        $display("\n=== TC11: Custom-0 (Conv-PE) ===");
        // custom-0: init=0 (accumulating)
        // Encoding: funct7=0, rs2=x4, rs1=x3, funct3=000, rd=x5, opcode=0001011
        present(enc_r(7'h00, 4, 3, 3'b000, 5, OP_CUSTOM0), 32'h500);
        chk(conv_start_o, 1,      "CONV: conv_start=1");
        chk(conv_init_o,  0,      "CONV: conv_init=0 (accum)");
        chk(wb_sel_o,     2'b10,  "CONV: wb_sel=conv");
        chk(reg_write_o,  1,      "CONV: reg_write=1");
        chk(rs1_addr_o,   5'd3,   "CONV: rs1=x3");
        chk(rs2_addr_o,   5'd4,   "CONV: rs2=x4");
        chk(rd_addr_o,    5'd5,   "CONV: rd=x5");

        // custom-0: init=1 (initialising) — funct7[0]=1
        present(enc_r(7'h01, 4, 3, 3'b000, 5, OP_CUSTOM0), 32'h500);
        chk(conv_start_o, 1, "CONV: conv_start=1");
        chk(conv_init_o,  1, "CONV: conv_init=1 (init)");

        // Non-custom-0 must not assert conv_start
        present(enc_r(7'h00, 3, 2, 3'b000, 1, OP_R), 32'h500);
        chk(conv_start_o, 0, "R-type: conv_start=0");

        // =====================================================================
        // TC12 — Immediate encoding
        // =====================================================================
        $display("\n=== TC12: Immediate encoding ===");
        // I-type: +100
        present(enc_i(12'd100, 1, 3'b000, 2, OP_I), 32'h0);
        chk(imm_o, 32'h64, "I-imm: +100");

        // I-type: -1 (sign-extended)
        present(enc_i(12'hFFF, 1, 3'b000, 2, OP_I), 32'h0);
        chk(imm_o, 32'hFFFFFFFF, "I-imm: -1 sign-extended");

        // S-type: offset 20
        present(enc_s(12'd20, 3, 2, 3'b010, OP_STORE), 32'h0);
        chk(imm_o, 32'h14, "S-imm: +20");

        // S-type: negative offset -4
        present(enc_s(12'hFFC, 3, 2, 3'b010, OP_STORE), 32'h0);
        chk(imm_o, 32'hFFFFFFFC, "S-imm: -4 sign-extended");

        // B-type: +16 (branch offset)
        present(enc_b(13'd16, 2, 1, 3'b000, OP_BR), 32'h0);
        chk(imm_o, 32'h10, "B-imm: +16");

        // U-type: 20'hDEAD placed at [31:12] -> 0x000DEAD000 truncated to 0x0DEAD000
        present(enc_u(20'hDEAD, 1, OP_LUI), 32'h0);
        chk(imm_o, 32'h0DEAD000, "U-imm: 0x0DEAD000");

        // J-type: +256
        present(enc_j(21'd256, 1, OP_JAL), 32'h0);
        chk(imm_o, 32'h100, "J-imm: +256");

        // J-type: negative offset -4
        present(enc_j(21'h1FFFFC, 1, OP_JAL), 32'h0);
        chk(imm_o, 32'hFFFFFFFC, "J-imm: -4 sign-extended");

        // =====================================================================
        // TC13 — Register file write-back and read-back
        // =====================================================================
        $display("\n=== TC13: Regfile write-back and read-back ===");
        // Write x5=0xCAFE_BEEF, x6=0x1234_5678 via WB port
        wb_write(5'd5, 32'hCAFEBEEF);
        wb_write(5'd6, 32'h12345678);

        // Read them back as RS1=x5, RS2=x6
        present(enc_r(7'h00, 6, 5, 3'b000, 1, OP_R), 32'h0);
        chk(rs1_data_o, 32'hCAFEBEEF, "regfile rs1: x5=0xCAFEBEEF");
        chk(rs2_data_o, 32'h12345678, "regfile rs2: x6=0x12345678");

        // x0 always reads 0 regardless of write
        wb_write(5'd0, 32'hDEADBEEF);
        present(enc_r(7'h00, 0, 0, 3'b000, 1, OP_R), 32'h0);
        chk(rs1_data_o, 32'h0, "regfile x0 rs1=0 after write attempt");
        chk(rs2_data_o, 32'h0, "regfile x0 rs2=0 after write attempt");

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

    initial begin #200000; $display("WATCHDOG TIMEOUT"); $finish; end

endmodule