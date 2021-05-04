//对Xilinx Vivado中提供的DDR3控制器IP核模块进行例化，实现基本的DDR3读写操作。
//从0地址开始遍历写256*128bits数据到DDR3的地址0-2047中，每秒执行一次写入和读出操作。
//在执行完写入后，执行一次相同地址的读操作，将读出的256*128bits数据写入到片内RAM中，
//使用在线逻辑分析仪Chipscope可以查看有规律变化的DDR3数据读写时序。
module ddr3_test(
			// DDR3接口
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
			input		ext_rst_n,	//复位信号，低电平有效
				//LED指示灯接口
			output[3:0] led,		//用于测试的LED指示灯
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
//PLL例化
wire clk_200m;
wire sys_rst_n;
  pll_ip 	pll_ip_inst
   (
   // Clock in ports
    .clk_in1(sys_clk_i),      // input clk_in1
    // Clock out ports
    .clk_out1(clk_200m),     // output clk_out1
    // Status and control signals
    .reset(/*!ext_rst_n*/0), // input reset     为了方便逻辑分析仪观察，PLL一直使能
    .locked(sys_rst_n));      // output locked	
	
////////////////////////////////////////////////////
//DDR3 controller例化
	//DDR3控制器IP的用户接口信号：时钟与复位
wire ui_clk;	//时钟信号，是DDR3时钟（400MHz）的1/4，即100MHz
wire ui_clk_sync_rst;	//复位信号
	//DDR3控制器IP的用户接口信号：控制信号
wire[27:0] app_addr;	//DDR3地址总线
wire[2:0] app_cmd;		//DDR3命令总线，3‘b000--写；3'b001--读；3‘b011--wr_bytes（With ECC enabled, the wr_bytes operation is required for writes with any non-zero app_wdf_mask bits.）
wire app_en;	//DDR3操作请求信号，高电平有效
wire app_rdy;	//DDR3操作响应信号，表示当前的app_en请求已经获得响应，可以继续操作
wire init_calib_complete;	//校准初始化完成标志信号，高电平有效
	//DDR3控制器IP的用户接口信号：写数据信号
wire[127:0] app_wdf_data;	//DDR3写入数据总线
wire app_wdf_end;	//DDR3最后一个字节写入指示信号，与app_wdf_data同步指示当前操作为最后一个数据写入
//input [15:0]        app_wdf_mask;	//DDR3写入数据位屏蔽信号
wire app_wdf_wren;	//DDR3写入数据使能信号，表示当前写入数据有效
wire app_wdf_rdy;	//DDR3可以执行写入数据操作，该信号拉高表示写数据FIFO已经准备好接收数据
	//DDR3控制器IP的用户接口信号：读数据信号
wire[127:0] app_rd_data;	//DDR3读取数据总线
wire app_rd_data_end;	//DDR3最有一个字节读取指示信号，与app_rd_data同步指示当前操作为最后一个数据读出
wire app_rd_data_valid;	//DDR3读出数据使能信号，表示当前读出数据有效
	//DDR3控制器IP的用户接口信号：刷新请求与响应
wire app_ref_req = 1'b0;	//DDR3刷新请求信号，高电平有效，该信号拉高必须保持到app_ref_ack拉高表示刷新请求已经响应
wire app_ref_ack;	//DDR3刷新响应信号，高电平有效，该信号拉高表示已经执行DDR3的刷新操作
	//DDR3控制器IP的用户接口信号：ZQ校准请求与响应
wire app_zq_req = 1'b0;	//DDR3 ZQ校准命令请求信号，高电平有效，该信号拉高必须保持到app_zq_ack拉高表示刷新请求已经响应
wire app_zq_ack;	//DDR3 ZQ校准响应信号，高电平有效，该信号拉高表示已经执行DDR3的ZQ校准操作
	//DDR3控制器IP的用户接口信号：
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
	//产生数据源，用于测试DDR2的读写
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
//LED闪烁逻辑产生模块例化

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
