module MuskbusMux #(N = 2) (
	input reset,
	input clk,
	input MUSKBUS::req_t[N-1:0] bottom_reqs,
	input logic [N-1:0] bottom_respacks,
	output MUSKBUS::resp_t[N-1:0] bottom_resps,
	output logic [N-1:0] bottom_reqacks,
	output MUSKBUS::req_t top_req,
	output logic top_respack,
	input MUSKBUS::resp_t top_resp,
	input logic top_reqack
);

	typedef enum { idle, busy } state_t;

	state_t state_ff, new_state_cb;
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
					if (bottom_commands[ii].bid) begin
						new_state_cb = busy;
						new_user_cb = ii;
						break;
					end
				end
			end
			busy : begin 
				if (!bottom_commands[user_ff].bid) new_state_cb = idle;
			end
		endcase 

		top_req = bottom_reqs[new_user_cb];
		top_respack = bottom_respacks[new_user_cb];

		bottom_resps = 0;
		bottom_reqacks = 0;
		bottom_resps[new_user_cb] = top_result;
		bottom_reqacks[new_user_cb] = top_reqack;
	end

endmodule
