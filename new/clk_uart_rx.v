`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/09 11:14:54
// Design Name: 
// Module Name: clk_uart_rx
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








module en_uart_rx(
	input				clk,
	input               i_sample_valid,
	output	reg	        o_SAMPLE_EN
);

localparam                       i_RATE = 100 * 1000000 / 115200;//一个符号对应几个时钟周期

reg	[19:0]	cnt_clk = 20'd0;
always@(posedge clk)
begin
	if(!cnt_clk)
	begin
		o_SAMPLE_EN <= 1'b1;
	end
	else
	begin
		o_SAMPLE_EN <= 1'b0;
	end
end	

always@(posedge clk)
begin
    if (i_sample_valid)
    begin
        cnt_clk <= {i_RATE[19], i_RATE[19:1]};
    end
    else
    begin
        if(cnt_clk < (i_RATE-20'b1))
        begin
            cnt_clk <= cnt_clk + 20'b1;
        end
        else
        begin
            cnt_clk <= 20'b0;
        end
    end
end
endmodule 