/*
When en_queue, in_data will be latched on next clock edge.
After reset, out_data will always contain data at the head of the queue. 
After reset, data_cnt will always report amount of data in queue. 
On de_queue, queue head will advance on next clock edge. 
User should check empty_cnt and empty_cnt before making requests.
*/
module Queue #(IN_WIDTH, OUT_WIDTH, BUF_WIDTH) (
	input logic reset,
	input logic clk,
	input logic en_queue,
	input int in_cnt,
	input logic[0:IN_WIDTH-1] in_data,
	input logic de_queue,
	input int out_cnt,
	output logic[0:OUT_WIDTH-1] out_data
	output int used_cnt,
	output int empty_cnt,
);

	parameter R_BUF_WIDTH = BUF_WIDTH + 1; // extra bit is needed distinguish empty and full.

	logic [0:R_BUF_WIDTH-1] buf_ff, new_buf;
	int head_ff, tail_ff;

	always_ff @ (posedge clk) begin
		if (reset) begin
			head_ff <= 0;
		end else if (de_queue) begin
			assert(out_cnt <= data_cnt && out_cnt <= OUT_WIDTH) else $fatal;
			head_ff <= (head_ff + out_cnt) % R_BUF_WIDTH;
		end

		if (reset) begin
			tail_ff <= 0;
		end else if (en_queue) begin
			assert(in_cnt <= empty_cnt && in_cnt <= IN_WIDTH) else $fatal;
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
		new_buf = buf_ff;
		if (tail_ff + IN_WIDTH <= R_BUF_WIDTH) begin
			new_buf[tail_ff +: IN_WIDTH] = in_data;
		end else begin
			int prefix_width = R_BUF_WIDTH - tail_ff;
			int suffix_width = IN_WIDTH - prefix_width;
			new_buf[tail_ff +: prefix_width] = in_data[0 +: prefix_width];
			new_buf[0 +: suffix_width] = in_data[prefix_width +: suffix_width];
		end
	end
endmodule
