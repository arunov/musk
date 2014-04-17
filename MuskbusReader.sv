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

	enum { idle, sending, waiting, recving, serving } state_ff, new_state_cb;
	logic [0:64*8-1] buf_ff;
	int offset_ff;

	always_ff @ (posedge clk) begin
		if (reset) begin
			state_ff <= idle;
			offset_ff <= 0;
		end else begin
			state_ff <= new_state_cb;
		end

		if (new_state_cb == idle) offset_ff <= 0;

		if (new_state_cb == recving && bus_resp.respcyc) begin
		end
	end

	always_comb begin
		new_state_cb = state_ff;
		unique case(state_ff)
			idle : if (reqcyc) new_state_cb = sending;
			sending : if (bus_reqack) new_state_cb = waiting;
			waiting : if (bus_resp.respcyc) new_state_cb = recving;
			recving : if (offset_ff == 64 * 8) new_state_cb = serving;
			serving : if (!reqcyc) new_state_cb = idle;
		endcase

		bus_req = 0;
		bus_respack = 0;
		respcyc = 0;
		data = 0;

		if (new_state_cb != idle) bus_req.bid = 1;

		if (new_state_cb == sending) begin
			bus_req.reqcyc = 1;
			bus_req.reqtag = MUSKBUS::READ_MEM_TAG;
			bus_req.req = addr;
		end

		if (new_state_cb == recving) begin
			bus_respack = 1;
		end

		if (new_state_cb == serving) begin
			respcyc = 1;
			data = buf_ff;
		end
	end

endmodule
