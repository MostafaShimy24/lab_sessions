class my_monitor extends uvm_monitor;

  `uvm_component_utils(my_monitor)

  virtual my_interface vif;

  function new(string name = "my_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual my_interface)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", "Virtual interface not found in monitor")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);

      if (vif.rst_n && (vif.wr_en || vif.rd_en)) begin
        `uvm_info("MON",
          $sformatf("wr_en=%0b wr_data=0x%0h rd_en=%0b rd_data=0x%0h full=%0b empty=%0b",
                    vif.wr_en, vif.wr_data, vif.rd_en, vif.rd_data, vif.full, vif.empty),
          UVM_MEDIUM)
      end
    end
  endtask

endclass