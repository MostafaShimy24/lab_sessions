class my_sequencer extends uvm_sequencer #(my_seq_item);

  `uvm_component_utils(my_sequencer)

  virtual my_interface vif;

  function new(string name = "my_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual my_interface)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", "Virtual interface not found in sequencer")
  endfunction

endclass