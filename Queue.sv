/*
When !full and en_queue, in_data will be latched on next clock edge.
After reset, out_data and out_cnt will always be valid (give data at the head of the queue). 
On de_queue, queue head will advance on next clock edge. 
On strict_de_queue, queue head will advance on next clock edge if out_cnt == OUT_WIDTH.
de_queue and strict_de_queue can not be set at the same time.
*/
module Queue #(IN_WIDTH, OUT_WIDTH, BUF_WIDTH) (
	input logic reset,
	input logic clk,
	input logic en_queue,
	input int in_cnt,
	input logic[0:IN_WIDTH-1] in_data,
	output full,
	input logic de_queue,
	input logic strict_de_queue,
	output int out_cnt,
	output logic[0:OUT_WIDTH-1] out_data
);

	logic [0:BUF_WIDTH-1] buf_ff, new_buf;
	int head_ff, tail_ff;

	always_ff @ (posedge clk) begin
		if (reset) begin
			head_ff <= 0;
		end else if (de_queue || (strict_de_queue && out_cnt == OUT_WIDTH)) begin
			head_ff <= (head_ff + out_cnt) % BUF_WIDTH;
		end

		if (reset) begin
			tail_ff <= 0;
		end else if (!full && en_queue) begin
			tail_ff <= (tail_ff + in_cnt) % BUF_WIDTH;
			buf_ff <= new_buf;
		end

	end

	always_comb begin
		int real_tail = (tail_ff < head_ff) ? BUF_WIDTH + tail_ff : tail_ff;
		logic [0:BUF_WIDTH + OUT_WIDTH - 1] extended_buf = { buf_ff, buf_ff[0:OUT_WIDTH-1] };

		full = (real_tail - head_ff) >= (BUF_WIDTH - IN_WIDTH); // tail == head means empty, thus >= instead of >.
		out_cnt = (real_tail - head_ff) < OUT_WIDTH ? (read_tail - head_ff) : OUT_WIDTH;
		out_data = extended_buf[head_ff +: OUT_WIDTH];
	end

	always_comb begin
		new_buf = buf_ff;
		if (tail_ff + IN_WIDTH <= BUF_WIDTH) begin
			new_buf[tail_ff +: IN_WIDTH] = in_data;
		end else begin
			int prefix_width = BUF_WIDTH - tail_ff;
			int suffix_width = IN_WIDTH - prefix_width;
			new_buf[tail_ff +: prefix_width] = in_data[0 +: prefix_width];
			new_buf[0 +: suffix_width] = in_data[prefix_width +: suffix_width];
		end
	end
endmodule
