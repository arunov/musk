module MuskCore (
	/* verilator lint_off UNUSED */
	input[63:0] entry,
	input reset,
	input clk,
	Muskbus.Top bus
	/* verilator lint_on UNUSED */
);
/*
	enum {fetch_idle, fetch_active} fetch_state_ff, new_fetch_state_cb;
	logic[63:0] fetch_rip_ff;
	logic[0:2*64*8-1] decode_buffer_ff;
	int decode_offset_ff, fetch_offset_ff;

	always_ff @ (posedge clk) begin
		if (reset) begin
			fetch_state_ff <= active;
		end else
			fetch_state_ff <= new_fetch_state_cb;
		end

		if (reset) begin
			fetch_rip_ff <= entry & ~63;
			decode_offset_ff <= 64 + entry[5:0]; 
			fetch_offset_ff <= 0;
		end
	end
	always_comb begin
		if (fetch_state != fetch_idle) begin
			send_fetch_req = 0;
		end else if (result.reqack) begin
			send_fetch_req = 0;
		end else begin
			send_fetch_req = (fetch_offset - decode_offset < 7'd32);
		end
	end

	always @ (posedge clk) begin

		if (reset) begin

			fetch_state <= fetch_idle;
			fetch_rip <= entry & ~63;
			fetch_skip <= entry[5:0];
			fetch_offset <= 0;

		end else begin // !reset

			command.reqcyc <= send_fetch_req;
			command.req <= fetch_rip & ~63;
			command.reqtag <= { MUSKBUS::READ, MUSKBUS::MEMORY, 8'b0 };

			if (result.respcyc) begin
				assert(!send_fetch_req) else $fatal;
				fetch_state <= fetch_active;
				fetch_rip <= fetch_rip + 8;
				if (fetch_skip > 0) begin
					fetch_skip <= fetch_skip - 8;
				end else begin
					decode_buffer[fetch_offset*8 +: 64] <= result.resp;
					fetch_offset <= fetch_offset + 8;
				end
			end else begin
				if (fetch_state == fetch_active) begin
					fetch_state <= fetch_idle;
				end else if (result.reqack) begin
					assert(fetch_state == fetch_idle) else $fatal;
					fetch_state <= fetch_waiting;
				end
			end

		end
	end

	wire[0:(128+15)*8-1] decode_bytes_repeated = { decode_buffer, decode_buffer[0:15*8-1] }; // NOTE: buffer bits are left-to-right in increasing order
	wire[0:15*8-1] decode_bytes = decode_bytes_repeated[decode_offset*8 +: 15*8]; // NOTE: buffer bits are left-to-right in increasing order
	wire can_decode = (fetch_offset - decode_offset >= 7'd15);

	logic[3:0] bytes_decoded_this_cycle;
	always_comb begin
		if (can_decode) begin : decode_block
			// cse502 : Decoder here
			// remove the following line. It is only here to allow successful compilation in the absence of your code.
			if (decode_bytes == 0) ;

			// cse502 : following is an example of how to finish the simulation
			if (decode_bytes == 0 && fetch_state == fetch_idle) $finish;
		end else begin
			bytes_decoded_this_cycle = 0;
		end
	end

	always @ (posedge clk)
		if (reset) begin

			decode_offset <= 0;
			decode_buffer <= 0;

		end else begin // !reset

			decode_offset <= decode_offset + { 3'b0, bytes_decoded_this_cycle };

		end

	// cse502 : Use the following as a guide to print the Register File contents.
	final begin
		$display("RAX = %x", 0);
		$display("RBX = %x", 0);
		$display("RCX = %x", 0);
		$display("RDX = %x", 0);
		$display("RSI = %x", 0);
		$display("RDI = %x", 0);
		$display("RBP = %x", 0);
		$display("RSP = %x", 0);
		$display("R8 = %x", 0);
		$display("R9 = %x", 0);
		$display("R10 = %x", 0);
		$display("R11 = %x", 0);
		$display("R12 = %x", 0);
		$display("R13 = %x", 0);
		$display("R14 = %x", 0);
		$display("R15 = %x", 0);
	end
*/
endmodule
