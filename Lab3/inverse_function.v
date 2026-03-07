module inverse_function #(
    parameter WIDTH = 18,
    parameter FRAC  = 14
)(
    input clk,
    input rst,
    input start,
    input  [WIDTH-1:0] D,
    output [WIDTH-1:0] x_out
);

    localparam ONE = (1 << FRAC);
    localparam TWO = (2 << FRAC);

    reg [WIDTH-1:0] x_reg;
    wire [WIDTH-1:0] x_next;

    assign x_out = x_reg;

    // x * D
    wire [2*WIDTH-1:0] mult1;
    assign mult1 = x_reg * D;

    wire [WIDTH-1:0] xD = mult1 >> FRAC;

    // 2 - xD
    wire [WIDTH-1:0] sub = TWO - xD;

    // x * (2 - xD)
    wire [2*WIDTH-1:0] mult2;
    assign mult2 = x_reg * sub;

    assign x_next = mult2 >> FRAC;

    always @(posedge clk or posedge rst) begin
        if (rst)
            x_reg <= 0;
        else if (start)
            x_reg <= ONE;
        else
            x_reg <= x_next;
    end

endmodule
