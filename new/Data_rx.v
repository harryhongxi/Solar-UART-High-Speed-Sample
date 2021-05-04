`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/09 11:18:23
// Design Name: 
// Module Name: Data_rx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Data_rx(
    input clk,
    input rst_n,
    input rx_pin,
    output [1:0]  o_AD_state_query,
    output [15:0] o_sampling_rate_conf,
    output [15:0] o_sampling_point_conf,
    output        o_data_return,
    output        o_addr_inquiry,
    output [2:0]  o_func,
    output o_data_check_en,
    output [7:0]o_addr,
    output o_sampling_rate_conf_en,
    output o_sampling_point_conf_en
    );
    wire uart_en;
    wire rx_en;
    wire [7:0]rx_data; 
    wire [47:0]flame;
    wire flame_en;
    wire [2:0]flame_cnt;
    wire    uart_cnt_valid;
    wire data_check_en;
    wire data_check_en_t;
    
  en_uart_rx en_uart_rx(
  .clk(clk),
  .i_sample_valid(uart_cnt_valid),
  .o_SAMPLE_EN(uart_en)
  );
    
  uart_rx uart_rx(
  .clk(clk),
  .i_SAMPLE_EN(uart_en),
  .i_RX_B(rx_pin),   
  .o_RX_en(rx_en),
  .o_RX_word(rx_data),
  .o_sample_valid(uart_cnt_valid)
  );  
  
  data_combine data_combine(
      . clk(clk),
      . rst_n(rst_n),
      . rxd_data(rx_data),
      . rx_en(rx_en),
      . data_o(flame),
      . data_en(flame_en),
      .o_flmae_cnt(flame_cnt)
      );
    
   data_check(
          . clk(clk),
          . rst_n(rst_n),
          . data_in(flame),
          . data_en(flame_en),
          . o_AD_state_query(o_AD_state_query),
          . o_sampling_rate_conf(o_sampling_rate_conf),
          . o_sampling_point_conf(o_sampling_point_conf),
          . o_data_return(o_data_return),
          . o_addr_inquiry(o_addr_inquiry),
          . o_func(o_func),
          . o_data_check_en(o_data_check_en),
          . o_addr(o_addr),
          . o_sampling_rate_conf_en(o_sampling_rate_conf_en),
          . o_sampling_point_conf_en(o_sampling_point_conf_en),
          .	data_check_en(data_check_en),
          . data_check_en_t(data_check_en_t)
          ); 
    
    ila_data_rx ila_data_rx(
    .clk(clk),
    .probe0(uart_en),
    .probe1(rx_en),
    .probe2(rx_data),
    .probe3(flame_en),
    .probe4(flame),
    .probe5(o_AD_state_query),
    .probe6(o_addr_inquiry),
    .probe7(o_data_check_en),
    .probe8(o_data_return),
    .probe9(o_func),
    .probe10(o_sampling_point_conf),
    .probe11(o_sampling_rate_conf),
    .probe12(rx_pin),
    .probe13(flame_cnt),
    .probe14(data_check_en),
    .probe15(data_check_en_t)
    );
endmodule
