module  data2ddr_buffer(
    // input
    input   [ 0: 0]     I_clk,
    input   [ 0: 0]     I_rst,
    input   [ 0: 0]     I_data_valid,
    input   [11: 0]     I_data,
    input   [24: 0]     I_we_point_conf,
    input               I_ddr_sended_flag,
    // output
    output  [ 0: 0]     O_data_rd_sig,  // O_data_rd_sig is ahead before the corresponding data by 1 clock.
    output  [11: 0]     O_data_rd
);

// we_valid & we_data generator according to the number of I_we_point_conf
reg     [24: 0] we_cnt      =   25'b0;
reg     [ 0: 0] we_valid    =   1'b0;
//reg     [11: 0] we_data     =   12'b0;

//always @(posedge I_clk)
//begin
//     we_data     <=  I_data;
////     we_data     <=  we_cnt + 25'b1;
//end

always @(posedge I_clk)
begin
    if (I_rst)
    begin
        we_cnt      <=  25'b0;
        we_valid    <=  1'b0;
    end
    else
    begin
        if (we_cnt < I_we_point_conf)
        begin
            if (I_data_valid)
            begin
                we_cnt      <=  we_cnt + 25'b1;
                we_valid    <=  1'b1;
            end
            else
            begin
                we_cnt      <=  we_cnt;
                we_valid    <=  1'b0;
            end
        end
        else
        begin
            we_cnt      <=  we_cnt;
            we_valid    <=  1'b0;
        end
    end
end
    
//  O_data_rd_valid & O_data_rd generator
reg     [ 5: 0] rd_cnt      =   6'b0;
reg     [ 0: 0] rd_cnt_zero =   1'b1;
wire    [ 0: 0] rd_valid;
wire    [ 0: 0] wr_rst_busy;
wire    [ 0: 0] rd_rst_busy;
wire    [ 0: 0] rd_empty;
wire    [ 0: 0] we_full;

assign  rd_valid    =   (rd_cnt_zero) ? (!rd_empty) : (!rd_empty)&I_ddr_sended_flag;

always @(posedge I_clk) 
begin
    if (I_rst)
    begin
        rd_cnt      <=  25'b0;
        rd_cnt_zero <=  1'b1;
    end
    else
    begin
        case ({rd_valid, I_ddr_sended_flag})
            2'b00:  
            begin
                rd_cnt      <=  rd_cnt;
                rd_cnt_zero <=  rd_cnt_zero;
            end
            2'b01:  
            begin
                if (rd_cnt > 6'b1)
                begin
                    rd_cnt      <=  6'b0;
                    rd_cnt_zero <=  1'b0;
                end
                else
                begin
                    rd_cnt      <=  rd_cnt - 6'b1;
                    rd_cnt_zero <=  1'b1;
                end
            end
            2'b10:
            begin
                if (rd_cnt == 6'b11_1111) 
                begin
                    rd_cnt      <=  rd_cnt;
                    rd_cnt_zero <=  1'b0;
                end
                else
                begin
                    rd_cnt      <=  rd_cnt + 6'b1;
                    rd_cnt_zero <=  1'b0;
                end
            end  
            2'b11:
            begin
                rd_cnt      <=  rd_cnt;
                rd_cnt_zero <=  rd_cnt_zero;
            end  
        endcase
    end
end

assign  O_data_rd_sig       =  rd_valid;


// data2ddr_fifo
data2ddr_fifo    data2ddr_fifo_inst0
(
    .clk        (I_clk              ),
    .srst       (I_rst              ),
    .din        (I_data             ),
    .wr_en      (we_valid           ),
    .rd_en      (rd_valid           ),
    .dout       (O_data_rd          ),
    .full       (we_full            ),
    .empty      (rd_empty           )
);

ila_2     ila_2_inst0 
(
    .clk        (I_clk              ), 
    .probe0     (rd_valid           ),
    .probe1     (rd_empty           ),
    .probe2     (I_ddr_sended_flag  ),
    .probe3     (rd_cnt_zero        ),
    .probe4     (O_data_rd_sig      ),
    .probe5     (O_data_rd          )
);

endmodule