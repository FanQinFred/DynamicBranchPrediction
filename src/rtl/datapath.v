`timescale 1ns / 1ps

module datapath(
	
	input wire clk,rst,//时钟信号 重置信号
	
	//取指令阶段信号
	output wire[31:0] pcF, //取指令级地址寄存器
	input wire[31:0] instrF,// 取指令级的指令

	//指令译码阶段信号
	input wire pcsrcD,branchD, //译码阶段地址来源 与 条件跳转指令，相等则分支
	input wire jumpD,//无条件跳转指令地址
	output wire equalD,//两个寄存器源操作数相等则有效
	output wire[5:0] opD,functD,// 指令的操作码字段 //指令的功能码字段

	//运算级信号
	input wire memtoregE,//指令执行级的存储器写寄存器控制信号
	input wire alusrcE,regdstE,//执行指令级寄存器来源//指令执行级目标寄存器
	input wire regwriteE,//计算级控制是否写入寄存器
	input wire[2:0] alucontrolE,//计算单元计算类型选择
	output wire flushE,//指令运算级刷新信号

	//内存访问级信号
	input wire memtoregM,//内存操作级的存储器写寄存器控制信号
	input wire regwriteM,//访问内存级控制是否写入寄存器
	output wire[31:0] aluoutM,writedataM,//运算级的运算结果//待写回内存的值
	input wire[31:0] readdataM,//内存级读出的数据

	//写回级信号
	input wire memtoregW,//写回级的存储器写寄存器控制信号
	input wire regwriteW, //写回级读出的数据

	output wire [4:0] rsE,rtE,rdE,
	output wire [4:0] rsD,rtD,rdD,
	
	output lwstallD,branchstallD,

	output stallF,stallD

);
	
	//取指令阶段信号
	wire stallF;

	//地址控制信号
	wire [31:0] pcnextFD,pcnextbrFD,pcplus4F,pcbranchD;

	//指令译码阶段信号
	wire [31:0] pcplus4D,instrD;
	wire forwardaD,forwardbD;
	
	wire flushD,stallD; 
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srca2D,srcbD,srcb2D;

	//运算级信号
	wire [1:0] forwardaE,forwardbE;
	
	wire [4:0] writeregE;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] aluoutE;

	//内存访问级信号
	wire [4:0] writeregM;

	//写回级信号
	wire [4:0] writeregW;
	wire [31:0] aluoutW,readdataW,resultW;
	
	wire flushM,preErrorM;

	wire preErrorE;
	wire pred_takeD,pred_takeE;

	wire hazard_flushE;

	assign flushD=flushE;
	assign flushE=flushM | hazard_flushE;
	assign flushM=preErrorM;

	wire actual_takeE,actual_takeM;
	assign actual_takeE=equalE & branchE;

	//动态分支预测模块
	branch_predict branch_predict(
		//input
		.clk(clk), .rst(rst),
		.instrD(instrD),
		.flushD(flushD),.flushE(flushE),.flushM(flushM),
		.stallD(stallD),
		.pred_takeE(pred_takeE),            // 预测的是否跳转
		.actual_takeE(actual_takeE),    // 实际是否跳转
		.actual_takeM(actual_takeM),

	    .branchM(branchM),

		.pcF(pcF),
		.pcM(pcM),
		//output
		.pred_takeD(pred_takeD),       // D阶段使用
		.preErrorE(preErrorE)          // E阶段判断预测是否正确
    );

	//冒险模块
	hazard h(

		//取指令阶段信号
		.stallF(stallF),

		//指令译码阶段信号
		.rsD(rsD),
		.rtD(rtD),
		.branchD(branchD), 
		.forwardaD(forwardaD),
		.forwardbD(forwardbD),
		.stallD(stallD),

		//运算级信号
		.rsE(rsE),
		.rtE(rtE),
		.writeregE(writeregE),
		.regwriteE(regwriteE),
		.memtoregE(memtoregE),
		.forwardaE(forwardaE),
		.forwardbE(forwardbE),
		.flushE(hazard_flushE),
		
		//内存访问级信号
		.writeregM(writeregM),
		.regwriteM(regwriteM),
		.memtoregM(memtoregM),

		//写回级信号
		.writeregW(writeregW),
		.regwriteW(regwriteW),

		.lwstallD(lwstallD),
		.branchstallD(branchstallD)
		
	);

	//下一个指令地址计算
	//mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pcsrcD,pcnextbrFD);  //地址计算部分
    mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pred_takeD,pcnextbrFD);  //地址计算部分
	mux2 #(32) pcmux(pcnextbrFD, {pcplus4D[31:28],instrD[25:0],2'b00}, jumpD, pcnext);  //地址计算部分

	wire [31:0] pcnext;
	wire [31:0] pcD,pcE,pcM;

	//寄存器访问
	regfile rf(clk,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD);

	//取指触发器
	pc #(32) pcreg(clk,rst,1'b1,pcnext,pcF);  //地址计算部分
	adder pcadd1(pcF,32'b100,pcplus4F);  //地址计算部分
    
	//new
	flopenrc #(32) pcFD(clk,rst,~stallD,flushD,pcF,pcD);
	floprc #(32) pcDE(clk,rst,flushE,pcD,pcE);
	floprc #(32) pcEM(clk,rst,flushM,pcE,pcM);
	floprc #(32) pred_takeD_DE(clk,rst,flushE,pred_takeD,pred_takeE);
	//branchD, branchE,branchM
	wire branchE,branchM;
	floprc #(32) branchDE(clk,rst,flushE,branchD,branchE);
	floprc #(32) branchEM(clk,rst,flushM,branchE,branchM);
	//equalE
	wire equalE;
	floprc #(32) equalDE(clk,rst,flushE,equalD,equalE);

	//译指触发器
	flopenr #(32) r1D(clk,rst,~stallD,pcplus4F,pcplus4D);  //地址计算部分
	flopenrc #(32) r2D(clk,rst,~stallD,flushD,instrF,instrD);

	signext se(instrD[15:0],signimmD); //32位符号扩展立即数
	sl2 immsh(signimmD,signimmshD); //地址计算部分

	adder pcadd2(pcplus4D,signimmshD,pcbranchD);  //地址计算部分

	mux2 #(32) forwardamux(srcaD,aluoutM,forwardaD,srca2D);
	mux2 #(32) forwardbmux(srcbD,aluoutM,forwardbD,srcb2D);
	eqcmp comp(srca2D,srcb2D,equalD);

	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];

	//运算级信号触发器
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

	//内存访问级信号触发器
	flopr #(32) r1M(clk,rst,srcb2E,writedataM);
	flopr #(32) r2M(clk,rst,aluoutE,aluoutM);
	flopr #(5) r3M(clk,rst,writeregE,writeregM);

	//写回级信号触发器
	flopr #(32) r1W(clk,rst,aluoutM,aluoutW);
	flopr #(32) r2W(clk,rst,readdataM,readdataW);
	flopr #(5) r3W(clk,rst,writeregM,writeregW);
	mux2 #(32) resmux(aluoutW,readdataW,memtoregW,resultW);
endmodule
