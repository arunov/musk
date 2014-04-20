module MuskbusMux #(N = 2) (
	input reset,
	input clk,
	/* verilator lint_off UNDRIVEN */
	/* verilator lint_off UNUSED */
	Muskbus.Bottom bottoms[N],
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
				int k, ii;
				for (k = 0; k < N; k++) begin
					ii = (user_ff + 1 + k) % N;
					if (bottoms[ii].bid) begin
						new_state_cb = busy;
						new_user_cb = ii;
						break;
					end
				end
			end
			busy : begin 
				if (!bottoms[user_ff].bid) new_state_cb = idle;
			end
		endcase 

		top.req = bottoms[new_user_cb];
		top.respack = bottoms[new_user_cb];

		bottom_resps = 0;
		bottom_reqacks = 0;
		bottom_resps[new_user_cb] = top_result;
		bottom_reqacks[new_user_cb] = top_reqack;
	end

endmodule
