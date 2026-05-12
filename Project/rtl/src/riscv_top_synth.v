//==============================================================================
// riscv_top_synth.v — Synthesis Wrapper for ELCT1005 PROJ02
//------------------------------------------------------------------------------
// Same as riscv_top.v but imem is removed and exposed as external ports.
// mem_stage and dmem are kept COMPLETELY UNCHANGED internally.
// This gives Yosys a proper top-level boundary for show + STA.
//==============================================================================
`timescale 1ns / 1ps
`default_nettype none

module riscv_top_synth #(
    parameter integer CONV_LATENCY = 4,
    parameter integer DATA_WIDTH   = 32,
    parameter integer ACCUM_WIDTH  = 32,
    parameter         DMEM_HEX    = "data.hex"
) (
    input  wire        clk,
    input  wire        rst_n,

    // Instruction memory — external
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_rdata
);

    localparam [31:0] NOP = 32'h00000013;

    wire stall;
    wire flush;

    // ── IF stage ──────────────────────────────────────────────────────────────
    wire [31:0] pc_fetch, pc_if_out, pc_plus4_if;
    wire [1:0]  pc_src;
    wire [31:0] branch_target, jump_target;

    assign imem_addr = pc_fetch;

    if_stage u_if (
        .clk             (clk),
        .rst_n           (rst_n),
        .stall_i         (stall),
        .flush_i         (flush),
        .pc_src_i        (pc_src),
        .branch_target_i (branch_target),
        .jump_target_i   (jump_target),
        .instr_i         (imem_rdata),
        .pc_fetch_o      (pc_fetch),
        .pc_if_o         (pc_if_out),
        .pc_plus4_o      (pc_plus4_if)
    );

    // ── IF/ID register ────────────────────────────────────────────────────────
    reg [31:0] if_id_pc, if_id_pc4, if_id_instr;
    always @(posedge clk) begin
        if (!rst_n || flush) begin
            if_id_pc    <= 32'h0;
            if_id_pc4   <= 32'h4;
            if_id_instr <= NOP;
        end else if (!stall) begin
            if_id_pc    <= pc_if_out;
            if_id_pc4   <= pc_plus4_if;
            if_id_instr <= imem_rdata;
        end
    end

    // ── WB feedback ───────────────────────────────────────────────────────────
    wire [4:0]  wb_addr;
    wire [31:0] wb_data;
    wire        wb_we;

    // ── ID stage ──────────────────────────────────────────────────────────────
    wire [31:0] id_pc_if, id_pc_plus4, id_rs1_data, id_rs2_data, id_imm;
    wire [4:0]  id_rs1_addr, id_rs2_addr, id_rd_addr;
    wire [3:0]  id_alu_op;
    wire [1:0]  id_alu_src_a, id_mem_size, id_wb_sel;
    wire        id_alu_src_b, id_mem_read, id_mem_write, id_mem_sign_ext;
    wire        id_reg_write, id_is_branch, id_is_jal, id_is_jalr;
    wire [2:0]  id_branch_funct3;
    wire        id_conv_start, id_conv_init;

    id_stage u_id (
        .clk             (clk),           .rst_n           (rst_n),
        .pc_if_i         (if_id_pc),      .pc_plus4_i      (if_id_pc4),
        .instr_i         (if_id_instr),   .wb_we_i         (wb_we),
        .wb_addr_i       (wb_addr),       .wb_data_i       (wb_data),
        .pc_if_o         (id_pc_if),      .pc_plus4_o      (id_pc_plus4),
        .rs1_data_o      (id_rs1_data),   .rs2_data_o      (id_rs2_data),
        .rs1_addr_o      (id_rs1_addr),   .rs2_addr_o      (id_rs2_addr),
        .rd_addr_o       (id_rd_addr),    .imm_o           (id_imm),
        .alu_op_o        (id_alu_op),     .alu_src_a_o     (id_alu_src_a),
        .alu_src_b_o     (id_alu_src_b),  .mem_read_o      (id_mem_read),
        .mem_write_o     (id_mem_write),  .mem_size_o      (id_mem_size),
        .mem_sign_ext_o  (id_mem_sign_ext),
        .wb_sel_o        (id_wb_sel),     .reg_write_o     (id_reg_write),
        .is_branch_o     (id_is_branch),  .branch_funct3_o (id_branch_funct3),
        .is_jal_o        (id_is_jal),     .is_jalr_o       (id_is_jalr),
        .conv_start_o    (id_conv_start), .conv_init_o     (id_conv_init)
    );

    // ── ID/EX register ────────────────────────────────────────────────────────
    reg [31:0] id_ex_pc_if, id_ex_pc_plus4, id_ex_rs1_data, id_ex_rs2_data, id_ex_imm;
    reg [4:0]  id_ex_rs1_addr, id_ex_rs2_addr, id_ex_rd_addr;
    reg [3:0]  id_ex_alu_op;
    reg [1:0]  id_ex_alu_src_a, id_ex_mem_size, id_ex_wb_sel;
    reg        id_ex_alu_src_b, id_ex_mem_read, id_ex_mem_write, id_ex_mem_sign_ext;
    reg        id_ex_reg_write, id_ex_is_branch, id_ex_is_jal, id_ex_is_jalr;
    reg [2:0]  id_ex_branch_funct3;
    reg        id_ex_conv_start, id_ex_conv_init;

    always @(posedge clk) begin
        if (!rst_n || flush) begin
            id_ex_pc_if<=32'h0;         id_ex_pc_plus4<=32'h4;
            id_ex_rs1_data<=32'h0;      id_ex_rs2_data<=32'h0;
            id_ex_rs1_addr<=5'h0;       id_ex_rs2_addr<=5'h0;
            id_ex_rd_addr<=5'h0;        id_ex_imm<=32'h0;
            id_ex_alu_op<=4'b0;         id_ex_alu_src_a<=2'b0;
            id_ex_alu_src_b<=1'b0;      id_ex_mem_read<=1'b0;
            id_ex_mem_write<=1'b0;      id_ex_mem_size<=2'b10;
            id_ex_mem_sign_ext<=1'b1;   id_ex_wb_sel<=2'b0;
            id_ex_reg_write<=1'b0;      id_ex_is_branch<=1'b0;
            id_ex_branch_funct3<=3'b0;  id_ex_is_jal<=1'b0;
            id_ex_is_jalr<=1'b0;        id_ex_conv_start<=1'b0;
            id_ex_conv_init<=1'b0;
        end else if (!stall) begin
            id_ex_pc_if<=id_pc_if;              id_ex_pc_plus4<=id_pc_plus4;
            id_ex_rs1_data<=id_rs1_data;        id_ex_rs2_data<=id_rs2_data;
            id_ex_rs1_addr<=id_rs1_addr;        id_ex_rs2_addr<=id_rs2_addr;
            id_ex_rd_addr<=id_rd_addr;          id_ex_imm<=id_imm;
            id_ex_alu_op<=id_alu_op;            id_ex_alu_src_a<=id_alu_src_a;
            id_ex_alu_src_b<=id_alu_src_b;      id_ex_mem_read<=id_mem_read;
            id_ex_mem_write<=id_mem_write;      id_ex_mem_size<=id_mem_size;
            id_ex_mem_sign_ext<=id_mem_sign_ext;id_ex_wb_sel<=id_wb_sel;
            id_ex_reg_write<=id_reg_write;      id_ex_is_branch<=id_is_branch;
            id_ex_branch_funct3<=id_branch_funct3;
            id_ex_is_jal<=id_is_jal;           id_ex_is_jalr<=id_is_jalr;
            id_ex_conv_start<=id_conv_start;    id_ex_conv_init<=id_conv_init;
        end
    end

    // ── EX stage ──────────────────────────────────────────────────────────────
    wire [31:0] ex_alu_result, ex_conv_result, ex_rs2_data, ex_pc_plus4;
    wire [4:0]  ex_rd_addr;
    wire [1:0]  ex_mem_size, ex_wb_sel;
    wire        ex_mem_read, ex_mem_write, ex_mem_sign_ext;
    wire        ex_reg_write, ex_is_jump;
    wire        conv_done_sig, conv_start_pulse_sig;

    ex_stage #(
        .CONV_LATENCY(CONV_LATENCY), .DATA_WIDTH(DATA_WIDTH), .ACCUM_WIDTH(ACCUM_WIDTH)
    ) u_ex (
        .clk(clk),                       .rst_n(rst_n),
        .pc_if_i(id_ex_pc_if),           .pc_plus4_i(id_ex_pc_plus4),
        .rs1_data_i(id_ex_rs1_data),     .rs2_data_i(id_ex_rs2_data),
        .rs1_addr_i(id_ex_rs1_addr),     .rs2_addr_i(id_ex_rs2_addr),
        .rd_addr_i(id_ex_rd_addr),       .imm_i(id_ex_imm),
        .alu_op_i(id_ex_alu_op),         .alu_src_a_i(id_ex_alu_src_a),
        .alu_src_b_i(id_ex_alu_src_b),   .mem_read_i(id_ex_mem_read),
        .mem_write_i(id_ex_mem_write),   .mem_size_i(id_ex_mem_size),
        .mem_sign_ext_i(id_ex_mem_sign_ext), .wb_sel_i(id_ex_wb_sel),
        .reg_write_i(id_ex_reg_write),   .is_branch_i(id_ex_is_branch),
        .branch_funct3_i(id_ex_branch_funct3),
        .is_jal_i(id_ex_is_jal),         .is_jalr_i(id_ex_is_jalr),
        .conv_start_i(id_ex_conv_start), .conv_init_i(id_ex_conv_init),
        .alu_result_o(ex_alu_result),    .conv_result_o(ex_conv_result),
        .rs2_data_o(ex_rs2_data),        .rd_addr_o(ex_rd_addr),
        .pc_plus4_o(ex_pc_plus4),        .mem_read_o(ex_mem_read),
        .mem_write_o(ex_mem_write),      .mem_size_o(ex_mem_size),
        .mem_sign_ext_o(ex_mem_sign_ext),.wb_sel_o(ex_wb_sel),
        .reg_write_o(ex_reg_write),      .is_jump_o(ex_is_jump),
        .pc_src_o(pc_src),               .flush_o(flush),
        .branch_target_o(branch_target), .jump_target_o(jump_target),
        .stall_o(stall),                 .conv_done_o(conv_done_sig),
        .conv_start_pulse_o(conv_start_pulse_sig)
    );

    // ── EX/MEM register ───────────────────────────────────────────────────────
    reg [31:0] ex_mem_alu_result, ex_mem_conv_result, ex_mem_rs2_data, ex_mem_pc_plus4;
    reg [4:0]  ex_mem_rd_addr;
    reg [1:0]  ex_mem_mem_size, ex_mem_wb_sel;
    reg        ex_mem_mem_read, ex_mem_mem_write, ex_mem_mem_sign_ext;
    reg        ex_mem_reg_write, ex_mem_is_jump;

    reg [1:0]  conv_wb_sel_hold;
    reg        conv_reg_write_hold;
    reg [4:0]  conv_rd_addr_hold;
    reg [31:0] conv_pc_plus4_hold;

    always @(posedge clk) begin
        if (!rst_n) begin
            conv_wb_sel_hold<=2'b0; conv_reg_write_hold<=1'b0;
            conv_rd_addr_hold<=5'h0; conv_pc_plus4_hold<=32'h4;
        end else if (stall) begin
            conv_wb_sel_hold<=ex_mem_wb_sel;       conv_reg_write_hold<=ex_mem_reg_write;
            conv_rd_addr_hold<=ex_mem_rd_addr;     conv_pc_plus4_hold<=ex_mem_pc_plus4;
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            ex_mem_alu_result<=32'h0;   ex_mem_conv_result<=32'h0;
            ex_mem_rs2_data<=32'h0;     ex_mem_rd_addr<=5'h0;
            ex_mem_pc_plus4<=32'h4;     ex_mem_mem_read<=1'b0;
            ex_mem_mem_write<=1'b0;     ex_mem_mem_size<=2'b10;
            ex_mem_mem_sign_ext<=1'b1;  ex_mem_wb_sel<=2'b0;
            ex_mem_reg_write<=1'b0;     ex_mem_is_jump<=1'b0;
        end else if (conv_done_sig) begin
            ex_mem_conv_result<=ex_conv_result;
            ex_mem_wb_sel<=conv_wb_sel_hold;        ex_mem_reg_write<=conv_reg_write_hold;
            ex_mem_rd_addr<=conv_rd_addr_hold;      ex_mem_pc_plus4<=conv_pc_plus4_hold;
            ex_mem_alu_result<=32'h0;               ex_mem_rs2_data<=32'h0;
            ex_mem_mem_read<=1'b0;                  ex_mem_mem_write<=1'b0;
            ex_mem_mem_size<=2'b10;                 ex_mem_mem_sign_ext<=1'b1;
            ex_mem_is_jump<=1'b0;
        end else if (!stall) begin
            ex_mem_alu_result<=ex_alu_result;       ex_mem_conv_result<=ex_conv_result;
            ex_mem_rs2_data<=ex_rs2_data;           ex_mem_rd_addr<=ex_rd_addr;
            ex_mem_pc_plus4<=ex_pc_plus4;           ex_mem_mem_read<=ex_mem_read;
            ex_mem_mem_write<=ex_mem_write;         ex_mem_mem_size<=ex_mem_size;
            ex_mem_mem_sign_ext<=ex_mem_sign_ext;   ex_mem_wb_sel<=ex_wb_sel;
            ex_mem_reg_write<=ex_reg_write;         ex_mem_is_jump<=ex_is_jump;
        end
    end

    // ── MEM stage — UNCHANGED, keeps internal dmem ────────────────────────────
    wire [31:0] mem_alu_result, mem_load_data, mem_conv_result, mem_pc_plus4;
    wire [4:0]  mem_rd_addr;
    wire [1:0]  mem_wb_sel;
    wire        mem_reg_write, mem_is_jump;

    mem_stage #(
        .ACCUM_WIDTH (ACCUM_WIDTH),
        .DMEM_HEX    (DMEM_HEX)
    ) u_mem (
        .clk            (clk),
        .rst_n          (rst_n),
        .alu_result_i   (ex_mem_alu_result),
        .rs2_data_i     (ex_mem_rs2_data),
        .conv_result_i  (ex_mem_conv_result),
        .rd_addr_i      (ex_mem_rd_addr),
        .pc_plus4_i     (ex_mem_pc_plus4),
        .mem_read_i     (ex_mem_mem_read),
        .mem_write_i    (ex_mem_mem_write),
        .mem_size_i     (ex_mem_mem_size),
        .mem_sign_ext_i (ex_mem_mem_sign_ext),
        .wb_sel_i       (ex_mem_wb_sel),
        .reg_write_i    (ex_mem_reg_write),
        .is_jump_i      (ex_mem_is_jump),
        .alu_result_o   (mem_alu_result),
        .load_data_o    (mem_load_data),
        .conv_result_o  (mem_conv_result),
        .rd_addr_o      (mem_rd_addr),
        .pc_plus4_o     (mem_pc_plus4),
        .wb_sel_o       (mem_wb_sel),
        .reg_write_o    (mem_reg_write),
        .is_jump_o      (mem_is_jump)
    );

    // ── MEM/WB register ───────────────────────────────────────────────────────
    reg [31:0] mem_wb_alu_result, mem_wb_load_data, mem_wb_conv_result, mem_wb_pc_plus4;
    reg [4:0]  mem_wb_rd_addr;
    reg [1:0]  mem_wb_wb_sel;
    reg        mem_wb_reg_write, mem_wb_is_jump;

    always @(posedge clk) begin
        if (!rst_n) begin
            mem_wb_alu_result<=32'h0;   mem_wb_load_data<=32'h0;
            mem_wb_conv_result<=32'h0;  mem_wb_rd_addr<=5'h0;
            mem_wb_pc_plus4<=32'h4;     mem_wb_wb_sel<=2'b0;
            mem_wb_reg_write<=1'b0;     mem_wb_is_jump<=1'b0;
        end else if (!stall && !conv_done_sig) begin
            mem_wb_alu_result<=mem_alu_result;      mem_wb_load_data<=mem_load_data;
            mem_wb_conv_result<=mem_conv_result;    mem_wb_rd_addr<=mem_rd_addr;
            mem_wb_pc_plus4<=mem_pc_plus4;          mem_wb_wb_sel<=mem_wb_sel;
            mem_wb_reg_write<=mem_reg_write;        mem_wb_is_jump<=mem_is_jump;
        end
    end

    // ── WB stage ──────────────────────────────────────────────────────────────
    wb_stage u_wb (
        .alu_result_i  (mem_wb_alu_result),
        .load_data_i   (mem_wb_load_data),
        .conv_result_i (mem_wb_conv_result),
        .pc_plus4_i    (mem_wb_pc_plus4),
        .rd_addr_i     (mem_wb_rd_addr),
        .wb_sel_i      (mem_wb_wb_sel),
        .reg_write_i   (mem_wb_reg_write),
        .is_jump_i     (mem_wb_is_jump),
        .wb_addr_o     (wb_addr),
        .wb_data_o     (wb_data),
        .wb_we_o       (wb_we)
    );

endmodule
`default_nettype wire