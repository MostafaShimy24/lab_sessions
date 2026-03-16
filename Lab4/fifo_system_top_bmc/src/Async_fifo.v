module Async_fifo #(
  parameter D_SIZE = 8,   // data width
  parameter A_SIZE = 4,   // address width => depth = 16
  parameter P_SIZE = 5,   // pointer width = A_SIZE + 1
  parameter F_DEPTH = 16  // fifo depth = 2^A_SIZE
)
(
   input                    i_w_clk,
   input                    i_w_rstn,
   input                    i_w_inc,
   input                    i_r_clk,
   input                    i_r_rstn,
   input                    i_r_inc,
   input   [D_SIZE-1:0]     i_w_data,
   output  [D_SIZE-1:0]     o_r_data,
   output                   o_full,
   output                   o_empty
);

wire [A_SIZE-1:0] r_addr, w_addr;
wire [P_SIZE-1:0] w2r_ptr, r2w_ptr;
wire [P_SIZE-1:0] gray_w_ptr, gray_rd_ptr;

// ------------------------------------------------------------
// Optional parameter sanity checks for simulation/formal
// ------------------------------------------------------------
`ifndef SYNTHESIS
initial begin
    if (P_SIZE != A_SIZE + 1) begin
        $error("Async_fifo: P_SIZE must equal A_SIZE + 1");
    end
    if (F_DEPTH != (1 << A_SIZE)) begin
        $error("Async_fifo: F_DEPTH must equal 2^A_SIZE");
    end
end
`endif

// ------------------------------------------------------------
// Dual-port FIFO memory
// ------------------------------------------------------------
fifo_mem #(
    .F_DEPTH(F_DEPTH),
    .A_SIZE(A_SIZE),
    .D_SIZE(D_SIZE),
    .P_SIZE(P_SIZE)
) u_fifo_mem (
    .w_clk (i_w_clk),
    .w_rstn(i_w_rstn),
    .w_inc (i_w_inc),
    .w_full(o_full),
    .w_addr(w_addr),
    .r_addr(r_addr),
    .w_data(i_w_data),
    .r_data(o_r_data)
);

// ------------------------------------------------------------
// Synchronize write Gray pointer into read clock domain
// Must be a 2FF synchronizer in DF_Sync
// ------------------------------------------------------------
DF_Sync #(.DATA_SIZE(P_SIZE)) u_w2r_sync (
    .sync_clk (i_r_clk),
    .sync_rstn(i_r_rstn),
    .unsync_ip(gray_w_ptr),
    .sync_op (w2r_ptr)
);

// ------------------------------------------------------------
// Write pointer / full generation
// Must implement Gray full rule internally
// ------------------------------------------------------------
fifo_wr #(
    .P_SIZE(P_SIZE)
) u_fifo_wr (
    .w_clk      (i_w_clk),
    .w_rstn     (i_w_rstn),
    .w_inc      (i_w_inc),
    .sync_rd_ptr(r2w_ptr),
    .w_addr     (w_addr),
    .gray_w_ptr (gray_w_ptr),
    .full       (o_full)
);
// ------------------------------------------------------------
// Read pointer / empty generation
// Empty when synchronized write Gray pointer equals read pointer
// ------------------------------------------------------------
fifo_rd #(
    .P_SIZE(P_SIZE)
) u_fifo_rd (
    .r_clk      (i_r_clk),
    .r_rstn     (i_r_rstn),
    .r_inc      (i_r_inc),
    .sync_wr_ptr(w2r_ptr),
    .rd_addr    (r_addr),
    .gray_rd_ptr(gray_rd_ptr),
    .empty      (o_empty)
);

// ------------------------------------------------------------
// Synchronize read Gray pointer into write clock domain
// Must be a 2FF synchronizer in DF_Sync
// ------------------------------------------------------------
DF_Sync #(.DATA_SIZE(P_SIZE)) u_r2w_sync (
    .sync_clk (i_w_clk),
    .sync_rstn(i_w_rstn),
    .unsync_ip(gray_rd_ptr),
    .sync_op (r2w_ptr)
);

endmodule