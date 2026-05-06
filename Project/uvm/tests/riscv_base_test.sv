//==============================================================================
// riscv_base_test.sv — Base UVM Test
//------------------------------------------------------------------------------
// Common setup for all RISC-V UVM tests: instantiates the environment,
// manages reset, and provides the backdoor loading mechanism.
//==============================================================================

class riscv_base_test extends uvm_test;

    `uvm_component_utils(riscv_base_test)

    riscv_env   m_env;
    virtual riscv_if vif;

    // Program storage — filled by the sequence, used to load imem
    bit [31:0] program_words [$];

    function new(string name = "riscv_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env = riscv_env::type_id::create("m_env", this);

        if (!uvm_config_db #(virtual riscv_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not set for test")
    endfunction

    // =========================================================================
    // Load program into imem via backdoor (called before reset release)
    // =========================================================================
    task load_program_backdoor();
        int i;
        int nop_default = 32'h00000013;

        `uvm_info("TEST", $sformatf("Loading %0d instructions into imem backdoor",
                  program_words.size()), UVM_MEDIUM)

        // Fill all of imem with NOPs first
        for (i = 0; i < 1024; i++)
            vif.write_imem(i, nop_default);

        // Write program words
        for (i = 0; i < program_words.size(); i++) begin
            vif.write_imem(i, program_words[i]);
            `uvm_info("TEST", $sformatf("  imem[%0d] = 0x%08h", i, program_words[i]), UVM_HIGH)
        end
    endtask

    // =========================================================================
    // Collect instructions from the imem driver's queue
    // =========================================================================
    task collect_program_from_driver();
        imem_driver drv;
        drv = m_env.m_imem_agent.drv;
        program_words = drv.program_mem;
        `uvm_info("TEST", $sformatf("Collected %0d instructions from driver",
                  program_words.size()), UVM_MEDIUM)
    endtask

    // =========================================================================
    // Apply reset
    // =========================================================================
    task apply_reset();
        `uvm_info("TEST", "Applying reset...", UVM_MEDIUM)
        @(posedge vif.clk);
        // Reset is already low from tb_top initial block
        repeat (5) @(posedge vif.clk);
        // Load program during reset
        load_program_backdoor();
        @(negedge vif.clk);
        // Release reset via vif
        vif.release_reset();
        `uvm_info("TEST", "Reset released", UVM_MEDIUM)
    endtask

    // =========================================================================
    // Wait for program to reach terminal self-loop
    // =========================================================================
// =========================================================================
// Wait for program to reach terminal self-loop
// =========================================================================
task wait_for_completion(int max_cycles = 5000);
    int cycle;
    bit [31:0] prev_pc;
    int stall_count;

    prev_pc = 32'hFFFF_FFFF;
    stall_count = 0;

    for (cycle = 0; cycle < max_cycles; cycle++) begin
        @(posedge vif.clk);
        #1;

        // Check if PC is stuck and pipeline is not stalled.
        // This indicates the terminal self-loop.
        if ((vif.pc_reg === prev_pc) && !vif.stall) begin
            stall_count++;

            if (stall_count > 5) begin
                `uvm_info("TEST", $sformatf(
                    "Program completed at PC=0x%08h after %0d cycles",
                    prev_pc,
                    cycle
                ), UVM_MEDIUM)
                return;
            end
        end
        else begin
            stall_count = 0;
        end

        prev_pc = vif.pc_reg;
    end

    `uvm_warning("TEST", $sformatf(
        "Timeout after %0d cycles ? PC=0x%08h",
        max_cycles,
        prev_pc
    ))
endtask

    // =========================================================================
    // Default run phase — subclasses override to start specific sequences
    // =========================================================================
// =========================================================================
// Default run phase ? subclasses override to start specific sequences
// =========================================================================
// =========================================================================
// Default run phase ? subclasses override to start specific sequences
// =========================================================================
task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    apply_reset();

    wait_for_completion(5000);

    // Give some time for pipeline drain after completion
    repeat (20) @(posedge vif.clk);

    phase.drop_objection(this);
endtask

endclass : riscv_base_test
