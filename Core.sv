module Core (
	input[63:0] entry
,	/* verilator lint_off UNDRIVEN */ /* verilator lint_off UNUSED */ Sysbus bus /* verilator lint_on UNUSED */ /* verilator lint_on UNDRIVEN */
);

	logic reset, clk;
	MUSKBUS::req_t req;
	MUSKBUS::resp_t resp;
	logic reqack, respack;
	/* verilator lint_off UNUSED */ logic dummy_bid; /* verilator lint_on UNUSED */

	assign reset = bus.reset;
	assign clk = bus.clk;

	assign dummy_bid = req.bid;
	assign bus.reqcyc = req.reqcyc;
	assign bus.reqtag = req.reqtag;
	assign bus.req = req.req;

	assign bus.respack = respack;

	assign resp.respcyc = bus.respcyc;
	//assign resp.resptag = bus.resptag;
	assign resp.resp = bus.resp;

	assign reqack = bus.reqack;

	MuskCore core(entry, reset, clk, req, respack, resp, reqack);

endmodule
