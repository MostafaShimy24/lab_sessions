class my_seq_item extends uvm_sequence_item;

  rand logic [7:0] data;
       logic       wr_en;   // 1 = write, 0 = read

  `uvm_object_utils_begin(my_seq_item)
    `uvm_field_int(data,  UVM_ALL_ON)
    `uvm_field_int(wr_en, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "my_seq_item");
    super.new(name);
  endfunction

endclass