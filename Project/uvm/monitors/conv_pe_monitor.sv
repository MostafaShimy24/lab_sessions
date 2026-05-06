//==============================================================================
// conv_pe_monitor.sv — Conv-PE Monitor (Passive)
//------------------------------------------------------------------------------
// Monitors the Conv-PE FSM state transitions (IDLE→BUSY→DONE→IDLE).
// Broadcasts transition events to the coverage collector and result
// transactions to the scoreboard.
//==============================================================================

class conv_txn extends uvm_sequence_item;
    `uvm_object_utils(conv_txn)

    bit [1:0]  prev_status;  // FSM state before transition
    bit [1:0]  curr_status;  // FSM state after transition
    bit [31:0] result;       // conv_result value (valid on DONE)
    bit        busy;
    bit        done;
    time       tstamp;

    function new(string name = "conv_txn");
        super.new(name);
    endfunction

    virtual function string convert2string();
        string s;
        s = $sformatf("CONV: %02b->%02b busy=%0b done=%0b result=0x%08h @%0t",
                      prev_status, curr_status, busy, done, result, tstamp);
        return s;
    endfunction
endclass : conv_txn


class conv_pe_monitor extends uvm_monitor;

    `uvm_component_utils(conv_pe_monitor)

    virtual riscv_if vif;
    uvm_analysis_port #(conv_txn) ap;

    function new(string name = "conv_pe_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual riscv_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not set for conv_pe_monitor")
    endfunction

    task run_phase(uvm_phase phase);
        conv_txn  txn;
        bit [1:0] prev_state;
        bit [1:0] curr_state;

        @(posedge vif.rst_n);
        @(posedge vif.clk);

        prev_state = 2'b00; // IDLE after reset

        forever begin
            @(posedge vif.clk);
            #1;

            curr_state = vif.conv_status;

            if (curr_state != prev_state) begin
                txn = conv_txn::type_id::create("conv_txn");
                txn.prev_status = prev_state;
                txn.curr_status = curr_state;
                txn.busy        = vif.conv_busy;
                txn.done        = vif.conv_done;
                txn.result      = vif.conv_result;
                txn.tstamp      = $time;
                `uvm_info("CONV_MON", txn.convert2string(), UVM_MEDIUM)
                ap.write(txn);
            end

            prev_state = curr_state;
        end
    endtask

endclass : conv_pe_monitor
