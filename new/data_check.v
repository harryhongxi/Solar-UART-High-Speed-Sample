module data_check(
	input clk,
	input rst_n,
	input [47:0]data_in,
	input data_en,
	output [1:0]  o_AD_state_query,
	output [15:0] o_sampling_rate_conf,
	output [15:0] o_sampling_point_conf,
	output 		  o_data_return,
	output        o_addr_inquiry,
	output [2:0] o_func,
	output  reg o_data_check_en,
	output [7:0]o_addr,
	output reg o_sampling_rate_conf_en,
	output reg o_sampling_point_conf_en,
	output reg data_check_en,
    output reg data_check_en_t
    );

//localparam       HEAD         = h'F0;
//localparam       ADDRESS      = h'A5;//start bit
//localparam       S_SEND_BYTE  = 3;//data bits
//localparam       S_STOP       = 4;//stop bit
localparam       local_addr       = 03;

	
reg [47:0] data_rx;
reg [7:0]  i_addr;
reg [7:0]  head;
reg [7:0]  func;
reg [15:0] data_2byte;
reg [7:0]  tail;
reg [1:0]  AD_state_query;
reg [15:0] sampling_rate_conf;
reg [15:0] sampling_point_conf;
reg data_return;
reg addr_inquiry;
//reg data_check_en;
//reg data_check_en_t;
reg data_check_en_tt;
reg data_check_en_ttt;
reg  [47:0]data_rx_t;
reg [7:0] fun_t;

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		data_rx <= 48'b0;
		data_check_en <= 1'b0;end
	else begin
		if(data_en) begin
			data_check_en <= 1'b1;
			data_rx <= data_in;end
		else begin
			data_check_en <= 1'b0;
			data_rx <= data_rx;end
		end
end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) 
		data_rx_t <= 48'b0;
	else 
        data_rx_t <= data_rx;
end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)begin
		head <= 8'b0;
		i_addr <= 8'b0;
		data_2byte <= 16'b0;
		tail <= 8'b0;
		fun_t <= 8'b0;
		end
	else begin
		head <= data_rx_t [47:40]; 
		i_addr <= data_rx [39:32];
		data_2byte <= data_rx_t [23:8];
		tail <= data_rx_t [7:0];
		fun_t <= data_rx [31:24];
	end
end



always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		func <= 8'b0;
	else begin
		if (i_addr == local_addr || fun_t == 8'd4)
			func <= data_rx_t [31:24];
		else 
			func <= 8'b0;end
end


always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)begin
		AD_state_query <= 2'b0;
		sampling_rate_conf <= 16'd5;  // indicate the init. sampling rate is 20MSPS
		sampling_point_conf <= 16'd1;
		data_return <= 1'b0;
		addr_inquiry <= 1'b0;
	end
	else begin
		case (func[2:0])
		1:  begin
			if (data_2byte == 16'b0 || data_2byte > 16'd6)begin // if the sampling rate is out-of defined
				AD_state_query <= 2'b01;
				sampling_rate_conf <= sampling_rate_conf;end
			else begin
				AD_state_query <= 2'b00;
				sampling_rate_conf <= data_2byte;end
		    end
			
		2:	begin
			if (data_2byte == 16'b0)begin
				AD_state_query <= 2'b10;
				sampling_point_conf <= sampling_point_conf;end
			else begin
				AD_state_query <= 2'b11;
				sampling_point_conf <= data_2byte;end
		    end
		3:  data_return <= 1'b1;
		4:	addr_inquiry <= 1'b1;//(¸Äµ¥Âö³å)
		default:begin
				AD_state_query <= AD_state_query;
				sampling_rate_conf <= sampling_rate_conf;
				sampling_point_conf <= sampling_point_conf;
				data_return <= data_return;
				addr_inquiry <= addr_inquiry;
				end
	endcase
	end

end

always@(posedge clk or negedge rst_n)
begin
     if(!rst_n)begin
        data_check_en_t <= 1'b0;
        data_check_en_tt <= 1'b0;
        data_check_en_ttt <= 1'b0;
        end
    else begin
        data_check_en_tt <= data_check_en;
        data_check_en_ttt <= data_check_en_tt;
        data_check_en_t <= data_check_en_ttt;end
end


always@(posedge clk or negedge rst_n)
begin
     if(!rst_n)
        o_data_check_en <= 1'b0;
    else if (( i_addr == local_addr) ||(func[2:0]== 3'd4))
        o_data_check_en <= data_check_en_t;
    else 
        o_data_check_en <= 1'b0;
end

always@(posedge clk or negedge rst_n)
begin
     if(!rst_n)
        o_sampling_rate_conf_en <= 1'b0;
    else if (( i_addr == local_addr)&&func[2:0]== 3'd1 && AD_state_query == 2'b00)  
        o_sampling_rate_conf_en <= data_check_en_t;
    else 
        o_sampling_rate_conf_en <= 1'b0;
end

always@(posedge clk or negedge rst_n)
begin
     if(!rst_n)
        o_sampling_point_conf_en <= 1'b0;
    else if (( i_addr == local_addr)&&func[2:0]== 3'd2 && AD_state_query == 2'b11)  
        o_sampling_point_conf_en <= data_check_en_t;
    else 
        o_sampling_point_conf_en <= 1'b0;
end

assign o_AD_state_query      = AD_state_query;
assign o_addr_inquiry        = addr_inquiry;
assign o_data_return         = data_return;
assign o_sampling_point_conf = sampling_point_conf;
assign o_sampling_rate_conf  = sampling_rate_conf;
assign o_func 				 = func[2:0];
assign o_addr                = local_addr;

// && addr == 
                                
endmodule	