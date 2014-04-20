`include "UOP.sv"

logic _reset;
uop_ins_t[IN_UOP-1:0] _in_uop = {"a", "b", "c", "d"};
uop_size_t _in_size;
uop_size_t _q_elements; // Number of uops in queue
logic _get_uop = 0;
uop_ins_t[OUT_UOP-1:0] _out_uop;
uop_size_t _out_size;

UopQueue queue(bus.clk, _reset, _in_uop, _in_size, _q_elements, _get_uop, _out_uop, _out_size);

logic[3:0] reset_values = {1'b1, 1'b0, 1'b0, 1'b0};
uop_size_t[3:0] in_size_values = {0, 1, 2, 0};

int count = 0;

always_ff @ (posedge bus.clk) begin
	if(count < 4) begin
		_reset = reset_values[count];
		_in_size = in_size_values[count];
		$display("q_elements: %d", _q_elements);
	end
	count = count + 1;
end



