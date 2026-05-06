//==============================================================================
// riscv_coverage.sv ? Functional Coverage Collector
//==============================================================================

`ifndef RISCV_COVERAGE_SV
`define RISCV_COVERAGE_SV

class riscv_coverage extends uvm_subscriber #(wb_txn);

    `uvm_component_utils(riscv_coverage)

    // Extra analysis export for Conv-PE transactions.
    // uvm_analysis_imp_conv must already be declared in riscv_uvm_pkg.sv using:
    // `uvm_analysis_imp_decl(_conv)
    uvm_analysis_imp_conv #(conv_txn, riscv_coverage) conv_export;

    virtual riscv_if vif;

    // =========================================================================
    // Coverage variables
    // =========================================================================
    bit [6:0]  sampled_opcode;
    bit [3:0]  sampled_alu_op;
    bit [31:0] sampled_alu_a;
    bit [31:0] sampled_alu_b;
    bit [2:0]  sampled_branch_funct3;
    bit        sampled_branch_taken;
    bit        sampled_is_branch;

    bit [1:0]  conv_prev_status;
    bit [1:0]  conv_curr_status;

    // =========================================================================
    // Covergroup 1: RV32I Opcode Classes
    // =========================================================================
    covergroup cg_opcode;
        option.per_instance = 1;
        option.name         = "cg_opcode";

        cp_opcode: coverpoint sampled_opcode {
            bins r_type    = {7'b0110011};
            bins i_arith   = {7'b0010011};
            bins load      = {7'b0000011};
            bins store     = {7'b0100011};
            bins branch    = {7'b1100011};
            bins jal       = {7'b1101111};
            bins jalr      = {7'b1100111};
            bins lui       = {7'b0110111};
            bins auipc     = {7'b0010111};
            bins fence     = {7'b0001111};
            bins system    = {7'b1110011};
            bins custom0   = {7'b0001011};
        }
    endgroup

    // =========================================================================
    // Covergroup 2: Conv-PE FSM State Transitions
    // =========================================================================
    covergroup cg_conv_status;
        option.per_instance = 1;
        option.name         = "cg_conv_status";

        cp_prev: coverpoint conv_prev_status {
            bins idle = {2'b00};
            bins busy = {2'b01};
            bins done = {2'b10};
        }

        cp_curr: coverpoint conv_curr_status {
            bins idle = {2'b00};
            bins busy = {2'b01};
            bins done = {2'b10};
        }

        cx_transition: cross cp_prev, cp_curr {
            bins idle_to_busy = binsof(cp_prev.idle) && binsof(cp_curr.busy);
            bins busy_to_done = binsof(cp_prev.busy) && binsof(cp_curr.done);
            bins done_to_idle = binsof(cp_prev.done) && binsof(cp_curr.idle);

            ignore_bins idle_stay = binsof(cp_prev.idle) && binsof(cp_curr.idle);
            ignore_bins busy_stay = binsof(cp_prev.busy) && binsof(cp_curr.busy);
            ignore_bins done_stay = binsof(cp_prev.done) && binsof(cp_curr.done);
        }
    endgroup

    // =========================================================================
    // Covergroup 3: ALU Boundary Values
    // =========================================================================
    covergroup cg_alu_boundary;
        option.per_instance = 1;
        option.name         = "cg_alu_boundary";

        cp_operand_a: coverpoint sampled_alu_a {
            bins zero      = {32'h0000_0000};
            bins pos_one   = {32'h0000_0001};
            bins neg_one   = {32'hFFFF_FFFF};
            bins max_pos   = {32'h7FFF_FFFF};
            bins min_neg   = {32'h8000_0000};
            bins others    = default;
        }

        cp_operand_b: coverpoint sampled_alu_b {
            bins zero      = {32'h0000_0000};
            bins pos_one   = {32'h0000_0001};
            bins neg_one   = {32'hFFFF_FFFF};
            bins max_pos   = {32'h7FFF_FFFF};
            bins min_neg   = {32'h8000_0000};
            bins others    = default;
        }

        cp_shift_amt: coverpoint sampled_alu_b[4:0] {
            bins zero_shift = {5'd0};
            bins max_shift  = {5'd31};
            bins others     = default;
        }

        cp_alu_op: coverpoint sampled_alu_op {
            bins add  = {4'b0000};
            bins sub  = {4'b0001};
            bins sll  = {4'b0010};
            bins slt  = {4'b0011};
            bins sltu = {4'b0100};
            bins xor_ = {4'b0101};
            bins srl  = {4'b0110};
            bins sra  = {4'b0111};
            bins or_  = {4'b1000};
            bins and_ = {4'b1001};
        }
    endgroup

    // =========================================================================
    // Covergroup 4: Branch Type ? Taken/Not-Taken
    // =========================================================================
    covergroup cg_branch;
        option.per_instance = 1;
        option.name         = "cg_branch";

        cp_branch_type: coverpoint sampled_branch_funct3 {
            bins beq  = {3'b000};
            bins bne  = {3'b001};
            bins blt  = {3'b100};
            bins bge  = {3'b101};
            bins bltu = {3'b110};
            bins bgeu = {3'b111};
        }

        cp_taken: coverpoint sampled_branch_taken {
            bins taken     = {1'b1};
            bins not_taken = {1'b0};
        }

        cx_branch_x_taken: cross cp_branch_type, cp_taken;
    endgroup

    // =========================================================================
    // Constructor
    // =========================================================================
    function new(string name = "riscv_coverage", uvm_component parent = null);
        super.new(name, parent);

        cg_opcode       = new();
        cg_conv_status  = new();
        cg_alu_boundary = new();
        cg_branch       = new();
    endfunction

    // =========================================================================
    // Build Phase
    // =========================================================================
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        conv_export = new("conv_export", this);

        if (!uvm_config_db #(virtual riscv_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "Virtual interface not set for riscv_coverage")
        end
    endfunction

    // =========================================================================
    // WB transaction handler
    // =========================================================================
    virtual function void write(wb_txn t);
        // Currently not sampling from wb_txn directly.
        // Pipeline-level coverage is sampled periodically in run_phase().
    endfunction

    // =========================================================================
    // Conv transaction handler
    // =========================================================================
    virtual function void write_conv(conv_txn t);
        conv_prev_status = t.prev_status;
        conv_curr_status = t.curr_status;
        cg_conv_status.sample();
    endfunction

    // =========================================================================
    // Periodic sampling task
    // =========================================================================
    task run_phase(uvm_phase phase);
        @(posedge vif.rst_n);

        forever begin
            @(posedge vif.clk);
            #1;
            sample_pipeline_signals();
        end
    endtask

    // =========================================================================
    // Sample pipeline signals through virtual interface
    // =========================================================================
    function void sample_pipeline_signals();

        if (vif.stall) begin
            return;
        end

        sampled_opcode = vif.if_id_instr[6:0];
        cg_opcode.sample();

        sampled_alu_op = vif.id_ex_alu_op;
        sampled_alu_a  = vif.ex_op_a;
        sampled_alu_b  = vif.ex_op_b;
        cg_alu_boundary.sample();

        sampled_is_branch     = vif.id_ex_is_branch;
        sampled_branch_funct3 = vif.id_ex_branch_funct3;
        sampled_branch_taken  = vif.ex_branch_taken;

        if (sampled_is_branch) begin
            cg_branch.sample();
        end
    endfunction

    // =========================================================================
    // End-of-test coverage report
    // =========================================================================
    function void report_phase(uvm_phase phase);
        `uvm_info("COV", "========================================", UVM_NONE)
        `uvm_info("COV", "  Coverage Summary", UVM_NONE)
        `uvm_info("COV", $sformatf("  cg_opcode:       %.1f%%", cg_opcode.get_inst_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf("  cg_conv_status:  %.1f%%", cg_conv_status.get_inst_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf("  cg_alu_boundary: %.1f%%", cg_alu_boundary.get_inst_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf("  cg_branch:       %.1f%%", cg_branch.get_inst_coverage()), UVM_NONE)
        `uvm_info("COV", "========================================", UVM_NONE)
    endfunction

endclass : riscv_coverage

`endif