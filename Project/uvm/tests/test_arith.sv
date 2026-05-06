//==============================================================================
// test_arith.sv — Arithmetic Test (SEQ_ARITH)
//==============================================================================

class test_arith extends riscv_base_test;

    `uvm_component_utils(test_arith)

    function new(string name = "test_arith", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        seq_arith seq;
        phase.raise_objection(this);

        seq = seq_arith::type_id::create("seq");

        // Start the sequence on the imem agent's sequencer
        // This generates instructions into the driver's queue
        fork
            seq.start(m_env.m_imem_agent.sqr);
        join_none

        // Wait a bit for sequence to finish generating
        #100;

        // Collect program from driver and load via backdoor
        collect_program_from_driver();
        apply_reset();

        // Wait for program execution to complete
        wait_for_completion(8000);

        // Extra drain time
        repeat (50) @(posedge vif.clk);

        // Final register file dump for debug
        dump_regfile();

        phase.drop_objection(this);
    endtask

    function void dump_regfile();
        int i;
        bit [31:0] val;
        `uvm_info("TEST", "=== Register File Dump ===", UVM_LOW)
        for (i = 0; i < 32; i++) begin
            if (i == 0)
                val = 32'h0;
            else
                val = vif.read_regfile(i);
            if (val != 0)
                `uvm_info("TEST", $sformatf("  x%0d = 0x%08h", i, val), UVM_LOW)
        end
    endfunction

endclass : test_arith
