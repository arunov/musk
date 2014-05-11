module APipeline(
	input logic reset,
	input logic clk,
	input logic in_ready,
	input DecoderTypes::micro_op_t in_mop,
	output logic busy,
	output logic out_ready,
	output DecoderTypes::micro_op_t out_mop
);

import DecoderTypes::*;

	logic alu_in_ready_ff, alu_out_ready_ff;
	micro_op_t alu_in_ff, alu_out_ff;

	always_ff @ (posedge clk) begin
		if (reset) begin
			alu_in_ready_ff <= 0;
		end else begin
			alu_in_ready_ff <= in_ready;
		end
		alu_in_ff <= in_mop;
	end

	always_ff @ (posedge clk) begin
		if (reset) begin
			alu_out_ready_ff <= 0;
		end else begin
			alu_out_ready_ff <= alu_in_ready_ff;
			if (alu_in_ready_ff) alu_out_ff <= ALU::alu(alu_in_ff);
		end
	end

	assign out_ready = alu_out_ready_ff;
	assign out_mop = alu_out_ff;
	assign busy = 0;
endmodule
