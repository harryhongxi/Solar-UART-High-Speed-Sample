module  ADC_data_buffer(
    // input
    input           I_clk_we,   // I_clk here is assumed to be 200MHz
    input           I_data_we_valid,
    input   [11: 0] I_data_we,
    input           I_clk_rd,
    input           I_rst_n,
    // output
    output  reg [ 0: 0] O_data_rd_valid,
    output      [11: 0] O_data_rd
);

// srst generator
reg rst_n_tmp = 1'b1;
reg fifo_srst = 1'b0;

always@(posedge I_clk_we)
begin
    rst_n_tmp <= I_rst_n;
    if (!rst_n_tmp & I_rst_n)
    begin
        fifo_srst <= 1'b1;
    end
    else
    begin
        fifo_srst <= 1'b0;
    end
end


// adc data fifo
wire wr_rst_busy;
wire rd_rst_busy;
wire rd_empty;
wire we_full;

adc_data_fifo   adc_data_fifo_inst0
(
    .rst(fifo_srst),
    .wr_clk(I_clk_we),
    .rd_clk(I_clk_rd),
    .din(I_data_we),
    .wr_en(I_data_we_valid),
    .rd_en(!rd_empty),
    .dout(O_data_rd),
    .full(we_full),
    .empty(rd_empty),
    .wr_rst_busy(wr_rst_busy),
    .rd_rst_busy(rd_rst_busy)
);

always@(posedge I_clk_rd)
begin
    O_data_rd_valid <=  !rd_empty;
end

endmodule