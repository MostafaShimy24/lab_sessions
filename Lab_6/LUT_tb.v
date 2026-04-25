`timescale 1ns/1ps

module LUT_tb;

    reg clk;
    reg rst_n;
    reg [1:0] in;
    reg [1:0] shift_amt;
    reg is_sync;

    wire y;

    // Instantiate DUT
    LUT dut (
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .shift_amt(shift_amt),
        .is_sync(is_sync),
        .y(y)
    );

    // Clock generation
    always #5 clk = ~clk;

    integer i, j;

    initial begin
        // Init
        clk = 0;
        rst_n = 0;
        is_sync = 0;
        in = 0;
        shift_amt = 0;

        // Reset
        #10;
        rst_n = 1;

        $display("---- COMBINATIONAL MODE ----");

        // Test all combinations (combinational)
        is_sync = 0;
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                in = i;
                shift_amt = j;
                #2;
                $display("in=%b shift=%b -> y=%b", in, shift_amt, y);
            end
        end

        // Test synchronous mode
        $display("---- SYNCHRONOUS MODE ----");

        is_sync = 1;

        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                in = i;
                shift_amt = j;
                @(posedge clk); 
                #1;
                $display("SYNC in=%b shift=%b -> y=%b", in, shift_amt, y);
            end
        end

        #20;
        $finish;
    end

endmodule