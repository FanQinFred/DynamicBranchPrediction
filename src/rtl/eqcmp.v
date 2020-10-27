`timescale 1ns / 1ps


module eqcmp(
	input wire [31:0] a,b,
	output wire y
    );

	assign y = (a == b) ? 1 : 0;
endmodule
