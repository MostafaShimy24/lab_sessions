//==============================================================================
// test_branch.sv — Branch Test (SEQ_BRANCH)
//==============================================================================

class test_branch extends riscv_base_test;

    `uvm_component_utils(test_branch)

    function new(string name = "test_branch", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        seq_branch seq;
        phase.raise_objection(this);

        seq = seq_branch::type_id::create("seq");

        fork
            seq.start(m_env.m_imem_agent.sqr);
        join_none

        #100;

        collect_program_from_driver();
        apply_reset();
        wait_for_completion(5000);

        repeat (50) @(posedge vif.clk);

        // Dump marker registers to verify branch behavior
        dump_branch_markers();

        phase.drop_objection(this);
    endtask

    function void dump_branch_markers();
        bit [31:0] x30_val, x31_val;

        x30_val = tb_top.u_dut.u_id.u_regfile.regs[30];
        x31_val = tb_top.u_dut.u_id.u_regfile.regs[31];

        `uvm_info("TEST", "=== Branch Marker Registers ===", UVM_LOW)
        `uvm_info("TEST", $sformatf("  x30 = 0x%08h", x30_val), UVM_LOW)
        `uvm_info("TEST", $sformatf("  x31 = 0x%08h", x31_val), UVM_LOW)

        // Full regfile dump for debug
        begin
            int i;
            bit [31:0] val;
            `uvm_info("TEST", "=== Full Register File ===", UVM_LOW)
            for (i = 1; i < 32; i++) begin
                val = tb_top.u_dut.u_id.u_regfile.regs[i];
                if (val != 0)
                    `uvm_info("TEST", $sformatf("  x%0d = 0x%08h", i, val), UVM_LOW)
            end
        end
    endfunction

endclass : test_branch
