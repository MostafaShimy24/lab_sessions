`ifndef VERILATOR
module testbench;
  reg [4095:0] vcdfile;
  reg clock;
`else
module testbench(input clock, output reg genclock);
  initial genclock = 1;
`endif
  reg genclock = 1;
  reg [31:0] cycle = 0;
  reg [0:0] PI_i_r_clk;
  reg [0:0] PI_o_empty;
  reg [0:0] PI_i_w_clk;
  reg [0:0] PI_i_r_inc;
  reg [0:0] PI_i_r_rstn;
  reg [0:0] PI_o_full;
  reg [0:0] PI_i_w_inc;
  reg [3:0] PI_w_addr;
  reg [0:0] PI_i_w_rstn;
  fifo_system_top_formal UUT (
    .i_r_clk(PI_i_r_clk),
    .o_empty(PI_o_empty),
    .i_w_clk(PI_i_w_clk),
    .i_r_inc(PI_i_r_inc),
    .i_r_rstn(PI_i_r_rstn),
    .o_full(PI_o_full),
    .i_w_inc(PI_i_w_inc),
    .w_addr(PI_w_addr),
    .i_w_rstn(PI_i_w_rstn)
  );
`ifndef VERILATOR
  initial begin
    if ($value$plusargs("vcd=%s", vcdfile)) begin
      $dumpfile(vcdfile);
      $dumpvars(0, testbench);
    end
    #5 clock = 0;
    while (genclock) begin
      #5 clock = 0;
      #5 clock = 1;
    end
  end
`endif
  initial begin
`ifndef VERILATOR
    #1;
`endif
    // UUT.$auto$async2sync.\cc:107:execute$115  = 1'b0;
    // UUT.$auto$async2sync.\cc:107:execute$121  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$119  = 1'b1;
    // UUT.$auto$async2sync.\cc:116:execute$125  = 1'b1;
    UUT._witness_.anyinit_procdff_63 = 1'b1;
    UUT._witness_.anyinit_procdff_68 = 1'b0;

    // state 0
    PI_i_r_clk = 1'b0;
    PI_o_empty = 1'b1;
    PI_i_w_clk = 1'b0;
    PI_i_r_inc = 1'b0;
    PI_i_r_rstn = 1'b1;
    PI_o_full = 1'b0;
    PI_i_w_inc = 1'b0;
    PI_w_addr = 4'b0000;
    PI_i_w_rstn = 1'b0;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_i_r_clk <= 1'b0;
      PI_o_empty <= 1'b0;
      PI_i_w_clk <= 1'b0;
      PI_i_r_inc <= 1'b0;
      PI_i_r_rstn <= 1'b0;
      PI_o_full <= 1'b0;
      PI_i_w_inc <= 1'b0;
      PI_w_addr <= 4'b0000;
      PI_i_w_rstn <= 1'b0;
    end

    genclock <= cycle < 1;
    cycle <= cycle + 1;
  end
endmodule
