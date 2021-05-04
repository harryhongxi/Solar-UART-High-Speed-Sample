
//²¨ÌØÂÊ460800

module uart_rx(
	input							clk,
	input							i_SAMPLE_EN,
	input							i_RX_B,
	
	output	reg				o_RX_en,
	output	reg	[7 :0]	    o_RX_word,
	output  reg            o_sample_valid
);

reg	[2 :0]	state = 3'b0;
parameter	IDLE = 3'b0;
parameter	DATA = 3'd2;
parameter	REND = 3'd4;
reg	i_RX_bit = 1'b1;
reg i_RX_bit_tmp = 1'b1;
always@(posedge clk)
begin
	i_RX_bit <= i_RX_B;
	i_RX_bit_tmp <= i_RX_bit;
end

always@(posedge clk)
begin
    if (state == IDLE)
    begin
        if (i_RX_bit_tmp & !i_RX_bit)
        begin
            o_sample_valid <= 1'b1;
        end
        else
        begin
            o_sample_valid <= 1'b0;
        end
    end
    else
    begin
        o_sample_valid <= 1'b0;
    end
end

reg	[3 :0]	M = 4'd8;
always@(posedge clk)
begin
	case(state)
	IDLE:
	begin
		if(!i_RX_bit & i_SAMPLE_EN)
		begin
			M <= 4'd0;
		end
		else
		begin
			M <= 4'd8;
		end
	end
	DATA:
	begin
		if(i_SAMPLE_EN && (M < 4'd8))
		begin
			M <= M + 4'd1;
		end
		else
		begin
			M <= M;
		end
	end
	default:
	begin
		M <= 4'd8;
	end
	endcase
end
always@(posedge clk)
begin
	case(state)
	IDLE:
	begin
		if(!i_RX_bit & i_SAMPLE_EN)
		begin
			state <= DATA;
		end
		else
		begin
			state <= IDLE;
		end
	end
	DATA:
	begin
		if(M < 4'd8)
		begin
			state <= DATA;
		end
		else
		begin
			state <= REND;
		end
	end
	REND:
	begin
		if(i_RX_bit & i_SAMPLE_EN)
		begin
			state <= IDLE;
		end
		else
		begin
			state <= REND;
		end
	end
	default:
	begin
		state <= IDLE;
	end
	endcase
end
reg	[7 :0]	word_tmp = 8'd0;
always@(posedge clk)
begin
	if((M < 4'd8) && i_SAMPLE_EN)
	begin
		word_tmp <= {i_RX_bit,word_tmp[7:1]};
	end
	else
	begin
		word_tmp <= word_tmp;
	end
end
always@(posedge clk)
begin
	if((i_RX_bit & i_SAMPLE_EN) && (state == REND))
	begin
		o_RX_en <= 1'b1;
		o_RX_word <= word_tmp;
	end
	else
	begin
		o_RX_en <= 1'b0;
		o_RX_word <= o_RX_word;
	end
end
endmodule 