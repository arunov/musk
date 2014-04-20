`include "UOP.sv"

module UopQueue (
	input logic reset,
	input logic clk,
	input uop_ins_t[IN_UOP-1:0] in_uop,
	input uop_size_t in_size,
	output uop_size_t q_elements, // Number of uops in queue
	input logic get_uop,
	output uop_ins_t[OUT_UOP-1:0] out_uop,
	output uop_size_t out_size
);

	uop_index_t head, tail;
	uop_ins_t[QU_UOP-1:0] queue;

	uop_index_t new_head, new_tail;
	uop_size_t q_space;

	always_ff @ (posedge clk) begin
		if(reset) begin
			head <= 0;
			tail <= 0;
		end else begin
			head <= new_head;
			tail <= new_tail;
		end
	end

	always_comb begin
		new_head = head;
		new_tail = tail;

		q_elements = tail - head;
		q_space = QU_UOP - q_elements;

		if(in_size > 0 && q_space >= in_size) begin
			uop_index_t i;
			for(i = 0; i < in_size; i++) begin
				queue[tail+i] = in_uop[i];
			end
			new_tail = tail + in_size;
		end

		if(get_uop && q_elements > 0) begin
			uop_index_t i;
			for(i = 0; i < OUT_UOP; i ++) begin
				out_uop[i] = queue[head+i];
			end
			new_head = head + OUT_UOP;
		end
	end
endmodule

