module Core (
	input[63:0] entry,
	/* verilator lint_off UNDRIVEN */
	/* verilator lint_off UNUSED */ 
	Sysbus bus 
	/* verilator lint_on UNUSED */
	/* verilator lint_on UNDRIVEN */
);

	logic reset, clk;
	/* verilator lint_off UNDRIVEN */
	/* verilator lint_off UNUSED */
	Muskbus muskbus;
	/* verilator lint_on UNUSED */
	/* verilator lint_on UNDRIVEN */

	assign reset = bus.reset;
	assign clk = bus.clk;

	assign bus.reqcyc = muskbus.reqcyc;
	assign bus.reqtag = muskbus.reqtag;
	assign bus.req = muskbus.req;
	assign bus.respack = muskbus.respack;

	assign muskbus.respcyc = bus.respcyc;
	assign muskbus.resp = bus.resp;
	assign muskbus.reqack = bus.reqack;

/*
	always_comb begin
		$display("#####");
		$display("reqcyc=%x", muskbus.reqcyc);
		$display("reqtag=%x", muskbus.reqtag);
		$display("req=%x", muskbus.req);
		$display("respack=%x", muskbus.respack);
		$display("respcyc=%x", muskbus.respcyc);
		$display("resp=%x", muskbus.resp);
		$display("reqack=%x", muskbus.reqack);
	end
*/

	MuskCore core(entry, reset, clk, muskbus);

endmodule
