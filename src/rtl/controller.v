`timescale 1ns / 1ps


module controller(
	input wire clk,rst,
	
	//decode stage
	input wire[5:0] opD,functD,
	output wire pcsrcD,branchD,jumpD,

	input equalD,
	
	//execute stage
	input wire flushE,
	output wire memtoregE,alusrcE,
	output wire regdstE,regwriteE,	
	output wire[2:0] alucontrolE,

	//mem stage
	output wire memtoregM,memwriteM,regwriteM,
	
	//write back stage
	output wire memtoregW,regwriteW

);
	
	//decode stage
	wire[1:0] aluopD;
	wire memtoregD,memwriteD,alusrcD,regdstD,regwriteD;
	wire[2:0] alucontrolD;

	//execute stage
	wire memwriteE;

	maindec md(
		opD,
		memtoregD,memwriteD,
		branchD,alusrcD,
		regdstD,regwriteD,
		jumpD,
		aluopD
	);

	aludec ad(functD,aluopD,alucontrolD);

	assign pcsrcD = branchD & equalD;

	//pipeline registers
	floprc #(8) regE(
		clk,
		rst,
		flushE,
		{memtoregD,memwriteD,alusrcD,regdstD,regwriteD,alucontrolD},
		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,alucontrolE}
	);

	flopr #(8) regM(
		clk,rst,
		{memtoregE,memwriteE,regwriteE},
		{memtoregM,memwriteM,regwriteM}
	);

	flopr #(8) regW(
		clk,rst,
		{memtoregM,regwriteM},
		{memtoregW,regwriteW}
	);

endmodule
