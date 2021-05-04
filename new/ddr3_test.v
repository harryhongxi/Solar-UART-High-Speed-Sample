//��Xilinx Vivado���ṩ��DDR3������IP��ģ�����������ʵ�ֻ�����DDR3��д������
//��0��ַ��ʼ����д256*128bits���ݵ�DDR3�ĵ�ַ0-2047�У�ÿ��ִ��һ��д��Ͷ���������
//��ִ����д���ִ��һ����ͬ��ַ�Ķ���������������256*128bits����д�뵽Ƭ��RAM�У�
//ʹ�������߼�������Chipscope���Բ鿴�й��ɱ仯��DDR3���ݶ�дʱ��
module ddr3_test(
			// DDR3�ӿ�
			inout [15:0]       ddr3_dq,
			inout [1:0]        ddr3_dqs_n,
			inout [1:0]        ddr3_dqs_p,
			output [13:0]      ddr3_addr,
			output [2:0]       ddr3_ba,
			output             ddr3_ras_n,
			output             ddr3_cas_n,
			output             ddr3_we_n,
			output             ddr3_reset_n,
			output [0:0]       ddr3_ck_p,
			output [0:0]       ddr3_ck_n,
			output [0:0]       ddr3_cke,
			output [1:0]       ddr3_dm,
			output [0:0]       ddr3_odt,
			// Single-ended system clock
			input       sys_clk_i,
			input		ext_rst_n,	//��λ�źţ��͵�ƽ��Ч
				//LEDָʾ�ƽӿ�
			output[3:0] led,		//���ڲ��Ե�LEDָʾ��
			output tx_pin,
			input[11:0] adc_data,
			output adc_clk,
			input write_s,
//			input send_s,
//			input ready_s,
			
			input rx_pin
//            output [1:0]  o_AD_state_query,
//            output [15:0] o_sampling_rate_conf,
//            output [15:0] o_sampling_point_conf,
//            output        o_data_return,
//            output        o_addr_inquiry,
//            output [2:0]  o_func,
//            output o_data_check_en
    );
            wire [1:0]  o_AD_state_query;
                wire [15:0] o_sampling_rate_conf;
                wire [15:0] o_sampling_point_conf;
                wire        o_data_return;
                wire        o_addr_inquiry;
                wire [2:0]  o_func;
                wire o_data_check_en;


////////////////////////////////////////////////////
//PLL����
wire clk_200m;
wire sys_rst_n;
  pll_ip 	pll_ip_inst
   (
   // Clock in ports
    .clk_in1(sys_clk_i),      // input clk_in1
    // Clock out ports
    .clk_out1(clk_200m),     // output clk_out1
    // Status and control signals
    .reset(/*!ext_rst_n*/0), // input reset     Ϊ�˷����߼������ǹ۲죬PLLһֱʹ��
    .locked(sys_rst_n));      // output locked	
	
////////////////////////////////////////////////////
//DDR3 controller����
	//DDR3������IP���û��ӿ��źţ�ʱ���븴λ
wire ui_clk;	//ʱ���źţ���DDR3ʱ�ӣ�400MHz����1/4����100MHz
wire ui_clk_sync_rst;	//��λ�ź�
	//DDR3������IP���û��ӿ��źţ������ź�
wire[27:0] app_addr;	//DDR3��ַ����
wire[2:0] app_cmd;		//DDR3�������ߣ�3��b000--д��3'b001--����3��b011--wr_bytes��With ECC enabled, the wr_bytes operation is required for writes with any non-zero app_wdf_mask bits.��
wire app_en;	//DDR3���������źţ��ߵ�ƽ��Ч
wire app_rdy;	//DDR3������Ӧ�źţ���ʾ��ǰ��app_en�����Ѿ������Ӧ�����Լ�������
wire init_calib_complete;	//У׼��ʼ����ɱ�־�źţ��ߵ�ƽ��Ч
	//DDR3������IP���û��ӿ��źţ�д�����ź�
wire[127:0] app_wdf_data;	//DDR3д����������
wire app_wdf_end;	//DDR3���һ���ֽ�д��ָʾ�źţ���app_wdf_dataͬ��ָʾ��ǰ����Ϊ���һ������д��
//input [15:0]        app_wdf_mask;	//DDR3д������λ�����ź�
wire app_wdf_wren;	//DDR3д������ʹ���źţ���ʾ��ǰд��������Ч
wire app_wdf_rdy;	//DDR3����ִ��д�����ݲ��������ź����߱�ʾд����FIFO�Ѿ�׼���ý�������
	//DDR3������IP���û��ӿ��źţ��������ź�
wire[127:0] app_rd_data;	//DDR3��ȡ��������
wire app_rd_data_end;	//DDR3����һ���ֽڶ�ȡָʾ�źţ���app_rd_dataͬ��ָʾ��ǰ����Ϊ���һ�����ݶ���
wire app_rd_data_valid;	//DDR3��������ʹ���źţ���ʾ��ǰ����������Ч
	//DDR3������IP���û��ӿ��źţ�ˢ����������Ӧ
wire app_ref_req = 1'b0;	//DDR3ˢ�������źţ��ߵ�ƽ��Ч�����ź����߱��뱣�ֵ�app_ref_ack���߱�ʾˢ�������Ѿ���Ӧ
wire app_ref_ack;	//DDR3ˢ����Ӧ�źţ��ߵ�ƽ��Ч�����ź����߱�ʾ�Ѿ�ִ��DDR3��ˢ�²���
	//DDR3������IP���û��ӿ��źţ�ZQУ׼��������Ӧ
wire app_zq_req = 1'b0;	//DDR3 ZQУ׼���������źţ��ߵ�ƽ��Ч�����ź����߱��뱣�ֵ�app_zq_ack���߱�ʾˢ�������Ѿ���Ӧ
wire app_zq_ack;	//DDR3 ZQУ׼��Ӧ�źţ��ߵ�ƽ��Ч�����ź����߱�ʾ�Ѿ�ִ��DDR3��ZQУ׼����
	//DDR3������IP���û��ӿ��źţ�
wire app_sr_req = 1'b0;
wire app_sr_active;
		  

ddr3_ip 		ddr3_ip_inst (
    // Memory interface ports
    .ddr3_addr                      (ddr3_addr),  // output [13:0]		ddr3_addr
    .ddr3_ba                        (ddr3_ba),  // output [2:0]		ddr3_ba
    .ddr3_cas_n                     (ddr3_cas_n),  // output			ddr3_cas_n
    .ddr3_ck_n                      (ddr3_ck_n),  // output [0:0]		ddr3_ck_n
    .ddr3_ck_p                      (ddr3_ck_p),  // output [0:0]		ddr3_ck_p
    .ddr3_cke                       (ddr3_cke),  // output [0:0]		ddr3_cke
    .ddr3_ras_n                     (ddr3_ras_n),  // output			ddr3_ras_n
    .ddr3_reset_n                   (ddr3_reset_n),  // output			ddr3_reset_n
    .ddr3_we_n                      (ddr3_we_n),  // output			ddr3_we_n
    .ddr3_dq                        (ddr3_dq),  // inout [15:0]		ddr3_dq
    .ddr3_dqs_n                     (ddr3_dqs_n),  // inout [1:0]		ddr3_dqs_n
    .ddr3_dqs_p                     (ddr3_dqs_p),  // inout [1:0]		ddr3_dqs_p
    .init_calib_complete            (init_calib_complete),  // output			init_calib_complete
      
    .ddr3_dm                        (ddr3_dm),  // output [1:0]		ddr3_dm
    .ddr3_odt                       (ddr3_odt),  // output [0:0]		ddr3_odt
    // Application interface ports
    .app_addr                       (app_addr),  // input [27:0]		app_addr
    .app_cmd                        (app_cmd),  // input [2:0]		app_cmd
    .app_en                         (app_en),  // input				app_en
    .app_wdf_data                   (app_wdf_data),  // input [127:0]		app_wdf_data
    .app_wdf_end                    (app_wdf_end),  // input				app_wdf_end
    .app_wdf_wren                   (app_wdf_wren),  // input				app_wdf_wren
    .app_rd_data                    (app_rd_data),  // output [127:0]		app_rd_data
    .app_rd_data_end                (app_rd_data_end),  // output			app_rd_data_end
    .app_rd_data_valid              (app_rd_data_valid),  // output			app_rd_data_valid
    .app_rdy                        (app_rdy),  // output			app_rdy
    .app_wdf_rdy                    (app_wdf_rdy),  // output			app_wdf_rdy
    .app_sr_req                     (app_sr_req),  // input			app_sr_req
    .app_ref_req                    (app_ref_req),  // input			app_ref_req
    .app_zq_req                     (app_zq_req),  // input			app_zq_req
    .app_sr_active                  (app_sr_active),  // output			app_sr_active
    .app_ref_ack                    (app_ref_ack),  // output			app_ref_ack
    .app_zq_ack                     (app_zq_ack),  // output			app_zq_ack
    .ui_clk                         (ui_clk),  // output			ui_clk
    .ui_clk_sync_rst                (ui_clk_sync_rst),  // output			ui_clk_sync_rst
    .app_wdf_mask                   (16'h00/*app_wdf_mask*/),  // input [15:0]		app_wdf_mask
    // System Clock Ports
    .sys_clk_i                       (clk_200m),  // input			sys_clk_i
    .sys_rst                        (sys_rst_n) // input sys_rst
    );	
    
reg[15:0] tmpcnt;

//always@(posedge ui_clk or negedge ext_rst_n)
//begin
//    if(ext_rst_n == 1'b0) tmpcnt <= 16'd0;
//    else
//    begin
//    if(tmpcnt == 16'd1000) 
//    begin
//        tmpcnt <= 16'd0;
//        div100k <= ~div100k;
//    end
//    else tmpcnt <= tmpcnt + 1'b1;
//    end
//end
////////////////////////////////////////////////////
	//��������Դ�����ڲ���DDR2�Ķ�д
wire    [11: 0] adc_data_rd;
wire            adc_data_rd_valid;
wire    [15: 0] sampling_rate_setting;
wire            sampling_rate_valid;

data_source		u2_data_source(
					.clk(ui_clk),
					.rst_n((!ui_clk_sync_rst)&&(ext_rst_n)),
					.app_addr(app_addr),
					.app_cmd(app_cmd),
					.app_en(app_en),
					.app_rdy(app_rdy),
					.app_wdf_data(app_wdf_data),
					.app_wdf_end(app_wdf_end),
					.app_wdf_wren(app_wdf_wren),
					.app_wdf_rdy(app_wdf_rdy),
					.app_rd_data(app_rd_data),
					.app_rd_data_end(app_rd_data_end),
					.app_rd_data_valid(app_rd_data_valid),
					.tx_pin(tx_pin),
					.adc_data(adc_data_rd),
					.write_s(write_s),
//					.send_s(send_s),
//					.ready_s(ready_s),
					.led(led),
					.rx_pin(rx_pin),
                    .I_data_rd_valid(adc_data_rd_valid),
                    .O_sampling_rate_setting(sampling_rate_setting),
                    .O_sampling_rate_valid(sampling_rate_valid)
				);	
	
////////////////////////////////////////////////////
//LED��˸�߼�����ģ������

//led_controller		u3_led_controller(
//						.clk(ui_clk),			
//						.rst_n(!ui_clk_sync_rst),
//						.led(led[0])
//					);	
	
//	Data_rx Data_rx(
//	   . clk(ui_clk),
//        . rst_n((!ui_clk_sync_rst)&&(ext_rst_n)),
//        . rx_pin(rx_pin),
//        . o_AD_state_query(o_AD_state_query),
//        . o_sampling_rate_conf(o_sampling_rate_conf),
//        . o_sampling_point_conf(o_sampling_point_conf),
//        . o_data_return(o_data_return),
//        . o_addr_inquiry(o_addr_inquiry),
//        . o_func(o_func),
//        . o_data_check_en(o_data_check_en)
//	);

ADC_interface   ADC_interface_inst0
(
    // input
    .I_clk(clk_200m),  // I_clk here is assumed to be 200MHz
    .I_data_we(adc_data),
    .I_clk_rd(ui_clk),
    .I_rst_n(ext_rst_n),
    .I_sampling_rate_setting(sampling_rate_setting),
    .I_sampling_rate_valid(sampling_rate_valid),
    // output
    .O_adc_clk(adc_clk),
    .O_data_rd_valid(adc_data_rd_valid),
    .O_data_rd(adc_data_rd)
);

ila_1   ila_1_inst
(
    .clk(ui_clk),
    .probe0(adc_data_rd),
    .probe1(adc_clk),
    .probe2(app_rdy),
    .probe3(app_wdf_rdy)
);

endmodule
