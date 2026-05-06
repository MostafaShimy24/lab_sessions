//==============================================================================
// dmem_store_monitor.sv — Data Memory Store Monitor (Passive)
//------------------------------------------------------------------------------
// Watches the EX/MEM pipeline register for store transactions.
// On every cycle where mem_write=1 in the MEM stage, a store transaction is
// sent to the scoreboard via an analysis port.
//==============================================================================

class store_txn extends uvm_sequence_item;
    `uvm_object_utils(store_txn)

    bit [31:0] addr;
    bit [31:0] data;
    bit [1:0]  size;   // 00=byte, 01=half, 10=word
    time       tstamp;

    function new(string name = "store_txn");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("STORE: addr=0x%08h data=0x%08h size=%0d @%0t",
                         addr, data, size, tstamp);
    endfunction
endclass : store_txn


class dmem_store_monitor extends uvm_monitor;

    `uvm_component_utils(dmem_store_monitor)

    virtual riscv_if vif;
    uvm_analysis_port #(store_txn) ap;

    function new(string name = "dmem_store_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual riscv_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not set for dmem_store_monitor")
    endfunction

    task run_phase(uvm_phase phase);
        store_txn txn;

        @(posedge vif.rst_n);
        @(posedge vif.clk);

        forever begin
            @(posedge vif.clk);
            #1;

            // Probe the MEM stage store signals
            if (tb_top.u_dut.ex_mem_mem_write) begin
                txn = store_txn::type_id::create("store_txn");
                txn.addr   = tb_top.u_dut.ex_mem_alu_result;
                txn.data   = tb_top.u_dut.ex_mem_rs2_data;
                txn.size   = tb_top.u_dut.ex_mem_mem_size;
                txn.tstamp = $time;
                `uvm_info("STORE_MON", txn.convert2string(), UVM_HIGH)
                ap.write(txn);
            end
        end
    endtask

endclass : dmem_store_monitor
