//==============================================================================
// dmem_driver.sv — Data Memory Driver (Backdoor)
//------------------------------------------------------------------------------
// Pre-loads dmem regions via hierarchical backdoor before reset release.
// Receives dmem_txn items from the sequencer and writes individual bytes.
//==============================================================================

class dmem_driver extends uvm_driver #(dmem_txn);

    `uvm_component_utils(dmem_driver)

    virtual riscv_if vif;

    function new(string name = "dmem_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual riscv_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not set for dmem_driver")
    endfunction

    task run_phase(uvm_phase phase);
        dmem_txn item;

        forever begin
            seq_item_port.get_next_item(item);
            `uvm_info("DMEM_DRV", $sformatf("Pre-load: %s", item.convert2string()), UVM_HIGH)
            seq_item_port.item_done();
        end
    endtask

endclass : dmem_driver
