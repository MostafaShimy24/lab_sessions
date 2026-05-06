//==============================================================================
// dmem_sequencer.sv — Data Memory Sequencer
//==============================================================================

class dmem_sequencer extends uvm_sequencer #(dmem_txn);

    `uvm_component_utils(dmem_sequencer)

    function new(string name = "dmem_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass : dmem_sequencer
