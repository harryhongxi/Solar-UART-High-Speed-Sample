//LED��˸�߼�����ģ��
module led_controller(
				//ʱ�Ӻ͸�λ�ӿ�
			input clk,		//25MHz����ʱ��	
			input rst_n,	//�͵�ƽϵͳ��λ�ź�����	
				//LEDָʾ�ƽӿ�
			output led		//���ڲ��Ե�LEDָʾ��
		);

		
////////////////////////////////////////////////////		
//��������LED��˸Ƶ��	
reg[27:0] cnt;

always @(posedge clk or negedge rst_n)
	if(!rst_n) cnt <= 28'd0;
	else cnt <= cnt+1'b1;

assign led = cnt[27];		

endmodule

