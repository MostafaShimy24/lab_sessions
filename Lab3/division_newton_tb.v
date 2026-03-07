`timescale 1ns / 1ps

module division_newton_tb;

    parameter DIV_WIDTH = 36;
    parameter WIDTH     = 18;
    parameter FRAC      = 14;
    parameter WAIT_CYCLES = 12;

    reg clk;
    reg rst;
    reg start;

    reg  [DIV_WIDTH-1:0] dividend;   // Q22.14
    reg  [WIDTH-1:0]     divisor;    // Q4.14
    wire [WIDTH-1:0]     quotient;   // Q4.14

    // DUT
    division_newton #(
        .DIV_WIDTH(DIV_WIDTH),
        .WIDTH(WIDTH),
        .FRAC(FRAC)
    ) DUT (
        .clk(clk),
        .rst(rst),
        .start(start),
        .dividend(dividend),
        .divisor(divisor),
        .quotient(quotient)
    );

    // Clock
    always #5 clk = ~clk;

    // ----------------------------
    // Conversion Functions
    // ----------------------------

    function real fixed_to_real_18;
        input [WIDTH-1:0] value;
        begin
            fixed_to_real_18 = value / (2.0**FRAC);
        end
    endfunction

    function real fixed_to_real_36;
        input [DIV_WIDTH-1:0] value;
        begin
            fixed_to_real_36 = value / (2.0**FRAC);
        end
    endfunction

    function [WIDTH-1:0] real_to_fixed_18;
        input real value;
        begin
            real_to_fixed_18 = $rtoi(value * (2.0**FRAC));
        end
    endfunction

    function [DIV_WIDTH-1:0] real_to_fixed_36;
        input real value;
        begin
            real_to_fixed_36 = $rtoi(value * (2.0**FRAC));
        end
    endfunction

    real expected;
    real result;

    task run_test;
        input real A_real;
        input real D_real;
        begin
            dividend = real_to_fixed_36(A_real);
            divisor  = real_to_fixed_18(D_real);

            expected = A_real / D_real;

            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;

            repeat (WAIT_CYCLES) @(posedge clk);

            result = fixed_to_real_18(quotient);

            $display("--------------------------------------");
            $display("A = %f , D = %f", A_real, D_real);
            $display("Expected = %f", expected);
            $display("DUT      = %f", result);
            $display("Error    = %f", expected - result);
        end
    endtask

    initial begin
        $dumpfile("division_newton_sim.vcd");
        $dumpvars(0,division_newton_tb);
        clk = 0;
        rst = 1;
        start = 0;

        #20 rst = 0;

        $display("======================================");
        $display("  Newton Divider Testbench    ");
        $display("======================================");

        // Small controlled cases
        run_test(10, 2.6);   // expected 4.0
        run_test(2.5, 2.5);    // expected 5.0
        run_test(8.6, 2.5);    // expected 2.5

        $display("======================================");
        $display("Test Finished");
        $display("======================================");

        $finish;
    end

endmodule