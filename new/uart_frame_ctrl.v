module  uart_frame_ctrl(
    // Input Port
    input           I_clk,
    input           I_rst_n,
    input           I_cmd_valid,
    input   [ 2: 0] I_cmd_data,
    input           I_ddr_data_valid,
    input   [15: 0] I_ddr_data,
    input           I_tx_data_ready,
    input   [ 7: 0] I_device_addr,
    input   [15: 0] I_trans_length,
    input   [15: 0] I_sampling_rate,
    input   [15: 0] I_sampling_num,
    // Output Port
    output          O_tx_data_valid,
    output  [ 7: 0] O_tx_data,
    output          O_tx_data_rd_ctrl,
    output          O_state_rd_trig
);

wire                excutate_valid;
wire                tx_cmd_valid;
wire    [ 2: 0]     tx_cmd_data;

CMD_queue   CMD_queue_inst0
(
    // Input Port
    .I_clk              (I_clk              ),
    .I_rst_n            (I_rst_n            ),
    .I_cmd_valid        (I_cmd_valid        ),
    .I_cmd_data         (I_cmd_data         ),
    .I_excutate_valid   (excutate_valid     ),
    // Output Port
    .O_cmd_valid        (tx_cmd_valid       ),
    .O_cmd_data         (tx_cmd_data        )
);

CMD_excutate    CMD_excutate_inst0
(
    // Input Port
    .I_clk              (I_clk              ),
    .I_cmd_valid        (tx_cmd_valid       ),
    .I_cmd_data         (tx_cmd_data        ),
    .I_ddr_data_valid   (I_ddr_data_valid   ),
    .I_ddr_data         (I_ddr_data         ),
    .I_tx_data_ready    (I_tx_data_ready    ),
    .I_device_addr      (I_device_addr      ),
    .I_trans_length     (I_trans_length     ),
    .I_sampling_rate    (I_sampling_rate    ),
    .I_sampling_num     (I_sampling_num     ),
    // Output Port
    .O_excutate_valid   (excutate_valid     ),
    .O_tx_data_valid    (O_tx_data_valid    ),
    .O_tx_data          (O_tx_data          ),
    .O_tx_data_rd_ctrl  (O_tx_data_rd_ctrl  ),
    .O_state_rd_trig    (O_state_rd_trig    )
);

endmodule
