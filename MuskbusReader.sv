module MuskbusReader (
	input reset,
	input clk,
	/* verilator lint_off UNUSED */
	Muskbus.Top bus,
	/* verilator lint_on UNUSED */
	input logic reqcyc,
	input logic [63:0] addr,
	output logic respcyc,
	output logic [0:64*8-1] data
);

	enum { idle, reading } state_ff, new_state_cb;
	logic reqack_received_ff;
	logic [0:64*8-1] buf_ff;
	int offset_ff;

	always_ff @ (posedge clk) begin
		if (reset) begin
			state_ff <= idle;
			offset_ff <= 0;
			reqack_received_ff <= 0;
		end else begin
			state_ff <= new_state_cb;
			if (bus.respcyc) begin
				buf_ff[offset_ff +: 64] <= bus.resp;
				offset_ff <= offset_ff + 64;
			end
			if (bus.reqack) begin
				reqack_received_ff <= 1;
			end
			if (new_state_cb == idle) begin
				offset_ff <= 0;
				reqack_received_ff <= 0;
			end
		end
	end

	always_comb begin
		new_state_cb = state_ff;
		unique case(state_ff)
			idle : if (reqcyc) new_state_cb = reading;
			reading : if (offset_ff == 64 * 8) new_state_cb = idle;
		endcase

		bus.bid = 0;
		bus.reqcyc = 0;
		bus.reqtag = MUSKBUS::READ_MEM_TAG;
		bus.req = addr;
		bus.respack = bus.respcyc;

		respcyc = 0;
		data = 0;

		// The state_ff == reading condition is to let respack last for one
		// more cycle after all data are read, such that system.cpp will pop
		// the last item off the queue.
		// Also, don't bid as soon as new_state_cb becomes reading, otherwise
		// the reader could occupy the bus for too long.
		if (state_ff == reading) bus.bid = 1;

		if (state_ff == reading && !reqack_received_ff) begin
			bus.reqcyc = 1;
		end

		if (offset_ff == 64 * 8) begin
			respcyc = 1;
			data = buf_ff;
		end
	end

endmodule
