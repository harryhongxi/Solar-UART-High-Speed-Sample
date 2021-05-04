// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.4 (win64) Build 2086221 Fri Dec 15 20:55:39 MST 2017
// Date        : Sun Jan 10 14:28:00 2021
// Host        : Harry-PC running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub {g:/Liu
//               Task/ddr3/s7_ddr3_testMINE/Project/ddr3_test.srcs/sources_1/ip/fifo_cmd/fifo_cmd_stub.v}
// Design      : fifo_cmd
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35tftg256-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_1,Vivado 2017.4" *)
module fifo_cmd(clk, srst, din, wr_en, rd_en, dout, full, empty)
/* synthesis syn_black_box black_box_pad_pin="clk,srst,din[2:0],wr_en,rd_en,dout[2:0],full,empty" */;
  input clk;
  input srst;
  input [2:0]din;
  input wr_en;
  input rd_en;
  output [2:0]dout;
  output full;
  output empty;
endmodule
