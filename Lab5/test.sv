class my_test extends uvm_test;

  `uvm_component_utils(my_test)

  my_env      env_h;
  my_sequence seq_h;

  function new(string name = "my_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env_h = my_env::type_id::create("env_h", this);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    seq_h = my_sequence::type_id::create("seq_h");
    seq_h.start(env_h.agent_h.seqr);

    phase.drop_objection(this);
  endtask

endclass