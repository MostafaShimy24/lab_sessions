module LUT (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [1:0]  in,         // selects input combination
    input  wire [1:0]  shift_amt,  // function select 
    input  wire        is_sync,    // 0: combinational, 1: registered

    output wire        y
);

    wire [3:0] lut0 = 4'b1100; // in = 00
    wire [3:0] lut1 = 4'b0110; // in = 01
    wire [3:0] lut2 = 4'b0110; // in = 10
    wire [3:0] lut3 = 4'b0011; // in = 11

    // --------------------------------------------------------
    // Row selection 
    // --------------------------------------------------------
    wire [3:0] selected_row =
        (in == 2'b00) ? lut0 :
        (in == 2'b01) ? lut1 :
        (in == 2'b10) ? lut2 :
                        lut3;

    // --------------------------------------------------------
    // Function selection 
    // --------------------------------------------------------
    wire comb_y;
    assign comb_y = selected_row[shift_amt];

    // --------------------------------------------------------
    // Register 
    // --------------------------------------------------------
    reg y_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            y_reg <= 1'b0;
        else
            y_reg <= comb_y;
    end

    // --------------------------------------------------------
    // Output selection 
    // --------------------------------------------------------
    assign y = (is_sync) ? y_reg : comb_y;

endmodule