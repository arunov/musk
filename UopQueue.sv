import UOP::*;

module UopQueue (
	input logic reset,
	input logic clk,
	input UOP::uop_ins_t[0:(UOP::IN_UOP-1)] in_uop,
	input UOP::uop_size_t in_size,
	output UOP::uop_size_t q_elements, // Number of uops in queue
	input logic get_uop,
	output UOP::uop_ins_t[0:(UOP::OUT_UOP-1)] out_uop,
	output UOP::uop_size_t out_size
);

	UOP::uop_index_t head, tail, head_old, tail_old;
	UOP::uop_ins_t[0:(UOP::QU_UOP-1)] queue;
	UOP::uop_size_t q_space, q_out_size;

	always_ff @ (posedge clk) begin
		head_old <= head;
		tail_old <= tail;
		if(reset) begin
			head <= 0;
			tail <= 0;
		end else begin
			if(in_size > 0 && q_space >= in_size) begin
				int i;
				for(i = 0; i < int'(in_size); i ++) begin
					queue[i+int'(tail)] <= in_uop[i];
				end
				tail <= tail + in_size;
			end

			if(get_uop && q_elements > 0) begin
				int i;
				for(i = 0; i < int'(q_out_size); i ++) begin
					out_uop[i] <= queue[i+int'(head)];
				end
				head <= head + q_out_size;
				out_size <= q_out_size;
			end
		end
	end

	always_comb begin
		q_elements = tail - head;
		q_space = UOP::QU_UOP - q_elements;

		if(q_elements > UOP::OUT_UOP) begin
			q_out_size = UOP::OUT_UOP;
		end else begin
			q_out_size = q_elements;
		end
	end

endmodule

