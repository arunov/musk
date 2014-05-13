/*
When en_queue, in_data will be latched on next clock edge.
After reset, out_data will always contain data at the head of the queue. 
After reset, data_cnt will always report amount of data in queue. 
On de_queue, queue head will advance on next clock edge. 
User should check empty_cnt and empty_cnt before making requests.
DATA_BUF_WIDTH should be at least (IN_WIDTH * 2 - 2).
Do NOT enqueue when empty_cnt < IN_WIDTH.
*/
module Queue #(IN_WIDTH = 64, OUT_WIDTH = 64, DATA_BUF_WIDTH = 64 * 4) (
	input logic reset,
	input logic clk,
	input logic en_queue,
	input int in_cnt,
	input logic[0:IN_WIDTH-1] in_data,
	input logic de_queue,
	input int out_cnt,
	output logic[0:OUT_WIDTH-1] out_data,
	output int used_cnt,
	output int empty_cnt
);

	parameter R_BUF_WIDTH = DATA_BUF_WIDTH + 1; // extra bit is needed distinguish empty and full.

	logic [0:R_BUF_WIDTH-1] buf_ff, new_buf;
	int head_ff, tail_ff;

	always_ff @ (posedge clk) begin
		if (reset) begin
			head_ff <= 0;
		end else if (de_queue) begin
			assert(out_cnt <= used_cnt && out_cnt <= OUT_WIDTH) else $fatal;
			head_ff <= (head_ff + out_cnt) % R_BUF_WIDTH;
		end

		if (reset) begin
			tail_ff <= 0;
		end else if (en_queue) begin
			assert(in_cnt <= IN_WIDTH && IN_WIDTH <= empty_cnt) else $fatal;
			tail_ff <= (tail_ff + in_cnt) % R_BUF_WIDTH;
			buf_ff <= new_buf;
		end
	end

	always_comb begin
		int real_tail = (tail_ff < head_ff) ? R_BUF_WIDTH + tail_ff : tail_ff;
		logic [0:R_BUF_WIDTH + OUT_WIDTH - 1] extended_buf = { buf_ff, buf_ff[0:OUT_WIDTH-1] };

		out_data = extended_buf[head_ff +: OUT_WIDTH];
		used_cnt = real_tail - head_ff;
		empty_cnt = R_BUF_WIDTH - used_cnt - 1; // tail == head means empty, thus the -1. 
	end

	always_comb begin
		logic [0:R_BUF_WIDTH + IN_WIDTH - 1] extended_buf = { buf_ff, buf_ff[0 +: IN_WIDTH] };
		extended_buf[tail_ff +: IN_WIDTH] = in_data;
		new_buf = extended_buf[0 +: R_BUF_WIDTH];
		if (tail_ff + IN_WIDTH > R_BUF_WIDTH) begin
			// This trick only works if R_BUF_WIDTH >= (IN_WIDTH * 2 - 1) and empty_cnt >= IN_WIDTH.
			new_buf[0 +: IN_WIDTH] = extended_buf[R_BUF_WIDTH +: IN_WIDTH];
		end
	end
endmodule
