module Core (
	input[63:0] entry
,	/* verilator lint_off UNDRIVEN */ /* verilator lint_off UNUSED */ Sysbus bus /* verilator lint_on UNUSED */ /* verilator lint_on UNDRIVEN */
);

	`include "Decoder.sv"
	`include "ALU.sv" 

	enum { fetch_idle, fetch_waiting, fetch_active } fetch_state;
	logic[63:0] fetch_rip;
	logic[0:2*64*8-1] decode_buffer; // NOTE: buffer bits are left-to-right in increasing order
	logic[5:0] fetch_skip;
	logic[6:0] fetch_offset, decode_offset;

	logic can_exec_ff;

	logic[0:16*64-1] reg_file_ff;
	logic[0:16*64-1] reg_file_cb;

	fat_instruction_t fat_inst_ff;
	fat_instruction_t fat_inst_cb;


	function logic mtrr_is_mmio(logic[63:0] physaddr);
		mtrr_is_mmio = ((physaddr > 640*1024 && physaddr < 1024*1024));
	endfunction

	logic send_fetch_req;
	always_comb begin
		if (fetch_state != fetch_idle) begin
			send_fetch_req = 0; // hack: in theory, we could try to send another request at this point
		end else if (bus.reqack) begin
			send_fetch_req = 0; // hack: still idle, but already got ack (in theory, we could try to send another request as early as this)
		end else begin
			send_fetch_req = (fetch_offset - decode_offset < 7'd32);
		end
	end

	assign bus.respack = bus.respcyc; // always able to accept response

	always_ff @ (posedge bus.clk)
		if (bus.reset) begin

			fetch_state <= fetch_idle;
			fetch_rip <= entry & ~63;
			fetch_skip <= entry[5:0];
			fetch_offset <= 0;

		end else begin // !bus.reset

			bus.reqcyc <= send_fetch_req;
			bus.req <= fetch_rip & ~63;
			bus.reqtag <= { bus.READ, bus.MEMORY, 8'b0 };

			if (bus.respcyc) begin
				assert(!send_fetch_req) else $fatal;
				fetch_state <= fetch_active;
				fetch_rip <= fetch_rip + 8;
				if (fetch_skip > 0) begin
					fetch_skip <= fetch_skip - 8;
				end else begin
					decode_buffer[fetch_offset*8 +: 64] <= bus.resp;
					//$display("fill at %d: %x [%x]", fetch_offset, bus.resp, decode_buffer);
					fetch_offset <= fetch_offset + 8;
				end
			end else begin
				if (fetch_state == fetch_active) begin
					fetch_state <= fetch_idle;
				end else if (bus.reqack) begin
					assert(fetch_state == fetch_idle) else $fatal;
					fetch_state <= fetch_waiting;
				end
			end

		end

	wire[0:(128+15)*8-1] decode_bytes_repeated = { decode_buffer, decode_buffer[0:15*8-1] }; // NOTE: buffer bits are left-to-right in increasing order
	wire[0:15*8-1] decode_bytes = decode_bytes_repeated[decode_offset*8 +: 15*8]; // NOTE: buffer bits are left-to-right in increasing order
	wire can_decode = (fetch_offset - decode_offset >= 7'd15);

	function logic opcode_inside(logic[7:0] value, low, high);
		opcode_inside = (value >= low && value <= high);
	endfunction

	logic[3:0] bytes_decoded_this_cycle;

	always_comb begin
		if (can_decode) begin : decode_block
			// cse502 : Decoder here
			`ifdef INS_OUT
			logic[6:0] rip_corr = fetch_offset - decode_offset;
			$write("%x:", fetch_rip - rip_corr);
			`endif
			bytes_decoded_this_cycle = decode(decode_bytes, fat_inst_cb);

			// cse502 : following is an example of how to finish the simulation
			// if (decode_bytes == 0 && fetch_state == fetch_idle) $finish;
		end else begin
			bytes_decoded_this_cycle = 0;
			fat_inst_cb = 0;
		end
	end

	always_ff @ (posedge bus.clk)
		if (bus.reset) begin

			decode_offset <= 0;
			decode_buffer <= 0;

		end else begin // !bus.reset

			decode_offset <= decode_offset + { 3'b0, bytes_decoded_this_cycle };

		end

	//logic decode_valid_cb ;
	logic decode_valid_cb;
	assign decode_valid_cb = can_decode && bytes_decoded_this_cycle > 0;

	always_ff @ (posedge bus.clk)
		if (bus.reset) begin 
			can_exec_ff <= 0;
			fat_inst_ff <= 0;
		end else begin
			can_exec_ff <= decode_valid_cb;
			if (decode_valid_cb) begin
				fat_inst_ff <= fat_inst_cb;
			end
		end

	logic exec_end_cb;
	always_comb begin
		if (can_exec_ff) begin
			exec_end_cb = ALU(fat_inst_ff, reg_file_ff, reg_file_cb);
		end else begin
			exec_end_cb = 0;
			reg_file_cb = 0;
		end
	end

	logic exec_valid_cb;
	assign exec_valid_cb = can_exec_ff && !exec_end_cb;

	always_ff @ (posedge bus.clk)
		if (bus.reset) begin
			reg_file_ff <= 0;
		end else begin
			if (exec_valid_cb) begin
				reg_file_ff <= reg_file_cb;
			end 

			if (exec_end_cb) begin
				$finish;
			end
		end

	// cse502 : Use the following as a guide to print the Register File contents.
	final begin
		$display("RAX = %x", `get_64(reg_file_ff, 0));
		$display("RCX = %x", `get_64(reg_file_ff, 1));
		$display("RDX = %x", `get_64(reg_file_ff, 2));
		$display("RBX = %x", `get_64(reg_file_ff, 3));
		$display("RSP = %x", `get_64(reg_file_ff, 4));
		$display("RBP = %x", `get_64(reg_file_ff, 5));
		$display("RSI = %x", `get_64(reg_file_ff, 6));
		$display("RDI = %x", `get_64(reg_file_ff, 7));
		$display("R8 = %x", `get_64(reg_file_ff, 8));
		$display("R9 = %x", `get_64(reg_file_ff, 9));
		$display("R10 = %x", `get_64(reg_file_ff, 10));
		$display("R11 = %x", `get_64(reg_file_ff, 11));
		$display("R12 = %x", `get_64(reg_file_ff, 12));
		$display("R13 = %x", `get_64(reg_file_ff, 13));
		$display("R14 = %x", `get_64(reg_file_ff, 14));
		$display("R15 = %x", `get_64(reg_file_ff, 15));
	end
endmodule
