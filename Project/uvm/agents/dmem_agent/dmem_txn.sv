//==============================================================================
// dmem_txn.sv — Data Memory Transaction Item
//------------------------------------------------------------------------------
// Represents a single dmem pre-load operation (address + data + size).
// Used by the dmem_driver to backdoor-write data before simulation starts.
//==============================================================================

class dmem_txn extends uvm_sequence_item;

    `uvm_object_utils(dmem_txn)

    // Address within dmem (byte address, 0–4095)
    rand bit [11:0] addr;
    // Data to write
    rand bit [31:0] data;
    // Size: 00=byte, 01=half, 10=word
    rand bit [1:0]  size;

    constraint c_aligned {
        if (size == 2'b01) addr[0]   == 1'b0;   // half-word aligned
        if (size == 2'b10) addr[1:0] == 2'b00;   // word aligned
    }

    constraint c_addr_range {
        addr < 12'hFFC;  // stay within 4KB
    }

    function new(string name = "dmem_txn");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("dmem_txn: addr=0x%03h data=0x%08h size=%0d", addr, data, size);
    endfunction

endclass : dmem_txn
