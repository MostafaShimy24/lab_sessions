module division_newton #(
    parameter DIV_WIDTH = 36,
    parameter WIDTH     = 18,
    parameter FRAC      = 14
)(
    input clk,
    input rst,
    input start,
    input  [DIV_WIDTH-1:0] dividend,   // Q22.14
    input  [WIDTH-1:0]     divisor,    // Q4.14
    output [WIDTH-1:0]     quotient    // Q4.14
);

    // Registers
    wire [DIV_WIDTH-1:0] dividend_reg;
    wire [WIDTH-1:0] divisor_reg;

    dff_rg #(DIV_WIDTH) REG_A (
        .clk(clk),
        .rst(rst),
        .d(dividend),
        .q(dividend_reg)
    );

    dff_rg #(WIDTH) REG_D (
        .clk(clk),
        .rst(rst),
        .d(divisor),
        .q(divisor_reg)
    );

    // Normalize
    wire [WIDTH-1:0] D_norm;
    wire [4:0] shift_count;

    normalize_q4_14 NORM (
        .D_in(divisor_reg),
        .D_norm(D_norm),
        .shift_count(shift_count)
    );

    // Inverse
    wire [WIDTH-1:0] inverse_out;

    inverse_function #(WIDTH, FRAC) INV (
        .clk(clk),
        .rst(rst),
        .start(start),
        .D(D_norm),
        .x_out(inverse_out)
    );

    // Multiply 36 × 18
    wire [DIV_WIDTH+WIDTH-1:0] mult_full;
    assign mult_full = dividend_reg * inverse_out;

    // Return to Q22.14
    wire [DIV_WIDTH+WIDTH-1:0] mult_scaled;
    assign mult_scaled = mult_full >> FRAC;

    // Compensate normalization
    wire [DIV_WIDTH+WIDTH-1:0] corrected;
    assign corrected = mult_scaled >> shift_count;

    // Take lower 18 bits as Q4.14 result
    dff_rg #(WIDTH) OUT_REG (
        .clk(clk),
        .rst(rst),
        .d(corrected[WIDTH-1:0]),
        .q(quotient)
    );

endmodule