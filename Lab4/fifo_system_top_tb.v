`timescale 1ns/1ps

module fifo_system_top_tb;

    // ------------------------------------------------------------
    // Parameters
    // ------------------------------------------------------------
    parameter D_SIZE  = 8;
    parameter A_SIZE  = 4;
    parameter P_SIZE  = 5;
    parameter F_DEPTH = 16;

    // ------------------------------------------------------------
    // DUT signals
    // ------------------------------------------------------------
    reg                i_w_clk;
    reg                i_w_rstn;
    reg                i_write_req;
    reg [D_SIZE-1:0]   i_w_data;

    reg                i_r_clk;
    reg                i_r_rstn;
    reg                i_read_req;

    wire [D_SIZE-1:0]  o_r_data;
    wire               o_full;
    wire               o_empty;

    // ------------------------------------------------------------
    // DUT instance
    // ------------------------------------------------------------
    fifo_system_top #(
        .D_SIZE (D_SIZE),
        .A_SIZE (A_SIZE),
        .P_SIZE (P_SIZE),
        .F_DEPTH(F_DEPTH)
    ) dut (
        .i_w_clk    (i_w_clk),
        .i_w_rstn   (i_w_rstn),
        .i_write_req(i_write_req),
        .i_w_data   (i_w_data),
        .i_r_clk    (i_r_clk),
        .i_r_rstn   (i_r_rstn),
        .i_read_req (i_read_req),
        .o_r_data   (o_r_data),
        .o_full     (o_full),
        .o_empty    (o_empty)
    );

    // ------------------------------------------------------------
    // Clocks
    // ------------------------------------------------------------
    initial begin
        i_w_clk = 1'b0;
        forever #5 i_w_clk = ~i_w_clk;   // 10 ns period
    end

    initial begin
        i_r_clk = 1'b0;
        forever #7 i_r_clk = ~i_r_clk;   // 14 ns period
    end

    // ------------------------------------------------------------
    // Scoreboard
    // ------------------------------------------------------------
    reg [D_SIZE-1:0] expected_mem [0:255];
    reg [D_SIZE-1:0] expected_data;
    reg [D_SIZE-1:0] pending_expected;

    reg pending_read_check;

    integer sb_wr_ptr;
    integer sb_rd_ptr;
    integer sb_count;
    integer error_count;
    integer i;

    // ------------------------------------------------------------
    // Accepted writes tracking
    // ------------------------------------------------------------
    always @(posedge i_w_clk) begin
        if (i_w_rstn && i_write_req && !o_full) begin
            expected_mem[sb_wr_ptr] = i_w_data;
            sb_wr_ptr = sb_wr_ptr + 1;
            sb_count  = sb_count + 1;

            $display("[%0t] WRITE accepted: data=0x%0h, scoreboard_count=%0d",
                     $time, i_w_data, sb_count);
        end
        else if (i_w_rstn && i_write_req && o_full) begin
            $display("[%0t] WRITE blocked (FULL): data=0x%0h",
                     $time, i_w_data);
        end
    end

    // ------------------------------------------------------------
    // Accepted reads tracking + compare
    // Compare one read clock later because read_module registers o_data
    // ------------------------------------------------------------
    always @(posedge i_r_clk or negedge i_r_rstn) begin
        if (!i_r_rstn) begin
            pending_read_check <= 1'b0;
            pending_expected   <= {D_SIZE{1'b0}};
        end
        else begin
            if (pending_read_check) begin
                if (o_r_data !== pending_expected) begin
                    $display("[%0t] ERROR: read mismatch. expected=0x%0h got=0x%0h",
                             $time, pending_expected, o_r_data);
                    error_count = error_count + 1;
                end
                else begin
                    $display("[%0t] READ matched: data=0x%0h", $time, o_r_data);
                end
            end

            pending_read_check <= 1'b0;

            if (i_read_req && !o_empty) begin
                if (sb_count == 0) begin
                    $display("[%0t] ERROR: scoreboard underflow during accepted read", $time);
                    error_count = error_count + 1;
                end
                else begin
                    expected_data = expected_mem[sb_rd_ptr];
                    sb_rd_ptr = sb_rd_ptr + 1;
                    sb_count  = sb_count - 1;

                    pending_expected   <= expected_data;
                    pending_read_check <= 1'b1;

                    $display("[%0t] READ accepted: expected_next=0x%0h, scoreboard_count=%0d",
                             $time, expected_data, sb_count);
                end
            end
            else if (i_read_req && o_empty) begin
                $display("[%0t] READ blocked (EMPTY)", $time);
            end
        end
    end

    // ------------------------------------------------------------
    // Tasks
    // ------------------------------------------------------------
    task reset_dut;
    begin
        i_write_req = 1'b0;
        i_read_req  = 1'b0;
        i_w_data    = {D_SIZE{1'b0}};
        i_w_rstn    = 1'b0;
        i_r_rstn    = 1'b0;

        sb_wr_ptr = 0;
        sb_rd_ptr = 0;
        sb_count  = 0;
        error_count = 0;

        pending_read_check = 1'b0;
        pending_expected   = {D_SIZE{1'b0}};

        repeat (4) @(posedge i_w_clk);
        repeat (4) @(posedge i_r_clk);

        i_w_rstn = 1'b1;
        i_r_rstn = 1'b1;

        $display("\n[%0t] Reset released\n", $time);
    end
    endtask

    task write_one;
        input [D_SIZE-1:0] data;
    begin
        @(negedge i_w_clk);
        i_write_req = 1'b1;
        i_w_data    = data;

        @(negedge i_w_clk);
        i_write_req = 1'b0;
    end
    endtask

    task read_one;
    begin
        @(negedge i_r_clk);
        i_read_req = 1'b1;

        @(negedge i_r_clk);
        i_read_req = 1'b0;
    end
    endtask

    task fill_fifo_until_full;
        integer k;
    begin
        $display("\n========== SCENARIO 1A: Sequential write until FULL ==========\n");
        k = 0;
        while (!o_full && k < (F_DEPTH + 8)) begin
            write_one(k[D_SIZE-1:0]);
            k = k + 1;
        end

        if (!o_full) begin
            $display("[%0t] ERROR: FIFO never asserted FULL during fill", $time);
            error_count = error_count + 1;
        end
        else begin
            $display("[%0t] FIFO reached FULL as expected", $time);
        end
    end
    endtask

    task drain_fifo_until_empty;
        integer k;
    begin
        $display("\n========== SCENARIO 1B: Read until EMPTY ==========\n");
        k = 0;
        while (!o_empty && k < (F_DEPTH + 8)) begin
            read_one();
            k = k + 1;
        end

        @(posedge i_r_clk);

        if (!o_empty) begin
            $display("[%0t] ERROR: FIFO never asserted EMPTY during drain", $time);
            error_count = error_count + 1;
        end
        else begin
            $display("[%0t] FIFO reached EMPTY as expected", $time);
        end
    end
    endtask

    task simultaneous_rw_independent_clocks;
        integer wcount;
        integer rcount;
    begin
        $display("\n========== SCENARIO 2: Simultaneous read/write on independent clocks ==========\n");

        i_write_req = 1'b0;
        i_read_req  = 1'b0;

        fork
            begin : WRITE_THREAD
                for (wcount = 0; wcount < 12; wcount = wcount + 1) begin
                    @(negedge i_w_clk);
                    if (!o_full) begin
                        i_write_req = 1'b1;
                        i_w_data    = 8'h40 + wcount;
                    end
                    else begin
                        i_write_req = 1'b0;
                    end

                    @(negedge i_w_clk);
                    i_write_req = 1'b0;
                end
            end

            begin : READ_THREAD
                repeat (2) @(negedge i_r_clk);

                for (rcount = 0; rcount < 12; rcount = rcount + 1) begin
                    @(negedge i_r_clk);
                    if (!o_empty) begin
                        i_read_req = 1'b1;
                    end
                    else begin
                        i_read_req = 1'b0;
                    end

                    @(negedge i_r_clk);
                    i_read_req = 1'b0;
                end
            end
        join

        while (!o_empty) begin
            read_one();
        end

        @(posedge i_r_clk);
        $display("[%0t] Simultaneous R/W scenario completed", $time);
    end
    endtask

    task write_when_full_check;
        reg [D_SIZE-1:0] blocked_data;
    begin
        $display("\n========== SCENARIO 3: Write attempts when FULL ==========\n");

        while (!o_full) begin
            write_one($random);
        end

        blocked_data = 8'hAA;

        @(negedge i_w_clk);
        i_write_req = 1'b1;
        i_w_data    = blocked_data;

        @(negedge i_w_clk);
        i_w_data    = 8'hBB;

        @(negedge i_w_clk);
        i_w_data    = 8'hCC;

        @(negedge i_w_clk);
        i_write_req = 1'b0;

        if (!o_full) begin
            $display("[%0t] ERROR: FIFO lost FULL unexpectedly during blocked writes", $time);
            error_count = error_count + 1;
        end

        while (!o_empty) begin
            read_one();
        end

        @(posedge i_r_clk);

        if (sb_count != 0) begin
            $display("[%0t] ERROR: scoreboard not empty after draining full FIFO", $time);
            error_count = error_count + 1;
        end
        else begin
            $display("[%0t] Blocked writes did not corrupt FIFO contents", $time);
        end
    end
    endtask

    task read_when_empty_check;
        reg [D_SIZE-1:0] old_data;
    begin
        $display("\n========== SCENARIO 4: Read attempts when EMPTY ==========\n");

        while (!o_empty) begin
            read_one();
        end

        @(posedge i_r_clk);
        old_data = o_r_data;

        @(negedge i_r_clk);
        i_read_req = 1'b1;

        @(negedge i_r_clk);
        i_read_req = 1'b1;

        @(negedge i_r_clk);
        i_read_req = 1'b1;

        @(negedge i_r_clk);
        i_read_req = 1'b0;

        @(posedge i_r_clk);

        if (!o_empty) begin
            $display("[%0t] ERROR: FIFO lost EMPTY unexpectedly during blocked reads", $time);
            error_count = error_count + 1;
        end
        else begin
            $display("[%0t] FIFO remained EMPTY during blocked reads", $time);
        end

        if (o_r_data !== old_data) begin
            $display("[%0t] WARNING: output changed during empty reads. Check DUT intent.", $time);
        end
        else begin
            $display("[%0t] No visible underflow behavior on output", $time);
        end
    end
    endtask

    // ------------------------------------------------------------
    // Main sequence
    // ------------------------------------------------------------
    initial begin
        reset_dut();

        fill_fifo_until_full();
        drain_fifo_until_empty();

        simultaneous_rw_independent_clocks();

        write_when_full_check();

        read_when_empty_check();

        $display("\n====================================================");
        if (error_count == 0)
            $display("TEST PASSED: no errors detected");
        else
            $display("TEST FAILED: error_count = %0d", error_count);
        $display("====================================================\n");

        #50;
        $finish;
    end

endmodule