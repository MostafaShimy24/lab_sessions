module write_module #(
    parameter D_SIZE = 8
)(
    input                   w_clk,
    input                   w_rstn,

    input                   i_write_req,
    input  [D_SIZE-1:0]     i_data,

    input                   fifo_full,

    output reg              w_inc,
    output reg [D_SIZE-1:0] w_data
);

always @(posedge w_clk or negedge w_rstn)
begin
    if(!w_rstn)
    begin
        w_inc  <= 1'b0;
        w_data <= {D_SIZE{1'b0}};
    end
    else
    begin
        if(i_write_req && !fifo_full)
        begin
            w_inc  <= 1'b1;
            w_data <= i_data;
        end
        else
        begin
            w_inc <= 1'b0;
        end
    end
end

endmodule