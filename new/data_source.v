module data_source(
				//DDR3������IP���û��ӿ��źţ�ʱ���븴λ
			input       [  0:  0]   clk,	//ʱ���źţ���DDR3ʱ�ӣ�400MHz����1/4����100MHz
			input       [  0:  0]   rst_n,	//��λ�ź�
				//DDR3������IP���û��ӿ��źţ������ź�
			output reg  [ 27:  0]   app_addr,	//DDR3��ַ����
			output reg  [  2:  0]   app_cmd,		//DDR3�������ߣ�3'b000--д��3'b001--����3'b011--wr_bytes��With ECC enabled, the wr_bytes operation is required for writes with any non-zero app_wdf_mask bits.��
			output reg  [  0:  0]   app_en,	//DDR3���������źţ��ߵ�ƽ��Ч
			input       [  0:  0]   app_rdy,	//DDR3������Ӧ�źţ���ʾ��ǰ��app_en�����Ѿ������Ӧ�����Լ�������????????
				//DDR3������IP���û��ӿ��źţ�д�����ź�
			output reg  [127:  0]   app_wdf_data,	//DDR3д����������
			output reg  [  0:  0]   app_wdf_end,	//DDR3���һ���ֽ�д��ָʾ�źţ���app_wdf_dataͬ��ָʾ��ǰ����Ϊ���һ������д��????????
			output reg  [  0:  0]   app_wdf_wren,	//DDR3д������ʹ���źţ���ʾ��ǰд��������Ч
			input       [  0:  0]   app_wdf_rdy,	//DDR3����ִ��д�����ݲ��������ź����߱�ʾд����FIFO�Ѿ�׼���ý�������
				//DDR3������IP���û��ӿ��źţ��������ź�
			input       [127:  0]   app_rd_data,	//DDR3��ȡ��������
			input       [  0:  0]   app_rd_data_end,	//DDR3����һ���ֽڶ�ȡָʾ�źţ���app_rd_dataͬ��ָʾ��ǰ����Ϊ���һ�����ݶ���????????
			input       [  0:  0]   app_rd_data_valid,	//DDR3��������ʹ���źţ���ʾ��ǰ����������Ч
			output      [  0:  0]   tx_pin,
			input       [ 11:  0]   adc_data,
			input       [  0:  0]   write_s,
//			input send_s,
//			input ready_s,
			output reg  [  3:  0]   led,
			input       [  0:  0]   rx_pin,
			input       [  0:  0]   I_data_rd_valid,
			output      [ 15:  0]   O_sampling_rate_setting,
			output      [  0:  0]   O_sampling_rate_valid
		);

////////////////////////////////////////////////////		
//��0��ַ��ʼ����д256*128bits���ݵ�DDR3�ĵ�ַ0-2047�У�ÿ��ִ��һ��д��Ͷ���������????????
//��ִ����д���ִ��һ����ͬ��ַ�Ķ���������������????????256*128bits����д�뵽Ƭ��RAM�У�
//ʹ�������߼�������Chipscope���Բ鿴�й��ɱ仯��DDR3���ݶ�дʱ��
////////////////////////////////////////////////////
//parameter BURST_WR_128BIT = 25'd10_000_000;	//burstд��������
//parameter BURST_RD_128BIT = 25'd10_000_000;	//burst����������


////////////////////////////////////////////////////
//������дDDR3������״̬
parameter   SIDLE   =   4'd0;
parameter   SWRDB   =   4'd1;
parameter   SRDDB   =   4'd2;
parameter   SSTOP   =   4'd3;
	
reg [ 3: 0]  nstate,cstate;
reg [24: 0]  num;
reg [24: 0]  wrnum;
reg [24: 0] rd_addr;
reg [24: 0] we_addr;

wire    [ 0: 0] tx_data_valid;
wire    [15: 0] tx_data;
wire    [ 0: 0] tx_data_ready;
wire    [ 0: 0] tx_data_rd_ctrl;
wire    [ 0: 0] state_rd_trig;

reg [24: 0] we_point_128bit_conf = 25'd00_001_000;
reg [24: 0] rd_point_128bit_conf = 25'd00_001_000;


parameter   TX_RDY_IDLE    =   2'd0;
parameter   TX_RDY_WATI    =   2'd1;

reg [ 1: 0] tx_rdy_cstate = 2'b0;
reg [ 1: 0] tx_rdy_nstate = 2'b0;
reg [ 0: 0] tx_rdy_flag = 1'b0;

always @(posedge clk or negedge rst_n)
	if(!rst_n) cstate <= SIDLE;
	else cstate <= nstate;

reg [ 0: 0] write_s_pre     =   1'b1;
reg [26: 0] latch_win_cnt   =   27'd10_000_000;
reg [ 0: 0] write_s_win     =   1'd0;

always @(posedge clk)
begin
    write_s_pre <= write_s;
end

always @(posedge clk)
begin
    if ((write_s_pre & !write_s) && (latch_win_cnt >= 27'd10_000_000))
    begin
        latch_win_cnt <= 27'd0;
        write_s_win <= 1'b1;
    end
    else
    begin
        if (latch_win_cnt < 27'd10_000_000)
        begin
            latch_win_cnt <= latch_win_cnt + 27'd1;
            write_s_win <= 1'b0;
        end
        else
        begin
            latch_win_cnt <= latch_win_cnt;
            write_s_win <= 1'b0;
        end
    end
end

	//���ݶ�д�ٲÿ���״̬��  or timer_wrreq or timer_rdreq
always @(cstate or state_rd_trig or num or wrnum or write_s_win or we_point_128bit_conf or rd_point_128bit_conf)
begin
	case(cstate)
		SIDLE: 
		begin
		    led = 4'b0111;
			if(write_s_win) 
			begin
                nstate = SWRDB;
			end
			else
			begin
                if(state_rd_trig)
                begin
                    nstate = SRDDB;
                end
                else
                begin
                    nstate = SIDLE;
                end
			end
		end
		SWRDB:
		begin	//д����
		    led = 4'b1011;
			if(wrnum > we_point_128bit_conf)
			begin
                nstate = SSTOP;
            end
            else 
            begin
                nstate = SWRDB;
			end
		end
		SRDDB: begin	//������
		    led = 4'b1101;
			if(num > rd_point_128bit_conf)
			begin
			     nstate = SSTOP;
			end
			else
			begin
			     nstate = SRDDB;
			end
		end
		SSTOP: 
		begin
            led = 4'b1110;
            nstate = SIDLE;
		end
		default:
		begin
            nstate = SSTOP;
        end
	endcase
end

assign  tx_data_valid = ((cstate == SRDDB) && tx_rdy_flag)?1'b1:1'b0;

reg [ 2: 0] sub_rd_addr = 3'b0;
	
always@(posedge clk)
begin
    if (app_rdy & app_en)//(tx_rdy_flag)
    begin
        sub_rd_addr <=  rd_addr[ 2: 0];
    end
    else
    begin
        sub_rd_addr <=  sub_rd_addr;
    end
end

reg [15: 0] app_rd_data_buf     = 16'b0;

always@(posedge clk)
begin
    if (app_rd_data_valid)
    begin
        case (sub_rd_addr)
            3'd0:   app_rd_data_buf <= app_rd_data[127:112];
            3'd1:   app_rd_data_buf <= app_rd_data[111: 96];
            3'd2:   app_rd_data_buf <= app_rd_data[ 95: 80];
            3'd3:   app_rd_data_buf <= app_rd_data[ 79: 64];
            3'd4:   app_rd_data_buf <= app_rd_data[ 63: 48];
            3'd5:   app_rd_data_buf <= app_rd_data[ 47: 32];
            3'd6:   app_rd_data_buf <= app_rd_data[ 31: 16];
            3'd7:   app_rd_data_buf <= app_rd_data[ 15:  0];
        endcase
    end
    else
    begin
        app_rd_data_buf <= app_rd_data_buf;
    end
end

reg [15: 0] tx_data_tmp     = 16'b0;
always@(posedge clk)
begin
    if (tx_rdy_flag)
    begin
        tx_data_tmp <= app_rd_data_buf;
    end
    else
    begin
        tx_data_tmp <= tx_data_tmp;
    end
end

assign  tx_data = tx_rdy_flag ? app_rd_data_buf : tx_data_tmp;

////////////////////////////////////////////////////	
//����д���ݿ����źż�����
	
always@(posedge clk)
begin
    if (!rst_n || cstate != SRDDB)
    begin
        num     <=  25'd1;
        rd_addr <=  25'b0;
    end
    else
    begin
        if (app_rdy & app_en)//(tx_rdy_flag)
        begin
            num     <=  num + 25'b1;
            rd_addr <=  rd_addr + 25'b1;
        end
        else
        begin
            num     <=  num;
            rd_addr <=  rd_addr;
        end
    end
end

always@(tx_rdy_cstate or tx_data_rd_ctrl or tx_data_ready or app_rdy)
begin
    case (tx_rdy_cstate)
        TX_RDY_IDLE:
        begin
            if (tx_data_rd_ctrl & tx_data_ready)
            begin
                if (!app_rdy)
                begin
                    tx_rdy_nstate = TX_RDY_WATI;
                    tx_rdy_flag = 1'b0;
                end
                else
                begin
                    tx_rdy_nstate = TX_RDY_IDLE;
                    tx_rdy_flag = 1'b1;
                end
            end
            else
            begin
                tx_rdy_nstate = TX_RDY_IDLE;
                tx_rdy_flag = 1'b0;
            end
        end
        TX_RDY_WATI:
        begin
            if (!app_rdy)
            begin
                tx_rdy_nstate = TX_RDY_WATI;
                tx_rdy_flag = 1'b0;
            end
            else
            begin
                tx_rdy_nstate = TX_RDY_IDLE;
                tx_rdy_flag = 1'b1;
            end
        end
        default:
        begin
            tx_rdy_nstate = TX_RDY_IDLE;
            tx_rdy_flag = 1'b0;
        end
    endcase
end

always@(posedge clk)
begin
    tx_rdy_cstate <= tx_rdy_nstate;
end

// data2ddr_buffer(fifo) is set to buffer the data from the ADC to DDR write port
wire    [ 0: 0] buf_data_rd_sig;
wire    [11: 0] buf_data_rd;

data2ddr_buffer
(
    // Input Port
    .I_clk                      (clk                                ),//    input   [ 0: 0]     I_clk,
    .I_rst                      (write_s_win                        ),//    input   [ 0: 0]     I_rst,
    .I_data_valid               (I_data_rd_valid                    ),//    input   [ 0: 0]     I_data_valid,
    .I_data                     (adc_data                           ),//    input   [11: 0]     I_data,
    .I_we_point_conf            (we_point_128bit_conf               ),//    input   [24: 0]     I_we_point_conf,
    .I_ddr_sended_flag          (app_wdf_rdy & app_rdy & app_en     ),//    input               I_ddr_sended_flag,
    // Output Port
    .O_data_rd_sig              (buf_data_rd_sig                    ),//    output  reg [ 0: 0] O_data_rd_sig,
    .O_data_rd                  (buf_data_rd                        ) //    output      [11: 0] O_data_rd
);

//  Following part is the logic to control the DDR3 interface

//  ddr write counter & wrnum generator
always @(posedge clk)
begin
	if(write_s_win || (cstate != SWRDB))
	begin
	   wrnum   <=  25'd1;
	   we_addr <=  25'b0;
	end
	else
	begin
        if(app_wdf_rdy & app_rdy & app_en)
        begin
            wrnum   <=  wrnum + 25'd1;
            we_addr <=  we_addr + 25'b1;
        end
        else
        begin
            wrnum   <=  wrnum;
            we_addr <=  we_addr;
        end
	end	
end

// app_cmd generator
always @(posedge clk)
begin
    case (cstate)
        SWRDB:      app_cmd <= 3'b000;
        SRDDB:      app_cmd <= 3'b001;
        default:    app_cmd <= 3'b000;
    endcase
end

// app_en, app_wdf_data & app_addr generator
always @(posedge clk)
begin
    case (cstate)
        SWRDB:
        begin
            if(buf_data_rd_sig && (wrnum <= we_point_128bit_conf))
            begin
                app_en              <=  1'b1;
            end
            else
            begin
                if (!(app_wdf_rdy & app_rdy) & app_en)
                begin
                    app_en              <=  1'b1;
                end
                else
                begin
                    app_en              <=  1'b0;
                end
            end
            if (app_wdf_rdy & app_rdy & app_en)
            begin
                app_addr[27: 3]     <=  {wrnum[24], wrnum[24], wrnum[24], wrnum[24: 3]};
                app_addr[ 2: 0]     <=  3'b0;
            end
            else
            begin
                app_addr[27: 0]     <=  app_addr[27: 0];
            end
        end
        SRDDB:
        begin
            if (tx_rdy_flag && (num <= rd_point_128bit_conf))
            begin
                app_en              <=  1'b1;
            end
            else
            begin
                if (!app_rdy & app_en)
                begin
                    app_en              <=  1'b1;
                end
                else
                begin
                    app_en              <=  1'b0;
                end
            end
            if (app_rdy & app_en)
            begin
                app_addr[27: 3]     <=  {num[24], num[24], num[24], num[24: 3]};
                app_addr[ 2: 0]     <=  3'b0;
            end
            else
            begin
                app_addr[27: 0]     <=  app_addr[27: 0];
            end
            // if (tx_rdy_flag && (num <= rd_point_128bit_conf))
            // begin
            //     app_en              <=  1'b1;
            //     app_addr[27: 3]     <=  {rd_addr[24], rd_addr[24],rd_addr[24], rd_addr[24: 3]};
            //     app_addr[ 2: 0]     <=  3'b0;	
            // end	
            // else 
            // begin
            //     app_en              <=  1'b0;
            //     app_addr[27: 0]     <=  app_addr[27: 0];
            // end 
        end
        default: 
        begin
            app_en              <=  1'b0;
            app_addr[27: 0]     <=  28'd0;
        end
    endcase
end

// assign  app_wdf_wren    =   ((cstate == SWRDB) && (app_wdf_rdy & app_rdy & app_en))?1'b1:1'b0;
// assign  app_wdf_end     =   ((cstate == SWRDB) && (app_wdf_rdy & app_rdy & app_en))?1'b1:1'b0;
// assign  app_wdf_data    =   {112'b0, buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd};

always @(posedge clk) 
begin
    if ((cstate == SWRDB) && (app_wdf_rdy & app_rdy & app_en))
    begin
        app_wdf_wren        <=  1'b1;
        app_wdf_end         <=  1'b1;
        // app_wdf_data[15: 0] <=  {buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd};
        // if (we_addr[2:0] == 3'b0) 
        // begin
        //     app_wdf_data[127: 16]   <=  112'b0;
        // end
        // else
        // begin
        //     app_wdf_data[127: 16]   <=  app_wdf_data[111: 0];
        // end
        case (we_addr[2:0])
            3'd0:   
            begin
                app_wdf_data[127:112]   <=  {buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd};
                app_wdf_data[111:  0]   <=  app_wdf_data[111:  0];
            end
            3'd1:
            begin
                app_wdf_data[127:120]   <=  app_wdf_data[127:120];
                app_wdf_data[111: 96]   <=  {buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd};
                app_wdf_data[ 95:  0]   <=  app_wdf_data[111:  0];
            end   
            3'd2:   
            begin
                app_wdf_data[127: 96]   <=  app_wdf_data[127: 96];
                app_wdf_data[ 95: 80]   <=  {buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd};
                app_wdf_data[ 79:  0]   <=  app_wdf_data[111:  0];
            end
            3'd3:   
            begin
                app_wdf_data[127: 80]   <=  app_wdf_data[127: 80];
                app_wdf_data[ 79: 64]   <=  {buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd};
                app_wdf_data[ 63:  0]   <=  app_wdf_data[111:  0];
            end
            3'd4:   
            begin
                app_wdf_data[127: 64]   <=  app_wdf_data[127: 64];
                app_wdf_data[ 63: 48]   <=  {buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd};
                app_wdf_data[ 47:  0]   <=  app_wdf_data[111:  0];
            end
            3'd5:   
            begin
                app_wdf_data[127: 48]   <=  app_wdf_data[127: 48];
                app_wdf_data[ 47: 32]   <=  {buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd};
                app_wdf_data[ 31:  0]   <=  app_wdf_data[111:  0];
            end
            3'd6:
            begin
                app_wdf_data[127: 32]   <=  app_wdf_data[127: 32];
                app_wdf_data[ 31: 16]   <=  {buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd};
                app_wdf_data[ 15:  0]   <=  app_wdf_data[111:  0];
            end   
            3'd7:
            begin
                app_wdf_data[127: 16]   <=  app_wdf_data[127: 16];
                app_wdf_data[ 15:  0]   <=  {buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd};
            end   
        endcase
    end
    else
    begin
        app_wdf_wren        <=  1'b0;
        app_wdf_end         <=  1'b0;
        app_wdf_data        <=  app_wdf_data;
    end
end


wire    [ 7: 0] uart_tx_data;
wire    [ 0: 0] uart_tx_valid;

wire    [ 1: 0] AD_state_query;
wire    [15: 0] sampling_rate_conf;
wire    [15: 0] sampling_point_conf;
wire    [ 7: 0] addr;
wire    [ 0: 0] addr_inquiry;
wire    [ 2: 0] func;
wire    [ 0: 0] data_check_en;
wire    [ 0: 0] data_check_en_d;

reg     [ 0: 0] data_check_en_t;
reg     [ 0: 0] data_check_en_tt;
wire    [ 0: 0] sampling_rate_conf_en;
wire    [ 0: 0] sampling_point_conf_en;

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)begin
        data_check_en_t <= 1'b0;
        data_check_en_tt <= 1'b0;end
    else begin
        data_check_en_t <= data_check_en;
        data_check_en_tt <= data_check_en_t;end
end

reg [2:0] func_d;

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        func_d <= 3'b000;
    else 
        func_d <= func;
end

assign data_check_en_d = ({data_check_en_tt,data_check_en_t} == 2'b01)?1:0;

uart_tx#
(
	.CLK_FRE(100),
	.BAUD_RATE(115200)
) uart_tx_inst
(
	.clk                        (clk                      ),
	.rst_n                      (rst_n                    ),
	.tx_data                    (uart_tx_data             ),
	.tx_data_valid              (uart_tx_valid            ),
	.tx_data_ready              (tx_data_ready            ),
	.tx_pin                     (tx_pin                   )
);

 uart_frame_ctrl uart_frame_ctrl
 (
    // Input Port
    .I_clk                      (clk                    ),//    input           I_clk,
    .I_rst_n                    (rst_n                  ),//    input           I_rst_n,
    .I_cmd_valid                (data_check_en_d        ),//    input           I_cmd_valid,
    .I_cmd_data                 (func                   ),//    input   [ 2: 0] I_cmd_data,
    .I_ddr_data_valid           (tx_data_valid          ),//    input           I_ddr_data_valid,
    .I_ddr_data                 (tx_data                ),//    input   [ 7: 0] I_ddr_data,
    .I_tx_data_ready            (tx_data_ready          ),//    input           I_tx_data_ready,
    .I_device_addr              (addr                   ),//    input   [ 7: 0] I_device_addr,
    .I_trans_length             (sampling_point_conf    ),//    input   [15: 0] I_trans_length,
    .I_sampling_rate            (sampling_rate_conf     ),//    input   [15: 0] I_sampling_rate,
    .I_sampling_num             (sampling_point_conf    ),//    input   [15: 0] I_sampling_num,
    // Output Port
    .O_tx_data_valid            (uart_tx_valid          ),//    output          O_tx_data_valid,
    .O_tx_data                  (uart_tx_data           ),//    output  [ 7: 0] O_tx_data
    .O_tx_data_rd_ctrl          (tx_data_rd_ctrl        ),
    .O_state_rd_trig            (state_rd_trig          )
);

Data_rx  Data_rx
(
     .clk                       (clk                    ),//    input clk,
     .rst_n                     (rst_n                  ),//    input rst_n,
     .rx_pin                    (rx_pin                 ),//    input rx_pin,
     .o_AD_state_query          (AD_state_query         ),//    output [1:0]  o_AD_state_query,
     .o_sampling_rate_conf      (sampling_rate_conf     ),//    output [15:0] o_sampling_rate_conf,
     .o_sampling_point_conf     (sampling_point_conf    ),//    output [15:0] o_sampling_point_conf,
     .o_data_return             (                       ),//    output        o_data_return,
     .o_addr_inquiry            (addr_inquiry           ),//    output        o_addr_inquiry,
     .o_func                    (func                   ),//    output [2:0]  o_func,
     .o_data_check_en           (data_check_en          ),//    output o_data_check_en
     .o_addr                    (addr                   ),
     .o_sampling_rate_conf_en   (sampling_rate_conf_en  ),
     .o_sampling_point_conf_en  (sampling_point_conf_en )
);
    
ila_data_source     ila_data_source
(
    .clk(clk), 
    .probe0(cstate),
    .probe1(wrnum),
    .probe2(app_wdf_rdy),
    .probe3(I_data_rd_valid),
    .probe4(app_en),
    .probe5(app_wdf_data[15:0]),
    .probe6(app_rdy),
    .probe7(app_rd_data_valid),
    .probe8({buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd[11], buf_data_rd}),
    .probe9(app_addr[27:3])
);


assign  O_sampling_rate_setting = sampling_rate_conf;
assign  O_sampling_rate_valid = sampling_rate_conf_en;

always@(posedge clk)
begin
    if (sampling_point_conf_en)
    begin
        we_point_128bit_conf <= {sampling_point_conf[13:0], 10'b0} - {6'b0, sampling_point_conf, 3'b0} - {5'b0, sampling_point_conf, 4'b0};
        rd_point_128bit_conf <= {sampling_point_conf[13:0], 10'b0} - {6'b0, sampling_point_conf, 3'b0} - {5'b0, sampling_point_conf, 4'b0};
    end
    else
    begin
        we_point_128bit_conf <= we_point_128bit_conf;
        rd_point_128bit_conf <= rd_point_128bit_conf;
    end
end

endmodule

