module  CMD_queue(
    // Input Port
    input           I_clk,
    input           I_rst_n,
    input           I_cmd_valid,
    input   [ 2: 0] I_cmd_data,
    input           I_excutate_valid,
    // Output Port
    output  reg         O_cmd_valid,
    output      [ 2: 0] O_cmd_data
);

// srst generator
reg rst_n_tmp = 1'b1;
reg fifo_srst = 1'b0;

always@(posedge I_clk)
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

// CMD FIFO WE Logic init.
reg         fifo_we = 1'b0;
reg [ 2: 0] fifo_we_data;

always@(posedge I_clk)
begin
    if (I_cmd_valid)
    begin
        fifo_we <= 1'b1;
        fifo_we_data <= I_cmd_data;
    end
    else
    begin
        fifo_we <= 1'b0;
        fifo_we_data <= 3'b0;
    end
end

// CMD FIFO 
wire            rd_empty;
wire [ 2: 0]    rd_data;
wire            we_full;
wire            fifo_rd;
fifo_cmd    fifo_cmd_inst0
(
    .clk        (I_clk              ),
    .srst       (fifo_srst          ),
    .din        (fifo_we_data       ),
    .wr_en      (fifo_we            ),
    .rd_en      (fifo_rd            ),
    .dout       (rd_data            ),
    .full       (we_full            ),
    .empty      (rd_empty           )
);

// CMD FIFO RD Logic init.

assign  fifo_rd = I_excutate_valid & !rd_empty;

// always@(posedge I_clk)
// begin
//     if(I_excutate_valid & !rd_empty)
//     begin
//         fifo_rd <= 1'b1;
//     end
//     else
//     begin
//         fifo_rd <= 1'b0;
//     end
// end

always@(posedge I_clk)
begin
    if (fifo_rd)
    begin
        O_cmd_valid <= 1'b1;
    end
    else
    begin
        O_cmd_valid <= 1'b0;
    end
end

reg fifo_rd_tmp = 1'b0;

always@(posedge I_clk)
begin
    fifo_rd_tmp <= fifo_rd;
end

assign O_cmd_data = fifo_rd_tmp?rd_data:3'b0;

//ila_1   ila_1_inst
//(
//    .clk(I_clk),
//    .probe0(fifo_we_data),
//    .probe1(fifo_we),
//    .probe2(rd_data),
//    .probe3(fifo_rd),
//    .probe4(rd_empty),
//    .probe5(O_cmd_data),
//    .probe6(O_cmd_valid),
//    .probe7(I_cmd_data),
//    .probe8(I_cmd_valid),
//    .probe9(I_excutate_valid)
//);

endmodule