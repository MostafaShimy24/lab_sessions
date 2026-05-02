module LUT (clk,
    is_sync,
    rst_n,
    y,
    in,
    shift_amt);
 input clk;
 input is_sync;
 input rst_n;
 output y;
 input [1:0] in;
 input [1:0] shift_amt;

 wire _0_;
 wire comb_y;
 wire y_reg;

 sky130_fd_sc_hd__maj3_1 _1_ (.A(in[1]),
    .B(in[0]),
    .C(shift_amt[0]),
    .X(_0_));
 sky130_fd_sc_hd__xor2_1 _2_ (.A(shift_amt[1]),
    .B(_0_),
    .X(comb_y));
 sky130_fd_sc_hd__mux2_1 _3_ (.A0(comb_y),
    .A1(y_reg),
    .S(is_sync),
    .X(y));
 sky130_fd_sc_hd__dfrtp_1 _4_ (.CLK(clk),
    .D(comb_y),
    .RESET_B(rst_n),
    .Q(y_reg));
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_0_Right_0 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_1_Right_1 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_2_Right_2 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_3_Right_3 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_0_Left_4 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_1_Left_5 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_2_Left_6 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_3_Left_7 ();
 sky130_fd_sc_hd__fill_8 FILLER_0_3 ();
 sky130_fd_sc_hd__fill_8 FILLER_0_11 ();
 sky130_fd_sc_hd__fill_4 FILLER_0_19 ();
 sky130_fd_sc_hd__fill_2 FILLER_0_23 ();
 sky130_fd_sc_hd__fill_1 FILLER_1_3 ();
 sky130_fd_sc_hd__fill_1 FILLER_1_24 ();
 sky130_fd_sc_hd__fill_4 FILLER_2_19 ();
 sky130_fd_sc_hd__fill_2 FILLER_2_23 ();
 sky130_fd_sc_hd__fill_8 FILLER_3_3 ();
 sky130_fd_sc_hd__fill_4 FILLER_3_19 ();
 sky130_fd_sc_hd__fill_2 FILLER_3_23 ();
endmodule
