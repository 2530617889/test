module test(ge,shi,zubie1,zuhao1,clock,deng1,deng2,deng3,deng4,reset,ok,stop,add,k1,k2,k3,k4,clk4,lcd_rs,lcd_en,lcd_rw,lcd_data);
	input reset,ok,stop,add,k1,k2,k3,k4,clk4;
	
	output lcd_rs,lcd_en,lcd_rw,lcd_data;
	output [6:0] ge,shi;
	wire [7:0] lcd_data;
	//output t;
	//output [3:0] score1,score2,score3,score4;
	output clock,deng1,deng2,deng3,deng4;
	//output [1:0] zubie,zuhao;
	output[6:0] zubie1,zuhao1;
	 reg [6:0] zubie,zuhao;
	reg clock,deng1,deng2,deng3,deng4;
	reg flag,block;//答题weigui flag;    block fengsuo dati xinhao
	reg [7:0] score1,score2,score3,score4;
	reg [4:0] t,tt;
	reg [63:0] tmp;
	reg clk;
	reg [6:0] ge_wei, shi_wei;
	
	initial begin 
		score1=100; score2=100;score3=100;score4=100; zubie=0; zuhao=0;
	end
	always @(posedge clk4) begin
		if( tmp >= 10000000 ) begin
			clk = ~clk;
			tmp = 0;
		end
		else
			tmp = tmp + 1;
	end
	
	zh u_ge(ge, ge_wei);
	zh u_shi(shi, shi_wei);
	
	zh u4(zubie1, zubie);
	zh u5(zuhao1, zuhao);
	
	LCD u3(.clk_en(clk),.lcd_rs(lcd_rs),.lcd_rw(lcd_rw),.lcd_en(lcd_en),.zubie(zubie),.zuhao(zuhao),
		.score1(score1),.score2(score2),.score3(score3),.score4(score4),.lcd_data(lcd_data));
//信号锁存
	always@(posedge clk)
		begin	//裁判发信号，开始抢答，指示灯灭，蜂鸣器禁声
			
			if(!ok) begin {deng1,deng2,deng3,deng4,block}<=5'b11110;
			t=0;	flag=0; zuhao=0;
				//panduan weigui qiqian qingda 
				if(k1||k2||k3||k4) 
					flag=1;  //weigui fengmingqi xiang 
							
			end
			else begin if(k1)  //第一组按键是否按下
					begin if(!block)
						begin deng1=0; //点亮第一组灯
						block=1;  //封锁抢答信号
						zuhao=1;
						t=1; //第一组已按下，可启动答题计时器
						end
					end
				else if(k2)   //第二组
					begin if(!block)
					begin deng2=0;block=1;zuhao=2;t=1;end  end
				else if(k3)   //第三组
					begin if(!block)
					begin deng3=0;block=1;zuhao=3;t=1;end  end
				else if(k4)   //第四组
					begin if(!block)
					begin deng4=0;block=1;zuhao=4;t=1;end  end
				if(t!=0)
					begin if(t>30)   //30s
							  begin t=0;  flag=1'b1;  end  //clock<=0;
						  else begin t=t+1; 
									if(stop)
										begin t=0; end
							   end
					 end  
		end
		end		
	always @(t)
			if(flag==1) begin clock=0; 
					if(k1)  zubie=1;
					else if(k2)  zubie=2;
					else if(k3)  zubie=3;
					else if(k4)  zubie=4;
					else zubie=0;
					end
		else begin clock=1;  zubie=0; end

	
	always @(posedge clk)
		if(!ok) begin tt=0; ge_wei=tt%10; shi_wei=tt/10; end
		else
		if(t!=0)
				begin if(tt>30)   //30s
						  begin tt=0;  ge_wei=tt%10; shi_wei=tt/10; end  //clock<=0;
					  else begin tt=tt+1;  ge_wei=tt%10; shi_wei=tt/10;
								if(stop)
									begin tt=0;  ge_wei=tt%10; shi_wei=tt/10;end
						   end
				 end  
	/********************************************************************/
	//计分
	always@(posedge add)   //加分
		begin if(reset)  //初始化各组的起始分数
			begin score1=100; score2=100;score3=100;score4=100; end   // 100分
		else if (k1)  //第一组加分
			score1=score1+10;
		else if (k2)  //第一组加分
			score2=score2+10;
		else if (k3)  //第一组加分
			score3=score3+10;
		else if (k4)  //第一组加分
			score4=score4+10;
		end
endmodule


module zh(S,Q);
	output [7:0] S;
	input [7:0] Q;
	reg [7:0] S;
	always @(Q)
		case(Q)
			8'b00000000: S<=7'b1000000;
			8'b00000001: S<=7'b1111001;
			8'b00000010: S<=7'b0100100;
			8'b00000011: S<=7'b0110000;
			8'b00000100: S<=7'b0011001;
			8'b00000101: S<=7'b0010010;
			8'b00000110: S<=7'b0000010;
			8'b00000111: S<=7'b1111000;
			8'b00001000: S<=7'b0000000;
			8'b00001001: S<=7'b0010000;
			default: S<=7'b1111111;
		endcase
endmodule
//*****************************************************************************
module LCD(clk_en,lcd_rs,lcd_rw,lcd_en,zubie,zuhao,score1,score2,score3,score4,lcd_data);
	input clk_en;
	input [1:0]zubie,zuhao;
	input [7:0]score1,score2,score3,score4;
	output lcd_rs,lcd_en,lcd_rw;
	output [7:0] lcd_data;
	
	reg lcd_rs;
	wire lcd_en,lcd_rw;
	
	reg [7:0] lcd_data;
	reg [1:8] FirstLine [0:31];
	
	wire rst;
	
	reg [7:0] current_state;//当前状态
	reg [1:0] state_counter;//状态计数
	reg en_temp;//使能标志
	reg [15:0] clk_counter;//时钟计数
//	reg clk_en;//时钟使能
	
	reg [4:0] Count;
	//reg [1:8] state [0:4];
	
	initial 
	begin
		FirstLine[0]<="0"+zubie;
		FirstLine[1]<=" ";
		FirstLine[2]<="0"+zuhao;
		FirstLine[3]<=" ";
		FirstLine[4]<="1";
		FirstLine[5]<=":";
		FirstLine[6]<="0"+score1/100;
		FirstLine[7]<="0"+score1/10;
		
		FirstLine[8]<="0"+score1%10;
		FirstLine[9]<=" ";
		FirstLine[10]<="2";
		FirstLine[11]<=":";
		FirstLine[12]<="0"+score2/100;
		FirstLine[13]<="0"+score2/10;
		
		FirstLine[14]<="0"+score2%10;
		FirstLine[15]<=" ";
		
		FirstLine[16]<="3";
		FirstLine[17]<=":";
		FirstLine[18]<="0"+score3/100;
		FirstLine[19]<="0"+score3/10;
		
		FirstLine[20]<="0"+score3%10;
		FirstLine[21]<=" ";
		FirstLine[22]<="4";
		FirstLine[23]<=":";
		FirstLine[24]<="0"+score4/100;
		FirstLine[25]<="0"+score4/10;
		
		FirstLine[26]<="0"+score4%10;
		FirstLine[27]<=" ";
		FirstLine[28]<=" ";
		FirstLine[29]<=" ";
		FirstLine[30]<=" ";
		FirstLine[31]<=" ";
		
		
	end
	
	assign lcd_rw=1'b0;//一直为写状态
	assign rst = 1;
	/********************状态编码******************************/
	parameter set0=8'b0000_0000,
	set1=8'b0000_0001,
	set2=8'b0000_0011,
	set3=8'b0000_0100,
	set4=8'b0000_0101,
	set5=8'b0000_0110,
	data1=8'b0000_1000,
	data2=8'b0000_1001,
	data3=8'b0000_1010,
	data4=8'b0000_1011,
	data5=8'b0000_1100,
	data6=8'b0000_1101,
	data7=8'b0000_1110,
	data8=8'b0000_1111,
	data9=8'b0001_0000,
	data10=8'b0001_0001,
	data11=8'b0001_0010,
	data12=8'b0001_0011,
	data13=8'b0001_0100,
	data14=8'b0001_0101,
	data15=8'b0001_0110,
	data16=8'b0001_0111,
	data17=8'b0001_1000,
	data18=8'b0001_1001,
	data19=8'b0001_1010,
	data20=8'b0001_1011,
	data21=8'b0001_1100,
	data22=8'b0001_1101,
	data23=8'b0001_1110,
	data24=8'b0001_1111,
	data25=8'b0010_0001,
	data26=8'b0010_0010,
	data27=8'b0010_0011,
	data28=8'b0010_0100,
	data29=8'b0010_0101,
	data30=8'b0010_0110,
	data31=8'b0010_0111,
	data32=8'b0010_1000, 
	stop=8'b1111_1111;
	

	
	/**************状态转换时钟***********************/

	
	
	
	/**************状态转换**************************///

	always  begin
		
		FirstLine[0]<="0"+zubie;
		FirstLine[1]<=" ";
		FirstLine[2]<="0"+zuhao;
		FirstLine[3]<=" ";
		FirstLine[4]<="1";
		FirstLine[5]<=":";
		FirstLine[6]<="0"+score1/100;
		FirstLine[7]<="0"+(score1/10)%10;
		
		FirstLine[8]<="0"+score1%10;
		FirstLine[9]<=" ";
		FirstLine[10]<="2";
		FirstLine[11]<=":";
		FirstLine[12]<="0"+score2/100;
		FirstLine[13]<="0"+(score2/10)%10;
		
		FirstLine[14]<="0"+score2%10;
		FirstLine[15]<=" ";
		
		FirstLine[16]<="3";
		FirstLine[17]<=":";
		FirstLine[18]<="0"+score3/100;
		FirstLine[19]<="0"+(score3/10)%10;
		
		FirstLine[20]<="0"+score3%10;
		FirstLine[21]<=" ";
		FirstLine[22]<="4";
		FirstLine[23]<=":";
		FirstLine[24]<="0"+score4/100;
		FirstLine[25]<="0"+(score4/10)%10;
		
		FirstLine[26]<="0"+score4%10;
		FirstLine[27]<=" ";
		FirstLine[28]<=" ";
		FirstLine[29]<=" ";
		FirstLine[30]<=" ";
		FirstLine[31]<=" ";
	end
		


	
	
		always @(posedge clk_en or negedge rst) begin
		
		
		if(!rst) begin
			current_state<=set0;
		end
				
		else begin		
			case (current_state)
			/*********************************************************************************/
				set0:begin lcd_rs<=1'b0;lcd_data<=8'h38;current_state<=set1; end//显示模式设置
				set1:begin lcd_rs<=1'b0;lcd_data<=8'h0c;current_state<=set2; end//显示开及光标设置
				set2:begin lcd_rs<=1'b0;lcd_data<=8'h06;current_state<=set3; end//显示光标移动设置
				set3:begin lcd_rs<=1'b0;lcd_data<=8'h01;current_state<=set4; end//显示清屏
				set4:begin lcd_rs<=1'b0;lcd_data<=8'h80;current_state<=data1; end//设置第一行地址
				/***********************************************************************************/
				data1:begin lcd_rs<=1'b1;lcd_data<=FirstLine[0];current_state<=data2; end//显示第1个字符
				data2:begin lcd_rs<=1'b1;lcd_data<=FirstLine[1];current_state<=data3; end//显示第2个字符
				data3:begin lcd_rs<=1'b1;lcd_data<=FirstLine[2];current_state<=data4; end//显示第3个字符
				data4:begin lcd_rs<=1'b1;lcd_data<=FirstLine[3];current_state<=data5; end//显示第4个字符
				data5:begin lcd_rs<=1'b1;lcd_data<=FirstLine[4];current_state<=data6; end//显示第5个字符
				data6:begin lcd_rs<=1'b1;lcd_data<=FirstLine[5];current_state<=data7; end//显示第6个字符
				data7:begin lcd_rs<=1'b1;lcd_data<=FirstLine[6];current_state<=data8; end//显示第7个字符
				data8:begin lcd_rs<=1'b1;lcd_data<=FirstLine[7];current_state<=data9; end//显示第8个字符

				data9:begin lcd_rs<=1'b1;lcd_data<=FirstLine[8];current_state<=data10; end//显示第1个字符
				data10:begin lcd_rs<=1'b1;lcd_data<=FirstLine[9];current_state<=data11; end//显示第2个字符
				data11:begin lcd_rs<=1'b1;lcd_data<=FirstLine[10];current_state<=data12; end//显示第3个字符
				data12:begin lcd_rs<=1'b1;lcd_data<=FirstLine[11];current_state<=data13; end//显示第4个字符
				data13:begin lcd_rs<=1'b1;lcd_data<=FirstLine[12];current_state<=data14; end//显示第5个字符
				data14:begin lcd_rs<=1'b1;lcd_data<=FirstLine[13];current_state<=data15; end//显示第6个字符
				data15:begin lcd_rs<=1'b1;lcd_data<=FirstLine[14];current_state<=data16; end//显示第7个字符
				data16:begin lcd_rs<=1'b1;lcd_data<=FirstLine[15];current_state<=set5; end//显示第8个字符

				set5:begin lcd_rs<=1'b0;lcd_data<=8'hc0;current_state<=data17; end//设置第2行地址

				data17:begin lcd_rs<=1'b1;lcd_data<=FirstLine[16];current_state<=data18; end//显示第1个字符
				data18:begin lcd_rs<=1'b1;lcd_data<=FirstLine[17];current_state<=data19; end//显示第2个字符
				data19:begin lcd_rs<=1'b1;lcd_data<=FirstLine[18];current_state<=data20; end//显示第3个字符
				data20:begin lcd_rs<=1'b1;lcd_data<=FirstLine[19];current_state<=data21; end//显示第4个字符
				data21:begin lcd_rs<=1'b1;lcd_data<=FirstLine[20];current_state<=data22; end//显示第5个字符
				data22:begin lcd_rs<=1'b1;lcd_data<=FirstLine[21];current_state<=data23; end//显示第6个字符
				data23:begin lcd_rs<=1'b1;lcd_data<=FirstLine[22];current_state<=data24; end//显示第7个字符
				data24:begin lcd_rs<=1'b1;lcd_data<=FirstLine[23];current_state<=data25; end//显示第8个字符

				data25:begin lcd_rs<=1'b1;lcd_data<=FirstLine[24];current_state<=data26; end//显示第二个字符
				data26:begin lcd_rs<=1'b1;lcd_data<=FirstLine[25];current_state<=data27; end//显示第四个字符
				data27:begin lcd_rs<=1'b1;lcd_data<=FirstLine[26];current_state<=data28; end//显示第五个字符
				data28:begin lcd_rs<=1'b1;lcd_data<=" ";current_state<=data29; end//显示第六个字符
				data29:begin lcd_rs<=1'b1;lcd_data<=FirstLine[28];current_state<=data30; end//显示第七个字符
				data30:begin lcd_rs<=1'b1;lcd_data<=" ";current_state<=data31; end//显示第八个字符
				data31:begin lcd_rs<=1'b1;lcd_data<=FirstLine[30];current_state<=data32; end//显示第九个字符
				data32:begin lcd_rs<=1'b1;lcd_data<=" ";current_state<=stop; end//显示第九个字符
				/*********************************************************************************/
				stop:begin //控制指令与数据写入的次数
						lcd_rs<=1'b0;
						lcd_data<=8'b0000_0000;
						if(state_counter!=2'b10) begin
							en_temp<=1'b0;
							current_state<=set4;
							state_counter<=state_counter+1'b1;
						end
						else begin
							current_state<=set4;
							en_temp<=1'b0;//最后数据写入完成后将lcd_en线拉高
						end
					end
				default: current_state<=set0;
			endcase 
		end
	end
	
	assign lcd_en=clk_en|en_temp;//lcd_en为‘1’有效

endmodule

	
	
	
