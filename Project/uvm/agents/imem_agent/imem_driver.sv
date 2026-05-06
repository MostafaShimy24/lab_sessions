//==============================================================================
// imem_driver.sv — Instruction Memory Driver (Backdoor)
//------------------------------------------------------------------------------
// Receives instruction items from the sequencer and writes them into the DUT's
// imem array via hierarchical cross-module reference. After all instructions
// are loaded, it asserts reset to start execution, then monitors PC to detect
// the terminal self-loop (end of program).
//==============================================================================

class imem_driver extends uvm_driver #(riscv_instr_item);

    `uvm_component_utils(imem_driver)

    virtual riscv_if vif;

    // Storage for the complete program to be loaded
    bit [31:0] program_mem [$];

    function new(string name = "imem_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual riscv_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not set for imem_driver")
    endfunction

    task run_phase(uvm_phase phase);
        riscv_instr_item item;

        // Collect all instructions from the sequence
        program_mem.delete();
        forever begin
            seq_item_port.get_next_item(item);
            program_mem.push_back(item.instr);
            `uvm_info("IMEM_DRV", $sformatf("Queued instr[%0d] = 0x%08h",
                      program_mem.size()-1, item.instr), UVM_HIGH)
            seq_item_port.item_done();
        end
    endtask

endclass : imem_driver
