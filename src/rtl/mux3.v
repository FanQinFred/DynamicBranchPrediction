`timescale 1ns / 1ps

//数据前推控制信号
module mux3 #(parameter WIDTH = 8)(
	input wire[WIDTH-1:0] d0,d1,d2,
	input wire[1:0] s,
	output wire[WIDTH-1:0] y
    );

	assign y = (s == 2'b00) ? d0 :
				(s == 2'b01) ? d1:
				(s == 2'b10) ? d2: d0;
endmodule
