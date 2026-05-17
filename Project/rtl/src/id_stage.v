//==============================================================================
// id_stage.v — Instruction Decode Stage
//------------------------------------------------------------------------------
// Project : ELCT1005 PROJ02 — Pipelined RISC-V CPU with Conv-PE
//
// Responsibilities:
//   1. Decode all 40 RV32I instructions + custom-0 (Conv-PE)
//   2. Read two operands from the register file (async, same cycle)
//   3. Generate sign-extended immediates for all six formats (I/S/B/U/J/R)
//   4. Produce control signals for EX / MEM / WB stages
//   5. Instantiate regfile.v (write port driven by WB stage via top-level)
//
// Immediate formats:
//   I : { {20{instr[31]}}, instr[31:20] }
//   S : { {20{instr[31]}}, instr[31:25], instr[11:7] }
//   B : { {19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0 }
//   U : { instr[31:12], 12'b0 }
//   J : { {11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0 }
//   R : no immediate
//
// ALU operand-A select (alu_src_a_o):
//   2'b00  rs1_data    (normal ALU / load / store / branch)
//   2'b01  pc_if_i     (AUIPC, JAL target adder)
//   2'b10  32'h0       (LUI — result = imm only)
//
// ALU operand-B select (alu_src_b_o):
//   1'b0   rs2_data    (R-type)
//   1'b1   imm         (I / S / B / U / J -types)
//
// WB result select (wb_sel_o):
//   2'b00  ALU result
//   2'b01  Memory load data
//   2'b10  Conv-PE result
//
// FENCE / ECALL / EBREAK are treated as NOPs (reg_write_o=0,
// mem_read_o=0, mem_write_o=0) — legal for a single-core design.
//==============================================================================
`timescale 1ns / 1ps
`default_nettype none

module id_stage (
    input  wire        clk,
    input  wire        rst_n,

    // From IF/ID pipeline register
    input  wire [31:0] pc_if_i,
    input  wire [31:0] pc_plus4_i,
    input  wire [31:0] instr_i,

    // WB write-back port (feeds regfile write port)
    input  wire        wb_we_i,
    input  wire [4:0]  wb_addr_i,
    input  wire [31:0] wb_data_i,

    // ---- Outputs to ID/EX pipeline register --------------------------------

    // Pass-through PC values
    output wire [31:0] pc_if_o,
    output wire [31:0] pc_plus4_o,

    // Register data & addresses
    output wire [31:0] rs1_data_o,
    output wire [31:0] rs2_data_o,
    output wire [4:0]  rs1_addr_o,
    output wire [4:0]  rs2_addr_o,
    output wire [4:0]  rd_addr_o,

    // Sign-extended immediate
    output wire [31:0] imm_o,

    // EX controls
    output wire [3:0]  alu_op_o,
    output wire [1:0]  alu_src_a_o,    // 00=rs1, 01=PC, 10=zero
    output wire        alu_src_b_o,    // 0=rs2,  1=imm

    // MEM controls
    output wire        mem_read_o,
    output wire        mem_write_o,
    output wire [1:0]  mem_size_o,     // 00=byte, 01=half, 10=word
    output wire        mem_sign_ext_o, // 1=sign-extend load

    // WB controls
    output wire [1:0]  wb_sel_o,       // 00=ALU, 01=mem, 10=conv
    output wire        reg_write_o,

    // Branch / jump controls
    output wire        is_branch_o,
    output wire [2:0]  branch_funct3_o,
    output wire        is_jal_o,
    output wire        is_jalr_o,

    // Conv-PE dispatch
    output wire        conv_start_o,
    output wire        conv_init_o     // funct7[0]
);

    // =========================================================================
    // Instruction field extraction
    // =========================================================================
    wire [6:0] opcode = instr_i[6:0];
    wire [4:0] rd     = instr_i[11:7];
    wire [2:0] funct3 = instr_i[14:12];
    wire [4:0] rs1    = instr_i[19:15];
    wire [4:0] rs2    = instr_i[24:20];
    wire [6:0] funct7 = instr_i[31:25];

    // =========================================================================
    // Opcode constants (RV32I + custom-0)
    // =========================================================================
    localparam OP_R      = 7'b0110011;   // R-type arithmetic
    localparam OP_I_ARITH= 7'b0010011;   // I-type arithmetic
    localparam OP_LOAD   = 7'b0000011;   // Loads
    localparam OP_STORE  = 7'b0100011;   // Stores
    localparam OP_BRANCH = 7'b1100011;   // Branches
    localparam OP_JAL    = 7'b1101111;   // JAL
    localparam OP_JALR   = 7'b1100111;   // JALR
    localparam OP_LUI    = 7'b0110111;   // LUI
    localparam OP_AUIPC  = 7'b0010111;   // AUIPC
    localparam OP_FENCE  = 7'b0001111;   // FENCE (NOP)
    localparam OP_SYSTEM = 7'b1110011;   // ECALL / EBREAK (NOP)
    localparam OP_CUSTOM0= 7'b0001011;   // Conv-PE custom-0

    // =========================================================================
    // Register file instantiation
    // =========================================================================
    wire [31:0] rs1_data, rs2_data;

    regfile u_regfile (
        .clk      (clk),
        .rst_n    (rst_n),
        .rs1_addr (rs1),
        .rs2_addr (rs2),
        .rs1_data (rs1_data),
        .rs2_data (rs2_data),
        .we       (wb_we_i),
        .rd_addr  (wb_addr_i),
        .rd_data  (wb_data_i)
    );

    // =========================================================================
    // Immediate generation
    // =========================================================================
    wire [31:0] imm_i = {{20{instr_i[31]}}, instr_i[31:20]};

    wire [31:0] imm_s = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};

    wire [31:0] imm_b = {{19{instr_i[31]}}, instr_i[31], instr_i[7],
                          instr_i[30:25], instr_i[11:8], 1'b0};

    wire [31:0] imm_u = {instr_i[31:12], 12'b0};

    wire [31:0] imm_j = {{11{instr_i[31]}}, instr_i[31], instr_i[19:12],
                          instr_i[20], instr_i[30:21], 1'b0};

    // Mux the correct immediate based on opcode
    reg [31:0] imm;
    always @* begin
        case (opcode)
            OP_I_ARITH,
            OP_LOAD,
            OP_JALR   : imm = imm_i;
            OP_STORE  : imm = imm_s;
            OP_BRANCH : imm = imm_b;
            OP_LUI,
            OP_AUIPC  : imm = imm_u;
            OP_JAL    : imm = imm_j;
            default   : imm = 32'h0;
        endcase
    end

    // =========================================================================
    // ALU operation decode
    // =========================================================================

    // R-type and I-type arithmetic share the same funct3 -> alu_op mapping.
    // SUB and SRA are distinguished from ADD and SRL by funct7[5].
    function [3:0] funct3_to_aluop;
        input [2:0] f3;
        input       f7_5;       // funct7[5] — selects SUB over ADD, SRA over SRL
        begin
            case (f3)
                3'b000: funct3_to_aluop = f7_5 ? 4'b0001 : 4'b0000; // SUB : ADD
                3'b001: funct3_to_aluop = 4'b0010;                   // SLL
                3'b010: funct3_to_aluop = 4'b0011;                   // SLT
                3'b011: funct3_to_aluop = 4'b0100;                   // SLTU
                3'b100: funct3_to_aluop = 4'b0101;                   // XOR
                3'b101: funct3_to_aluop = f7_5 ? 4'b0111 : 4'b0110; // SRA : SRL
                3'b110: funct3_to_aluop = 4'b1000;                   // OR
                3'b111: funct3_to_aluop = 4'b1001;                   // AND
                default: funct3_to_aluop = 4'b0000;
            endcase
        end
    endfunction

    reg [3:0] alu_op;
    always @* begin
        case (opcode)
            OP_R      : alu_op = funct3_to_aluop(funct3, funct7[5]);
            OP_I_ARITH: begin
                // SLLI / SRLI / SRAI: funct7[5] distinguishes SRA from SRL.
                // For all other I-type arithmetic funct7[5] must be treated
                // as 0 (e.g. ADDI has no SUB variant).
                if (funct3 == 3'b001 || funct3 == 3'b101)
                    alu_op = funct3_to_aluop(funct3, funct7[5]);
                else
                    alu_op = funct3_to_aluop(funct3, 1'b0);
            end
            // All other instructions use ADD for effective-address calculation
            // (loads, stores, branches, JAL, JALR, AUIPC, LUI)
            default   : alu_op = 4'b0000; // ADD
        endcase
    end

    // =========================================================================
    // ALU source selects
    // =========================================================================
    reg [1:0] alu_src_a;
    reg       alu_src_b;

    always @* begin
        // Operand A
        case (opcode)
            OP_AUIPC: alu_src_a = 2'b01;   // PC
            OP_LUI  : alu_src_a = 2'b10;   // zero (result = imm)
            default : alu_src_a = 2'b00;   // rs1
        endcase

        // Operand B
        case (opcode)
            OP_R,
            OP_BRANCH: alu_src_b = 1'b0;   // rs2
            default  : alu_src_b = 1'b1;   // immediate
        endcase
    end

    // =========================================================================
    // Memory controls
    // =========================================================================
    wire is_load  = (opcode == OP_LOAD);
    wire is_store = (opcode == OP_STORE);

    // mem_size from funct3 lower 2 bits: 00=byte, 01=half, 10=word
    wire [1:0] mem_size     = funct3[1:0];
    // sign_ext: 0 when funct3[2]=1 (LBU / LHU = unsigned loads)
    wire       mem_sign_ext = ~funct3[2];

    // =========================================================================
    // WB controls
    // =========================================================================
    reg [1:0] wb_sel;
    reg       reg_write;

    always @* begin
        wb_sel    = 2'b00;   // default: ALU result
        reg_write = 1'b0;

        case (opcode)
            OP_R,
            OP_I_ARITH,
            OP_LUI,
            OP_AUIPC  : begin wb_sel = 2'b00; reg_write = 1'b1; end
            OP_LOAD   : begin wb_sel = 2'b01; reg_write = 1'b1; end
            OP_JAL,
            OP_JALR   : begin wb_sel = 2'b00; reg_write = 1'b1; end
            OP_CUSTOM0: begin wb_sel = 2'b10; reg_write = 1'b1; end
            // STORE, BRANCH, FENCE, SYSTEM: no register write
            default   : begin wb_sel = 2'b00; reg_write = 1'b0; end
        endcase
    end

    // =========================================================================
    // Branch / jump detection
    // =========================================================================
    wire is_branch = (opcode == OP_BRANCH);
    wire is_jal    = (opcode == OP_JAL);
    wire is_jalr   = (opcode == OP_JALR);

    // =========================================================================
    // Conv-PE dispatch
    // =========================================================================
    wire conv_start = (opcode == OP_CUSTOM0);
    wire conv_init  = funct7[0];   // funct7[0]=1 => initialising MAC

    // =========================================================================
    // Output assignments
    // =========================================================================
    assign pc_if_o         = pc_if_i;
    assign pc_plus4_o      = pc_plus4_i;

    assign rs1_data_o      = rs1_data;
    assign rs2_data_o      = rs2_data;
    assign rs1_addr_o      = rs1;
    assign rs2_addr_o      = rs2;
    assign rd_addr_o       = rd;

    assign imm_o           = imm;

    assign alu_op_o        = alu_op;
    assign alu_src_a_o     = alu_src_a;
    assign alu_src_b_o     = alu_src_b;

    assign mem_read_o      = is_load;
    assign mem_write_o     = is_store;
    assign mem_size_o      = mem_size;
    assign mem_sign_ext_o  = mem_sign_ext;

    assign wb_sel_o        = wb_sel;
    assign reg_write_o     = reg_write;

    assign is_branch_o     = is_branch;
    assign branch_funct3_o = funct3;
    assign is_jal_o        = is_jal;
    assign is_jalr_o       = is_jalr;

    assign conv_start_o    = conv_start;
    assign conv_init_o     = conv_init;

endmodule

`default_nettype wire