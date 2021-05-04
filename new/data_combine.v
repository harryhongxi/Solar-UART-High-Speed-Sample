`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/08 22:34:05
// Design Name: 
// Module Name: data_combine
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


module data_combine(
	input clk,
	input rst_n,
	input [7:0]rxd_data,
	input rx_en,
	output [47:0]data_o,
	output data_en,
	output [2:0] o_flmae_cnt
    );


reg [47:0] data_temp;
reg [2:0]  flmae_cnt;
reg rx_en_t;
reg rx_en_tt;
reg combine_finish;
wire rx_en_flag;


always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)begin
		rx_en_t <= 1'b0;
		rx_en_tt <= 1'b0;end
	else begin
		rx_en_t <= rx_en;
		rx_en_tt <= rx_en_t;end
end

reg	[26: 0]	watchdog_cnt = 27'b0;
reg [ 0: 0]	watchdog_rst = 1'b0;
always @(posedge clk) 
begin
	if (rx_en_flag)
	begin
		watchdog_cnt	<=	27'b0;
		watchdog_rst	<=	1'b0;
	end
	else
	begin
		if (watchdog_cnt < 27'd10_000_000)
		begin
			watchdog_cnt	<=	watchdog_cnt + 1'b1;
			watchdog_rst	<=	1'b0;
		end
		else
		begin
			watchdog_cnt	<=	watchdog_cnt;
			watchdog_rst	<=	1'b1;
		end
	end
end

//assign rx_en_flag = ({rx_en_t,rx_en} == 2'b01)? 1:0;
assign  rx_en_flag =  rx_en;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		flmae_cnt <= 3'b0;
	else
	begin
		if (rx_en_flag)
		begin
			if (flmae_cnt < 3'd5)
				flmae_cnt <= flmae_cnt + 3'b1;			
		    else 
			    flmae_cnt <= 3'b0;
		end	
		else 
			flmae_cnt <= watchdog_rst ? 1'b0 : flmae_cnt;	
	end		
end


always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		data_temp <= 48'b0;
	else
	   if (rx_en_flag)
	   begin
            case(flmae_cnt)
                0: data_temp[47:40] <= rxd_data;
                1: data_temp[39:32] <= rxd_data;
                2: data_temp[31:24] <= rxd_data;
                3: data_temp[23:16] <= rxd_data;
                4: data_temp[15:8]  <= rxd_data;
                5: data_temp[7:0]   <= rxd_data;
                default: data_temp <= data_temp;
             endcase
	   end	
       else
          data_temp <= data_temp;	
end

//always@(flmae_cnt)
//begin
//		case(flmae_cnt)
//			0: data_temp[47:40] = rxd_data;
//			1: data_temp[39:32] = rxd_data;
//			2: data_temp[31:24] = rxd_data;
//			3: data_temp[23:16] = rxd_data;
//			4: data_temp[15:8]  = rxd_data;
//			5: data_temp[7:0]   = rxd_data;
//			default: data_temp  = data_temp;
//	     endcase
//end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		combine_finish <= 1'b0;
	else begin
		if (rx_en_flag && flmae_cnt == 3'd5)
			combine_finish <= 1'b1;
		else
			combine_finish <= 1'b0;
	end
end

assign data_en = combine_finish;
assign data_o = data_temp;
assign o_flmae_cnt = flmae_cnt;

endmodule