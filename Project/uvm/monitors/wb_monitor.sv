//==============================================================================
// wb_monitor.sv — Write-Back Stage Monitor (Passive)
//------------------------------------------------------------------------------
// Observes register write-backs at the WB stage via hierarchical probes.
// On every cycle where wb_we=1 and wb_addr!=0, a transaction is sent to the
// scoreboard and coverage collector via analysis ports.
//==============================================================================

class wb_txn extends uvm_sequence_item;
    `uvm_object_utils(wb_txn)

    bit [4:0]  rd_addr;
    bit [31:0] rd_data;
    bit        we;
    time       tstamp;

    function new(string name = "wb_txn");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("WB: we=%0b rd=x%0d data=0x%08h @%0t", we, rd_addr, rd_data, tstamp);
    endfunction
endclass : wb_txn


class wb_monitor extends uvm_monitor;

    `uvm_component_utils(wb_monitor)

    virtual riscv_if vif;
    uvm_analysis_port #(wb_txn) ap;

    function new(string name = "wb_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual riscv_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not set for wb_monitor")
    endfunction

    task run_phase(uvm_phase phase);
        wb_txn txn;

        // Wait for reset de-assertion
        @(posedge vif.rst_n);
        @(posedge vif.clk);

        forever begin
            @(posedge vif.clk);
            #1; // sample after clock edge settles

            // Hierarchical probes into the DUT WB signals
            if (tb_top.u_dut.wb_we && tb_top.u_dut.wb_addr != 5'd0) begin
                txn = wb_txn::type_id::create("wb_txn");
                txn.we      = 1'b1;
                txn.rd_addr = tb_top.u_dut.wb_addr;
                txn.rd_data = tb_top.u_dut.wb_data;
                txn.tstamp  = $time;
                `uvm_info("WB_MON", txn.convert2string(), UVM_HIGH)
                ap.write(txn);
            end
        end
    endtask

endclass : wb_monitor
