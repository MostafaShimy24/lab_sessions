module fifo_system_top_formal;

parameter D_SIZE  = 8;
parameter A_SIZE  = 3;
parameter P_SIZE  = 4;
parameter F_DEPTH = 8;

reg i_w_clk;
reg i_r_clk;

reg i_w_rstn;
reg i_r_rstn;

reg i_write_req;
reg i_read_req;

reg [D_SIZE-1:0] i_w_data;

wire [D_SIZE-1:0] o_r_data;
wire o_full;
wire o_empty;

-------------------------------------------------
-- DUT
-------------------------------------------------

fifo_system_top #(
    .D_SIZE(D_SIZE),
    .A_SIZE(A_SIZE),
    .P_SIZE(P_SIZE),
    .F_DEPTH(F_DEPTH)
) dut (
    .i_w_clk(i_w_clk),
    .i_w_rstn(i_w_rstn),
    .i_write_req(i_write_req),
    .i_w_data(i_w_data),

    .i_r_clk(i_r_clk),
    .i_r_rstn(i_r_rstn),
    .i_read_req(i_read_req),

    .o_r_data(o_r_data),
    .o_full(o_full),
    .o_empty(o_empty)
);

-------------------------------------------------
-- Clock generation
-------------------------------------------------

initial i_w_clk = 0;
always i_w_clk = !i_w_clk;

initial i_r_clk = 0;
always i_r_clk = !i_r_clk;

-------------------------------------------------
-- Symbolic inputs
-------------------------------------------------

always @(*) begin
    i_write_req = $anyseq;
    i_read_req  = $anyseq;
    i_w_data    = $anyseq;
end

-------------------------------------------------
-- Reset assumptions
-------------------------------------------------

initial assume(!i_w_rstn);
initial assume(!i_r_rstn);

-------------------------------------------------
-- Environment constraints
-------------------------------------------------

always @(posedge i_w_clk)
    assume(!(i_write_req && o_full));

always @(posedge i_r_clk)
    assume(!(i_read_req && o_empty));

-------------------------------------------------
-- Basic FIFO safety
-------------------------------------------------

always @(posedge i_w_clk)
    assert(!(o_full && o_empty));

-------------------------------------------------
-- Cover activity
-------------------------------------------------

always @(posedge i_w_clk)
    cover(i_write_req && !o_full);

always @(posedge i_r_clk)
    cover(i_read_req && !o_empty);

endmodule