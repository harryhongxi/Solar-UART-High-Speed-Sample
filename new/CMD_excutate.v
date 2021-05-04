module  CMD_excutate(
    // Input Port
    input           I_clk,
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
    output  reg          O_excutate_valid,
    output  reg          O_tx_data_valid,
    output  reg  [ 7: 0] O_tx_data,
    output               O_tx_data_rd_ctrl,
    output  reg          O_state_rd_trig
);

parameter   SIDLE = 4'd0;
parameter   SHEAD = 4'd1;
parameter   SADDR = 4'd2;
parameter   SFUNC = 4'd3;
parameter   SLENT = 4'd4;
parameter   SDATA = 4'd5;
parameter   STAIL = 4'd6;

// state excutate
reg [ 3: 0] cstate;
reg [ 3: 0] nstate;

// cmd_code latch
reg [ 7: 0] cmd_code;

always@(posedge I_clk)
begin
    if(I_cmd_valid)
    begin
        cmd_code <= {4'b0, I_cmd_data};
    end
    else
    begin
        if (cstate == SIDLE)
        begin
            cmd_code <= 8'd0;
        end
        else
        begin
            cmd_code <= cmd_code;
        end
    end
end

always@(posedge I_clk)
begin
    cstate <= nstate;
end

// len_cnt generator
reg [ 1: 0] len_cnt = 2'b0;

always@(posedge I_clk)
begin
    if (nstate == SLENT)
    begin
        if (I_tx_data_ready && !O_tx_data_valid  && len_cnt < 2'd2)
        begin
            len_cnt <= len_cnt + 2'b1;
        end
        else
        begin
            len_cnt <= len_cnt;
        end
    end
    else
    begin
        len_cnt <= 2'b0;
    end
end

// frame_cnt generator
reg [15: 0] frame_cnt = 16'b0;
reg         frame_end = 1'b1;

always@(posedge I_clk)
begin
    if (cstate == SIDLE)
    begin
        frame_cnt <= 16'd0;
    end
    else
    begin
        if (cmd_code == 8'd3 && frame_cnt < I_trans_length && cstate == SFUNC && O_tx_data_valid)
        begin
            frame_cnt <= frame_cnt + 16'd1;
        end
        else
        begin
            frame_cnt <= frame_cnt;
        end
    end
end

always@(posedge I_clk)
begin
    if (frame_cnt >= I_trans_length || frame_cnt == 16'd0)
    begin
        frame_end <= 1'b1;
    end
    else
    begin
        frame_end <= 1'b0;
    end
end

// data_cnt generator
reg [15: 0] data_cnt = 16'b0;
reg [15: 0] data_length = 16'd2;

always@(posedge I_clk)
begin
    if (cmd_code == 8'd3)
    begin
        data_length <= 16'd2000;
    end
    else
    begin
        data_length <= 16'd2;
    end
end

always@(posedge I_clk)
begin
    if (nstate == SDATA)
    begin
        if (data_cnt < data_length)
        begin
            if (cmd_code != 8'd3 && I_tx_data_ready  && !O_tx_data_valid)
            begin
                data_cnt <= data_cnt + 16'b1;
            end
            else
            begin
                if (I_ddr_data_valid || (data_cnt[0] && I_tx_data_ready  && !O_tx_data_valid))
                begin
                    data_cnt <= data_cnt + 16'b1;
                end
                else
                begin
                    data_cnt <= data_cnt;
                end
            end
        end
        else
        begin
            data_cnt <= data_cnt;
        end
    end
    else
    begin
        data_cnt <= 16'b0;
    end
end

// O_tx_data_rd_ctrl generator
//always@(posedge I_clk)
//begin
//    if (nstate == SDATA && cmd_code == 8'd3 && I_tx_data_ready  && !O_tx_data_valid)
//    begin
//        O_tx_data_rd_ctrl <= 1'b1;
//    end
//    else
//    begin
//        O_tx_data_rd_ctrl <= 1'b0;
//    end
//end

assign  O_tx_data_rd_ctrl = (nstate == SDATA && cmd_code == 8'd3 && I_tx_data_ready  && !O_tx_data_valid)?((!data_cnt[0])?1:0):0;

// O_state_rd_trig generator
always@(posedge I_clk)
begin
    if (nstate == SHEAD && cmd_code == 8'd3)
    begin
        O_state_rd_trig <= 1'b1;
    end
    else
    begin
        O_state_rd_trig <= 1'b0;
    end
end

// uart_tx control excutate
always@(posedge I_clk)
begin
    case (nstate)
        SIDLE: 
        begin
            O_tx_data <= 8'h00;
            O_tx_data_valid <= 1'b0;
        end
        SHEAD: 
        begin
            if (I_tx_data_ready & !O_tx_data_valid)
            begin
                O_tx_data <= 8'hF0;
                O_tx_data_valid <= 1'b1;
            end
            else
            begin
                O_tx_data <= 8'h00;
                O_tx_data_valid <= 1'b0;
            end
        end
        SADDR: 
        begin
            if (I_tx_data_ready & !O_tx_data_valid)
            begin
                O_tx_data <= I_device_addr;
                O_tx_data_valid <= 1'b1;
            end
            else
            begin
                O_tx_data <= 8'h00;
                O_tx_data_valid <= 1'b0;
            end
        end
        SFUNC: 
        begin
            if (I_tx_data_ready & !O_tx_data_valid)
            begin
                O_tx_data <= cmd_code;
                O_tx_data_valid <= 1'b1;
            end
            else
            begin
                O_tx_data <= 8'h00;
                O_tx_data_valid <= 1'b0;
            end
        end
        SLENT: 
        begin
            if (I_tx_data_ready & !O_tx_data_valid)
            begin
                case (len_cnt)
                    2'd0:
                    begin
                        O_tx_data <= frame_cnt[15:8];
                        O_tx_data_valid <= 1'b1;
                    end
                    2'd1: 
                    begin
                        O_tx_data <= frame_cnt[7:0];
                        O_tx_data_valid <= 1'b1;
                    end
                    default: 
                    begin
                        O_tx_data <= 8'h00;
                        O_tx_data_valid <= 1'b0;
                    end
                endcase
            end
            else
            begin
                O_tx_data <= 8'h00;
                O_tx_data_valid <= 1'b0;
            end
        end
        SDATA: // this part should be modified according to the uart_tx test case
        begin
            case (cmd_code)
                8'd1: //cmd_sampling_rate_check
                begin
                    if (I_tx_data_ready  && !O_tx_data_valid)
                    case (data_cnt[1:0])
                        2'd0:
                        begin
                            O_tx_data <= I_sampling_rate[15:8];
                            O_tx_data_valid <= 1'b1;
                        end
                        2'd1: 
                        begin
                            O_tx_data <= I_sampling_rate[7:0];
                            O_tx_data_valid <= 1'b1;
                        end
                        default: 
                        begin
                            O_tx_data <= 8'h00;
                            O_tx_data_valid <= 1'b0;
                        end
                    endcase
                    else
                    begin
                        O_tx_data <= 8'h00;
                        O_tx_data_valid <= 1'b0;
                    end
                end
                8'd2: //cmd_sampling_num_check
                begin
                    if (I_tx_data_ready  && !O_tx_data_valid)
                    begin
                        case (data_cnt[1:0])
                            2'd0:
                            begin
                                O_tx_data <= I_sampling_num[15:8];
                                O_tx_data_valid <= 1'b1;
                            end
                            2'd1: 
                            begin
                                O_tx_data <= I_sampling_num[7:0];
                                O_tx_data_valid <= 1'b1;
                            end
                            default: 
                            begin
                                O_tx_data <= 8'h00;
                                O_tx_data_valid <= 1'b0;
                            end
                        endcase
                    end
                    else
                    begin
                        O_tx_data <= 8'h00;
                        O_tx_data_valid <= 1'b0;
                    end
                end
                8'd3: //cmd_data_reply
                begin
                    if (I_ddr_data_valid || (data_cnt[0] && I_tx_data_ready  && !O_tx_data_valid))
                    begin
                        if (!data_cnt[0])
                        begin
                            O_tx_data <= I_ddr_data[15:8];
                        end
                        else
                        begin
                            O_tx_data <= I_ddr_data[7:0];
                        end
                        O_tx_data_valid <= 1'b1;
                    end
                    else
                    begin
                        O_tx_data <= 8'b0;
                        O_tx_data_valid <= 1'b0;
                    end
                end
                8'd4: // cmd_addr_check
                begin
                    if (I_tx_data_ready  && !O_tx_data_valid)
                    begin
                        case (data_cnt[1:0])
                            2'd0:
                            begin
                                O_tx_data <= 8'd0;
                                O_tx_data_valid <= 1'b1;
                            end
                            2'd1: 
                            begin
                                O_tx_data <= I_device_addr;
                                O_tx_data_valid <= 1'b1;
                            end
                            default: 
                            begin
                                O_tx_data <= 8'h00;
                                O_tx_data_valid <= 1'b0;
                            end
                        endcase
                    end
                    else
                    begin
                        O_tx_data <= 8'b0;
                        O_tx_data_valid <= 1'b0;
                    end
                end
                default:
                begin
                    O_tx_data <= 8'h00;
                    O_tx_data_valid <= 1'b0;
                end
            endcase
        end
        STAIL: 
        begin
            if (I_tx_data_ready & !O_tx_data_valid)
            begin
                O_tx_data <= 8'hFF;
                O_tx_data_valid <= 1'b1;
            end
            else
            begin
                O_tx_data <= 8'h00;
                O_tx_data_valid <= 1'b0;
            end
        end
        default: 
        begin
            O_tx_data <= 8'h00;
            O_tx_data_valid <= 1'b0;
        end
    endcase
end

// state change
always@(cstate or I_cmd_valid or I_tx_data_ready or O_tx_data_valid or len_cnt or data_cnt or frame_end or cmd_code or data_length)
begin
    case (cstate)
        SIDLE: 
        begin
            if(I_cmd_valid)
            begin
                nstate = SHEAD;
            end
            else
            begin
                nstate = SIDLE;
            end
        end
        SHEAD:
        begin
            if(I_tx_data_ready & !O_tx_data_valid)
            begin
                nstate = SADDR;
            end
            else
            begin
                nstate = SHEAD;
            end
        end
        SADDR:
        begin
            if(I_tx_data_ready & !O_tx_data_valid)
            begin
                nstate = SFUNC;
            end
            else
            begin
                nstate = SADDR;
            end
        end
        SFUNC:
        begin
            if(I_tx_data_ready & !O_tx_data_valid)
            begin
                if(cmd_code == 8'd3)
                begin
                    nstate = SLENT;
                end
                else
                begin
                    nstate = SDATA;
                end
            end
            else
            begin
                nstate = SFUNC;
            end
        end
        SLENT:
        begin
            if(I_tx_data_ready && (len_cnt == 2'd2) && !O_tx_data_valid)
            begin
                nstate = SDATA;
            end
            else
            begin
                nstate = SLENT;
            end
        end
        SDATA:
        begin
            if(I_tx_data_ready && (data_cnt == data_length) && !O_tx_data_valid)
            begin
                nstate = STAIL;
            end
            else
            begin
                nstate = SDATA;
            end
        end
        STAIL:
        begin
            if(I_tx_data_ready & !O_tx_data_valid)
            begin
                if(cmd_code == 8'd3 && !frame_end)
                begin
                    nstate = SHEAD;
                end
                else
                begin
                    nstate = SIDLE;
                end
            end
            else
            begin
                nstate = STAIL;
            end
        end
        default: 
        begin
            nstate <= SIDLE;
        end
    endcase
end

// O_excutate_valid generateor
always@(posedge I_clk)
begin
    if(I_cmd_valid)
    begin
        O_excutate_valid <= 1'b0;
    end
    else
    begin
        if(cstate == SIDLE)
        begin
            O_excutate_valid <= 1'b1;
        end
        else
        begin
            O_excutate_valid <= 1'b0;
        end
    end
end

ila_0   ila_0_inst
(
    .clk(I_clk),
    .probe0(cstate),
    .probe1(nstate),
    .probe2(data_cnt),
    .probe3(frame_cnt),
    .probe4(cmd_code),
    .probe5(O_tx_data),
    .probe6(O_tx_data_valid),
    .probe7(I_tx_data_ready),
    .probe8(O_excutate_valid),
    .probe9(frame_end),
    .probe10(I_ddr_data_valid),
    .probe11(I_ddr_data)
);

endmodule