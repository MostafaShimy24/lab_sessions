class my_driver extends uvm_driver #(my_seq_item);

  `uvm_component_utils(my_driver)

  virtual my_interface vif;

  function new(string name = "my_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual my_interface)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", "Virtual interface not found in driver")
  endfunction

  task run_phase(uvm_phase phase);
    my_seq_item tr;

    vif.wr_en   <= 1'b0;
    vif.rd_en   <= 1'b0;
    vif.wr_data <= '0;

    forever begin
      seq_item_port.get_next_item(tr);

      // Drive for one cycle
      @(posedge vif.clk);
      if (!vif.rst_n) begin
        vif.wr_en   <= 1'b0;
        vif.rd_en   <= 1'b0;
        vif.wr_data <= '0;
      end
      else begin
        if (tr.wr_en) begin
          vif.wr_en   <= 1'b1;
          vif.rd_en   <= 1'b0;
          vif.wr_data <= tr.data;
        end
        else begin
          vif.wr_en   <= 1'b0;
          vif.rd_en   <= 1'b1;
          vif.wr_data <= '0;
        end
      end

      // Remove enables next cycle
      @(posedge vif.clk);
      vif.wr_en <= 1'b0;
      vif.rd_en <= 1'b0;

      seq_item_port.item_done();
    end
  endtask

endclass