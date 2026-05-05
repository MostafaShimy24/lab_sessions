//==============================================================================
// riscv_top.v — Top-Level Pipelined RISC-V CPU with Conv-PE
//------------------------------------------------------------------------------
// Project : ELCT1005 PROJ02 — Pipelined RISC-V CPU with Conv-PE
//
// Architecture: 5-stage pipeline — IF → ID → EX → MEM → WB
//
// This file wires together all stage modules and holds the four pipeline
// registers (IF/ID, ID/EX, EX/MEM, MEM/WB). All sequential logic is
// synchronous with active-low reset (rst_n).
//
// Pipeline register control:
//   Stall (conv_busy from EX):
//     - Freeze PC in IF stage
//     - Hold ALL four pipeline registers unchanged
//   Flush (branch taken or jump, from EX):
//     - Load NOP into IF/ID and ID/EX registers (squash wrong-path instructions)
//     - Flush overrides stall (same priority as in if_stage)
//     - EX/MEM and MEM/WB are NOT flushed — instructions already past EX
//       are valid and should complete
//
// Module hierarchy:
//   riscv_top
//   ├─ imem         (instruction memory)
//   ├─ if_stage     (PC register + next-PC mux)
//   ├─ id_stage     (decode + regfile)
//   │   └─ regfile  (inside id_stage)
//   ├─ ex_stage     (ALU + branch + Conv-PE)
//   │   ├─ alu      (inside ex_stage)
//   │   └─ conv_pe  (inside ex_stage)
//   ├─ mem_stage    (data memory)
//   │   └─ dmem     (inside mem_stage)
//   └─ wb_stage     (WB mux — combinational only)
//==============================================================================
`timescale 1ns / 1ps
`default_nettype none

module riscv_top #(
    parameter integer CONV_LATENCY = 4,
    parameter integer DATA_WIDTH   = 32,
    parameter integer ACCUM_WIDTH  = 32,
    parameter         IMEM_HEX    = "program.hex",
    parameter         DMEM_HEX    = "data.hex"
) (
    input wire clk,
    input wire rst_n
);

    // =========================================================================
    // NOP constant — ADDI x0, x0, 0
    // =========================================================================
    localparam [31:0] NOP = 32'h00000013;

    // =========================================================================
    // Stall and flush signals (driven by EX stage)
    // =========================================================================
    wire stall;     // Conv-PE busy — freeze all stages
    wire flush;     // Branch taken or jump — squash IF/ID and ID/EX

    // =========================================================================
    // IF stage wires
    // =========================================================================
    wire [31:0] pc_fetch;        // PC → imem address
    wire [31:0] pc_if_out;       // delayed PC (aligned with imem output)
    wire [31:0] pc_plus4_if;     // PC+4 from IF stage

    // Next-PC control from EX stage
    wire [1:0]  pc_src;
    wire [31:0] branch_target;
    wire [31:0] jump_target;

    // Instruction from imem (synchronous / registered)
    wire [31:0] imem_instr;

    // =========================================================================
    // imem instantiation
    // =========================================================================
    imem #(
        .DEPTH_WORDS (1024),
        .HEX_FILE    (IMEM_HEX)
    ) u_imem (
        .clk   (clk),
        .addr  (pc_fetch),
        .instr (imem_instr)
    );

    // =========================================================================
    // IF stage
    // =========================================================================
    if_stage u_if (
        .clk              (clk),
        .rst_n            (rst_n),
        .stall_i          (stall),
        .flush_i          (flush),
        .pc_src_i         (pc_src),
        .branch_target_i  (branch_target),
        .jump_target_i    (jump_target),
        .instr_i          (imem_instr),
        .pc_fetch_o       (pc_fetch),
        .pc_if_o          (pc_if_out),
        .pc_plus4_o       (pc_plus4_if)
    );

    // =========================================================================
    // IF/ID pipeline register
    // =========================================================================
    reg [31:0] if_id_pc;
    reg [31:0] if_id_pc4;
    reg [31:0] if_id_instr;

    always @(posedge clk) begin
        if (!rst_n || flush) begin
            if_id_pc    <= 32'h0;
            if_id_pc4   <= 32'h4;
            if_id_instr <= NOP;
        end else if (!stall) begin
            if_id_pc    <= pc_if_out;
            if_id_pc4   <= pc_plus4_if;
            if_id_instr <= imem_instr;
        end
        // stall: hold current values
    end

    // =========================================================================
    // ID stage — includes regfile internally
    // WB write-back signals fed back from WB stage
    // =========================================================================
    wire [31:0] id_pc_if,    id_pc_plus4;
    wire [31:0] id_rs1_data, id_rs2_data;
    wire [4:0]  id_rs1_addr, id_rs2_addr, id_rd_addr;
    wire [31:0] id_imm;
    wire [3:0]  id_alu_op;
    wire [1:0]  id_alu_src_a;
    wire        id_alu_src_b;
    wire        id_mem_read,  id_mem_write;
    wire [1:0]  id_mem_size;
    wire        id_mem_sign_ext;
    wire [1:0]  id_wb_sel;
    wire        id_reg_write;
    wire        id_is_branch;
    wire [2:0]  id_branch_funct3;
    wire        id_is_jal,   id_is_jalr;
    wire        id_conv_start, id_conv_init;

    // WB → ID feed-back
    wire [4:0]  wb_addr;
    wire [31:0] wb_data;
    wire        wb_we;

    id_stage u_id (
        .clk             (clk),
        .rst_n           (rst_n),
        .pc_if_i         (if_id_pc),
        .pc_plus4_i      (if_id_pc4),
        .instr_i         (if_id_instr),
        .wb_we_i         (wb_we),
        .wb_addr_i       (wb_addr),
        .wb_data_i       (wb_data),
        .pc_if_o         (id_pc_if),
        .pc_plus4_o      (id_pc_plus4),
        .rs1_data_o      (id_rs1_data),
        .rs2_data_o      (id_rs2_data),
        .rs1_addr_o      (id_rs1_addr),
        .rs2_addr_o      (id_rs2_addr),
        .rd_addr_o       (id_rd_addr),
        .imm_o           (id_imm),
        .alu_op_o        (id_alu_op),
        .alu_src_a_o     (id_alu_src_a),
        .alu_src_b_o     (id_alu_src_b),
        .mem_read_o      (id_mem_read),
        .mem_write_o     (id_mem_write),
        .mem_size_o      (id_mem_size),
        .mem_sign_ext_o  (id_mem_sign_ext),
        .wb_sel_o        (id_wb_sel),
        .reg_write_o     (id_reg_write),
        .is_branch_o     (id_is_branch),
        .branch_funct3_o (id_branch_funct3),
        .is_jal_o        (id_is_jal),
        .is_jalr_o       (id_is_jalr),
        .conv_start_o    (id_conv_start),
        .conv_init_o     (id_conv_init)
    );

    // =========================================================================
    // ID/EX pipeline register
    // On flush: zero all control signals (NOP bubble)
    // =========================================================================
    reg [31:0] id_ex_pc_if,    id_ex_pc_plus4;
    reg [31:0] id_ex_rs1_data, id_ex_rs2_data;
    reg [4:0]  id_ex_rs1_addr, id_ex_rs2_addr, id_ex_rd_addr;
    reg [31:0] id_ex_imm;
    reg [3:0]  id_ex_alu_op;
    reg [1:0]  id_ex_alu_src_a;
    reg        id_ex_alu_src_b;
    reg        id_ex_mem_read,  id_ex_mem_write;
    reg [1:0]  id_ex_mem_size;
    reg        id_ex_mem_sign_ext;
    reg [1:0]  id_ex_wb_sel;
    reg        id_ex_reg_write;
    reg        id_ex_is_branch;
    reg [2:0]  id_ex_branch_funct3;
    reg        id_ex_is_jal,    id_ex_is_jalr;
    reg        id_ex_conv_start, id_ex_conv_init;

    always @(posedge clk) begin
        if (!rst_n || flush) begin
            // Insert NOP bubble — zero all control signals
            id_ex_pc_if        <= 32'h0;
            id_ex_pc_plus4     <= 32'h4;
            id_ex_rs1_data     <= 32'h0;
            id_ex_rs2_data     <= 32'h0;
            id_ex_rs1_addr     <= 5'h0;
            id_ex_rs2_addr     <= 5'h0;
            id_ex_rd_addr      <= 5'h0;
            id_ex_imm          <= 32'h0;
            id_ex_alu_op       <= 4'b0000;
            id_ex_alu_src_a    <= 2'b00;
            id_ex_alu_src_b    <= 1'b0;
            id_ex_mem_read     <= 1'b0;
            id_ex_mem_write    <= 1'b0;
            id_ex_mem_size     <= 2'b10;
            id_ex_mem_sign_ext <= 1'b1;
            id_ex_wb_sel       <= 2'b00;
            id_ex_reg_write    <= 1'b0;   // <-- key: no register write for bubble
            id_ex_is_branch    <= 1'b0;
            id_ex_branch_funct3<= 3'b000;
            id_ex_is_jal       <= 1'b0;
            id_ex_is_jalr      <= 1'b0;
            id_ex_conv_start   <= 1'b0;
            id_ex_conv_init    <= 1'b0;
        end else if (!stall) begin
            id_ex_pc_if        <= id_pc_if;
            id_ex_pc_plus4     <= id_pc_plus4;
            id_ex_rs1_data     <= id_rs1_data;
            id_ex_rs2_data     <= id_rs2_data;
            id_ex_rs1_addr     <= id_rs1_addr;
            id_ex_rs2_addr     <= id_rs2_addr;
            id_ex_rd_addr      <= id_rd_addr;
            id_ex_imm          <= id_imm;
            id_ex_alu_op       <= id_alu_op;
            id_ex_alu_src_a    <= id_alu_src_a;
            id_ex_alu_src_b    <= id_alu_src_b;
            id_ex_mem_read     <= id_mem_read;
            id_ex_mem_write    <= id_mem_write;
            id_ex_mem_size     <= id_mem_size;
            id_ex_mem_sign_ext <= id_mem_sign_ext;
            id_ex_wb_sel       <= id_wb_sel;
            id_ex_reg_write    <= id_reg_write;
            id_ex_is_branch    <= id_is_branch;
            id_ex_branch_funct3<= id_branch_funct3;
            id_ex_is_jal       <= id_is_jal;
            id_ex_is_jalr      <= id_is_jalr;
            id_ex_conv_start   <= id_conv_start;
            id_ex_conv_init    <= id_conv_init;
        end
    end

    // =========================================================================
    // EX stage
    // =========================================================================
    wire [31:0] ex_alu_result,  ex_conv_result;
    wire [31:0] ex_rs2_data;
    wire [4:0]  ex_rd_addr;
    wire [31:0] ex_pc_plus4;
    wire        ex_mem_read,    ex_mem_write;
    wire [1:0]  ex_mem_size;
    wire        ex_mem_sign_ext;
    wire [1:0]  ex_wb_sel;
    wire        ex_reg_write,   ex_is_jump;

    ex_stage #(
        .CONV_LATENCY (CONV_LATENCY),
        .DATA_WIDTH   (DATA_WIDTH),
        .ACCUM_WIDTH  (ACCUM_WIDTH)
    ) u_ex (
        .clk              (clk),
        .rst_n            (rst_n),
        .pc_if_i          (id_ex_pc_if),
        .pc_plus4_i       (id_ex_pc_plus4),
        .rs1_data_i       (id_ex_rs1_data),
        .rs2_data_i       (id_ex_rs2_data),
        .rs1_addr_i       (id_ex_rs1_addr),
        .rs2_addr_i       (id_ex_rs2_addr),
        .rd_addr_i        (id_ex_rd_addr),
        .imm_i            (id_ex_imm),
        .alu_op_i         (id_ex_alu_op),
        .alu_src_a_i      (id_ex_alu_src_a),
        .alu_src_b_i      (id_ex_alu_src_b),
        .mem_read_i       (id_ex_mem_read),
        .mem_write_i      (id_ex_mem_write),
        .mem_size_i       (id_ex_mem_size),
        .mem_sign_ext_i   (id_ex_mem_sign_ext),
        .wb_sel_i         (id_ex_wb_sel),
        .reg_write_i      (id_ex_reg_write),
        .is_branch_i      (id_ex_is_branch),
        .branch_funct3_i  (id_ex_branch_funct3),
        .is_jal_i         (id_ex_is_jal),
        .is_jalr_i        (id_ex_is_jalr),
        .conv_start_i     (id_ex_conv_start),
        .conv_init_i      (id_ex_conv_init),
        .alu_result_o     (ex_alu_result),
        .conv_result_o    (ex_conv_result),
        .rs2_data_o       (ex_rs2_data),
        .rd_addr_o        (ex_rd_addr),
        .pc_plus4_o       (ex_pc_plus4),
        .mem_read_o       (ex_mem_read),
        .mem_write_o      (ex_mem_write),
        .mem_size_o       (ex_mem_size),
        .mem_sign_ext_o   (ex_mem_sign_ext),
        .wb_sel_o         (ex_wb_sel),
        .reg_write_o      (ex_reg_write),
        .is_jump_o        (ex_is_jump),
        .pc_src_o         (pc_src),
        .flush_o          (flush),
        .branch_target_o  (branch_target),
        .jump_target_o    (jump_target),
        .stall_o          (stall)
    );

    // =========================================================================
    // EX/MEM pipeline register
    // =========================================================================
    reg [31:0] ex_mem_alu_result,  ex_mem_conv_result;
    reg [31:0] ex_mem_rs2_data;
    reg [4:0]  ex_mem_rd_addr;
    reg [31:0] ex_mem_pc_plus4;
    reg        ex_mem_mem_read,    ex_mem_mem_write;
    reg [1:0]  ex_mem_mem_size;
    reg        ex_mem_mem_sign_ext;
    reg [1:0]  ex_mem_wb_sel;
    reg        ex_mem_reg_write,   ex_mem_is_jump;

    always @(posedge clk) begin
        if (!rst_n) begin
            ex_mem_alu_result   <= 32'h0;
            ex_mem_conv_result  <= 32'h0;
            ex_mem_rs2_data     <= 32'h0;
            ex_mem_rd_addr      <= 5'h0;
            ex_mem_pc_plus4     <= 32'h4;
            ex_mem_mem_read     <= 1'b0;
            ex_mem_mem_write    <= 1'b0;
            ex_mem_mem_size     <= 2'b10;
            ex_mem_mem_sign_ext <= 1'b1;
            ex_mem_wb_sel       <= 2'b00;
            ex_mem_reg_write    <= 1'b0;
            ex_mem_is_jump      <= 1'b0;
        // end else if (!stall) begin
        //     ex_mem_alu_result   <= ex_alu_result;
        //     ex_mem_conv_result  <= ex_conv_result;
        //     ex_mem_rs2_data     <= ex_rs2_data;
        //     ex_mem_rd_addr      <= ex_rd_addr;
        //     ex_mem_pc_plus4     <= ex_pc_plus4;
        //     ex_mem_mem_read     <= ex_mem_read;
        //     ex_mem_mem_write    <= ex_mem_write;
        //     ex_mem_mem_size     <= ex_mem_size;
        //     ex_mem_mem_sign_ext <= ex_mem_sign_ext;
        //     ex_mem_wb_sel       <= ex_wb_sel;
        //     ex_mem_reg_write    <= ex_reg_write;
        //     ex_mem_is_jump      <= ex_is_jump;
        end else if (conv_done) begin
        // Special capture: latch conv_result when Conv-PE finishes
        // All other fields already correct (frozen during stall)
            ex_mem_conv_result <= ex_conv_result;
            ex_mem_wb_sel      <= ex_wb_sel;       // ensure 2'b10 is captured
            ex_mem_reg_write   <= ex_reg_write;
            ex_mem_rd_addr     <= ex_rd_addr;
            ex_mem_pc_plus4    <= ex_pc_plus4;
            ex_mem_alu_result  <= ex_alu_result;
            ex_mem_rs2_data    <= ex_rs2_data;
            ex_mem_mem_read    <= ex_mem_read;
            ex_mem_mem_write   <= ex_mem_write;
            ex_mem_mem_size    <= ex_mem_size;
            ex_mem_mem_sign_ext<= ex_mem_sign_ext;
            ex_mem_is_jump     <= ex_is_jump;
        end else if (!stall) begin
            ex_mem_alu_result   <= ex_alu_result;
            ex_mem_conv_result  <= ex_conv_result;
            ex_mem_rs2_data     <= ex_rs2_data;
            ex_mem_rd_addr      <= ex_rd_addr;
            ex_mem_pc_plus4     <= ex_pc_plus4;
            ex_mem_mem_read     <= ex_mem_read;
            ex_mem_mem_write    <= ex_mem_write;
            ex_mem_mem_size     <= ex_mem_size;
            ex_mem_mem_sign_ext <= ex_mem_sign_ext;
            ex_mem_wb_sel       <= ex_wb_sel;
            ex_mem_reg_write    <= ex_reg_write;
            ex_mem_is_jump      <= ex_is_jump;
        end
    end

    // =========================================================================
    // MEM stage
    // =========================================================================
    wire [31:0] mem_alu_result,  mem_load_data;
    wire [31:0] mem_conv_result;
    wire [4:0]  mem_rd_addr;
    wire [31:0] mem_pc_plus4;
    wire [1:0]  mem_wb_sel;
    wire        mem_reg_write,   mem_is_jump;

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

    // =========================================================================
    // MEM/WB pipeline register
    // =========================================================================
    reg [31:0] mem_wb_alu_result,  mem_wb_load_data;
    reg [31:0] mem_wb_conv_result;
    reg [4:0]  mem_wb_rd_addr;
    reg [31:0] mem_wb_pc_plus4;
    reg [1:0]  mem_wb_wb_sel;
    reg        mem_wb_reg_write,   mem_wb_is_jump;

    always @(posedge clk) begin
        if (!rst_n) begin
            mem_wb_alu_result  <= 32'h0;
            mem_wb_load_data   <= 32'h0;
            mem_wb_conv_result <= 32'h0;
            mem_wb_rd_addr     <= 5'h0;
            mem_wb_pc_plus4    <= 32'h4;
            mem_wb_wb_sel      <= 2'b00;
            mem_wb_reg_write   <= 1'b0;
            mem_wb_is_jump     <= 1'b0;
        end else if (!stall) begin
            mem_wb_alu_result  <= mem_alu_result;
            mem_wb_load_data   <= mem_load_data;
            mem_wb_conv_result <= mem_conv_result;
            mem_wb_rd_addr     <= mem_rd_addr;
            mem_wb_pc_plus4    <= mem_pc_plus4;
            mem_wb_wb_sel      <= mem_wb_sel;
            mem_wb_reg_write   <= mem_reg_write;
            mem_wb_is_jump     <= mem_is_jump;
        end
    end

    // =========================================================================
    // WB stage
    // =========================================================================
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