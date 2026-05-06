//==============================================================================
// imem_agent.sv — Instruction Memory Agent (Active)
//==============================================================================

class imem_agent extends uvm_agent;

    `uvm_component_utils(imem_agent)

    imem_sequencer  sqr;
    imem_driver     drv;

    function new(string name = "imem_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (get_is_active() == UVM_ACTIVE) begin
            sqr = imem_sequencer::type_id::create("sqr", this);
            drv = imem_driver::type_id::create("drv", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (get_is_active() == UVM_ACTIVE)
            drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

endclass : imem_agent
