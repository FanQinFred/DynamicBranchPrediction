`timescale 1ns / 1ps

module maindec(
	input wire[5:0] op,

	output wire memtoreg,memwrite,
	output wire branch,alusrc,
	output wire regdst,regwrite,
	output wire jump,
	output wire[1:0] aluop
    );
	reg[8:0] controls;
	assign {regwrite,regdst,alusrc,branch,memwrite,memtoreg,jump,aluop} = controls;

	//op觉得控制信号
	always @(*) begin
		case (op)
			6'b000000:controls <= 9'b110000010;
			6'b100011:controls <= 9'b101001000;
			6'b101011:controls <= 9'b001010000;
			6'b000100:controls <= 9'b000100001;
			6'b001000:controls <= 9'b101000000;
			6'b000010:controls <= 9'b000000100;
			default:  controls <= 9'b000000000;
		endcase
	end
endmodule
