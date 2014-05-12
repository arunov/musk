module MuskbusMux (
	input reset,
	input clk,
	/* verilator lint_off UNDRIVEN */
	/* verilator lint_off UNUSED */
	Muskbus.Bottom bot0,
	Muskbus.Bottom bot1,
	Muskbus.Top top
	/* verilator lint_on UNUSED */
	/* verilator lint_off UNDRIVEN */
);

	enum { idle, busy } state_ff, new_state_cb;
	int user_ff, new_user_cb;

	always_ff @ (posedge clk) begin
		if (reset) begin
			state_ff <= idle;
			user_ff <= 0;
		end else begin
			state_ff <= new_state_cb;
			user_ff <= new_user_cb;
		end
	end

	always_comb begin
		new_state_cb = state_ff;
		new_user_cb = user_ff;
		unique case (state_ff)
			idle : begin
				if (bot0.bid) begin 
					new_state_cb = busy;
					new_user_cb = 0;
				end else if (bot1.bid) begin
					new_state_cb = busy;
					new_user_cb = 1;
				end
			end
			busy : begin 
				if ((user_ff == 0 && !bot0.bid) || (user_ff == 1 && !bot1.bid)) begin
					new_state_cb = idle;
				end
			end
		endcase 
	end

	always_comb begin

		top.bid     = 0;
		top.reqcyc  = 0;
		top.reqtag  = 0;
		top.req     = 0;
		top.respack = 0;

		bot0.respcyc = 0;
		bot0.resp    = 0;
		bot0.reqack  = 0;

		bot1.respcyc = 0;
		bot1.resp    = 0;
		bot1.reqack  = 0;

		if (new_user_cb == 0 && new_state_cb == busy) begin

			top.bid     = bot0.bid;
			top.reqcyc  = bot0.reqcyc;
			top.reqtag  = bot0.reqtag;
			top.req     = bot0.req;
			top.respack = bot0.respack;

			bot0.respcyc = top.respcyc;
			bot0.resp    = top.resp;
			bot0.reqack  = top.reqack;

		end else if (new_user_cb == 1 && new_state_cb == busy) begin

			top.bid     = bot1.bid;
			top.reqcyc  = bot1.reqcyc;
			top.reqtag  = bot1.reqtag;
			top.req     = bot1.req;
			top.respack = bot1.respack;

			bot1.respcyc = top.respcyc;
			bot1.resp    = top.resp;
			bot1.reqack  = top.reqack;

		end
	end

endmodule
