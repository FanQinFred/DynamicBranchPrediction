`timescale 1ns / 1ps

module datapath(
	
	input wire clk,rst,//ʱ���ź� �����ź�
	
	//ȡָ��׶���??
	output wire[31:0] pcF, //ȡָ���ַ�Ĵ�??
	input wire[31:0] instrF,// ȡָ���ָ??

	//ָ������׶��ź�
	input wire pcsrcD,branchD, //����׶ε�ַ��Դ ?? ������תָ�������֧
	input wire jumpD,//��������תָ���ַ
	output wire equalD,//�����Ĵ���Դ�������������Ч
	output wire[5:0] opD,functD,// ָ��Ĳ������ֶ� //ָ��Ĺ������ֶ�

	//���㼶��??
	input wire memtoregE,//ָ��ִ�м��Ĵ洢��д�Ĵ���������??
	input wire alusrcE,regdstE,//ִ��ָ��Ĵ�����Դ//ָ��ִ�м�Ŀ��Ĵ���
	input wire regwriteE,//���㼶�����Ƿ�д��Ĵ���
	input wire[2:0] alucontrolE,//���㵥Ԫ��������ѡ��
	output wire flushE,//ָ�����㼶ˢ����??

	//�ڴ���ʼ���??
	input wire memtoregM,//�ڴ�������Ĵ洢��д�Ĵ���������??
	input wire regwriteM,//�����ڴ漶�����Ƿ�д��Ĵ���
	output wire[31:0] aluoutM,writedataM,//���㼶��������//��д���ڴ��??
	input wire[31:0] readdataM,//�ڴ漶����������

	//д�ؼ���??
	input wire memtoregW,//д�ؼ��Ĵ洢��д�Ĵ���������??
	input wire regwriteW, //д�ؼ�����������

	output wire [4:0] rsE,rtE,rdE,
	output wire [4:0] rsD,rtD,rdD,
	
	output lwstallD,branchstallD,

	output stallF,stallD

);
	
	//ȡָ��׶���??
	wire stallF;

	//��ַ�����ź�
	wire [31:0] pcnextFD,pcnextbrFD,pcplus4F,pcbranchD;

	//ָ������׶��ź�
	wire [31:0] pcplus4D,instrD;
	wire forwardaD,forwardbD;
	
	wire flushD,stallD; 
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srca2D,srcbD,srcb2D;

	//���㼶��??
	wire [1:0] forwardaE,forwardbE;
	
	wire [4:0] writeregE;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] aluoutE;

	//�ڴ���ʼ���??
	wire [4:0] writeregM;

	//д�ؼ���??
	wire [4:0] writeregW;
	wire [31:0] aluoutW,readdataW,resultW;
	
	wire flushM,preErrorM;

	wire preErrorE;
	assign preErrorE = (pred_chooseD==1)? preErrorE_global:preErrorE_local;
	wire preErrorE_global,preErrorE_local,pred_takeD_local,pred_takeD_global;
	wire pred_takeD,pred_takeE;
	assign pred_takeD = (pred_chooseD==1)? pred_takeD_global:pred_takeD_local;
	wire hazard_flushE;
	wire actual_takeD;
	assign flushD=flushE;
	assign flushE=flushM | hazard_flushE;
	assign flushM=preErrorM;

	wire actual_takeE,actual_takeM;
	
	assign actual_takeD = equalD & branchD;
	branch_predict_local branch_predict_local(
    .clk(clk), 
	.rst(rst),

    .instrD(instrD),

    .flushD(flushD),
	.flushE(flushE),
	.flushM(flushM),
    .stallD(stallD),

    .pred_takeE(pred_takeE),      // Ԥ����Ƿ���???
    .actual_takeE(actual_takeE),    // ʵ���Ƿ���ת
    .actual_takeM(actual_takeM),

    .branchM(branchM),

    .pcF(pcF),
    .pcM(pcM),

    .pred_takeD(pred_takeD_local),    // D�׶�ʹ��
    .preErrorE(preErrorE_local)      // E�׶��ж�Ԥ���Ƿ���ȷ
);

wire pred_chooseD;
branch_predict_global branch_predict_global(
    .clk(clk), 
	.rst(rst),

    .instrD(instrD),

    .flushD(flushD),
	.flushE(flushE),
	.flushM(flushM),
    .stallD(stallD),

    .pred_takeE(pred_takeE),      // 棰勬祴鐨勬槸鍚﹁烦锟�????
    .actual_takeE(actual_takeE),    // 瀹為檯鏄惁璺宠�?
    .actual_takeD(actual_takeD),

    .branchD(branchD),
    .pcF(pcF),

    .pred_takeD(pred_takeD_global),    // D闃舵浣跨敤
    .preErrorE(preErrorE_global)      // E闃舵鍒ゆ柇棰勬祴鏄惁姝ｇ�?
);
	branch_predict_choose branch_predict_choose(
    .clk(clk), 
	.rst(rst),
    .flushD(flushD),.flushE(flushE),.flushM(flushM),.stallD(stallD),
    .pcF(pcF),
	.pcM(pcM),
	.branchM(branchM),
    .global_errorM(preErrorM_global),
    .local_errorM(preErrorM_local),
    .pred_chooseD(pred_chooseD)
);

	//ð��ģ��
	hazard h(

		//ȡָ��׶���??
		.stallF(stallF),

		//ָ������׶��ź�
		.rsD(rsD),
		.rtD(rtD),
		.branchD(branchD), 
		.forwardaD(forwardaD),
		.forwardbD(forwardbD),
		.stallD(stallD),

		//���㼶��??
		.rsE(rsE),
		.rtE(rtE),
		.writeregE(writeregE),
		.regwriteE(regwriteE),
		.memtoregE(memtoregE),
		.forwardaE(forwardaE),
		.forwardbE(forwardbE),
		.flushE(hazard_flushE),
		
		//�ڴ���ʼ���??
		.writeregM(writeregM),
		.regwriteM(regwriteM),
		.memtoregM(memtoregM),

		//д�ؼ���??
		.writeregW(writeregW),
		.regwriteW(regwriteW),

		.lwstallD(lwstallD),
		.branchstallD(branchstallD)
		
	);

	//��һ��ָ���ַ����
	//mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pcsrcD,pcnextbrFD);  //��ַ���㲿��
    mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pred_takeD,pcnextbrFD);  //��ַ���㲿��
	mux2 #(32) pcmux(pcnextbrFD, {pcplus4D[31:28],instrD[25:0],2'b00}, jumpD, pcnextFD);  //��ַ���㲿��

	wire [31:0] pcD,pcE,pcM;

	//�Ĵ�����??
	regfile rf(clk,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD);


    // ��֧Ԥ�ⲻ��ȷ�����
	wire [31:0] pcnext;
	mux2 #(32) pcError(pcnextFD,pcM,preErrorM & branchM,pcnext);  //��ַ���㲿��

	//ȡָ����??
	pc #(32) pcreg(clk,rst,1'b1,pcnext,pcF);  //��ַ���㲿��
	adder pcadd1(pcF,32'b100,pcplus4F);  //��ַ���㲿��
    
	//new
	flopenrc #(32) pcFD(clk,rst,~stallD,flushD,pcF,pcD);
	floprc #(32) pcDE(clk,rst,flushE,pcD,pcE);
	floprc #(32) pcEM(clk,rst,flushM,pcE,pcM);
	floprc #(32) pred_takeD_DE(clk,rst,flushE,pred_takeD,pred_takeE);
	//branchD, branchE,branchM
	wire branchE;
	floprc #(32) branchDE(clk,rst,flushE,branchD,branchE);
	floprc #(32) branchEM(clk,rst,flushM,branchE,branchM);
	//equalE
	wire equalE;
    //preErrorM
	wire preErrorM_local,preErrorM_global;
	floprc #(32) preErrorEM(clk,rst,flushM,preErrorE,preErrorM);
	floprc #(32) preErrorEM_local(clk,rst,flushM,preErrorE_local,preErrorM_local);
	floprc #(32) preErrorEM_global(clk,rst,flushM,preErrorE_global,preErrorM_global);
	floprc #(32) actual_takeDE(clk,rst,flushE,actual_takeD,actual_takeE);
	floprc #(32) actual_takeEM(clk,rst,flushM,actual_takeE,actual_takeM);



	//��ָ����??
	flopenr #(32) r1D(clk,rst,~stallD,pcplus4F,pcplus4D);  //��ַ���㲿��
	flopenrc #(32) r2D(clk,rst,~stallD,flushD,instrF,instrD);

	signext se(instrD[15:0],signimmD); //32λ������չ������
	sl2 immsh(signimmD,signimmshD); //��ַ���㲿��

	adder pcadd2(pcplus4D,signimmshD,pcbranchD);  //��ַ���㲿��

	mux2 #(32) forwardamux(srcaD,aluoutM,forwardaD,srca2D);
	mux2 #(32) forwardbmux(srcbD,aluoutM,forwardbD,srcb2D);
	eqcmp comp(srca2D,srcb2D,equalD);

	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];

	//���㼶�źŴ�����
	floprc #(32) r1E(clk,rst,flushE,srcaD,srcaE);
	floprc #(32) r2E(clk,rst,flushE,srcbD,srcbE);
	floprc #(32) r3E(clk,rst,flushE,signimmD,signimmE);
	floprc #(5) r4E(clk,rst,flushE,rsD,rsE);
	floprc #(5) r5E(clk,rst,flushE,rtD,rtE);
	floprc #(5) r6E(clk,rst,flushE,rdD,rdE);

	mux3 #(32) forwardaemux(srcaE,resultW,aluoutM,forwardaE,srca2E);
	mux3 #(32) forwardbemux(srcbE,resultW,aluoutM,forwardbE,srcb2E);
	mux2 #(32) srcbmux(srcb2E,signimmE,alusrcE,srcb3E);
	alu alu(srca2E,srcb3E,alucontrolE,aluoutE);
	mux2 #(5) wrmux(rtE,rdE,regdstE,writeregE);

	//�ڴ���ʼ��źŴ�����
	flopr #(32) r1M(clk,rst,srcb2E,writedataM);
	flopr #(32) r2M(clk,rst,aluoutE,aluoutM);
	flopr #(5) r3M(clk,rst,writeregE,writeregM);

	//д�ؼ��źŴ�����
	flopr #(32) r1W(clk,rst,aluoutM,aluoutW);
	flopr #(32) r2W(clk,rst,readdataM,readdataW);
	flopr #(5) r3W(clk,rst,writeregM,writeregW);
	mux2 #(32) resmux(aluoutW,readdataW,memtoregW,resultW);
endmodule
