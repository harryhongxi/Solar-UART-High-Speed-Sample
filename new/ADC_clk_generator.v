module  ADC_clk_generator(
    // input
    input           I_clk,  // I_clk here is assumed to be 200MHz
    input   [15: 0] I_sampling_rate_setting,
    input           I_sampling_rate_valid,
    // output
    output          O_adc_clk,
    output  reg     O_adc_data_valid
);

// clock count setting
reg [ 7: 0] cnt_max = 8'd4;

always@(posedge I_clk)
begin
    if (I_sampling_rate_valid)
    begin
        case (I_sampling_rate_setting[8:0])
            9'd1: // 1MSPS
            begin
                cnt_max <= 8'd99; 
            end
            9'd2: // 2MSPS
            begin
                cnt_max <= 8'd49;
            end
            9'd3: // 5MSPS
            begin
                cnt_max <= 8'd19;
            end
            9'd4: // 10MSPS
            begin
                cnt_max <= 8'd9;
            end
            9'd5: // 20MSPS
            begin
                cnt_max <= 8'd4;
            end
            9'd6: // 50MSPS
            begin
                cnt_max <= 8'd1;
            end
            default:
            begin
                cnt_max <= cnt_max;
            end 
        endcase
    end
    else
    begin
        cnt_max <= cnt_max;
    end
end

// adc clock generator
reg [ 7: 0] clk_cnt = 8'd0;
reg [ 0: 0] clk_pos = 1'b1;
always@(posedge I_clk)
begin
    if (clk_cnt == cnt_max)
    begin
        clk_cnt <= 8'b0;
    end
    else
    begin
        clk_cnt <= clk_cnt + 8'b1;
    end
end

always@(posedge I_clk)
begin
    if (clk_cnt == cnt_max)
    begin
        clk_pos <= ~clk_pos;
    end
    else
    begin
        clk_pos <= clk_pos;
    end
end

assign O_adc_clk = clk_pos;

// read adc data flag generator

always@(posedge I_clk)
begin
    if (!clk_pos && clk_cnt == 8'b0)
    begin
        O_adc_data_valid <= 1'b1;
    end
    else
    begin
        O_adc_data_valid <= 1'b0;
    end
end

endmodule
