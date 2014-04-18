module MuskbusWriter (
	input reset,
	input clk,
	output MUSKBUS::req_t bus_req,
	output logic bus_respack,
	input MUSKBUS::resp_t bus_resp,
	input logic bus_reqack,
	input logic reqcyc,
	input logic [63:0] addr,
	output logic respcyc,
	input logic [0:64*8-1] data
);

	enum { idle, writing, serving } state_ff, new_state_cb;
	int offset_ff;
	logic got_first_ack_ff;

	always_ff @ (posedge clk) begin
		if (reset) begin
			state_ff <= idle;
		end else begin
			state_ff <= new_state_cb;
		end

		if (reset) begin
			offset_ff <= 0;
			got_first_ack_ff <= 0;
		end

		if (got_first_ack_ff && bus_reqack) begin
			offset_ff <= offset_ff + 64;
		end

		if (new_state_cb == idle) begin
			offset_ff <= 0;
			got_first_ack_ff <= 0;
		end
	end

	always_comb begin
		new_state_cb = state_ff;
		unique case(state_ff)
			idle : if (reqcyc) new_state_cb = writing;
			writing : if (offset_ff == 64 * 8) new_state_cb = serving;
			serving : new_state_cb = idle;
		endcase

		bus_req = 0;
		bus_respack = 0;
		respcyc = 0;

		if (new_state_cb == writing) bus_req.bid = 1;

		if (new_state_cb == writing && !got_first_ack_ff) begin
			bus_req.reqcyc = 1;
			bus_req.reqtag = MUSKBUS::WRITE_MEM_TAG;
			bus_req.req = addr;
		end

		if (new_state_cb == writing && got_first_ack_ff) begin
			bus_req.reqcyc = 1;
			bus_req.reqtag = MUSKBUS::WRITE_MEM_TAG;
			bus_req.req = data[offset_ff +: 64];
		end

		if (new_state_cb == serving) begin
			respcyc = 1;
		end
	end

endmodule
