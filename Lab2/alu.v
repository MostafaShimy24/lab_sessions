// 
// Politecnico di Milano
// Code created using PandA - Version: PandA 0.9.7 - Revision 8b59b7ac7b9ab30cd20960921ab47ea5009163f1-main - Date 2026-02-22T11:29:29
// /tmp/.mount_bambu-k0kOZt/usr/bin/bambu executed with: /tmp/.mount_bambu-k0kOZt/usr/bin/bambu --top-fname=alu Alu.c 
// 
// Send any bug to: panda-info@polimi.it
// ************************************************************************
// The following text holds for all the components tagged with PANDA_LGPLv3.
// They are all part of the BAMBU/PANDA IP LIBRARY.
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 3 of the License, or (at your option) any later version.
// 
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public
// License along with the PandA framework; see the files COPYING.LIB
// If not, see <http://www.gnu.org/licenses/>.
// ************************************************************************

`ifdef __ICARUS__
  `define _SIM_HAVE_CLOG2
`endif
`ifdef VERILATOR
  `define _SIM_HAVE_CLOG2
`endif
`ifdef MODEL_TECH
  `define _SIM_HAVE_CLOG2
`endif
`ifdef VCS
  `define _SIM_HAVE_CLOG2
`endif
`ifdef NCVERILOG
  `define _SIM_HAVE_CLOG2
`endif
`ifdef XILINX_SIMULATOR
  `define _SIM_HAVE_CLOG2
`endif
`ifdef XILINX_ISIM
  `define _SIM_HAVE_CLOG2
`endif

// This component is part of the BAMBU/PANDA IP LIBRARY
// Copyright (C) 2004-2022 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>, Christian Pilato <christian.pilato@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module constant_value(out1);
  parameter BITSIZE_out1=1,
    value=1'b0;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  assign out1 = value;
endmodule

// This component is part of the BAMBU/PANDA IP LIBRARY
// Copyright (C) 2004-2022 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module register_STD(clock,
  reset,
  in1,
  wenable,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_out1=1;
  // IN
  input clock;
  input reset;
  input [BITSIZE_in1-1:0] in1;
  input wenable;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  reg [BITSIZE_out1-1:0] reg_out1 =0;
  assign out1 = reg_out1;
  always @(posedge clock)
    reg_out1 <= in1;

endmodule

// This component is part of the BAMBU/PANDA IP LIBRARY
// Copyright (C) 2020-2022 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module ui_extract_bit_expr_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output out1;
  assign out1 = (in1 >> in2)&1;
endmodule

// This component is part of the BAMBU/PANDA IP LIBRARY
// Copyright (C) 2016-2022 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module lut_expr_FU(in1,
  in2,
  in3,
  in4,
  in5,
  in6,
  in7,
  in8,
  in9,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input in2;
  input in3;
  input in4;
  input in5;
  input in6;
  input in7;
  input in8;
  input in9;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  reg[7:0] cleaned_in0;
  wire [7:0] in0;
  wire[BITSIZE_in1-1:0] shifted_s;
  assign in0 = {in9, in8, in7, in6, in5, in4, in3, in2};
  generate
    genvar i0;
    for (i0=0; i0<8; i0=i0+1)
    begin : L0
          always @(*)
          begin
             if (in0[i0] == 1'b1)
                cleaned_in0[i0] = 1'b1;
             else
                cleaned_in0[i0] = 1'b0;
          end
    end
  endgenerate
  assign shifted_s = in1 >> cleaned_in0;
  assign out1[0] = shifted_s[0];
  generate
     if(BITSIZE_out1 > 1)
       assign out1[BITSIZE_out1-1:1] = 0;
  endgenerate

endmodule

// This component is part of the BAMBU/PANDA IP LIBRARY
// Copyright (C) 2004-2022 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module UIdata_converter_FU(in1,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  // OUT
  output signed [BITSIZE_out1-1:0] out1;
  generate
  if (BITSIZE_out1 <= BITSIZE_in1)
  begin
    assign out1 = in1[BITSIZE_out1-1:0];
  end
  else
  begin
    assign out1 = {{(BITSIZE_out1-BITSIZE_in1){1'b0}},in1};
  end
  endgenerate
endmodule

// This component is part of the BAMBU/PANDA IP LIBRARY
// Copyright (C) 2004-2022 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module multi_read_cond_FU(in1,
  out1);
  parameter BITSIZE_in1=1, PORTSIZE_in1=2,
    BITSIZE_out1=1;
  // IN
  input [(PORTSIZE_in1*BITSIZE_in1)+(-1):0] in1;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  assign out1 = in1;
endmodule

// This component is part of the BAMBU/PANDA IP LIBRARY
// Copyright (C) 2004-2022 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module bit_and_expr_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1;
  // IN
  input signed [BITSIZE_in1-1:0] in1;
  input signed [BITSIZE_in2-1:0] in2;
  // OUT
  output signed [BITSIZE_out1-1:0] out1;
  assign out1 = in1 & in2;
endmodule

// This component is part of the BAMBU/PANDA IP LIBRARY
// Copyright (C) 2004-2022 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module ui_bit_and_expr_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  assign out1 = in1 & in2;
endmodule

// This component is part of the BAMBU/PANDA IP LIBRARY
// Copyright (C) 2004-2022 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module ui_bit_ior_expr_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  assign out1 = in1 | in2;
endmodule

// This component is part of the BAMBU/PANDA IP LIBRARY
// Copyright (C) 2004-2022 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module ui_bit_xor_expr_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  assign out1 = in1 ^ in2;
endmodule

// This component is part of the BAMBU/PANDA IP LIBRARY
// Copyright (C) 2004-2022 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module ui_cond_expr_FU(in1,
  in2,
  in3,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_in3=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  input [BITSIZE_in3-1:0] in3;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  assign out1 = in1 != 0 ? in2 : in3;
endmodule

// This component is part of the BAMBU/PANDA IP LIBRARY
// Copyright (C) 2004-2022 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module ui_lshift_expr_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1,
    PRECISION=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  `ifndef _SIM_HAVE_CLOG2
    function integer log2;
       input integer value;
       integer temp_value;
      begin
        temp_value = value-1;
        for (log2=0; temp_value>0; log2=log2+1)
          temp_value = temp_value>>1;
      end
    endfunction
  `endif
  `ifdef _SIM_HAVE_CLOG2
    parameter arg2_bitsize = $clog2(PRECISION);
  `else
    parameter arg2_bitsize = log2(PRECISION);
  `endif
  generate
    if(BITSIZE_in2 > arg2_bitsize)
      assign out1 = in1 << in2[arg2_bitsize-1:0];
    else
      assign out1 = in1 << in2;
  endgenerate
endmodule

// This component is part of the BAMBU/PANDA IP LIBRARY
// Copyright (C) 2004-2022 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module ui_minus_expr_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  assign out1 = in1 - in2;
endmodule

// This component is part of the BAMBU/PANDA IP LIBRARY
// Copyright (C) 2004-2022 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module ui_mult_expr_FU(clock,
  in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1,
    PIPE_PARAMETER=0;
  // IN
  input clock;
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  generate
    if(PIPE_PARAMETER==1)
    begin
      reg signed [BITSIZE_out1-1:0] out1_reg;
      assign out1 = out1_reg;
      always @(posedge clock)
      begin
        out1_reg <= in1 * in2;
      end
    end
    else if(PIPE_PARAMETER>1)
    begin
      reg [BITSIZE_in1-1:0] in1_in;
      reg [BITSIZE_in2-1:0] in2_in;
      wire [BITSIZE_out1-1:0] mult_res;
      reg [BITSIZE_out1-1:0] mul [PIPE_PARAMETER-2:0];
      integer i;
      assign mult_res = in1_in * in2_in;
      always @(posedge clock)
      begin
        in1_in <= in1;
        in2_in <= in2;
        mul[PIPE_PARAMETER-2] <= mult_res;
        for (i=0; i<PIPE_PARAMETER-2; i=i+1)
          mul[i] <= mul[i+1];
      end
      assign out1 = mul[0];
    end
    else
    begin
      assign out1 = in1 * in2;
    end
  endgenerate

endmodule

// This component is part of the BAMBU/PANDA IP LIBRARY
// Copyright (C) 2004-2022 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module ui_plus_expr_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  assign out1 = in1 + in2;
endmodule

// This component is part of the BAMBU/PANDA IP LIBRARY
// Copyright (C) 2004-2022 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module ui_rshift_expr_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1,
    PRECISION=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  `ifndef _SIM_HAVE_CLOG2
    function integer log2;
       input integer value;
       integer temp_value;
      begin
        temp_value = value-1;
        for (log2=0; temp_value>0; log2=log2+1)
          temp_value = temp_value>>1;
      end
    endfunction
  `endif
  `ifdef _SIM_HAVE_CLOG2
    parameter arg2_bitsize = $clog2(PRECISION);
  `else
    parameter arg2_bitsize = log2(PRECISION);
  `endif
  generate
    if(BITSIZE_in2 > arg2_bitsize)
      assign out1 = in1 >> (in2[arg2_bitsize-1:0]);
    else
      assign out1 = in1 >> in2;
  endgenerate

endmodule

// This component is part of the BAMBU/PANDA IP LIBRARY
// Copyright (C) 2004-2022 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>, Christian Pilato <christian.pilato@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module MUX_GATE(sel,
  in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1;
  // IN
  input sel;
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  assign out1 = sel ? in1 : in2;
endmodule

// Datapath RTL description for alu
// This component has been derived from the input source code and so it does not fall under the copyright of PandA framework, but it follows the input source code copyright, and may be aggregated with components of the BAMBU/PANDA IP LIBRARY.
// Author(s): Component automatically generated by bambu
// License: THIS COMPONENT IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
`timescale 1ns / 1ps
module datapath_alu(clock,
  reset,
  in_port_a,
  in_port_b,
  in_port_opcode,
  return_port,
  selector_MUX_7_gimple_return_FU_50_i0_0_0_0,
  wrenable_reg_0,
  OUT_MULTIIF_alu_33673_33804);
  // IN
  input clock;
  input reset;
  input [31:0] in_port_a;
  input [31:0] in_port_b;
  input [7:0] in_port_opcode;
  input selector_MUX_7_gimple_return_FU_50_i0_0_0_0;
  input wrenable_reg_0;
  // OUT
  output [31:0] return_port;
  output OUT_MULTIIF_alu_33673_33804;
  // Component and signal declarations
  wire [31:0] out_MUX_7_gimple_return_FU_50_i0_0_0_0;
  wire signed [5:0] out_UIdata_converter_FU_47_i0_fu_alu_33673_33773;
  wire signed [5:0] out_UIdata_converter_FU_48_i0_fu_alu_33673_33761;
  wire signed [5:0] out_bit_and_expr_FU_8_0_8_51_i0_fu_alu_33673_33762;
  wire signed [5:0] out_bit_and_expr_FU_8_0_8_51_i1_fu_alu_33673_33774;
  wire out_const_0;
  wire [5:0] out_const_1;
  wire [21:0] out_const_10;
  wire [22:0] out_const_11;
  wire [23:0] out_const_12;
  wire [2:0] out_const_13;
  wire [1:0] out_const_14;
  wire [2:0] out_const_15;
  wire [2:0] out_const_16;
  wire out_const_2;
  wire [1:0] out_const_3;
  wire [2:0] out_const_4;
  wire [16:0] out_const_5;
  wire [17:0] out_const_6;
  wire [18:0] out_const_7;
  wire [19:0] out_const_8;
  wire [20:0] out_const_9;
  wire out_lut_expr_FU_11_i0_fu_alu_33673_33809;
  wire out_lut_expr_FU_16_i0_fu_alu_33673_33812;
  wire out_lut_expr_FU_21_i0_fu_alu_33673_33815;
  wire out_lut_expr_FU_26_i0_fu_alu_33673_33818;
  wire out_lut_expr_FU_31_i0_fu_alu_33673_33821;
  wire out_lut_expr_FU_36_i0_fu_alu_33673_33824;
  wire out_lut_expr_FU_41_i0_fu_alu_33673_33827;
  wire out_lut_expr_FU_46_i0_fu_alu_33673_33830;
  wire out_lut_expr_FU_6_i0_fu_alu_33673_33877;
  wire out_multi_read_cond_FU_49_i0_fu_alu_33673_33804;
  wire [31:0] out_reg_0_reg_0;
  wire [31:0] out_ui_bit_and_expr_FU_32_32_32_52_i0_fu_alu_33673_33749;
  wire [31:0] out_ui_bit_ior_expr_FU_32_32_32_53_i0_fu_alu_33673_33753;
  wire [31:0] out_ui_bit_xor_expr_FU_32_32_32_54_i0_fu_alu_33673_33757;
  wire [31:0] out_ui_cond_expr_FU_32_32_32_32_55_i0_fu_alu_33673_33833;
  wire [31:0] out_ui_cond_expr_FU_32_32_32_32_55_i1_fu_alu_33673_33836;
  wire [31:0] out_ui_cond_expr_FU_32_32_32_32_55_i2_fu_alu_33673_33839;
  wire [31:0] out_ui_cond_expr_FU_32_32_32_32_55_i3_fu_alu_33673_33842;
  wire [31:0] out_ui_cond_expr_FU_32_32_32_32_55_i4_fu_alu_33673_33845;
  wire [31:0] out_ui_cond_expr_FU_32_32_32_32_55_i5_fu_alu_33673_33848;
  wire [31:0] out_ui_cond_expr_FU_32_32_32_32_55_i6_fu_alu_33673_33851;
  wire out_ui_extract_bit_expr_FU_10_i0_fu_alu_33673_33892;
  wire out_ui_extract_bit_expr_FU_12_i0_fu_alu_33673_33897;
  wire out_ui_extract_bit_expr_FU_13_i0_fu_alu_33673_33900;
  wire out_ui_extract_bit_expr_FU_14_i0_fu_alu_33673_33903;
  wire out_ui_extract_bit_expr_FU_15_i0_fu_alu_33673_33906;
  wire out_ui_extract_bit_expr_FU_17_i0_fu_alu_33673_33911;
  wire out_ui_extract_bit_expr_FU_18_i0_fu_alu_33673_33914;
  wire out_ui_extract_bit_expr_FU_19_i0_fu_alu_33673_33917;
  wire out_ui_extract_bit_expr_FU_20_i0_fu_alu_33673_33920;
  wire out_ui_extract_bit_expr_FU_22_i0_fu_alu_33673_33925;
  wire out_ui_extract_bit_expr_FU_23_i0_fu_alu_33673_33928;
  wire out_ui_extract_bit_expr_FU_24_i0_fu_alu_33673_33931;
  wire out_ui_extract_bit_expr_FU_25_i0_fu_alu_33673_33934;
  wire out_ui_extract_bit_expr_FU_27_i0_fu_alu_33673_33939;
  wire out_ui_extract_bit_expr_FU_28_i0_fu_alu_33673_33942;
  wire out_ui_extract_bit_expr_FU_29_i0_fu_alu_33673_33945;
  wire out_ui_extract_bit_expr_FU_2_i0_fu_alu_33673_33862;
  wire out_ui_extract_bit_expr_FU_30_i0_fu_alu_33673_33948;
  wire out_ui_extract_bit_expr_FU_32_i0_fu_alu_33673_33953;
  wire out_ui_extract_bit_expr_FU_33_i0_fu_alu_33673_33956;
  wire out_ui_extract_bit_expr_FU_34_i0_fu_alu_33673_33959;
  wire out_ui_extract_bit_expr_FU_35_i0_fu_alu_33673_33962;
  wire out_ui_extract_bit_expr_FU_37_i0_fu_alu_33673_33967;
  wire out_ui_extract_bit_expr_FU_38_i0_fu_alu_33673_33970;
  wire out_ui_extract_bit_expr_FU_39_i0_fu_alu_33673_33973;
  wire out_ui_extract_bit_expr_FU_3_i0_fu_alu_33673_33866;
  wire out_ui_extract_bit_expr_FU_40_i0_fu_alu_33673_33976;
  wire out_ui_extract_bit_expr_FU_42_i0_fu_alu_33673_33981;
  wire out_ui_extract_bit_expr_FU_43_i0_fu_alu_33673_33984;
  wire out_ui_extract_bit_expr_FU_44_i0_fu_alu_33673_33987;
  wire out_ui_extract_bit_expr_FU_45_i0_fu_alu_33673_33990;
  wire out_ui_extract_bit_expr_FU_4_i0_fu_alu_33673_33870;
  wire out_ui_extract_bit_expr_FU_5_i0_fu_alu_33673_33874;
  wire out_ui_extract_bit_expr_FU_7_i0_fu_alu_33673_33881;
  wire out_ui_extract_bit_expr_FU_8_i0_fu_alu_33673_33884;
  wire out_ui_extract_bit_expr_FU_9_i0_fu_alu_33673_33888;
  wire [31:0] out_ui_lshift_expr_FU_32_32_32_56_i0_fu_alu_33673_33763;
  wire [31:0] out_ui_minus_expr_FU_32_32_32_57_i0_fu_alu_33673_33741;
  wire [31:0] out_ui_mult_expr_FU_32_32_32_0_58_i0_fu_alu_33673_33745;
  wire [31:0] out_ui_plus_expr_FU_32_32_32_59_i0_fu_alu_33673_33729;
  wire [31:0] out_ui_rshift_expr_FU_32_32_32_60_i0_fu_alu_33673_33775;
  
  MUX_GATE #(.BITSIZE_in1(32),
    .BITSIZE_in2(32),
    .BITSIZE_out1(32)) MUX_7_gimple_return_FU_50_i0_0_0_0 (.out1(out_MUX_7_gimple_return_FU_50_i0_0_0_0),
    .sel(selector_MUX_7_gimple_return_FU_50_i0_0_0_0),
    .in1(out_reg_0_reg_0),
    .in2(out_ui_mult_expr_FU_32_32_32_0_58_i0_fu_alu_33673_33745));
  constant_value #(.BITSIZE_out1(1),
    .value(1'b0)) const_0 (.out1(out_const_0));
  constant_value #(.BITSIZE_out1(6),
    .value(6'b011111)) const_1 (.out1(out_const_1));
  constant_value #(.BITSIZE_out1(22),
    .value(22'b1000000000000000000000)) const_10 (.out1(out_const_10));
  constant_value #(.BITSIZE_out1(23),
    .value(23'b10000000000000000000000)) const_11 (.out1(out_const_11));
  constant_value #(.BITSIZE_out1(24),
    .value(24'b100000000000000000000000)) const_12 (.out1(out_const_12));
  constant_value #(.BITSIZE_out1(3),
    .value(3'b101)) const_13 (.out1(out_const_13));
  constant_value #(.BITSIZE_out1(2),
    .value(2'b11)) const_14 (.out1(out_const_14));
  constant_value #(.BITSIZE_out1(3),
    .value(3'b110)) const_15 (.out1(out_const_15));
  constant_value #(.BITSIZE_out1(3),
    .value(3'b111)) const_16 (.out1(out_const_16));
  constant_value #(.BITSIZE_out1(1),
    .value(1'b1)) const_2 (.out1(out_const_2));
  constant_value #(.BITSIZE_out1(2),
    .value(2'b10)) const_3 (.out1(out_const_3));
  constant_value #(.BITSIZE_out1(3),
    .value(3'b100)) const_4 (.out1(out_const_4));
  constant_value #(.BITSIZE_out1(17),
    .value(17'b10000000000000000)) const_5 (.out1(out_const_5));
  constant_value #(.BITSIZE_out1(18),
    .value(18'b100000000000000000)) const_6 (.out1(out_const_6));
  constant_value #(.BITSIZE_out1(19),
    .value(19'b1000000000000000000)) const_7 (.out1(out_const_7));
  constant_value #(.BITSIZE_out1(20),
    .value(20'b10000000000000000000)) const_8 (.out1(out_const_8));
  constant_value #(.BITSIZE_out1(21),
    .value(21'b100000000000000000000)) const_9 (.out1(out_const_9));
  ui_plus_expr_FU #(.BITSIZE_in1(32),
    .BITSIZE_in2(32),
    .BITSIZE_out1(32)) fu_alu_33673_33729 (.out1(out_ui_plus_expr_FU_32_32_32_59_i0_fu_alu_33673_33729),
    .in1(in_port_a),
    .in2(in_port_b));
  ui_minus_expr_FU #(.BITSIZE_in1(32),
    .BITSIZE_in2(32),
    .BITSIZE_out1(32)) fu_alu_33673_33741 (.out1(out_ui_minus_expr_FU_32_32_32_57_i0_fu_alu_33673_33741),
    .in1(in_port_a),
    .in2(in_port_b));
  ui_mult_expr_FU #(.BITSIZE_in1(32),
    .BITSIZE_in2(32),
    .BITSIZE_out1(32),
    .PIPE_PARAMETER(0)) fu_alu_33673_33745 (.out1(out_ui_mult_expr_FU_32_32_32_0_58_i0_fu_alu_33673_33745),
    .clock(clock),
    .in1(in_port_a),
    .in2(in_port_b));
  ui_bit_and_expr_FU #(.BITSIZE_in1(32),
    .BITSIZE_in2(32),
    .BITSIZE_out1(32)) fu_alu_33673_33749 (.out1(out_ui_bit_and_expr_FU_32_32_32_52_i0_fu_alu_33673_33749),
    .in1(in_port_a),
    .in2(in_port_b));
  ui_bit_ior_expr_FU #(.BITSIZE_in1(32),
    .BITSIZE_in2(32),
    .BITSIZE_out1(32)) fu_alu_33673_33753 (.out1(out_ui_bit_ior_expr_FU_32_32_32_53_i0_fu_alu_33673_33753),
    .in1(in_port_a),
    .in2(in_port_b));
  ui_bit_xor_expr_FU #(.BITSIZE_in1(32),
    .BITSIZE_in2(32),
    .BITSIZE_out1(32)) fu_alu_33673_33757 (.out1(out_ui_bit_xor_expr_FU_32_32_32_54_i0_fu_alu_33673_33757),
    .in1(in_port_a),
    .in2(in_port_b));
  UIdata_converter_FU #(.BITSIZE_in1(32),
    .BITSIZE_out1(6)) fu_alu_33673_33761 (.out1(out_UIdata_converter_FU_48_i0_fu_alu_33673_33761),
    .in1(in_port_b));
  bit_and_expr_FU #(.BITSIZE_in1(6),
    .BITSIZE_in2(6),
    .BITSIZE_out1(6)) fu_alu_33673_33762 (.out1(out_bit_and_expr_FU_8_0_8_51_i0_fu_alu_33673_33762),
    .in1(out_UIdata_converter_FU_48_i0_fu_alu_33673_33761),
    .in2(out_const_1));
  ui_lshift_expr_FU #(.BITSIZE_in1(32),
    .BITSIZE_in2(6),
    .BITSIZE_out1(32),
    .PRECISION(32)) fu_alu_33673_33763 (.out1(out_ui_lshift_expr_FU_32_32_32_56_i0_fu_alu_33673_33763),
    .in1(in_port_a),
    .in2(out_bit_and_expr_FU_8_0_8_51_i0_fu_alu_33673_33762));
  UIdata_converter_FU #(.BITSIZE_in1(32),
    .BITSIZE_out1(6)) fu_alu_33673_33773 (.out1(out_UIdata_converter_FU_47_i0_fu_alu_33673_33773),
    .in1(in_port_b));
  bit_and_expr_FU #(.BITSIZE_in1(6),
    .BITSIZE_in2(6),
    .BITSIZE_out1(6)) fu_alu_33673_33774 (.out1(out_bit_and_expr_FU_8_0_8_51_i1_fu_alu_33673_33774),
    .in1(out_UIdata_converter_FU_47_i0_fu_alu_33673_33773),
    .in2(out_const_1));
  ui_rshift_expr_FU #(.BITSIZE_in1(32),
    .BITSIZE_in2(6),
    .BITSIZE_out1(32),
    .PRECISION(32)) fu_alu_33673_33775 (.out1(out_ui_rshift_expr_FU_32_32_32_60_i0_fu_alu_33673_33775),
    .in1(in_port_a),
    .in2(out_bit_and_expr_FU_8_0_8_51_i1_fu_alu_33673_33774));
  multi_read_cond_FU #(.BITSIZE_in1(1),
    .PORTSIZE_in1(1),
    .BITSIZE_out1(1)) fu_alu_33673_33804 (.out1(out_multi_read_cond_FU_49_i0_fu_alu_33673_33804),
    .in1({out_lut_expr_FU_21_i0_fu_alu_33673_33815}));
  lut_expr_FU #(.BITSIZE_in1(17),
    .BITSIZE_out1(1)) fu_alu_33673_33809 (.out1(out_lut_expr_FU_11_i0_fu_alu_33673_33809),
    .in1(out_const_5),
    .in2(out_ui_extract_bit_expr_FU_7_i0_fu_alu_33673_33881),
    .in3(out_ui_extract_bit_expr_FU_8_i0_fu_alu_33673_33884),
    .in4(out_ui_extract_bit_expr_FU_9_i0_fu_alu_33673_33888),
    .in5(out_ui_extract_bit_expr_FU_10_i0_fu_alu_33673_33892),
    .in6(out_lut_expr_FU_6_i0_fu_alu_33673_33877),
    .in7(1'b0),
    .in8(1'b0),
    .in9(1'b0));
  lut_expr_FU #(.BITSIZE_in1(18),
    .BITSIZE_out1(1)) fu_alu_33673_33812 (.out1(out_lut_expr_FU_16_i0_fu_alu_33673_33812),
    .in1(out_const_6),
    .in2(out_ui_extract_bit_expr_FU_12_i0_fu_alu_33673_33897),
    .in3(out_ui_extract_bit_expr_FU_13_i0_fu_alu_33673_33900),
    .in4(out_ui_extract_bit_expr_FU_14_i0_fu_alu_33673_33903),
    .in5(out_ui_extract_bit_expr_FU_15_i0_fu_alu_33673_33906),
    .in6(out_lut_expr_FU_6_i0_fu_alu_33673_33877),
    .in7(1'b0),
    .in8(1'b0),
    .in9(1'b0));
  lut_expr_FU #(.BITSIZE_in1(19),
    .BITSIZE_out1(1)) fu_alu_33673_33815 (.out1(out_lut_expr_FU_21_i0_fu_alu_33673_33815),
    .in1(out_const_7),
    .in2(out_ui_extract_bit_expr_FU_17_i0_fu_alu_33673_33911),
    .in3(out_ui_extract_bit_expr_FU_18_i0_fu_alu_33673_33914),
    .in4(out_ui_extract_bit_expr_FU_19_i0_fu_alu_33673_33917),
    .in5(out_ui_extract_bit_expr_FU_20_i0_fu_alu_33673_33920),
    .in6(out_lut_expr_FU_6_i0_fu_alu_33673_33877),
    .in7(1'b0),
    .in8(1'b0),
    .in9(1'b0));
  lut_expr_FU #(.BITSIZE_in1(20),
    .BITSIZE_out1(1)) fu_alu_33673_33818 (.out1(out_lut_expr_FU_26_i0_fu_alu_33673_33818),
    .in1(out_const_8),
    .in2(out_ui_extract_bit_expr_FU_22_i0_fu_alu_33673_33925),
    .in3(out_ui_extract_bit_expr_FU_23_i0_fu_alu_33673_33928),
    .in4(out_ui_extract_bit_expr_FU_24_i0_fu_alu_33673_33931),
    .in5(out_ui_extract_bit_expr_FU_25_i0_fu_alu_33673_33934),
    .in6(out_lut_expr_FU_6_i0_fu_alu_33673_33877),
    .in7(1'b0),
    .in8(1'b0),
    .in9(1'b0));
  lut_expr_FU #(.BITSIZE_in1(21),
    .BITSIZE_out1(1)) fu_alu_33673_33821 (.out1(out_lut_expr_FU_31_i0_fu_alu_33673_33821),
    .in1(out_const_9),
    .in2(out_ui_extract_bit_expr_FU_27_i0_fu_alu_33673_33939),
    .in3(out_ui_extract_bit_expr_FU_28_i0_fu_alu_33673_33942),
    .in4(out_ui_extract_bit_expr_FU_29_i0_fu_alu_33673_33945),
    .in5(out_ui_extract_bit_expr_FU_30_i0_fu_alu_33673_33948),
    .in6(out_lut_expr_FU_6_i0_fu_alu_33673_33877),
    .in7(1'b0),
    .in8(1'b0),
    .in9(1'b0));
  lut_expr_FU #(.BITSIZE_in1(22),
    .BITSIZE_out1(1)) fu_alu_33673_33824 (.out1(out_lut_expr_FU_36_i0_fu_alu_33673_33824),
    .in1(out_const_10),
    .in2(out_ui_extract_bit_expr_FU_32_i0_fu_alu_33673_33953),
    .in3(out_ui_extract_bit_expr_FU_33_i0_fu_alu_33673_33956),
    .in4(out_ui_extract_bit_expr_FU_34_i0_fu_alu_33673_33959),
    .in5(out_ui_extract_bit_expr_FU_35_i0_fu_alu_33673_33962),
    .in6(out_lut_expr_FU_6_i0_fu_alu_33673_33877),
    .in7(1'b0),
    .in8(1'b0),
    .in9(1'b0));
  lut_expr_FU #(.BITSIZE_in1(23),
    .BITSIZE_out1(1)) fu_alu_33673_33827 (.out1(out_lut_expr_FU_41_i0_fu_alu_33673_33827),
    .in1(out_const_11),
    .in2(out_ui_extract_bit_expr_FU_37_i0_fu_alu_33673_33967),
    .in3(out_ui_extract_bit_expr_FU_38_i0_fu_alu_33673_33970),
    .in4(out_ui_extract_bit_expr_FU_39_i0_fu_alu_33673_33973),
    .in5(out_ui_extract_bit_expr_FU_40_i0_fu_alu_33673_33976),
    .in6(out_lut_expr_FU_6_i0_fu_alu_33673_33877),
    .in7(1'b0),
    .in8(1'b0),
    .in9(1'b0));
  lut_expr_FU #(.BITSIZE_in1(24),
    .BITSIZE_out1(1)) fu_alu_33673_33830 (.out1(out_lut_expr_FU_46_i0_fu_alu_33673_33830),
    .in1(out_const_12),
    .in2(out_ui_extract_bit_expr_FU_42_i0_fu_alu_33673_33981),
    .in3(out_ui_extract_bit_expr_FU_43_i0_fu_alu_33673_33984),
    .in4(out_ui_extract_bit_expr_FU_44_i0_fu_alu_33673_33987),
    .in5(out_ui_extract_bit_expr_FU_45_i0_fu_alu_33673_33990),
    .in6(out_lut_expr_FU_6_i0_fu_alu_33673_33877),
    .in7(1'b0),
    .in8(1'b0),
    .in9(1'b0));
  ui_cond_expr_FU #(.BITSIZE_in1(1),
    .BITSIZE_in2(32),
    .BITSIZE_in3(1),
    .BITSIZE_out1(32)) fu_alu_33673_33833 (.out1(out_ui_cond_expr_FU_32_32_32_32_55_i0_fu_alu_33673_33833),
    .in1(out_lut_expr_FU_11_i0_fu_alu_33673_33809),
    .in2(out_ui_plus_expr_FU_32_32_32_59_i0_fu_alu_33673_33729),
    .in3(out_const_0));
  ui_cond_expr_FU #(.BITSIZE_in1(1),
    .BITSIZE_in2(32),
    .BITSIZE_in3(32),
    .BITSIZE_out1(32)) fu_alu_33673_33836 (.out1(out_ui_cond_expr_FU_32_32_32_32_55_i1_fu_alu_33673_33836),
    .in1(out_lut_expr_FU_16_i0_fu_alu_33673_33812),
    .in2(out_ui_minus_expr_FU_32_32_32_57_i0_fu_alu_33673_33741),
    .in3(out_ui_cond_expr_FU_32_32_32_32_55_i0_fu_alu_33673_33833));
  ui_cond_expr_FU #(.BITSIZE_in1(1),
    .BITSIZE_in2(32),
    .BITSIZE_in3(32),
    .BITSIZE_out1(32)) fu_alu_33673_33839 (.out1(out_ui_cond_expr_FU_32_32_32_32_55_i2_fu_alu_33673_33839),
    .in1(out_lut_expr_FU_26_i0_fu_alu_33673_33818),
    .in2(out_ui_bit_and_expr_FU_32_32_32_52_i0_fu_alu_33673_33749),
    .in3(out_ui_cond_expr_FU_32_32_32_32_55_i1_fu_alu_33673_33836));
  ui_cond_expr_FU #(.BITSIZE_in1(1),
    .BITSIZE_in2(32),
    .BITSIZE_in3(32),
    .BITSIZE_out1(32)) fu_alu_33673_33842 (.out1(out_ui_cond_expr_FU_32_32_32_32_55_i3_fu_alu_33673_33842),
    .in1(out_lut_expr_FU_31_i0_fu_alu_33673_33821),
    .in2(out_ui_bit_ior_expr_FU_32_32_32_53_i0_fu_alu_33673_33753),
    .in3(out_ui_cond_expr_FU_32_32_32_32_55_i2_fu_alu_33673_33839));
  ui_cond_expr_FU #(.BITSIZE_in1(1),
    .BITSIZE_in2(32),
    .BITSIZE_in3(32),
    .BITSIZE_out1(32)) fu_alu_33673_33845 (.out1(out_ui_cond_expr_FU_32_32_32_32_55_i4_fu_alu_33673_33845),
    .in1(out_lut_expr_FU_36_i0_fu_alu_33673_33824),
    .in2(out_ui_bit_xor_expr_FU_32_32_32_54_i0_fu_alu_33673_33757),
    .in3(out_ui_cond_expr_FU_32_32_32_32_55_i3_fu_alu_33673_33842));
  ui_cond_expr_FU #(.BITSIZE_in1(1),
    .BITSIZE_in2(32),
    .BITSIZE_in3(32),
    .BITSIZE_out1(32)) fu_alu_33673_33848 (.out1(out_ui_cond_expr_FU_32_32_32_32_55_i5_fu_alu_33673_33848),
    .in1(out_lut_expr_FU_41_i0_fu_alu_33673_33827),
    .in2(out_ui_lshift_expr_FU_32_32_32_56_i0_fu_alu_33673_33763),
    .in3(out_ui_cond_expr_FU_32_32_32_32_55_i4_fu_alu_33673_33845));
  ui_cond_expr_FU #(.BITSIZE_in1(1),
    .BITSIZE_in2(32),
    .BITSIZE_in3(32),
    .BITSIZE_out1(32)) fu_alu_33673_33851 (.out1(out_ui_cond_expr_FU_32_32_32_32_55_i6_fu_alu_33673_33851),
    .in1(out_lut_expr_FU_46_i0_fu_alu_33673_33830),
    .in2(out_ui_rshift_expr_FU_32_32_32_60_i0_fu_alu_33673_33775),
    .in3(out_ui_cond_expr_FU_32_32_32_32_55_i5_fu_alu_33673_33848));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(3)) fu_alu_33673_33862 (.out1(out_ui_extract_bit_expr_FU_2_i0_fu_alu_33673_33862),
    .in1(in_port_opcode),
    .in2(out_const_4));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(3)) fu_alu_33673_33866 (.out1(out_ui_extract_bit_expr_FU_3_i0_fu_alu_33673_33866),
    .in1(in_port_opcode),
    .in2(out_const_13));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(3)) fu_alu_33673_33870 (.out1(out_ui_extract_bit_expr_FU_4_i0_fu_alu_33673_33870),
    .in1(in_port_opcode),
    .in2(out_const_15));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(3)) fu_alu_33673_33874 (.out1(out_ui_extract_bit_expr_FU_5_i0_fu_alu_33673_33874),
    .in1(in_port_opcode),
    .in2(out_const_16));
  lut_expr_FU #(.BITSIZE_in1(1),
    .BITSIZE_out1(1)) fu_alu_33673_33877 (.out1(out_lut_expr_FU_6_i0_fu_alu_33673_33877),
    .in1(out_const_2),
    .in2(out_ui_extract_bit_expr_FU_2_i0_fu_alu_33673_33862),
    .in3(out_ui_extract_bit_expr_FU_3_i0_fu_alu_33673_33866),
    .in4(out_ui_extract_bit_expr_FU_4_i0_fu_alu_33673_33870),
    .in5(out_ui_extract_bit_expr_FU_5_i0_fu_alu_33673_33874),
    .in6(1'b0),
    .in7(1'b0),
    .in8(1'b0),
    .in9(1'b0));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(1)) fu_alu_33673_33881 (.out1(out_ui_extract_bit_expr_FU_7_i0_fu_alu_33673_33881),
    .in1(in_port_opcode),
    .in2(out_const_0));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(1)) fu_alu_33673_33884 (.out1(out_ui_extract_bit_expr_FU_8_i0_fu_alu_33673_33884),
    .in1(in_port_opcode),
    .in2(out_const_2));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(2)) fu_alu_33673_33888 (.out1(out_ui_extract_bit_expr_FU_9_i0_fu_alu_33673_33888),
    .in1(in_port_opcode),
    .in2(out_const_3));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(2)) fu_alu_33673_33892 (.out1(out_ui_extract_bit_expr_FU_10_i0_fu_alu_33673_33892),
    .in1(in_port_opcode),
    .in2(out_const_14));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(1)) fu_alu_33673_33897 (.out1(out_ui_extract_bit_expr_FU_12_i0_fu_alu_33673_33897),
    .in1(in_port_opcode),
    .in2(out_const_0));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(1)) fu_alu_33673_33900 (.out1(out_ui_extract_bit_expr_FU_13_i0_fu_alu_33673_33900),
    .in1(in_port_opcode),
    .in2(out_const_2));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(2)) fu_alu_33673_33903 (.out1(out_ui_extract_bit_expr_FU_14_i0_fu_alu_33673_33903),
    .in1(in_port_opcode),
    .in2(out_const_3));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(2)) fu_alu_33673_33906 (.out1(out_ui_extract_bit_expr_FU_15_i0_fu_alu_33673_33906),
    .in1(in_port_opcode),
    .in2(out_const_14));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(1)) fu_alu_33673_33911 (.out1(out_ui_extract_bit_expr_FU_17_i0_fu_alu_33673_33911),
    .in1(in_port_opcode),
    .in2(out_const_0));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(1)) fu_alu_33673_33914 (.out1(out_ui_extract_bit_expr_FU_18_i0_fu_alu_33673_33914),
    .in1(in_port_opcode),
    .in2(out_const_2));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(2)) fu_alu_33673_33917 (.out1(out_ui_extract_bit_expr_FU_19_i0_fu_alu_33673_33917),
    .in1(in_port_opcode),
    .in2(out_const_3));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(2)) fu_alu_33673_33920 (.out1(out_ui_extract_bit_expr_FU_20_i0_fu_alu_33673_33920),
    .in1(in_port_opcode),
    .in2(out_const_14));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(1)) fu_alu_33673_33925 (.out1(out_ui_extract_bit_expr_FU_22_i0_fu_alu_33673_33925),
    .in1(in_port_opcode),
    .in2(out_const_0));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(1)) fu_alu_33673_33928 (.out1(out_ui_extract_bit_expr_FU_23_i0_fu_alu_33673_33928),
    .in1(in_port_opcode),
    .in2(out_const_2));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(2)) fu_alu_33673_33931 (.out1(out_ui_extract_bit_expr_FU_24_i0_fu_alu_33673_33931),
    .in1(in_port_opcode),
    .in2(out_const_3));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(2)) fu_alu_33673_33934 (.out1(out_ui_extract_bit_expr_FU_25_i0_fu_alu_33673_33934),
    .in1(in_port_opcode),
    .in2(out_const_14));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(1)) fu_alu_33673_33939 (.out1(out_ui_extract_bit_expr_FU_27_i0_fu_alu_33673_33939),
    .in1(in_port_opcode),
    .in2(out_const_0));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(1)) fu_alu_33673_33942 (.out1(out_ui_extract_bit_expr_FU_28_i0_fu_alu_33673_33942),
    .in1(in_port_opcode),
    .in2(out_const_2));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(2)) fu_alu_33673_33945 (.out1(out_ui_extract_bit_expr_FU_29_i0_fu_alu_33673_33945),
    .in1(in_port_opcode),
    .in2(out_const_3));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(2)) fu_alu_33673_33948 (.out1(out_ui_extract_bit_expr_FU_30_i0_fu_alu_33673_33948),
    .in1(in_port_opcode),
    .in2(out_const_14));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(1)) fu_alu_33673_33953 (.out1(out_ui_extract_bit_expr_FU_32_i0_fu_alu_33673_33953),
    .in1(in_port_opcode),
    .in2(out_const_0));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(1)) fu_alu_33673_33956 (.out1(out_ui_extract_bit_expr_FU_33_i0_fu_alu_33673_33956),
    .in1(in_port_opcode),
    .in2(out_const_2));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(2)) fu_alu_33673_33959 (.out1(out_ui_extract_bit_expr_FU_34_i0_fu_alu_33673_33959),
    .in1(in_port_opcode),
    .in2(out_const_3));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(2)) fu_alu_33673_33962 (.out1(out_ui_extract_bit_expr_FU_35_i0_fu_alu_33673_33962),
    .in1(in_port_opcode),
    .in2(out_const_14));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(1)) fu_alu_33673_33967 (.out1(out_ui_extract_bit_expr_FU_37_i0_fu_alu_33673_33967),
    .in1(in_port_opcode),
    .in2(out_const_0));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(1)) fu_alu_33673_33970 (.out1(out_ui_extract_bit_expr_FU_38_i0_fu_alu_33673_33970),
    .in1(in_port_opcode),
    .in2(out_const_2));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(2)) fu_alu_33673_33973 (.out1(out_ui_extract_bit_expr_FU_39_i0_fu_alu_33673_33973),
    .in1(in_port_opcode),
    .in2(out_const_3));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(2)) fu_alu_33673_33976 (.out1(out_ui_extract_bit_expr_FU_40_i0_fu_alu_33673_33976),
    .in1(in_port_opcode),
    .in2(out_const_14));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(1)) fu_alu_33673_33981 (.out1(out_ui_extract_bit_expr_FU_42_i0_fu_alu_33673_33981),
    .in1(in_port_opcode),
    .in2(out_const_0));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(1)) fu_alu_33673_33984 (.out1(out_ui_extract_bit_expr_FU_43_i0_fu_alu_33673_33984),
    .in1(in_port_opcode),
    .in2(out_const_2));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(2)) fu_alu_33673_33987 (.out1(out_ui_extract_bit_expr_FU_44_i0_fu_alu_33673_33987),
    .in1(in_port_opcode),
    .in2(out_const_3));
  ui_extract_bit_expr_FU #(.BITSIZE_in1(8),
    .BITSIZE_in2(2)) fu_alu_33673_33990 (.out1(out_ui_extract_bit_expr_FU_45_i0_fu_alu_33673_33990),
    .in1(in_port_opcode),
    .in2(out_const_14));
  register_STD #(.BITSIZE_in1(32),
    .BITSIZE_out1(32)) reg_0 (.out1(out_reg_0_reg_0),
    .clock(clock),
    .reset(reset),
    .in1(out_ui_cond_expr_FU_32_32_32_32_55_i6_fu_alu_33673_33851),
    .wenable(wrenable_reg_0));
  // io-signal post fix
  assign return_port = out_MUX_7_gimple_return_FU_50_i0_0_0_0;
  assign OUT_MULTIIF_alu_33673_33804 = out_multi_read_cond_FU_49_i0_fu_alu_33673_33804;

endmodule

// FSM based controller description for alu
// This component has been derived from the input source code and so it does not fall under the copyright of PandA framework, but it follows the input source code copyright, and may be aggregated with components of the BAMBU/PANDA IP LIBRARY.
// Author(s): Component automatically generated by bambu
// License: THIS COMPONENT IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
`timescale 1ns / 1ps
module controller_alu(done_port,
  selector_MUX_7_gimple_return_FU_50_i0_0_0_0,
  wrenable_reg_0,
  OUT_MULTIIF_alu_33673_33804,
  clock,
  reset,
  start_port);
  // IN
  input OUT_MULTIIF_alu_33673_33804;
  input clock;
  input reset;
  input start_port;
  // OUT
  output done_port;
  output selector_MUX_7_gimple_return_FU_50_i0_0_0_0;
  output wrenable_reg_0;
  parameter [2:0] S_0 = 3'b001,
    S_2 = 3'b100,
    S_1 = 3'b010;
  reg [2:0] _present_state=S_0, _next_state;
  reg done_port;
  reg selector_MUX_7_gimple_return_FU_50_i0_0_0_0;
  reg wrenable_reg_0;
  
  always @(posedge clock)
    if (reset == 1'b0) _present_state <= S_0;
    else _present_state <= _next_state;
  
  always @(*)
  begin
    done_port = 1'b0;
    selector_MUX_7_gimple_return_FU_50_i0_0_0_0 = 1'b0;
    wrenable_reg_0 = 1'b0;
    case (_present_state)
      S_0 :
        if(start_port == 1'b1)
        begin
          wrenable_reg_0 = 1'b1;
          casez (OUT_MULTIIF_alu_33673_33804)
            1'b1 :
              begin
                _next_state = S_1;
                done_port = 1'b1;
                wrenable_reg_0 = 1'b0;
              end
            default:
              begin
                _next_state = S_2;
                done_port = 1'b1;
              end
          endcase
        end
        else
        begin
          _next_state = S_0;
        end
      S_2 :
        begin
          selector_MUX_7_gimple_return_FU_50_i0_0_0_0 = 1'b1;
          _next_state = S_0;
        end
      S_1 :
        begin
          _next_state = S_0;
        end
      default :
        begin
          _next_state = S_0;
        end
    endcase
  end
endmodule

// This component is part of the BAMBU/PANDA IP LIBRARY
// Copyright (C) 2004-2022 Politecnico di Milano
// Author(s): Marco Lattuada <marco.lattuada@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module flipflop_AR(clock,
  reset,
  in1,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_out1=1;
  // IN
  input clock;
  input reset;
  input in1;
  // OUT
  output out1;
  
  reg reg_out1 =0;
  assign out1 = reg_out1;
  always @(posedge clock )
    if (reset == 1'b0)
      reg_out1 <= {BITSIZE_out1{1'b0}};
    else
      reg_out1 <= in1;
endmodule

// Top component for alu
// This component has been derived from the input source code and so it does not fall under the copyright of PandA framework, but it follows the input source code copyright, and may be aggregated with components of the BAMBU/PANDA IP LIBRARY.
// Author(s): Component automatically generated by bambu
// License: THIS COMPONENT IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
`timescale 1ns / 1ps
module _alu(clock,
  reset,
  start_port,
  done_port,
  a,
  b,
  opcode,
  return_port);
  // IN
  input clock;
  input reset;
  input start_port;
  input [31:0] a;
  input [31:0] b;
  input [7:0] opcode;
  // OUT
  output done_port;
  output [31:0] return_port;
  // Component and signal declarations
  wire OUT_MULTIIF_alu_33673_33804;
  wire done_delayed_REG_signal_in;
  wire done_delayed_REG_signal_out;
  wire selector_MUX_7_gimple_return_FU_50_i0_0_0_0;
  wire wrenable_reg_0;
  
  controller_alu Controller_i (.done_port(done_delayed_REG_signal_in),
    .selector_MUX_7_gimple_return_FU_50_i0_0_0_0(selector_MUX_7_gimple_return_FU_50_i0_0_0_0),
    .wrenable_reg_0(wrenable_reg_0),
    .OUT_MULTIIF_alu_33673_33804(OUT_MULTIIF_alu_33673_33804),
    .clock(clock),
    .reset(reset),
    .start_port(start_port));
  datapath_alu Datapath_i (.return_port(return_port),
    .OUT_MULTIIF_alu_33673_33804(OUT_MULTIIF_alu_33673_33804),
    .clock(clock),
    .reset(reset),
    .in_port_a(a),
    .in_port_b(b),
    .in_port_opcode(opcode),
    .selector_MUX_7_gimple_return_FU_50_i0_0_0_0(selector_MUX_7_gimple_return_FU_50_i0_0_0_0),
    .wrenable_reg_0(wrenable_reg_0));
  flipflop_AR #(.BITSIZE_in1(1),
    .BITSIZE_out1(1)) done_delayed_REG (.out1(done_delayed_REG_signal_out),
    .clock(clock),
    .reset(reset),
    .in1(done_delayed_REG_signal_in));
  // io-signal post fix
  assign done_port = done_delayed_REG_signal_out;

endmodule

// This component is part of the BAMBU/PANDA IP LIBRARY
// Copyright (C) 2004-2022 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module ui_view_convert_expr_FU(in1,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  assign out1 = in1;
endmodule

// Minimal interface for function: alu
// This component has been derived from the input source code and so it does not fall under the copyright of PandA framework, but it follows the input source code copyright, and may be aggregated with components of the BAMBU/PANDA IP LIBRARY.
// Author(s): Component automatically generated by bambu
// License: THIS COMPONENT IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
`timescale 1ns / 1ps
module alu(clock,
  reset,
  start_port,
  a,
  b,
  opcode,
  done_port,
  return_port);
  // IN
  input clock;
  input reset;
  input start_port;
  input [31:0] a;
  input [31:0] b;
  input [7:0] opcode;
  // OUT
  output done_port;
  output [31:0] return_port;
  // Component and signal declarations
  wire [31:0] out_return_port_ui_view_convert_expr_FU;
  
  _alu _alu_i0 (.done_port(done_port),
    .return_port(out_return_port_ui_view_convert_expr_FU),
    .clock(clock),
    .reset(reset),
    .start_port(start_port),
    .a(a),
    .b(b),
    .opcode(opcode));
  ui_view_convert_expr_FU #(.BITSIZE_in1(32),
    .BITSIZE_out1(32)) return_port_ui_view_convert_expr_FU (.out1(return_port),
    .in1(out_return_port_ui_view_convert_expr_FU));

endmodule


