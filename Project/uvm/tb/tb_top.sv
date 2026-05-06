//==============================================================================
// tb_top.sv — SystemVerilog Testbench Top Module
//------------------------------------------------------------------------------
// Instantiates the Verilog DUT (riscv_top), generates clock and reset,
// binds the virtual interface, and calls run_test() for UVM.
//==============================================================================

`timescale 1ns / 1ps

module tb_top;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import riscv_uvm_pkg::*;

    // =========================================================================
    // Clock and Reset
    // =========================================================================
    parameter CLK_PERIOD = 10;  // 100 MHz

    reg clk   = 1'b0;
    reg rst_n = 1'b0;

    always #(CLK_PERIOD/2) clk = ~clk;

    // =========================================================================
    // Virtual Interface
    // =========================================================================
    riscv_if rif (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // =========================================================================
    // DUT Instantiation
    // =========================================================================
    riscv_top #(
        .CONV_LATENCY (4),
        .DATA_WIDTH   (32),
        .ACCUM_WIDTH  (32),
        .IMEM_HEX     ("program.hex"),
        .DMEM_HEX     ("data.hex")
    ) u_dut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // =========================================================================
    // VCD Waveform Dump (optional, for debug)
    // =========================================================================
    initial begin
        $dumpfile("uvm_dump.vcd");
        $dumpvars(0, tb_top);
    end

    // =========================================================================
    // UVM Configuration and Test Start
    // =========================================================================
    initial begin
        // Register the virtual interface in the config DB
        uvm_config_db #(virtual riscv_if)::set(null, "*", "vif", rif);

        // Start UVM test (test name from +UVM_TESTNAME plusarg)
        run_test();
    end

    // =========================================================================
    // Timeout watchdog
    // =========================================================================
    initial begin
        #(CLK_PERIOD * 20000);
        $display("TB_TOP: WATCHDOG TIMEOUT");
        $finish;
    end

endmodule : tb_top
