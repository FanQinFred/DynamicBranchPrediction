`timescale 1ns / 1ps

//顶层模块设计
module top(
	input wire clk,rst,
	output wire[31:0] writedata,dataadr,
	output wire memwrite,
	output [31:0] instr,pc,readdata,
  
	output wire [4:0] rsE,rtE,rdE,
	output wire [4:0] rsD,rtD,rdD,

	output lwstallD,branchstallD,

	output stallF,
	output flushE,stallD
);

wire[31:0] pc,instr,readdata;

//mips
mips mips(
	.clk(clk),
	.rst(rst),
	.pcF(pc),
	.instrF(instr),
	.memwriteM(memwrite),
	.aluoutM(dataadr),
	.writedataM(writedata),
	.readdataM(readdata),
	.rsE(rsE),.rtE(rtE),.rdE(rdE),
	.rsD(rsD),.rtD(rtD),.rdD(rdD),

	.lwstallD(lwstallD),
	.branchstallD(branchstallD),

	.stallF(stallF),
	.flushE(flushE),.stallD(stallD)
);

//指令
inst_mem imem (
  .clka(~clk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(),      // input wire [3 : 0] wea
  .addra(pc),  // input wire [31 : 0] addra
  .dina(32'b0),    // input wire [31 : 0] dina
  .douta(instr)  // output wire [31 : 0] douta
);

//数据
data_mem dmem (
  .clka(~clk),    // input wire clka
  .ena(memwrite),      // input wire ena
  .wea({4{memwrite}}),      // input wire [3 : 0] wea
  .addra(dataadr),  // input wire [31 : 0] addra
  .dina(writedata),    // input wire [31 : 0] dina
  .douta(readdata)  // output wire [31 : 0] douta
);
endmodule
