module write_module #(
    parameter D_SIZE = 8
)(
    input                   w_clk,
    input                   w_rstn,

    input                   i_write_req,
    input  [D_SIZE-1:0]     i_data,

    input                   fifo_full,

    output                  w_inc,
    output [D_SIZE-1:0]     w_data
);

assign w_inc  = i_write_req && !fifo_full;
assign w_data = i_data;

endmodule