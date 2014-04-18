module MuskbusReader (
	input reset,
	input clk,
	output MUSKBUS::req_t bus_req,
	output logic bus_respack,
	input MUSKBUS::resp_t bus_resp,
	input logic bus_reqack,
	input logic reqcyc,
	input logic [63:0] addr,
	output logic respcyc,
	output logic [0:64*8-1] data
);

	enum { idle, init, waiting, reading, serving } state_ff, new_state_cb;
	logic [0:64*8-1] buf_ff;
	logic read_acked_ff;
	int offset_ff;

	always_ff @ (posedge clk) begin
		if (reset) begin
			state_ff <= idle;
		end else begin
			state_ff <= new_state_cb;
		end

		if (reset) begin
			offset_ff <= 0;
			read_acked_ff <= 0;
		end

		if (bus_resp.respcyc) begin
			buf_ff[offset_ff +: 64] <= bus_resp.resp;
			offset_ff <= offset_ff + 64;
		end

		if (bus_resp.reqack) read_acked_ff <= 1;

		if (new_state_cb == idle) begin
			offset_ff <= 0;
			read_acked_ff <= 0;
		end
	end

	always_comb begin
		new_state_cb = state_ff;
		unique case(state_ff)
			idle : if (reqcyc) new_state_cb = reading;
			reading : if (offset_ff == 64 * 8) new_state_cb = serving;
			serving : new_state_cb = idle;
		endcase

		bus_req = 0;
		bus_respack = 0;
		respcyc = 0;
		data = 0;

		if (new_state_cb == reading) bus_req.bid = 1;

		if (new_state_cb == reading && !read_acked_ff) begin
			bus_req.reqcyc = 1;
			bus_req.reqtag = MUSKBUS::READ_MEM_TAG;
			bus_req.req = addr;
		end

		bus_respack = bus_resp.respcyc;

		if (new_state_cb == serving) begin
			respcyc = 1;
			data = buf_ff;
		end
	end

endmodule
