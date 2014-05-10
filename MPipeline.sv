
import CACHE::*;
import DecoderTypes::*;

module MPipeline(
	input logic reset,
	input logic clk,
	input logic in_ready,
	input micro_op_t in_mop,
	output logic busy,
	output logic out_ready,
	output micro_op_t out_mop
	output cache_cmd_t ca_req_cmd,
	output logic [63:0] ca_req_addr,
	output logic [63:0] ca_req_data,
	input logic ca_respcyc,
	input logic [63:0] ca_resp_data
);

	logic mem_running_ff, mem_returns_ff;
	micro_op_t mem_cmd_ff, mem_out_ff, mem_out_cb;

	always_ff @ (posedge clk) begin
		if (reset) begin
			mem_running_ff <= 0;
		end else begin
			mem_running_ff <= in_ready || (mem_running_ff && !ca_respcyc);
		end

		if (in_ready && (!mem_running_ff || ca_respcyc)) mem_cmd_ff <= in_mop;
	end

	always_comb begin
		if (mem_running_ff) begin
			case (mem_cmd_ff.opcode)
				m_ld : ca_req_cmd = READ;
				m_st : ca_req_cmd = WRITE;
				default : begin
					ca_req_cmd = IDLE;
					$display("ERROR: unknown mem pipeline cmd: %x", mem_cmd_ff.opcode);
					$finish;
				end
			endcase
		end else begin
			ca_req_cmd = IDLE;
		end

		if (mem_cmd_ff.opcode == m_st) begin
			ca_req_data = mem_cmd_ff.src0_val.val;
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
			mem_returns_ff <= ca_respcyc;
		end
		mem_out_ff <= mem_out_cb;
	end

	always_comb begin
		mem_out_cb = mem_cmd_ff;
		mem_out_cb.dst_val.val = ca_resp_data;
	end

	assign out_ready = mem_returns_ff;
	assign out_mop = mem_out_ff;
	assign busy = mem_running_ff && !ca_respcyc;
endmodule
