// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.4 (win64) Build 2086221 Fri Dec 15 20:55:39 MST 2017
// Date        : Mon Feb  1 22:32:22 2021
// Host        : Harry-PC running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub {G:/Liu
//               Task/ddr3_v2_1/ddr3/s7_ddr3_testMINE/Project/ddr3_test.srcs/sources_1/ip/ila_data_source/ila_data_source_stub.v}
// Design      : ila_data_source
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35tftg256-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "ila,Vivado 2017.4" *)
module ila_data_source(clk, probe0, probe1, probe2, probe3, probe4, probe5, 
  probe6, probe7, probe8, probe9)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[3:0],probe1[24:0],probe2[0:0],probe3[0:0],probe4[0:0],probe5[15:0],probe6[0:0],probe7[0:0],probe8[15:0],probe9[15:0]" */;
  input clk;
  input [3:0]probe0;
  input [24:0]probe1;
  input [0:0]probe2;
  input [0:0]probe3;
  input [0:0]probe4;
  input [15:0]probe5;
  input [0:0]probe6;
  input [0:0]probe7;
  input [15:0]probe8;
  input [15:0]probe9;
endmodule
