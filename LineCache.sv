module LineCache (
	input reset,
	input clk,
	output MUSKBUS::req_t bus_req,
	output logic bus_respack,
	input MUSKBUS::resp_t bus_resp,
	input logic bus_reqack,
	input logic reqcyc,
	input CACHE::cmd_t cmd,
	input logic [63:0] req_addr,
	input logic [63:0] req_data,
	output logic respcyc,
	output logic [63:0] resp_data
);

	enum { idle } state_ff, new_state_cb;
	enum { empty, filled } linestate_ff, new_linestate_cb;
	logic [63:0] lineaddr_ff;
	logic [0:64*8-1] line_ff;

	always_ff @ (posedge clk) begin
		if (reset) begin
			state_ff <= idle;
			linestate_ff <= empty;
		end else begin
			state_ff <= new_state_cb;
			linestate_ff <= new_linestate_cb;
		end
	end

endmodule
