//==============================================================================
// wb_stage.v — Write-Back Stage
//------------------------------------------------------------------------------
// Project : ELCT1005 PROJ02 — Pipelined RISC-V CPU with Conv-PE
//
// Responsibilities:
//   1. Select the value to write back to the register file via a 4:1 mux:
//        wb_sel = 2'b00  ->  ALU result    (R-type, I-type, LUI, AUIPC)
//        wb_sel = 2'b01  ->  Load data     (LB, LH, LW, LBU, LHU)
//        wb_sel = 2'b10  ->  Conv-PE result(custom-0)
//        is_jump = 1     ->  PC + 4        (JAL, JALR — overrides wb_sel)
//   2. Drive the register file write port (rd_addr, rd_data, we)
//   3. Expose the write-back value and enable for forwarding to ID stage
//      (riscv_top.v connects wb_data_o / wb_we_o back to id_stage)
//
// Note: is_jump takes priority over wb_sel. JAL and JALR always write
// PC+4 regardless of wb_sel, which is set to 2'b00 in id_stage for those
// instructions (ALU computes the jump target, not the link address).
//==============================================================================
`timescale 1ns / 1ps
`default_nettype none

module wb_stage (
    // From MEM/WB pipeline register
    input  wire [31:0] alu_result_i,
    input  wire [31:0] load_data_i,
    input  wire [31:0] conv_result_i,
    input  wire [31:0] pc_plus4_i,
    input  wire [4:0]  rd_addr_i,
    input  wire [1:0]  wb_sel_i,
    input  wire        reg_write_i,
    input  wire        is_jump_i,

    // Register file write port (to id_stage wb_ inputs)
    output wire [4:0]  wb_addr_o,
    output wire [31:0] wb_data_o,
    output wire        wb_we_o
);

    // =========================================================================
    // 4:1 write-back mux
    // is_jump overrides wb_sel — JAL/JALR always write PC+4
    // =========================================================================
    reg [31:0] wb_data;
    always @* begin
        if (is_jump_i)
            wb_data = pc_plus4_i;          // JAL / JALR link address
        else begin
            case (wb_sel_i)
                2'b00:   wb_data = alu_result_i;   // R-type, I-type, LUI, AUIPC
                2'b01:   wb_data = load_data_i;    // loads
                2'b10:   wb_data = conv_result_i;  // Conv-PE
                default: wb_data = alu_result_i;
            endcase
        end
    end

    // =========================================================================
    // Output assignments
    // =========================================================================
    assign wb_addr_o = rd_addr_i;
    assign wb_data_o = wb_data;
    assign wb_we_o   = reg_write_i;

endmodule

`default_nettype wire