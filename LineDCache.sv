`include "MacroUtils.sv"

module LineDCache (
	input reset,
	input clk,
	/* verilator lint_off UNDRIVEN */
	/* verilator lint_off UNUSED */
	Muskbus.Top bus,
	/* verilator lint_on UNUSED */
	/* verilator lint_on UNDRIVEN */
	input CACHE::cache_cmd_t req_cmd,
	input logic [63:0] req_addr,
	input logic [63:0] req_data,
	output logic respcyc,
	output logic [63:0] resp_data
);

import CACHE::*;

	/* verilator lint_off UNDRIVEN */
	/* verilator lint_off UNUSED */
	Muskbus rbus, wbus;
	/* verilator lint_on UNUSED */
	/* verilator lint_on UNDRIVEN */

	MuskbusMux mm(reset, clk, rbus, wbus, bus);

	logic rd_reqcyc, rd_respcyc, wt_reqcyc, wt_respcyc;
	logic [63:0] rd_addr, wt_addr;
	logic [0:64*8-1] rd_data, wt_data;

	MuskbusReader reader(reset, clk, rbus, rd_reqcyc, rd_addr, rd_respcyc, rd_data);
	MuskbusWriter writer(reset, clk, wbus, wt_reqcyc, wt_addr, wt_respcyc, wt_data);

	enum { empty, filled } line_state_ff;
	logic [63:0] line_addr_ff;
	logic [0:64*8-1] line_data_ff;
	logic hit;

	assign hit = req_cmd != IDLE && line_state_ff == filled && line_addr_ff[63:6] == req_addr[63:6];

	assign resp_data = `get_64(line_data_ff, req_addr[5:3]);

	assign rd_reqcyc = req_cmd != IDLE && !respcyc && line_state_ff == empty;
	assign rd_addr = req_addr;

	assign wt_reqcyc = req_cmd != IDLE && !respcyc && line_state_ff == filled;
	assign wt_addr = line_addr_ff;
	assign wt_data = line_data_ff;

	always_ff @ (posedge clk) begin
		if (reset) begin
			line_state_ff <= empty;
			line_data_ff <= 0;
			line_addr_ff <= 0;
		end else begin
			if (rd_respcyc) begin
				line_state_ff <= filled;
				line_data_ff <= rd_data;
				line_addr_ff <= rd_addr;
			end else if (wt_respcyc) begin
				line_state_ff <= empty;
				line_data_ff <= 0;
				line_addr_ff <= 0;
			end else if (req_cmd == WRITE && hit) begin
				`get_64(line_data_ff, req_addr[5:3]) <= req_data;
			end
		end
	end

	always_comb begin
		if (req_cmd == FLUSH) begin
			respcyc = !hit;
		end else begin
			respcyc = hit;
		end
	end
endmodule
