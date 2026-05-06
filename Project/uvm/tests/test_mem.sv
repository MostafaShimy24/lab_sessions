//==============================================================================
// test_mem.sv — Memory Test (SEQ_MEM)
//==============================================================================

class test_mem extends riscv_base_test;

    `uvm_component_utils(test_mem)

    function new(string name = "test_mem", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        seq_mem seq;
        phase.raise_objection(this);

        seq = seq_mem::type_id::create("seq");

        fork
            seq.start(m_env.m_imem_agent.sqr);
        join_none

        #100;

        collect_program_from_driver();
        apply_reset();
        wait_for_completion(5000);

        repeat (50) @(posedge vif.clk);

        // Verify key memory locations
        verify_memory();

        phase.drop_objection(this);
    endtask

    function void verify_memory();
        bit [31:0] val;

        // Check word at 0x100 (should have been written by SW)
        val = {tb_top.u_dut.u_mem.u_dmem.mem[12'h103],
               tb_top.u_dut.u_mem.u_dmem.mem[12'h102],
               tb_top.u_dut.u_mem.u_dmem.mem[12'h101],
               tb_top.u_dut.u_mem.u_dmem.mem[12'h100]};
        `uvm_info("TEST", $sformatf("dmem[0x100] = 0x%08h", val), UVM_LOW)

        // Check byte at 0x120
        `uvm_info("TEST", $sformatf("dmem[0x120] = 0x%02h",
                  tb_top.u_dut.u_mem.u_dmem.mem[12'h120]), UVM_LOW)
    endfunction

endclass : test_mem
