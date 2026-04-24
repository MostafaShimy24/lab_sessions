`timescale 1ns/1ps

module top;

  import uvm_pkg::*;
  import my_pkg::*;
  `include "uvm_macros.svh"

  my_interface vif();

  // DUT instance
  fifo dut (
    .clk     (vif.clk),
    .rst_n   (vif.rst_n),
    .wr_en   (vif.wr_en),
    .wr_data (vif.wr_data),
    .rd_en   (vif.rd_en),
    .rd_data (vif.rd_data),
    .full    (vif.full),
    .empty   (vif.empty)
  );

  // Clock generation: 10 ns period
  initial begin
    vif.clk = 0;
    forever #5 vif.clk = ~vif.clk;
  end

  // Reset for 3 cycles
  initial begin
    vif.rst_n   = 0;
    vif.wr_en   = 0;
    vif.rd_en   = 0;
    vif.wr_data = 0;

    repeat (3) @(posedge vif.clk);
    vif.rst_n = 1;
  end

  initial begin
    uvm_config_db#(virtual my_interface)::set(null, "*", "vif", vif);
    run_test("my_test");
  end

endmodule	