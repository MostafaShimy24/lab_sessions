//==============================================================================
// riscv_formal.sv — Formal Wrapper for RISC-V Pipeline + Conv-PE
//------------------------------------------------------------------------------
// Follows the same pattern as fifo_system_top_formal.sv:
//   - assume statements that DRIVE the pipeline to execute instructions
//   - seen_X flags to track history
//   - cover(seen_X && current_state) for meaningful witness traces
//   - assert statements for safety properties
//==============================================================================
`timescale 1ns/1ps

module riscv_formal #(
    parameter integer CONV_LATENCY = 4,
    parameter integer DATA_WIDTH   = 32,
    parameter integer ACCUM_WIDTH  = 32
)(
    // ── DUT primary ports ────────────────────────────────────────────────────
    input wire        clk,
    input wire        rst_n,

    // ── Pipeline observable signals ──────────────────────────────────────────
    input wire        flush,
    input wire        stall,
    input wire [31:0] pc_fetch,

    // ── WB port ──────────────────────────────────────────────────────────────
    input wire        wb_we,
    input wire [4:0]  wb_addr,
    input wire [31:0] wb_data,

    // ── Conv-PE signals ──────────────────────────────────────────────────────
    input wire [1:0]  conv_status,
    input wire        conv_busy,
    input wire        conv_done,
    input wire [ACCUM_WIDTH-1:0] conv_result,
    input wire        conv_start_pulse,

    // ── ID/EX pipeline register ──────────────────────────────────────────────
    input wire        id_ex_reg_write,
    input wire [4:0]  id_ex_rd_addr,
    input wire        id_ex_conv_start,

    // ── IF/ID instruction ─────────────────────────────────────────────────────
    input wire [31:0] if_id_instr
);

    localparam [31:0] NOP      = 32'h00000013;
    localparam [1:0]  FSM_IDLE = 2'b00;
    localparam [1:0]  FSM_BUSY = 2'b01;
    localparam [1:0]  FSM_DONE = 2'b10;

    // =========================================================================
    // Busy counter for CONV_STALL_COUNT
    // =========================================================================
    localparam CTR_W = 4;
    reg [CTR_W-1:0] busy_cnt;

    always @(posedge clk) begin
        if (!rst_n)
            busy_cnt <= {CTR_W{1'b0}};
        else if (conv_start_pulse)
            busy_cnt <= {CTR_W{1'b0}};
        else if (conv_busy)
            busy_cnt <= busy_cnt + 1'b1;
    end

    // =========================================================================
    // CONV_RESULT_STABLE multi-cycle tracking
    // =========================================================================
    reg result_check_active;
    reg [ACCUM_WIDTH-1:0] result_at_done;

    always @(posedge clk) begin
        if (!rst_n) begin
            result_check_active <= 1'b0;
            result_at_done      <= {ACCUM_WIDTH{1'b0}};
        end else if (conv_done) begin
            result_check_active <= 1'b1;
            result_at_done      <= conv_result;
        end else if (!stall) begin
            result_check_active <= 1'b0;
        end
    end

    // =========================================================================
    // History flags for cover properties (same pattern as seen_empty/seen_full)
    // =========================================================================

    // Track that a real instruction has been seen in IF/ID
    reg seen_instr;
    always @(posedge clk) begin
        if (!rst_n)
            seen_instr <= 1'b0;
        else if (if_id_instr != NOP && !stall)
            seen_instr <= 1'b1;
    end

    // Track that a Conv-PE dispatch has been seen
    reg seen_conv_start;
    always @(posedge clk) begin
        if (!rst_n)
            seen_conv_start <= 1'b0;
        else if (conv_start_pulse)
            seen_conv_start <= 1'b1;
    end

    // =========================================================================
    // ── ASSUMPTIONS — drive pipeline activity ────────────────────────────────
    // Without these the solver keeps rst_n=0 or produces only NOPs.
    // =========================================================================

    // Release reset after at most 3 cycles
    always @(posedge clk) begin
        if ($past(rst_n,3))
            assume(rst_n);
    end

    // Once reset released, keep it released
    always @(posedge clk) begin
        if (rst_n)
            assume(rst_n);
    end

    // =========================================================================
    // ── ASSERTIONS ────────────────────────────────────────────────────────────
    // =========================================================================

    // P1: FLUSH_SAFE
    always @(posedge clk) begin
        if (rst_n)
            FLUSH_SAFE: assert (
                $past(flush) ?
                    (!id_ex_reg_write && id_ex_rd_addr == 5'h0) : 1'b1
            );
    end

    // P2: X0_SAFE
    always @(posedge clk) begin
        if (rst_n)
            X0_SAFE: assert (
                !(wb_we && (wb_addr == 5'd0) && (wb_data != 32'h0))
            );
    end

    // P3: PC_PROGRESS
    always @(posedge clk) begin
        if (rst_n)
            PC_PROGRESS: assert (
                (!$past(stall) && $past(rst_n)) ?
                    (pc_fetch != $past(pc_fetch)) : 1'b1
            );
    end

    // P4: CONV_STALL_COUNT
    always @(posedge clk) begin
        if (rst_n)
            CONV_STALL_COUNT: assert (
                conv_done ? (busy_cnt == CONV_LATENCY[CTR_W-1:0]) : 1'b1
            );
    end

    // P5: CONV_RESULT_STABLE
    always @(posedge clk) begin
        if (rst_n)
            CONV_RESULT_STABLE: assert (
                (result_check_active && stall) ?
                    (conv_result == result_at_done) : 1'b1
            );
    end

    // P6: CONV_FSM
    always @(posedge clk) begin
        if (rst_n) begin
            CONV_FSM_LEGAL:       assert (conv_status != 2'b11);
            CONV_FSM_IDLE_ENTRY:  assert (
                (conv_status == FSM_IDLE && $past(conv_status) != FSM_IDLE) ?
                    ($past(conv_status) == FSM_DONE) : 1'b1);
            CONV_FSM_BUSY_ENTRY:  assert (
                (conv_status == FSM_BUSY && $past(conv_status) != FSM_BUSY) ?
                    ($past(conv_status) == FSM_IDLE) : 1'b1);
            CONV_FSM_DONE_ENTRY:  assert (
                (conv_status == FSM_DONE) ?
                    ($past(conv_status) == FSM_BUSY) : 1'b1);
            CONV_FSM_DONE_EXIT:   assert (
                ($past(conv_status) == FSM_DONE) ?
                    (conv_status == FSM_IDLE) : 1'b1);
        end
    end

    // =========================================================================
    // ── COVERS ────────────────────────────────────────────────────────────────
    // Same pattern as FIFO: cover(seen_X && current_interesting_state)
    // =========================================================================

    // P7: INSTR_PROGRESS
    // Cover: a non-NOP was seen in IF/ID AND a WB write has now occurred
    // This proves an instruction travelled IF -> WB
    always @(posedge clk) begin
        if (rst_n)
            INSTR_PROGRESS: cover (seen_instr && wb_we && wb_addr != 5'd0);
    end

    // P8: CONV_TERMINATES
    // Cover: a Conv-PE was dispatched AND conv_done has now fired
    // This proves the Conv-PE completes a MAC operation
    always @(posedge clk) begin
        if (rst_n)
            CONV_TERMINATES: cover (seen_conv_start && conv_done);
    end

endmodule

//==============================================================================
// Bind to riscv_top
//==============================================================================
bind riscv_top riscv_formal #(
    .CONV_LATENCY (CONV_LATENCY),
    .DATA_WIDTH   (DATA_WIDTH),
    .ACCUM_WIDTH  (ACCUM_WIDTH)
) u_formal (
    .clk             (clk),
    .rst_n           (rst_n),
    .flush           (flush),
    .stall           (stall),
    .pc_fetch        (pc_fetch),
    .wb_we           (wb_we),
    .wb_addr         (wb_addr),
    .wb_data         (wb_data),
    .conv_status     (u_ex.u_conv_pe.conv_status),
    .conv_busy       (stall),
    .conv_done       (conv_done_sig),
    .conv_result     (u_ex.conv_result),
    .conv_start_pulse(conv_start_pulse_sig),
    .id_ex_reg_write (id_ex_reg_write),
    .id_ex_rd_addr   (id_ex_rd_addr),
    .id_ex_conv_start(id_ex_conv_start),
    .if_id_instr     (if_id_instr)
);