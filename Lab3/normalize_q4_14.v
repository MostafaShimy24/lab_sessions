module normalize_q4_14 (
    input  [17:0] D_in,
    output reg [17:0] D_norm,
    output reg [4:0] shift_count
);

    localparam HALF = 18'd8192;

    integer i;

    always @(*) begin
        D_norm = D_in;
        shift_count = 0;

        for (i = 0; i < 17; i = i + 1) begin
            if (D_norm < HALF) begin
                D_norm = D_norm << 1;
                shift_count = shift_count + 1;
            end
        end
    end

endmodule