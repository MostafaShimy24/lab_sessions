//==============================================================================
// dmem_agent.sv — Data Memory Agent (Active)
//==============================================================================

class dmem_agent extends uvm_agent;

    `uvm_component_utils(dmem_agent)

    dmem_sequencer  sqr;
    dmem_driver     drv;

    function new(string name = "dmem_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (get_is_active() == UVM_ACTIVE) begin
            sqr = dmem_sequencer::type_id::create("sqr", this);
            drv = dmem_driver::type_id::create("drv", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (get_is_active() == UVM_ACTIVE)
            drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

endclass : dmem_agent
