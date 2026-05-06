//==============================================================================
// riscv_props.v — Phase 1 Formal Properties (Safety + Conv-PE Bounded)
//------------------------------------------------------------------------------
// Properties proved here:
//   FLUSH_SAFE       — ID/EX holds NOP bubble cycle after flush  [unbounded]
//   X0_SAFE          — wb_we to x0 with non-zero data never occurs [unbounded]
//   PC_PROGRESS      — PC changes every unstalled cycle           [unbounded]
//   CONV_STALL_COUNT — exactly CONV_LATENCY stalls per MAC        [depth>=8]
//   CONV_RESULT_STABLE — conv_result holds from conv_done to WB  [depth>=8]
//   CONV_FSM         — only IDLE->BUSY->DONE->IDLE reachable      [depth>=8]
//==============================================================================
`timescale 1ns/1ps

module riscv_props #(
    parameter integer CONV_LATENCY = 4,
    parameter integer DATA_WIDTH   = 32,
    parameter integer ACCUM_WIDTH  = 32
)(
    input wire        clk,
    input wire        rst_n,
    input wire        flush,
    input wire        stall,
    input wire [31:0] pc_fetch,
    input wire        wb_we,
    input wire [4:0]  wb_addr,
    input wire [31:0] wb_data,
    input wire [1:0]  conv_status,
    input wire        conv_busy,
    input wire        conv_done,
    input wire [ACCUM_WIDTH-1:0] conv_result,
    input wire        conv_start_pulse,
    input wire        id_ex_reg_write,
    input wire [4:0]  id_ex_rd_addr,
    input wire [31:0] if_id_instr
);
    localparam [1:0] FSM_IDLE=2'b00, FSM_BUSY=2'b01, FSM_DONE=2'b10;
    localparam CTR_W = 4;

    reg [CTR_W-1:0] busy_cnt;
    always @(posedge clk) begin
        if (!rst_n)                busy_cnt <= {CTR_W{1'b0}};
        else if (conv_start_pulse) busy_cnt <= {CTR_W{1'b0}};
        else if (conv_busy)        busy_cnt <= busy_cnt + 1'b1;
    end

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

    always @(posedge clk) begin
        if (rst_n) begin
            FLUSH_SAFE: assert(
                $past(flush) ? (!id_ex_reg_write && id_ex_rd_addr==5'h0) : 1'b1);
            X0_SAFE: assert(
                !(wb_we && wb_addr==5'd0 && wb_data!=32'h0));
            PC_PROGRESS: assert(
                (!$past(stall) && $past(rst_n)) ?
                    (pc_fetch != $past(pc_fetch)) : 1'b1);
            CONV_STALL_COUNT: assert(
                conv_done ? (busy_cnt==CONV_LATENCY[CTR_W-1:0]) : 1'b1);
            CONV_RESULT_STABLE: assert(
                (result_check_active && stall) ?
                    (conv_result==result_at_done) : 1'b1);
            CONV_FSM_LEGAL:      assert(conv_status != 2'b11);
            CONV_FSM_IDLE_ENTRY: assert(
                (conv_status==FSM_IDLE && $past(conv_status)!=FSM_IDLE) ?
                    ($past(conv_status)==FSM_DONE) : 1'b1);
            CONV_FSM_BUSY_ENTRY: assert(
                (conv_status==FSM_BUSY && $past(conv_status)!=FSM_BUSY) ?
                    ($past(conv_status)==FSM_IDLE) : 1'b1);
            CONV_FSM_DONE_ENTRY: assert(
                (conv_status==FSM_DONE) ?
                    ($past(conv_status)==FSM_BUSY) : 1'b1);
            CONV_FSM_DONE_EXIT:  assert(
                ($past(conv_status)==FSM_DONE) ?
                    (conv_status==FSM_IDLE) : 1'b1);
        end
    end
endmodule

bind riscv_top riscv_props #(
    .CONV_LATENCY(CONV_LATENCY),.DATA_WIDTH(DATA_WIDTH),.ACCUM_WIDTH(ACCUM_WIDTH)
) u_props (
    .clk(clk),.rst_n(rst_n),.flush(flush),.stall(stall),
    .pc_fetch(pc_fetch),.wb_we(wb_we),.wb_addr(wb_addr),.wb_data(wb_data),
    .conv_status(u_ex.u_conv_pe.conv_status),.conv_busy(stall),
    .conv_done(conv_done_sig),.conv_result(u_ex.conv_result),
    .conv_start_pulse(conv_start_pulse_sig),
    .id_ex_reg_write(id_ex_reg_write),.id_ex_rd_addr(id_ex_rd_addr),
    .if_id_instr(if_id_instr)
);