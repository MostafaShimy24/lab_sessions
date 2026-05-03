

module __DESIGN__UNDER__TEST__
(
  clk,
  rst_n,
  in,
  shift_amt,
  is_sync,
  y,
  sin,
  shift,
  sout,
  tck,
  test
);

  wire _00_;
  wire _01_;
  wire _02_;
  wire _03_;
  wire _04_;
  wire _05_;
  wire _06_;
  wire \__BoundaryScanRegister_input__0__.dout ;
  wire \__BoundaryScanRegister_input__0__.sout ;
  wire \__BoundaryScanRegister_input__1__.dout ;
  wire \__BoundaryScanRegister_input__1__.sout ;
  wire \__BoundaryScanRegister_input__2__.dout ;
  wire \__BoundaryScanRegister_input__2__.sout ;
  wire \__BoundaryScanRegister_input__3__.dout ;
  wire \__BoundaryScanRegister_input__3__.sout ;
  wire \__BoundaryScanRegister_input__4__.dout ;
  wire \__BoundaryScanRegister_input__4__.sout ;
  wire \__BoundaryScanRegister_output__5__.sin ;
  wire \__uuf__._0_ ;
  wire \__uuf__.__clk_source__ ;
  wire \__uuf__.comb_y ;
  input clk;
  wire clk;
  input [1:0] in;
  wire [1:0] in;
  input is_sync;
  wire is_sync;
  input rst_n;
  wire rst_n;
  input shift;
  wire shift;
  input [1:0] shift_amt;
  wire [1:0] shift_amt;
  input sin;
  wire sin;
  output sout;
  wire sout;
  input tck;
  wire tck;
  input test;
  wire test;
  output y;
  wire y;

  sky130_fd_sc_hd__mux2_1
  _07_
  (
    .A0(in[0]),
    .A1(\__BoundaryScanRegister_input__0__.sout ),
    .S(test),
    .X(\__BoundaryScanRegister_input__0__.dout )
  );


  sky130_fd_sc_hd__mux2_1
  _08_
  (
    .A0(\__BoundaryScanRegister_input__0__.dout ),
    .A1(sin),
    .S(shift),
    .X(_00_)
  );


  sky130_fd_sc_hd__mux2_1
  _09_
  (
    .A0(in[1]),
    .A1(\__BoundaryScanRegister_input__1__.sout ),
    .S(test),
    .X(\__BoundaryScanRegister_input__1__.dout )
  );


  sky130_fd_sc_hd__mux2_1
  _10_
  (
    .A0(\__BoundaryScanRegister_input__1__.dout ),
    .A1(\__BoundaryScanRegister_input__0__.sout ),
    .S(shift),
    .X(_01_)
  );


  sky130_fd_sc_hd__mux2_1
  _11_
  (
    .A0(shift_amt[0]),
    .A1(\__BoundaryScanRegister_input__2__.sout ),
    .S(test),
    .X(\__BoundaryScanRegister_input__2__.dout )
  );


  sky130_fd_sc_hd__mux2_1
  _12_
  (
    .A0(\__BoundaryScanRegister_input__2__.dout ),
    .A1(\__BoundaryScanRegister_input__1__.sout ),
    .S(shift),
    .X(_02_)
  );


  sky130_fd_sc_hd__mux2_1
  _13_
  (
    .A0(shift_amt[1]),
    .A1(\__BoundaryScanRegister_input__3__.sout ),
    .S(test),
    .X(\__BoundaryScanRegister_input__3__.dout )
  );


  sky130_fd_sc_hd__mux2_1
  _14_
  (
    .A0(\__BoundaryScanRegister_input__3__.dout ),
    .A1(\__BoundaryScanRegister_input__2__.sout ),
    .S(shift),
    .X(_03_)
  );


  sky130_fd_sc_hd__mux2_1
  _15_
  (
    .A0(is_sync),
    .A1(\__BoundaryScanRegister_input__4__.sout ),
    .S(test),
    .X(\__BoundaryScanRegister_input__4__.dout )
  );


  sky130_fd_sc_hd__mux2_1
  _16_
  (
    .A0(\__BoundaryScanRegister_input__4__.dout ),
    .A1(\__BoundaryScanRegister_input__3__.sout ),
    .S(shift),
    .X(_04_)
  );


  sky130_fd_sc_hd__mux2_1
  _17_
  (
    .A0(y),
    .A1(\__BoundaryScanRegister_output__5__.sin ),
    .S(shift),
    .X(_05_)
  );


  sky130_fd_sc_hd__mux2_1
  _18_
  (
    .A0(clk),
    .A1(tck),
    .S(test),
    .X(\__uuf__.__clk_source__ )
  );


  sky130_fd_sc_hd__mux2_1
  _19_
  (
    .A0(\__uuf__.comb_y ),
    .A1(\__BoundaryScanRegister_input__4__.sout ),
    .S(shift),
    .X(_06_)
  );


  sky130_fd_sc_hd__dfrtp_1
  _20_
  (
    .CLK(tck),
    .D(_04_),
    .Q(\__BoundaryScanRegister_input__4__.sout ),
    .RESET_B(rst_n)
  );


  sky130_fd_sc_hd__dfrtp_1
  _21_
  (
    .CLK(tck),
    .D(_05_),
    .Q(sout),
    .RESET_B(rst_n)
  );


  sky130_fd_sc_hd__dfrtp_1
  _22_
  (
    .CLK(tck),
    .D(_03_),
    .Q(\__BoundaryScanRegister_input__3__.sout ),
    .RESET_B(rst_n)
  );


  sky130_fd_sc_hd__dfrtp_1
  _23_
  (
    .CLK(tck),
    .D(_02_),
    .Q(\__BoundaryScanRegister_input__2__.sout ),
    .RESET_B(rst_n)
  );


  sky130_fd_sc_hd__dfrtp_1
  _24_
  (
    .CLK(tck),
    .D(_01_),
    .Q(\__BoundaryScanRegister_input__1__.sout ),
    .RESET_B(rst_n)
  );


  sky130_fd_sc_hd__dfrtp_1
  _25_
  (
    .CLK(tck),
    .D(_00_),
    .Q(\__BoundaryScanRegister_input__0__.sout ),
    .RESET_B(rst_n)
  );


  sky130_fd_sc_hd__maj3_1
  \__uuf__._1_ 
  (
    .A(\__BoundaryScanRegister_input__1__.dout ),
    .B(\__BoundaryScanRegister_input__0__.dout ),
    .C(\__BoundaryScanRegister_input__2__.dout ),
    .X(\__uuf__._0_ )
  );


  sky130_fd_sc_hd__xor2_1
  \__uuf__._2_ 
  (
    .A(\__BoundaryScanRegister_input__3__.dout ),
    .B(\__uuf__._0_ ),
    .X(\__uuf__.comb_y )
  );


  sky130_fd_sc_hd__mux2_1
  \__uuf__._3_ 
  (
    .A0(\__uuf__.comb_y ),
    .A1(\__BoundaryScanRegister_output__5__.sin ),
    .S(\__BoundaryScanRegister_input__4__.dout ),
    .X(y)
  );


  sky130_fd_sc_hd__dfrtp_1
  \__uuf__._4_ 
  (
    .CLK(\__uuf__.__clk_source__ ),
    .D(_06_),
    .Q(\__BoundaryScanRegister_output__5__.sin ),
    .RESET_B(rst_n)
  );


endmodule



module tap_top
(
  tms_pad_i,
  tck_pad_i,
  trst_pad_i,
  tdi_pad_i,
  tdo_pad_o,
  tdo_padoe_o,
  shift_dr_o,
  pause_dr_o,
  update_dr_o,
  capture_dr_o,
  exit1_dr_o,
  exit2_dr_o,
  test_logic_reset_o,
  run_test_idle_o,
  extest_select_o,
  sample_preload_select_o,
  mbist_select_o,
  debug_select_o,
  preload_chain_o,
  tdo_o,
  debug_tdi_i,
  bs_chain_tdi_i,
  mbist_tdi_i,
  chain_tdi_i
);

  input tms_pad_i;
  input tck_pad_i;
  input trst_pad_i;
  input tdi_pad_i;
  output tdo_pad_o;
  output tdo_padoe_o;
  output shift_dr_o;
  output pause_dr_o;
  output update_dr_o;
  output capture_dr_o;
  output test_logic_reset_o;
  output run_test_idle_o;
  output exit1_dr_o;
  output exit2_dr_o;
  output extest_select_o;
  output sample_preload_select_o;
  output mbist_select_o;
  output debug_select_o;
  output preload_chain_o;
  output tdo_o;
  input debug_tdi_i;
  input bs_chain_tdi_i;
  input mbist_tdi_i;
  input chain_tdi_i;
  reg test_logic_reset;
  reg run_test_idle;
  reg select_dr_scan;
  reg capture_dr;
  reg shift_dr;
  reg exit1_dr;
  reg pause_dr;
  reg exit2_dr;
  reg update_dr;
  reg select_ir_scan;
  reg capture_ir;
  reg shift_ir;reg shift_ir_neg;
  reg exit1_ir;
  reg pause_ir;
  reg exit2_ir;
  reg update_ir;
  reg extest_select;
  reg sample_preload_select;
  reg idcode_select;
  reg mbist_select;
  reg debug_select;
  reg bypass_select;
  reg preload_chain_select;
  reg tdo_pad_o;
  reg tdo_padoe_o;
  reg tms_q1;reg tms_q2;reg tms_q3;reg tms_q4;
  wire tms_reset;
  assign tdo_o = tdi_pad_i;
  assign shift_dr_o = shift_dr;
  assign pause_dr_o = pause_dr;
  assign update_dr_o = update_dr;
  assign capture_dr_o = capture_dr;
  assign test_logic_reset_o = test_logic_reset;
  assign run_test_idle_o = run_test_idle;
  assign exit1_dr_o = exit1_dr;
  assign exit2_dr_o = exit2_dr;
  assign extest_select_o = extest_select;
  assign sample_preload_select_o = sample_preload_select;
  assign mbist_select_o = mbist_select;
  assign debug_select_o = debug_select;
  assign preload_chain_o = preload_chain_select;

  always @(posedge tck_pad_i) begin
    tms_q1 <= #1 tms_pad_i;
    tms_q2 <= #1 tms_q1;
    tms_q3 <= #1 tms_q2;
    tms_q4 <= #1 tms_q3;
  end

  assign tms_reset = tms_q1 & tms_q2 & tms_q3 & tms_q4 & tms_pad_i;

  always @(posedge tck_pad_i or posedge trst_pad_i) begin
    if(trst_pad_i) test_logic_reset <= #1 1'b1; 
    else if(tms_reset) test_logic_reset <= #1 1'b1; 
    else begin
      if(tms_pad_i & (test_logic_reset | select_ir_scan)) test_logic_reset <= #1 1'b1; 
      else test_logic_reset <= #1 1'b0;
    end
  end


  always @(posedge tck_pad_i or posedge trst_pad_i) begin
    if(trst_pad_i) run_test_idle <= #1 1'b0; 
    else if(tms_reset) run_test_idle <= #1 1'b0; 
    else if(~tms_pad_i & (test_logic_reset | run_test_idle | update_dr | update_ir)) run_test_idle <= #1 1'b1; 
    else run_test_idle <= #1 1'b0;
  end


  always @(posedge tck_pad_i or posedge trst_pad_i) begin
    if(trst_pad_i) select_dr_scan <= #1 1'b0; 
    else if(tms_reset) select_dr_scan <= #1 1'b0; 
    else if(tms_pad_i & (run_test_idle | update_dr | update_ir)) select_dr_scan <= #1 1'b1; 
    else select_dr_scan <= #1 1'b0;
  end


  always @(posedge tck_pad_i or posedge trst_pad_i) begin
    if(trst_pad_i) capture_dr <= #1 1'b0; 
    else if(tms_reset) capture_dr <= #1 1'b0; 
    else if(~tms_pad_i & select_dr_scan) capture_dr <= #1 1'b1; 
    else capture_dr <= #1 1'b0;
  end


  always @(posedge tck_pad_i or posedge trst_pad_i) begin
    if(trst_pad_i) shift_dr <= #1 1'b0; 
    else if(tms_reset) shift_dr <= #1 1'b0; 
    else if(~tms_pad_i & (capture_dr | shift_dr | exit2_dr)) shift_dr <= #1 1'b1; 
    else shift_dr <= #1 1'b0;
  end


  always @(posedge tck_pad_i or posedge trst_pad_i) begin
    if(trst_pad_i) exit1_dr <= #1 1'b0; 
    else if(tms_reset) exit1_dr <= #1 1'b0; 
    else if(tms_pad_i & (capture_dr | shift_dr)) exit1_dr <= #1 1'b1; 
    else exit1_dr <= #1 1'b0;
  end


  always @(posedge tck_pad_i or posedge trst_pad_i) begin
    if(trst_pad_i) pause_dr <= #1 1'b0; 
    else if(tms_reset) pause_dr <= #1 1'b0; 
    else if(~tms_pad_i & (exit1_dr | pause_dr)) pause_dr <= #1 1'b1; 
    else pause_dr <= #1 1'b0;
  end


  always @(posedge tck_pad_i or posedge trst_pad_i) begin
    if(trst_pad_i) exit2_dr <= #1 1'b0; 
    else if(tms_reset) exit2_dr <= #1 1'b0; 
    else if(tms_pad_i & pause_dr) exit2_dr <= #1 1'b1; 
    else exit2_dr <= #1 1'b0;
  end


  always @(posedge tck_pad_i or posedge trst_pad_i) begin
    if(trst_pad_i) update_dr <= #1 1'b0; 
    else if(tms_reset) update_dr <= #1 1'b0; 
    else if(tms_pad_i & (exit1_dr | exit2_dr)) update_dr <= #1 1'b1; 
    else update_dr <= #1 1'b0;
  end


  always @(posedge tck_pad_i or posedge trst_pad_i) begin
    if(trst_pad_i) select_ir_scan <= #1 1'b0; 
    else if(tms_reset) select_ir_scan <= #1 1'b0; 
    else if(tms_pad_i & select_dr_scan) select_ir_scan <= #1 1'b1; 
    else select_ir_scan <= #1 1'b0;
  end


  always @(posedge tck_pad_i or posedge trst_pad_i) begin
    if(trst_pad_i) capture_ir <= #1 1'b0; 
    else if(tms_reset) capture_ir <= #1 1'b0; 
    else if(~tms_pad_i & select_ir_scan) capture_ir <= #1 1'b1; 
    else capture_ir <= #1 1'b0;
  end


  always @(posedge tck_pad_i or posedge trst_pad_i) begin
    if(trst_pad_i) shift_ir <= #1 1'b0; 
    else if(tms_reset) shift_ir <= #1 1'b0; 
    else if(~tms_pad_i & (capture_ir | shift_ir | exit2_ir)) shift_ir <= #1 1'b1; 
    else shift_ir <= #1 1'b0;
  end


  always @(posedge tck_pad_i or posedge trst_pad_i) begin
    if(trst_pad_i) exit1_ir <= #1 1'b0; 
    else if(tms_reset) exit1_ir <= #1 1'b0; 
    else if(tms_pad_i & (capture_ir | shift_ir)) exit1_ir <= #1 1'b1; 
    else exit1_ir <= #1 1'b0;
  end


  always @(posedge tck_pad_i or posedge trst_pad_i) begin
    if(trst_pad_i) pause_ir <= #1 1'b0; 
    else if(tms_reset) pause_ir <= #1 1'b0; 
    else if(~tms_pad_i & (exit1_ir | pause_ir)) pause_ir <= #1 1'b1; 
    else pause_ir <= #1 1'b0;
  end


  always @(posedge tck_pad_i or posedge trst_pad_i) begin
    if(trst_pad_i) exit2_ir <= #1 1'b0; 
    else if(tms_reset) exit2_ir <= #1 1'b0; 
    else if(tms_pad_i & pause_ir) exit2_ir <= #1 1'b1; 
    else exit2_ir <= #1 1'b0;
  end


  always @(posedge tck_pad_i or posedge trst_pad_i) begin
    if(trst_pad_i) update_ir <= #1 1'b0; 
    else if(tms_reset) update_ir <= #1 1'b0; 
    else if(tms_pad_i & (exit1_ir | exit2_ir)) update_ir <= #1 1'b1; 
    else update_ir <= #1 1'b0;
  end

  reg [4-1:0] jtag_ir;
  reg [4-1:0] latched_jtag_ir;reg [4-1:0] latched_jtag_ir_neg;
  reg instruction_tdo;

  always @(posedge tck_pad_i or posedge trst_pad_i) begin
    if(trst_pad_i) jtag_ir[4-1:0] <= #1 4'b0; 
    else if(capture_ir) jtag_ir <= #1 4'b0101; 
    else if(shift_ir) jtag_ir[4-1:0] <= #1 { tdi_pad_i, jtag_ir[4-1:1] }; 
  end


  always @(negedge tck_pad_i) begin
    instruction_tdo <= #1 jtag_ir[0];
  end

  reg [31:0] idcode_reg;
  reg idcode_tdo;

  always @(posedge tck_pad_i) begin
    if(idcode_select & shift_dr) idcode_reg <= #1 { tdi_pad_i, idcode_reg[31:1] }; 
    else idcode_reg <= #1 32'h149511c3;
  end


  always @(negedge tck_pad_i) begin
    idcode_tdo <= #1 idcode_reg;
  end

  reg bypassed_tdo;
  reg bypass_reg;

  always @(posedge tck_pad_i or posedge trst_pad_i) begin
    if(trst_pad_i) bypass_reg <= #1 1'b0; 
    else if(shift_dr) bypass_reg <= #1 tdi_pad_i; 
  end


  always @(negedge tck_pad_i) begin
    bypassed_tdo <= #1 bypass_reg;
  end


  always @(posedge tck_pad_i or posedge trst_pad_i) begin
    if(trst_pad_i) latched_jtag_ir <= #1 4'b0010; 
    else if(tms_reset) latched_jtag_ir <= #1 4'b0010; 
    else if(update_ir) latched_jtag_ir <= #1 jtag_ir; 
  end


  always @(latched_jtag_ir) begin
    extest_select = 1'b0;
    sample_preload_select = 1'b0;
    idcode_select = 1'b0;
    mbist_select = 1'b0;
    debug_select = 1'b0;
    bypass_select = 1'b0;
    preload_chain_select = 1'b0;
    case(latched_jtag_ir)
      4'b0000: extest_select = 1'b1;
      4'b0001: sample_preload_select = 1'b1;
      4'b0010: idcode_select = 1'b1;
      4'b1001: mbist_select = 1'b1;
      4'b1000: debug_select = 1'b1;
      4'b1111: bypass_select = 1'b1;
      4'b0011: preload_chain_select = 1'b1;
      default: bypass_select = 1'b1;
    endcase
  end


  always @(shift_ir_neg or exit1_ir or instruction_tdo or latched_jtag_ir_neg or idcode_tdo or debug_tdi_i or bs_chain_tdi_i or mbist_tdi_i or chain_tdi_i or bypassed_tdo) begin
    if(shift_ir_neg) tdo_pad_o = instruction_tdo; 
    else begin
      case(latched_jtag_ir_neg)
        4'b0010: tdo_pad_o = idcode_tdo;
        4'b1000: tdo_pad_o = debug_tdi_i;
        4'b0001: tdo_pad_o = bs_chain_tdi_i;
        4'b0000: tdo_pad_o = bs_chain_tdi_i;
        4'b1001: tdo_pad_o = mbist_tdi_i;
        4'b0011: tdo_pad_o = chain_tdi_i;
        default: tdo_pad_o = bypassed_tdo;
      endcase
    end
  end


  always @(negedge tck_pad_i) begin
    tdo_padoe_o <= #1 shift_ir | shift_dr | exit2_dr | pause_dr & debug_select;
  end


  always @(negedge tck_pad_i) begin
    shift_ir_neg <= #1 shift_ir;
    latched_jtag_ir_neg <= #1 latched_jtag_ir;
  end


endmodule



module tap_wrapper
(
  tdi,
  tms,
  tck,
  trst,
  tdo_pad_o,
  tdo_paden_o,
  sout,
  sin,
  shift,
  test
);

  input tdi;
  input tms;
  input tck;
  input trst;
  input sout;
  output tdo_pad_o;
  output tdo_paden_o;
  output shift;
  output test;
  output sin;
  wire chain_tdi_i;
  wire __trst_high__;
  wire tdo_padoe_o;
  wire shift_dr_o;
  wire pause_dr_o;
  wire run_test_idle_o;
  wire test_logic_reset_o;
  wire exit1_dr_o;
  assign chain_tdi_i = sout;
  assign __trst_high__ = ~trst;
  assign shift = (pause_dr_o | (shift_dr_o | exit1_dr_o)) & preload_chain_o;
  assign test = ~test_logic_reset_o;
  assign sin = tdo_o;
  assign tdo_paden_o = ~tdo_padoe_o;

  tap_top
  __tap_top__
  (
    .tms_pad_i(tms),
    .tck_pad_i(tck),
    .trst_pad_i(__trst_high__),
    .tdi_pad_i(tdi),
    .tdo_pad_o(tdo_pad_o),
    .tdo_padoe_o(tdo_padoe_o),
    .shift_dr_o(shift_dr_o),
    .pause_dr_o(pause_dr_o),
    .run_test_idle_o(run_test_idle_o),
    .test_logic_reset_o(test_logic_reset_o),
    .exit1_dr_o(exit1_dr_o),
    .preload_chain_o(preload_chain_o),
    .tdo_o(tdo_o),
    .chain_tdi_i(chain_tdi_i)
  );


endmodule



module LUT
(
  clk,
  rst_n,
  in,
  shift_amt,
  is_sync,
  y,
  tms,
  tck,
  tdi,
  tdo,
  trst,
  tdo_paden_o
);

  input tms;
  input tck;
  input tdi;
  output tdo;
  output tdo_paden_o;
  input trst;
  input clk;
  input rst_n;
  input [1:0] in;
  input [1:0] shift_amt;
  input is_sync;
  output y;
  wire tdo_pad_o;
  wire tdo_paden_o;
  wire tms;
  wire tdi;
  wire trst;
  wire sin;
  wire sout;
  wire shift;
  wire test;

  tap_wrapper
  __tap_wrapper__
  (
    .tms(tms),
    .tck(tck),
    .trst(trst),
    .tdi(tdi),
    .tdo_pad_o(tdo),
    .tdo_paden_o(tdo_paden_o),
    .sin(sin),
    .sout(sout),
    .test(test),
    .shift(shift)
  );


  __DESIGN__UNDER__TEST__
  __dut__
  (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .shift_amt(shift_amt),
    .is_sync(is_sync),
    .sin(sin),
    .shift(shift),
    .tck(tck),
    .test(test),
    .y(y),
    .sout(sout)
  );


endmodule


