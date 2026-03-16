module fifo_mem #(
    parameter F_DEPTH = 16,
    parameter A_SIZE  = 4,
    parameter D_SIZE  = 8,
    parameter P_SIZE  = 5
)(
    input                  w_clk,
    input                  w_rstn,
    input                  w_inc,
    input                  w_full,
    input  [A_SIZE-1:0]    w_addr,
    input  [A_SIZE-1:0]    r_addr,
    input  [D_SIZE-1:0]    w_data,
    output [D_SIZE-1:0]    r_data
);

reg [D_SIZE-1:0] mem [0:F_DEPTH-1];

always @(posedge w_clk) begin
    if (w_inc && !w_full)
        mem[w_addr] <= w_data;
end

assign r_data = mem[r_addr];

endmodule