

module BoundaryScanRegister_input
(
  din,
  dout,
  sin,
  sout,
  clock,
  reset,
  testing,
  shift
);

  input din;
  output dout;
  input sin;
  output sout;
  input clock;input reset;input testing;input shift;
  reg store;

  always @(posedge clock or negedge reset) begin
    if(~reset) begin
      store <= 1'b0;
    end else begin
      store <= (shift)? sin : dout;
    end
  end

  assign sout = store;
  assign dout = (testing)? store : din;

endmodule



module BoundaryScanRegister_output
(
  din,
  dout,
  sin,
  sout,
  clock,
  reset,
  testing,
  shift
);

  input din;
  output dout;
  input sin;
  output sout;
  input clock;input reset;input testing;input shift;
  reg store;

  always @(posedge clock or negedge reset) begin
    if(~reset) begin
      store <= 1'b0;
    end else begin
      store <= (shift)? sin : dout;
    end
  end

  assign sout = store;
  assign dout = din;

endmodule



module \LUT.original 
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

  input sin;
  output sout;
  input shift;
  input tck;
  input test;
  wire __clk_source__;
  wire __chain_0__;
  assign __chain_0__ = sin;
  wire _0_;
  input clk;
  wire clk;
  wire comb_y;
  input [1:0] in;
  wire [1:0] in;
  input is_sync;
  wire is_sync;
  input rst_n;
  wire rst_n;
  input [1:0] shift_amt;
  wire [1:0] shift_amt;
  output y;
  wire y;
  wire y_reg;

  sky130_fd_sc_hd__maj3_1
  _1_
  (
    .A(in[1]),
    .B(in[0]),
    .C(shift_amt[0]),
    .X(_0_)
  );


  sky130_fd_sc_hd__xor2_1
  _2_
  (
    .A(shift_amt[1]),
    .B(_0_),
    .X(comb_y)
  );


  sky130_fd_sc_hd__mux2_1
  _3_
  (
    .A0(comb_y),
    .A1(y_reg),
    .S(is_sync),
    .X(y)
  );


  sky130_fd_sc_hd__dfrtp_1
  _4_
  (
    .CLK(__clk_source__),
    .D((shift)? __chain_0__ : comb_y),
    .Q(y_reg),
    .RESET_B(rst_n)
  );

  assign sout = y_reg;
  assign __clk_source__ = (test)? tck : clk;

endmodule



module LUT
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

  input sin;
  output sout;
  input rst_n;
  input shift;
  input tck;
  input test;
  input clk;
  wire __chain_0__;
  assign __chain_0__ = sin;
  input [1:0] in;
  wire [1:0] in__dout;
  wire __chain_1__;

  BoundaryScanRegister_input
  __BoundaryScanRegister_input__0__
  (
    .din(in[0]),
    .dout(in__dout[0]),
    .sin(__chain_0__),
    .sout(__chain_1__),
    .clock(tck),
    .reset(rst_n),
    .testing(test),
    .shift(shift)
  );

  wire __chain_2__;

  BoundaryScanRegister_input
  __BoundaryScanRegister_input__1__
  (
    .din(in[1]),
    .dout(in__dout[1]),
    .sin(__chain_1__),
    .sout(__chain_2__),
    .clock(tck),
    .reset(rst_n),
    .testing(test),
    .shift(shift)
  );

  input [1:0] shift_amt;
  wire [1:0] shift_amt__dout;
  wire __chain_3__;

  BoundaryScanRegister_input
  __BoundaryScanRegister_input__2__
  (
    .din(shift_amt[0]),
    .dout(shift_amt__dout[0]),
    .sin(__chain_2__),
    .sout(__chain_3__),
    .clock(tck),
    .reset(rst_n),
    .testing(test),
    .shift(shift)
  );

  wire __chain_4__;

  BoundaryScanRegister_input
  __BoundaryScanRegister_input__3__
  (
    .din(shift_amt[1]),
    .dout(shift_amt__dout[1]),
    .sin(__chain_3__),
    .sout(__chain_4__),
    .clock(tck),
    .reset(rst_n),
    .testing(test),
    .shift(shift)
  );

  input is_sync;
  wire is_sync__dout;
  wire __chain_5__;

  BoundaryScanRegister_input
  __BoundaryScanRegister_input__4__
  (
    .din(is_sync),
    .dout(is_sync__dout),
    .sin(__chain_4__),
    .sout(__chain_5__),
    .clock(tck),
    .reset(rst_n),
    .testing(test),
    .shift(shift)
  );

  wire __chain_6__;
  output y;
  wire y_din;
  wire __chain_7__;

  BoundaryScanRegister_output
  __BoundaryScanRegister_output__5__
  (
    .din(y_din),
    .dout(y),
    .sin(__chain_6__),
    .sout(__chain_7__),
    .clock(tck),
    .reset(rst_n),
    .testing(test),
    .shift(shift)
  );


  \LUT.original 
  __uuf__
  (
    .clk(clk),
    .rst_n(rst_n),
    .in(in__dout),
    .shift_amt(shift_amt__dout),
    .is_sync(is_sync__dout),
    .shift(shift),
    .tck(tck),
    .test(test),
    .sin(__chain_5__),
    .sout(__chain_6__),
    .y(y_din)
  );

  assign sout = __chain_7__;

endmodule


