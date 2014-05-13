module MPipeline(
	input logic reset,
	input logic clk,
	input logic in_ready,
	input DecoderTypes::micro_op_t in_mop,
	output logic busy,
	output logic out_ready,
	output DecoderTypes::micro_op_t out_mop,
	output CACHE::cache_cmd_t ca_req_cmd,
	output logic [63:0] ca_req_addr,
	output logic [63:0] ca_req_data,
	input logic ca_respcyc,
	input logic [63:0] ca_resp_data
);

import CACHE::*;
import DecoderTypes::*;

	logic mem_running_ff, mem_returns_ff;
	micro_op_t mem_cmd_ff, mem_out_ff, mem_out_cb;
	logic pipe_moving;

	assign pipe_moving = ca_respcyc || ca_req_cmd == IDLE;

	always_ff @ (posedge clk) begin
		if (reset) begin
			mem_running_ff <= 0;
		end else begin
			mem_running_ff <= in_ready || !pipe_moving;
		end

		if (in_ready && pipe_moving) mem_cmd_ff <= in_mop;
	end

	always_comb begin
		if (mem_running_ff) begin
			// $display("%s", mop_id2name(mem_cmd_ff.opcode));
			case (mem_cmd_ff.opcode)
				m_ld : ca_req_cmd = READ;
				m_st : ca_req_cmd = WRITE;
				m_clflush : ca_req_cmd = FLUSH;
				m_mnop : ca_req_cmd = IDLE;
				default : begin
					ca_req_cmd = IDLE;
					$display("ERROR: unknown mem pipeline cmd: %x", mem_cmd_ff.opcode);
				end
			endcase
		end else begin
			ca_req_cmd = IDLE;
		end

		if (mem_cmd_ff.opcode == m_st) begin
			ca_req_data = Utils::val_to_le_8bytes(mem_cmd_ff.src0_val.val);
			ca_req_addr = mem_cmd_ff.src1_val.val;
		end else begin
			ca_req_addr = mem_cmd_ff.src0_val.val;
			ca_req_data = 0;
		end
	end

	always_ff @ (posedge clk) begin
		if (reset) begin
			mem_returns_ff <= 0;
		end else begin
			mem_returns_ff <= ca_respcyc || (mem_running_ff && ca_req_cmd == IDLE);
		end
		mem_out_ff <= mem_out_cb;
	end

	always_comb begin
		mem_out_cb = mem_cmd_ff;
		mem_out_cb.dst_val.val = Utils::le_8bytes_to_val(ca_resp_data);
	end

	assign out_ready = mem_returns_ff;
	assign out_mop = mem_out_ff;
	assign busy = !pipe_moving;
endmodule
