`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/07 13:54:42
// Design Name: 
// Module Name: testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module testbench();
	reg clk;
	reg rst;

	wire[31:0] writedata,dataadr;
	wire[31:0] instr,pc,readdata;
	wire memwrite;

	wire lwstallD,branchstallD;

	
	wire [4:0] rsE,rtE,rdE;
	wire [4:0] rsD,rtD,rdD;

	wire stallF;
	wire flushE,stallD;

	top dut(
		.clk(clk),
		.rst(rst),
		.writedata(writedata),
		.dataadr(dataadr),
		.memwrite(memwrite),
		.instr(instr),
		.pc(pc),
		.readdata(readdata),
		
	    .rsE(rsE),.rtE(rtE),.rdE(rdE),
	    .rsD(rsD),.rtD(rtD),.rdD(rdD),

		.lwstallD(lwstallD),.branchstallD(branchstallD),

		.stallF(stallF),
	    .flushE(flushE),.stallD(stallD)
	);

	initial begin 
		rst <= 1;
		#205;
		rst <= 0;
	end

	always begin
		clk <= 1;
		#10;
		clk <= 0;
		#10;
	end

	always @(negedge clk) begin
		if(memwrite) begin
			/* code */
			if(dataadr === 84 & writedata === 7) begin
				/* code */
				$display("Simulation succeeded");
				$stop;
			end else if(dataadr !== 80) begin
				/* code */
				$display("Simulation Failed");
				$stop;
			end
		end
	end
endmodule
