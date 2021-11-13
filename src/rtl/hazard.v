`timescale 1ns / 1ps

module hazard(

	//取指令阶段信号
	output wire stallF,//取指令级暂停控制信号，低电位有效

	//指令译码阶段信号
	input wire[4:0] rsD,rtD,//指令译码阶段数据前推rs、rd寄存器
	input wire branchD,//条件跳转指令，相等则分支
	output wire forwardaD,forwardbD,//指令译码阶段数据前推rs、rd
	output wire stallD,//译码级暂停控制信号，低电位有效

	//运算级信号
	input wire[4:0] rsE,rtE,//运算阶段数据前推rs寄存器,运算阶段数据前推rt寄存器
	input wire[4:0] writeregE,//运算阶段写寄存器控制信号
	input wire regwriteE,//计算级控制是否写入寄存器
	input wire memtoregE,//指令执行级的存储器写寄存器控制信号
	output reg[1:0] forwardaE,forwardbE,//指令执行级阶段数据前推rs 指令执行级阶段数据前推rt
	output wire flushE,//指令运算级刷新信号

	//内存访问级信号
	input wire[4:0] writeregM,//内存阶段写寄存器控制信号
	input wire regwriteM,// 内存级控制是否写入寄存器
	input wire memtoregM,//内存数据写到寄存器

	//写回级信号
	input wire[4:0] writeregW,//写回阶段写寄存器控制信号
	input wire regwriteW,//写回级控制是否写入寄存器

	output lwstallD,branchstallD
);


	// 分支指令 冒险 产生的数据前推
	assign forwardaD = (rsD != 0 & rsD == writeregM & regwriteM);
	assign forwardbD = (rtD != 0 & rtD == writeregM & regwriteM);
	
	//运算级数据前推
	always @(*) begin
		forwardaE = 2'b00;
		forwardbE = 2'b00;
        /////////////////////////////////////////////////////////////////////////////////////////开始
		//处理两个R型或三个R型指令相关 比如三个add指令，三个都相关
		//处理rs寄存器
		if(rsE != 0) begin
			//此处还需进一步改进 还不能处理连续加法
			if(rsE == writeregM & regwriteM & writeregM !=0 ) begin
				forwardaE = 2'b10;
			end else if(rsE == writeregW & regwriteW & regwriteW !=0) begin
				forwardaE = 2'b01;
			end
		end
		//处理rt寄存器
		if(rtE != 0) begin
			if(rtE == writeregM & regwriteM & writeregM!=0) begin  // writeregM是内存级要写入的目的寄存器编号  regwriteM是是否写寄存器使能
				forwardbE = 2'b10;
			end else if(rtE == writeregW & regwriteW & writeregW!=0) begin
				forwardbE = 2'b01;
			end
		end
		/////////////////////////////////////////////////////////////////////////////////////////结束
	end

	//取指令的暂停控制信号  （属于数据冒险模块）
	assign #1 lwstallD = memtoregE & (rtE == rsD | rtE == rtD);

	//分支指令的暂停控制信号  （属于控制冒险模块）
	assign #1 branchstallD = branchD & ( regwriteE  &  (writeregE == rsD | writeregE == rtD)  |  memtoregM & (writeregM == rsD | writeregM == rtD) );

    //F级暂停
	assign #1 stallF = lwstallD;

    //D级暂停
	assign #1 stallD = lwstallD;

	//E级刷新
	assign #1 flushE = lwstallD;

endmodule
