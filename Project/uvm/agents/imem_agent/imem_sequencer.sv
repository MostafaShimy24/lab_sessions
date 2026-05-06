//==============================================================================
// imem_sequencer.sv — Instruction Memory Sequencer
//==============================================================================

class imem_sequencer extends uvm_sequencer #(riscv_instr_item);

    `uvm_component_utils(imem_sequencer)

    function new(string name = "imem_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass : imem_sequencer
