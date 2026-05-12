module simple_tb_riscv_top;

    reg clk;
    reg rst_n;

    integer pass_count = 0;
    integer fail_count = 0;

    riscv_top #(
        .IMEM_HEX("program.hex"),
        .DMEM_HEX("data.hex")
    ) dut (
        .clk(clk),
        .rst_n(rst_n)
    );

    // Clock
    always #5 clk = ~clk;

    // Reset
    initial begin
        clk = 0;
        rst_n = 0;
        #20 rst_n = 1;
    end

    // ================================
    // TEST SEQUENCE
    // ================================
    initial begin
        #1000;  // wait for pipeline to finish

        test_lw();
        test_add();
        test_zero_flag();

        // Final report
        $display("=====================================");
        $display("TOTAL PASS = %0d", pass_count);
        $display("TOTAL FAIL = %0d", fail_count);
        $display("=====================================");

        $finish;
    end

    // ================================
    // CHECK TASK
    // ================================
    task check;
        input [31:0] actual;
        input [31:0] expected;
        input [200:0] name;
        begin
            if (actual === expected) begin
                $display("PASS: %s | got=%0d", name, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: %s | got=%0d expected=%0d", name, actual, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ================================
    // TEST 1: LOAD
    // ================================
    task test_lw;
        begin
            check(dut.u_id.u_regfile.regs[2], 32'd100, "LW x2 = 100");
        end
    endtask

    // ================================
    // TEST 2: ADD
    // ================================
    task test_add;
        begin
            check(dut.u_id.u_regfile.regs[3], 32'd12, "ADD x3 = 12");
        end
    endtask

    // ================================
    // TEST 3: ZERO RESULT
    // ================================
    task test_zero_flag;
        begin
            check(dut.u_id.u_regfile.regs[6], 32'd0, "ADD -1 + 1 = 0");
        end
    endtask

endmodule