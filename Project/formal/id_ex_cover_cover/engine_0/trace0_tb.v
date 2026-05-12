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
  wire [0:0] PI_clk = clock;
  reg [31:0] PI_pc_i;
  reg [31:0] PI_instr_i;
  reg [0:0] PI_rst_n;
  id_ex_wrapper UUT (
    .clk(PI_clk),
    .pc_i(PI_pc_i),
    .instr_i(PI_instr_i),
    .rst_n(PI_rst_n)
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
    // UUT.$auto$async2sync.\cc:107:execute$900  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$904  = 1'b1;
    // UUT.$auto$async2sync.\cc:116:execute$910  = 1'b1;
    UUT.cycle_count = 6'b001100;
    UUT.id_ex_branch_funct3 = 3'b000;
    UUT.id_ex_conv_start = 1'b1;
    UUT.id_ex_is_branch = 1'b1;
    UUT.id_ex_is_jal = 1'b0;
    UUT.id_ex_is_jalr = 1'b0;
    UUT.id_ex_rd_addr = 5'b00100;
    UUT.id_ex_reg_write = 1'b0;
    UUT.id_ex_rs1_data = 32'b00000000000000000000000100000000;
    UUT.id_ex_rs2_data = 32'b00000000000001000000000000000000;
    UUT.seen_conv_start = 1'b1;
    UUT.seen_instr = 1'b1;
    UUT.u_ex.conv_start_i_r = 1'b0;
    UUT.u_ex.u_conv_pe.cnt_r = 4'b0010;
    UUT.u_ex.u_conv_pe.state_r = 2'b10;
    UUT.u_id.u_regfile.regs[5'b00000] = 32'b00000000000000000001000000000000;

    // state 0
    PI_pc_i = 32'b00000000000000000000000000000000;
    PI_instr_i = 32'b00000000000000000000000000010011;
    PI_rst_n = 1'b1;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_pc_i <= 32'b00000000000000000000000000000000;
      PI_instr_i <= 32'b00000000000000000000000000010011;
      PI_rst_n <= 1'b1;
    end

    // state 2
    if (cycle == 1) begin
      PI_pc_i <= 32'b00000000000000000000000000000000;
      PI_instr_i <= 32'b00000000000000000000000000010011;
      PI_rst_n <= 1'b1;
    end

    // state 3
    if (cycle == 2) begin
      PI_pc_i <= 32'b00000000000000000000000000000000;
      PI_instr_i <= 32'b00000000000000000000000000010011;
      PI_rst_n <= 1'b1;
    end

    // state 4
    if (cycle == 3) begin
      PI_pc_i <= 32'b00000000000000000000000000000000;
      PI_instr_i <= 32'b00000000000000000000000000010011;
      PI_rst_n <= 1'b1;
    end

    // state 5
    if (cycle == 4) begin
      PI_pc_i <= 32'b00000000000000000000000000000000;
      PI_instr_i <= 32'b00000000000000000000000000010011;
      PI_rst_n <= 1'b1;
    end

    // state 6
    if (cycle == 5) begin
      PI_pc_i <= 32'b00000000000000000000000000000000;
      PI_instr_i <= 32'b00000000000000000000000000010011;
      PI_rst_n <= 1'b1;
    end

    genclock <= cycle < 6;
    cycle <= cycle + 1;
  end
endmodule
