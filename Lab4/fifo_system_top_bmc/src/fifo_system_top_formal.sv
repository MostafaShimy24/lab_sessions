module fifo_system_top_formal #(
    parameter A_SIZE = 4
)(
    input  wire              i_w_clk,
    input  wire              i_w_rstn,
    input  wire              i_r_clk,
    input  wire              i_r_rstn,

    input  wire              i_w_inc,
    input  wire              i_r_inc,
    input  wire              o_full,
    input  wire              o_empty,

    input  wire [A_SIZE-1:0] w_addr
);

    localparam DEPTH = (1 << A_SIZE);

    reg seen_empty;
    reg seen_full;

    // Track that FIFO has been empty
    always @(posedge i_w_clk or negedge i_w_rstn) begin
        if (!i_w_rstn)
            seen_empty <= 1'b0;
        else if (o_empty)
            seen_empty <= 1'b1;
    end

    // Track that FIFO has been full
    always @(posedge i_r_clk or negedge i_r_rstn) begin
        if (!i_r_rstn)
            seen_full <= 1'b0;
        else if (o_full)
            seen_full <= 1'b1;
    end

    // ------------------------------------------------------------
    // Assertions
    // ------------------------------------------------------------
    always @(posedge i_w_clk) begin
        if (i_w_rstn)
            assert(!(i_w_inc && o_full));
    end

    always @(posedge i_r_clk) begin
        if (i_r_rstn)
            assert(!(i_r_inc && o_empty));
    end

    always @(posedge i_w_clk) begin
        if (i_w_rstn)
            assert(w_addr < DEPTH);
    end

    // ------------------------------------------------------------
    // Assumptions
    // ------------------------------------------------------------
    always @(posedge i_w_clk) begin
        if (i_w_rstn)
            assume(!(i_w_inc && o_full));
    end

    always @(posedge i_r_clk) begin
        if (i_r_rstn)
            assume(!(i_r_inc && o_empty));
    end


    // ------------------------------------------------------------
    // ADDED ASSUMPTIONS TO DRIVE FIFO ACTIVITY
    // ------------------------------------------------------------

    // If FIFO is not full, keep writing
    always @(posedge i_w_clk) begin
        if (i_w_rstn && !o_full)
            assume(i_w_inc);
    end

    // Once FIFO becomes full, start reading
    always @(posedge i_r_clk) begin
        if (i_r_rstn && o_full)
            assume(i_r_inc);
    end


    // ------------------------------------------------------------
    // Covers
    // ------------------------------------------------------------
    always @(posedge i_w_clk) begin
        if (i_w_rstn)
            cover(seen_empty && o_full);
    end

    always @(posedge i_r_clk) begin
        if (i_r_rstn)
            cover(seen_full && o_empty);
    end

endmodule


bind Async_fifo fifo_system_top_formal #(
    .A_SIZE(A_SIZE)
) u_fifo_formal (
    .i_w_clk (i_w_clk),
    .i_w_rstn(i_w_rstn),
    .i_r_clk (i_r_clk),
    .i_r_rstn(i_r_rstn),
    .i_w_inc (i_w_inc),
    .i_r_inc (i_r_inc),
    .o_full  (o_full),
    .o_empty (o_empty),
    .w_addr  (w_addr)
);