module read_module #(
    parameter D_SIZE = 8
)(
    input                   r_clk,
    input                   r_rstn,

    input                   i_read_req,
    input                   fifo_empty,

    input  [D_SIZE-1:0]     fifo_r_data,

    output                  r_inc,
    output reg [D_SIZE-1:0] o_data
);

assign r_inc = i_read_req && !fifo_empty;

always @(posedge r_clk or negedge r_rstn)
begin
    if (!r_rstn)
    begin
        o_data <= {D_SIZE{1'b0}};
    end
    else if (i_read_req && !fifo_empty)
    begin
        o_data <= fifo_r_data;
    end
end

endmodule