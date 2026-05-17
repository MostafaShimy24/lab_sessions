//==============================================================================
// id_ex_wrapper.v — ID+EX Wrapper for Formal Liveness Verification
//------------------------------------------------------------------------------
// Project : ELCT1005 PROJ02 — Pipelined RISC-V CPU with Conv-PE
//
// Purpose:
//   Lightweight wrapper used for Phase 1 liveness cover properties.
//
// Instantiates:
//   - id_stage
//   - ID/EX pipeline register
//   - ex_stage
//
// Notes:
//   - instr_i is solver-driven
//   - No IF/MEM/WB stages
//   - Formal properties embedded directly under `ifdef FORMAL
//==============================================================================

`timescale 1ns/1ps
`default_nettype none

module id_ex_wrapper #(
    parameter integer CONV_LATENCY = 4,
    parameter integer DATA_WIDTH   = 32,
    parameter integer ACCUM_WIDTH  = 32
)(
    input  wire        clk,
    input  wire        rst_n,

    // Solver-driven instruction stream
    input  wire [31:0] instr_i,
    input  wire [31:0] pc_i
);

    // =========================================================================
    // NOP
    // =========================================================================
    localparam [31:0] NOP = 32'h00000013;

    // =========================================================================
    // ID STAGE WIRES
    // =========================================================================
    wire [31:0] id_pc_if;
    wire [31:0] id_pc_plus4;

    wire [31:0] id_rs1_data;
    wire [31:0] id_rs2_data;

    wire [4:0]  id_rs1_addr;
    wire [4:0]  id_rs2_addr;
    wire [4:0]  id_rd_addr;

    wire [31:0] id_imm;

    wire [3:0]  id_alu_op;
    wire [1:0]  id_alu_src_a;
    wire        id_alu_src_b;

    wire        id_mem_read;
    wire        id_mem_write;
    wire [1:0]  id_mem_size;
    wire        id_mem_sign_ext;

    wire [1:0]  id_wb_sel;
    wire        id_reg_write;

    wire        id_is_branch;
    wire [2:0]  id_branch_funct3;

    wire        id_is_jal;
    wire        id_is_jalr;

    wire        id_conv_start;
    wire        id_conv_init;

    // =========================================================================
    // ID STAGE
    // =========================================================================
    id_stage u_id (
        .clk(clk),
        .rst_n(rst_n),

        .pc_if_i(pc_i),
        .pc_plus4_i(pc_i + 32'd4),

        .instr_i(instr_i),

        // WB disabled
        .wb_we_i(1'b0),
        .wb_addr_i(5'd0),
        .wb_data_i(32'd0),

        .pc_if_o(id_pc_if),
        .pc_plus4_o(id_pc_plus4),

        .rs1_data_o(id_rs1_data),
        .rs2_data_o(id_rs2_data),

        .rs1_addr_o(id_rs1_addr),
        .rs2_addr_o(id_rs2_addr),
        .rd_addr_o(id_rd_addr),

        .imm_o(id_imm),

        .alu_op_o(id_alu_op),
        .alu_src_a_o(id_alu_src_a),
        .alu_src_b_o(id_alu_src_b),

        .mem_read_o(id_mem_read),
        .mem_write_o(id_mem_write),

        .mem_size_o(id_mem_size),
        .mem_sign_ext_o(id_mem_sign_ext),

        .wb_sel_o(id_wb_sel),
        .reg_write_o(id_reg_write),

        .is_branch_o(id_is_branch),
        .branch_funct3_o(id_branch_funct3),

        .is_jal_o(id_is_jal),
        .is_jalr_o(id_is_jalr),

        .conv_start_o(id_conv_start),
        .conv_init_o(id_conv_init)
    );

    // =========================================================================
    // ID/EX PIPELINE REGISTER
    // =========================================================================
    reg [31:0] id_ex_pc_if;
    reg [31:0] id_ex_pc_plus4;

    reg [31:0] id_ex_rs1_data;
    reg [31:0] id_ex_rs2_data;

    reg [4:0]  id_ex_rs1_addr;
    reg [4:0]  id_ex_rs2_addr;
    reg [4:0]  id_ex_rd_addr;

    reg [31:0] id_ex_imm;

    reg [3:0]  id_ex_alu_op;
    reg [1:0]  id_ex_alu_src_a;
    reg        id_ex_alu_src_b;

    reg        id_ex_mem_read;
    reg        id_ex_mem_write;
    reg [1:0]  id_ex_mem_size;
    reg        id_ex_mem_sign_ext;

    reg [1:0]  id_ex_wb_sel;
    reg        id_ex_reg_write;

    reg        id_ex_is_branch;
    reg [2:0]  id_ex_branch_funct3;

    reg        id_ex_is_jal;
    reg        id_ex_is_jalr;

    reg        id_ex_conv_start;
    reg        id_ex_conv_init;

    // =========================================================================
    // EX STAGE OUTPUTS
    // =========================================================================
    wire [31:0] ex_alu_result;
    wire [31:0] ex_conv_result;
    wire [31:0] ex_rs2_data;

    wire [4:0]  ex_rd_addr;

    wire [31:0] ex_pc_plus4;

    wire        ex_mem_read;
    wire        ex_mem_write;

    wire [1:0]  ex_mem_size;
    wire        ex_mem_sign_ext;

    wire [1:0]  ex_wb_sel;
    wire        ex_reg_write;

    wire        ex_is_jump;

    wire [1:0]  pc_src;

    wire        flush;
    wire        stall;

    wire [31:0] branch_target;
    wire [31:0] jump_target;

    // =========================================================================
    // ID/EX REGISTER UPDATE
    // =========================================================================
    always @(posedge clk) begin

        if (!rst_n || flush) begin

            id_ex_pc_if           <= 32'h0;
            id_ex_pc_plus4        <= 32'h4;

            id_ex_rs1_data        <= 32'h0;
            id_ex_rs2_data        <= 32'h0;

            id_ex_rs1_addr        <= 5'h0;
            id_ex_rs2_addr        <= 5'h0;
            id_ex_rd_addr         <= 5'h0;

            id_ex_imm             <= 32'h0;

            id_ex_alu_op          <= 4'b0000;
            id_ex_alu_src_a       <= 2'b00;
            id_ex_alu_src_b       <= 1'b0;

            id_ex_mem_read        <= 1'b0;
            id_ex_mem_write       <= 1'b0;

            id_ex_mem_size        <= 2'b10;
            id_ex_mem_sign_ext    <= 1'b1;

            id_ex_wb_sel          <= 2'b00;
            id_ex_reg_write       <= 1'b0;

            id_ex_is_branch       <= 1'b0;
            id_ex_branch_funct3   <= 3'b000;

            id_ex_is_jal          <= 1'b0;
            id_ex_is_jalr         <= 1'b0;

            id_ex_conv_start      <= 1'b0;
            id_ex_conv_init       <= 1'b0;

        end
        else if (!stall) begin

            id_ex_pc_if           <= id_pc_if;
            id_ex_pc_plus4        <= id_pc_plus4;

            id_ex_rs1_data        <= id_rs1_data;
            id_ex_rs2_data        <= id_rs2_data;

            id_ex_rs1_addr        <= id_rs1_addr;
            id_ex_rs2_addr        <= id_rs2_addr;
            id_ex_rd_addr         <= id_rd_addr;

            id_ex_imm             <= id_imm;

            id_ex_alu_op          <= id_alu_op;
            id_ex_alu_src_a       <= id_alu_src_a;
            id_ex_alu_src_b       <= id_alu_src_b;

            id_ex_mem_read        <= id_mem_read;
            id_ex_mem_write       <= id_mem_write;

            id_ex_mem_size        <= id_mem_size;
            id_ex_mem_sign_ext    <= id_mem_sign_ext;

            id_ex_wb_sel          <= id_wb_sel;
            id_ex_reg_write       <= id_reg_write;

            id_ex_is_branch       <= id_is_branch;
            id_ex_branch_funct3   <= id_branch_funct3;

            id_ex_is_jal          <= id_is_jal;
            id_ex_is_jalr         <= id_is_jalr;

            id_ex_conv_start      <= id_conv_start;
            id_ex_conv_init       <= id_conv_init;

        end
    end

    // =========================================================================
    // EX STAGE
    // =========================================================================
    ex_stage #(
        .CONV_LATENCY(CONV_LATENCY),
        .DATA_WIDTH(DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) u_ex (

        .clk(clk),
        .rst_n(rst_n),

        .pc_if_i(id_ex_pc_if),
        .pc_plus4_i(id_ex_pc_plus4),

        .rs1_data_i(id_ex_rs1_data),
        .rs2_data_i(id_ex_rs2_data),

        .rs1_addr_i(id_ex_rs1_addr),
        .rs2_addr_i(id_ex_rs2_addr),

        .rd_addr_i(id_ex_rd_addr),

        .imm_i(id_ex_imm),

        .alu_op_i(id_ex_alu_op),
        .alu_src_a_i(id_ex_alu_src_a),
        .alu_src_b_i(id_ex_alu_src_b),

        .mem_read_i(id_ex_mem_read),
        .mem_write_i(id_ex_mem_write),

        .mem_size_i(id_ex_mem_size),
        .mem_sign_ext_i(id_ex_mem_sign_ext),

        .wb_sel_i(id_ex_wb_sel),
        .reg_write_i(id_ex_reg_write),

        .is_branch_i(id_ex_is_branch),
        .branch_funct3_i(id_ex_branch_funct3),

        .is_jal_i(id_ex_is_jal),
        .is_jalr_i(id_ex_is_jalr),

        .conv_start_i(id_ex_conv_start),
        .conv_init_i(id_ex_conv_init),

        .alu_result_o(ex_alu_result),
        .conv_result_o(ex_conv_result),

        .rs2_data_o(ex_rs2_data),
        .rd_addr_o(ex_rd_addr),

        .pc_plus4_o(ex_pc_plus4),

        .mem_read_o(ex_mem_read),
        .mem_write_o(ex_mem_write),

        .mem_size_o(ex_mem_size),
        .mem_sign_ext_o(ex_mem_sign_ext),

        .wb_sel_o(ex_wb_sel),
        .reg_write_o(ex_reg_write),

        .is_jump_o(ex_is_jump),

        .pc_src_o(pc_src),

        .flush_o(flush),
        .stall_o(stall),

        .branch_target_o(branch_target),
        .jump_target_o(jump_target)
    );

    // =========================================================================
    // FORMAL SECTION
    // =========================================================================
`ifdef FORMAL

    localparam [31:0] FORMAL_NOP        = 32'h00000013;
    localparam [31:0] FORMAL_ADDI_X1    = 32'h00100093;
    localparam [31:0] FORMAL_CONV_INIT  = 32'h0220818b;

    reg [5:0] cycle_count;

    always @(posedge clk) begin
        if (!rst_n)
            cycle_count <= 6'd0;
        else
            cycle_count <= cycle_count + 6'd1;
    end

    reg seen_instr;

    always @(posedge clk) begin
        if (!rst_n)
            seen_instr <= 1'b0;
        else if (instr_i != FORMAL_NOP)
            seen_instr <= 1'b1;
    end

    reg seen_conv_start;

    always @(posedge clk) begin
        if (!rst_n)
            seen_conv_start <= 1'b0;
        else if (id_ex_conv_start)
            seen_conv_start <= 1'b1;
    end

    // Reset assumptions
    always @(posedge clk) begin
        if (cycle_count < 6'd2)
            assume(!rst_n);
        else
            assume(rst_n);
    end

    // Instruction stream assumptions
    always @(posedge clk) begin

        if (rst_n && !seen_instr)
            assume(instr_i == FORMAL_ADDI_X1);

        else if (rst_n && seen_instr && !seen_conv_start)
            assume(instr_i == FORMAL_CONV_INIT);

        else if (rst_n)
            assume(instr_i == FORMAL_NOP);

    end

    // P7: INSTR_PROGRESS
    always @(posedge clk) begin
        if (rst_n) begin
            cover(
                seen_instr &&
                ex_reg_write &&
                (ex_rd_addr != 5'd0) &&
                (cycle_count >= 6'd6)
            );
        end
    end

    // P8: CONV_TERMINATES
    always @(posedge clk) begin
        if (rst_n) begin
            cover(
                seen_conv_start &&
                u_ex.u_conv_pe.conv_done &&
                (cycle_count >= (CONV_LATENCY + 6))
            );
        end
    end

`endif

endmodule

`default_nettype wire