//==============================================================================
// ex_stage.v — Execute Stage
//------------------------------------------------------------------------------
// Project : ELCT1005 PROJ02 — Pipelined RISC-V CPU with Conv-PE
//
// Responsibilities:
//   1. Operand-A mux   : rs1  / PC (AUIPC, JAL) / 0 (LUI)
//   2. Operand-B mux   : rs2  / sign-extended immediate
//   3. ALU             : all 10 RV32I operations (alu.v instance)
//   4. Branch comparator: resolves all 6 branch conditions from rs1 vs rs2
//   5. Dedicated adders : branch target (PC + B-imm) and
//                         JAL   target  (PC + J-imm)
//   6. JALR target     : (rs1 + I-imm) & ~1  — bit-0 cleared per spec
//   7. next-PC control : pc_src / flush / targets back to IF stage
//   8. Conv-PE         : dispatch conv_pe.v, assert stall while BUSY,
//                        capture result when DONE
//   9. Pass-through    : MEM / WB control signals to EX/MEM register
//
// JAL / JALR writeback:
//   Both instructions write PC+4 (link address) to RD, not the ALU result.
//   is_jump_o is asserted for JAL and JALR; the WB stage uses it to select
//   pc_plus4_o over the normal wb_sel mux output.
//
// Branch resolution (static not-taken prediction):
//   All branches are predicted not-taken (sequential PC).
//   When branch_taken is resolved in EX, flush_o is asserted to squash the
//   wrongly-fetched instruction in IF/ID, and branch_target_o drives IF.
//
// Conv-PE stall:
//   conv_busy from conv_pe freezes all pipeline stages (stall_o).
//   conv_done captures conv_result into the EX/MEM pipeline register.
//==============================================================================
`timescale 1ns / 1ps
`default_nettype none

module ex_stage #(
    parameter integer CONV_LATENCY = 4,
    parameter integer DATA_WIDTH   = 32,
    parameter integer ACCUM_WIDTH  = 32
) (
    input  wire        clk,
    input  wire        rst_n,

    // From ID/EX pipeline register
    input  wire [31:0] pc_if_i,
    input  wire [31:0] pc_plus4_i,
    input  wire [31:0] rs1_data_i,
    input  wire [31:0] rs2_data_i,
    input  wire [4:0]  rs1_addr_i,
    input  wire [4:0]  rs2_addr_i,
    input  wire [4:0]  rd_addr_i,
    input  wire [31:0] imm_i,
    input  wire [3:0]  alu_op_i,
    input  wire [1:0]  alu_src_a_i,   // 00=rs1, 01=PC, 10=zero
    input  wire        alu_src_b_i,   // 0=rs2,  1=imm
    input  wire        mem_read_i,
    input  wire        mem_write_i,
    input  wire [1:0]  mem_size_i,
    input  wire        mem_sign_ext_i,
    input  wire [1:0]  wb_sel_i,      // 00=ALU,01=mem,10=conv
    input  wire        reg_write_i,
    input  wire        is_branch_i,
    input  wire [2:0]  branch_funct3_i,
    input  wire        is_jal_i,
    input  wire        is_jalr_i,
    input  wire        conv_start_i,
    input  wire        conv_init_i,

    // ---- Outputs to EX/MEM pipeline register --------------------------------

    // ALU / Conv-PE results
    output wire [31:0] alu_result_o,   // effective addr for loads/stores + ALU WB
    output wire [31:0] conv_result_o,  // Conv-PE accumulator result
    output wire [31:0] rs2_data_o,     // store data (pass-through)
    output wire [4:0]  rd_addr_o,      // destination register (pass-through)
    output wire [31:0] pc_plus4_o,     // link address for JAL/JALR WB

    // MEM / WB control pass-throughs
    output wire        mem_read_o,
    output wire        mem_write_o,
    output wire [1:0]  mem_size_o,
    output wire        mem_sign_ext_o,
    output wire [1:0]  wb_sel_o,
    output wire        reg_write_o,
    output wire        is_jump_o,      // JAL or JALR — WB writes pc_plus4

    // ---- Next-PC control (back to IF stage) ---------------------------------
    output wire [1:0]  pc_src_o,       // 00=PC+4, 01=branch, 10=jump
    output wire        flush_o,        // squash IF/ID (branch taken or jump)
    output wire [31:0] branch_target_o,
    output wire [31:0] jump_target_o,

    // ---- Stall (to all stages) ----------------------------------------------
    output wire        stall_o,         // Conv-PE busy
    
    output wire        conv_done_o,
    output wire conv_start_pulse_o

);

    // =========================================================================
    // Operand muxes
    // =========================================================================
    reg [31:0] op_a;
    always @* begin
        case (alu_src_a_i)
            2'b01  : op_a = pc_if_i;      // AUIPC / JAL
            2'b10  : op_a = 32'h0;        // LUI
            default: op_a = rs1_data_i;   // normal
        endcase
    end

    wire [31:0] op_b = alu_src_b_i ? imm_i : rs2_data_i;

    // =========================================================================
    // ALU instance
    // =========================================================================
    wire [31:0] alu_result;
    wire        alu_zero;

    alu u_alu (
        .operand_a  (op_a),
        .operand_b  (op_b),
        .alu_op     (alu_op_i),
        .alu_result (alu_result),
        .zero       (alu_zero)
    );

    // =========================================================================
    // Branch comparator
    // Operates on raw rs1/rs2 (not ALU operands) per RV32I spec.
    // =========================================================================
    wire        eq   = (rs1_data_i == rs2_data_i);
    wire        ltu  = (rs1_data_i <  rs2_data_i);          // unsigned
    wire        lt   = ($signed(rs1_data_i) < $signed(rs2_data_i)); // signed

    reg branch_taken;
    always @* begin
        branch_taken = 1'b0;
        if (is_branch_i) begin
            case (branch_funct3_i)
                3'b000: branch_taken =  eq;    // BEQ
                3'b001: branch_taken = !eq;    // BNE
                3'b100: branch_taken =  lt;    // BLT
                3'b101: branch_taken = !lt;    // BGE
                3'b110: branch_taken =  ltu;   // BLTU
                3'b111: branch_taken = !ltu;   // BGEU
                default: branch_taken = 1'b0;
            endcase
        end
    end

    // =========================================================================
    // Target adders (dedicated — separate from ALU per spec)
    // =========================================================================
    // Branch target  : PC + B-imm  (B-imm bit[0] = 0, already encoded)
    wire [31:0] branch_target = pc_if_i + imm_i;

    // JAL target     : PC + J-imm
    // JALR target    : (rs1 + I-imm) & ~1  (clear bit 0)
    wire [31:0] jalr_raw    = rs1_data_i + imm_i;
    wire [31:0] jalr_target = {jalr_raw[31:1], 1'b0};
    wire [31:0] jal_target  = pc_if_i + imm_i;

    wire [31:0] jump_target = is_jalr_i ? jalr_target : jal_target;

    // =========================================================================
    // Next-PC control
    // =========================================================================
    wire is_jump = is_jal_i | is_jalr_i;

    // pc_src: jumps take priority over branches (only one can be active)
    assign pc_src_o = is_jump      ? 2'b10 :   // jump target
                      branch_taken ? 2'b01 :   // branch target
                                     2'b00;    // sequential PC+4

    assign flush_o         = is_jump | branch_taken;
    assign branch_target_o = branch_target;
    assign jump_target_o   = jump_target;

    // // =========================================================================
    // // Conv-PE instance
    // // =========================================================================


    // wire        conv_busy;
    // wire        conv_done;
    // wire [ACCUM_WIDTH-1:0] conv_result;
    // wire [1:0]  conv_status;

    // conv_pe #(
    //     .DATA_WIDTH   (DATA_WIDTH),
    //     .ACCUM_WIDTH  (ACCUM_WIDTH),
    //     .CONV_LATENCY (CONV_LATENCY)
    // ) u_conv_pe (
    //     .clk         (clk),
    //     .rst_n       (rst_n),
    //     //.conv_start  (conv_start_i),
    //     .conv_start  (conv_start_pulse),
    //     .init        (conv_init_i),
    //     .operand_a   (rs1_data_i),
    //     .operand_b   (rs2_data_i),
    //     .conv_busy   (conv_busy),
    //     .conv_done   (conv_done),
    //     .conv_result (conv_result),
    //     .conv_status (conv_status)
    // );

    // =========================================================================
    // Conv-PE rising-edge detector
    // conv_start_i stays HIGH during stall — pulse only on first cycle
    // =========================================================================
    reg  conv_start_i_r;
    always @(posedge clk) begin
        if (!rst_n) conv_start_i_r <= 1'b0;
        else        conv_start_i_r <= conv_start_i;
    end
    wire conv_start_pulse = conv_start_i & ~conv_start_i_r;

    // =========================================================================
    // Conv-PE instance
    // =========================================================================
    wire        conv_busy;
    wire        conv_done;
    wire [ACCUM_WIDTH-1:0] conv_result;
    wire [1:0]  conv_status;

    conv_pe #(
        .DATA_WIDTH   (DATA_WIDTH),
        .ACCUM_WIDTH  (ACCUM_WIDTH),
        .CONV_LATENCY (CONV_LATENCY)
    ) u_conv_pe (
        .clk         (clk),
        .rst_n       (rst_n),
        .conv_start  (conv_start_pulse),   // ← pulse, not raw level
        .init        (conv_init_i),
        .operand_a   (rs1_data_i),
        .operand_b   (rs2_data_i),
        .conv_busy   (conv_busy),
        .conv_done   (conv_done),
        .conv_result (conv_result),
        .conv_status (conv_status)
    );


    // =========================================================================
    // Output assignments
    // =========================================================================
    assign alu_result_o  = alu_result;
    assign conv_result_o = conv_result;
    assign rs2_data_o    = rs2_data_i;
    assign rd_addr_o     = rd_addr_i;
    assign pc_plus4_o    = pc_plus4_i;

    assign mem_read_o    = mem_read_i;
    assign mem_write_o   = mem_write_i;
    assign mem_size_o    = mem_size_i;
    assign mem_sign_ext_o= mem_sign_ext_i;
    assign wb_sel_o      = wb_sel_i;
    assign reg_write_o   = reg_write_i;
    assign is_jump_o     = is_jump;

    assign stall_o       = conv_busy;

    assign conv_done_o = conv_done;
    assign conv_start_pulse_o = conv_start_pulse;
endmodule

`default_nettype wire