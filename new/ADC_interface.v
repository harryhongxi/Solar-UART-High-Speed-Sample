module  ADC_interface(
    // input
    input           I_clk,  // I_clk here is assumed to be 200MHz
    input   [11: 0] I_data_we,
    input           I_clk_rd,
    input           I_rst_n,
    input   [15: 0] I_sampling_rate_setting,
    input           I_sampling_rate_valid,
    // output
    output          O_adc_clk,
    output  [ 0: 0] O_data_rd_valid,
    output  [11: 0] O_data_rd
);

wire adc_data_valid;

reg [15: 0] sampling_rate_setting;
reg [ 0: 0] sampling_rate_valid;

always@(posedge I_clk)
begin
    sampling_rate_setting <= I_sampling_rate_setting;
end

always@(posedge I_clk)
begin
    sampling_rate_valid <= I_sampling_rate_valid;
end

ADC_clk_generator ADC_clk_generator_inst0
(
    // input
    .I_clk                      (I_clk                      ),
    .I_sampling_rate_setting    (sampling_rate_setting       ),
    .I_sampling_rate_valid      (sampling_rate_valid          ),
    // output
    .O_adc_clk                  (O_adc_clk                  ),
    .O_adc_data_valid           (adc_data_valid             )
);

ADC_data_buffer ADC_data_buffer_inst0
(
    // input
    .I_clk_we                   (I_clk                      ),
    .I_data_we_valid            (adc_data_valid             ),
    .I_data_we                  (I_data_we                  ),
    .I_clk_rd                   (I_clk_rd                   ),
    .I_rst_n                    (I_rst_n                    ),
    // output
    .O_data_rd_valid            (O_data_rd_valid            ),
    .O_data_rd                  (O_data_rd                  )
);

endmodule