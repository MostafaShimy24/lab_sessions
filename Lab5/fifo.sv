module fifo #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 8
)(
  input  logic             clk,
  input  logic             rst_n,
  input  logic             wr_en,
  input  logic [WIDTH-1:0] wr_data,
  input  logic             rd_en,
  output logic [WIDTH-1:0] rd_data,
  output logic             full,
  output logic             empty
);

  localparam int ADDR_W = $clog2(DEPTH);

  logic [WIDTH-1:0] mem [0:DEPTH-1];
  logic [ADDR_W-1:0] wr_ptr, rd_ptr;
  logic [ADDR_W:0]   count;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr  <= '0;
      rd_ptr  <= '0;
      count   <= '0;
      rd_data <= '0;
    end
    else begin
      if (wr_en && !full) begin
        mem[wr_ptr] <= wr_data;
        wr_ptr      <= (wr_ptr == DEPTH-1) ? '0 : wr_ptr + 1'b1;
        count       <= count + 1'b1;
      end
      else if (rd_en && !empty) begin
        rd_data <= mem[rd_ptr];
        rd_ptr  <= (rd_ptr == DEPTH-1) ? '0 : rd_ptr + 1'b1;
        count   <= count - 1'b1;
      end
    end
  end

  assign empty = (count == 0);
  assign full  = (count == DEPTH);

endmodule