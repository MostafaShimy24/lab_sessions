class my_env extends uvm_env;

  `uvm_component_utils(my_env)

  my_agent agent_h;

  function new(string name = "my_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent_h = my_agent::type_id::create("agent_h", this);
  endfunction

endclass