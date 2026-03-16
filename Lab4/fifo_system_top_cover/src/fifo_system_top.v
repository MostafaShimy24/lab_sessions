module fifo_system_top #(
  parameter D_SIZE  = 8,
  parameter A_SIZE  = 4,
  parameter P_SIZE  = 5,
  parameter F_DEPTH = 16
)
(
   input                    i_w_clk,
   input                    i_w_rstn,
   input                    i_write_req,
   input  [D_SIZE-1:0]      i_w_data,

   input                    i_r_clk,
   input                    i_r_rstn,
   input                    i_read_req,

   output [D_SIZE-1:0]      o_r_data,
   output                   o_full,
   output                   o_empty
);

wire w_inc;
wire r_inc;

wire [D_SIZE-1:0] fifo_w_data;
wire [D_SIZE-1:0] fifo_r_data;

//------------------------------------------------
// write_module
//------------------------------------------------
write_module #(.D_SIZE(D_SIZE)) write_module_inst
(
    .w_clk      (i_w_clk),
    .w_rstn     (i_w_rstn),
    .i_write_req(i_write_req),
    .i_data     (i_w_data),
    .fifo_full  (o_full),
    .w_inc      (w_inc),
    .w_data     (fifo_w_data)
);

//------------------------------------------------
// FIFO
//------------------------------------------------
Async_fifo #(
  .D_SIZE (D_SIZE),
  .A_SIZE (A_SIZE),
  .P_SIZE (P_SIZE),
  .F_DEPTH(F_DEPTH)
) fifo (
   .i_w_clk (i_w_clk),
   .i_w_rstn(i_w_rstn),
   .i_w_inc (w_inc),

   .i_r_clk (i_r_clk),
   .i_r_rstn(i_r_rstn),
   .i_r_inc (r_inc),

   .i_w_data(fifo_w_data),
   .o_r_data(fifo_r_data),

   .o_full (o_full),
   .o_empty(o_empty)
);

//------------------------------------------------
// read_module
//------------------------------------------------
read_module #(.D_SIZE(D_SIZE)) read_module_inst
(
    .r_clk      (i_r_clk),
    .r_rstn     (i_r_rstn),
    .i_read_req (i_read_req),
    .fifo_empty (o_empty),
    .fifo_r_data(fifo_r_data),
    .r_inc      (r_inc),
    .o_data     (o_r_data)
);

endmodule