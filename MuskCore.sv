

module MuskCore (
	input[63:0] entry,
	input reset,
	input clk,
	/* verilator lint_off UNDRIVEN */
	/* verilator lint_off UNUSED */
	Muskbus.Top bus
	/* verilator lint_on UNUSED */
	/* verilator lint_on UNDRIVEN */
);

	import DECODER::decode;
	import DECODER::fat_instruction_t;
	import ALU::alu;

	parameter DECBUF_SIZE=4*64;

	logic[0:DECBUF_SIZE*8-1] decode_buffer_ff;
	logic[63:0] fetch_addr_ff;
	int decode_offset_ff, decode_buf_head_ff, decode_buf_tail_ff, bytes_decoded_this_cycle;

	logic rd_reqcyc_ff, rd_respcyc;
	logic [0:64*8-1] rd_data;
	MuskbusReader reader(reset, clk, bus, rd_reqcyc_ff, fetch_addr_ff, rd_respcyc, rd_data);

/*
	always_comb begin
		$display("fetch_addr_ff = %x", fetch_addr_ff);
		$display("decode_offset_ff = %x", decode_offset_ff);
		$display("decode_buf_head_ff = %x", decode_buf_head_ff);
		$display("decode_buf_tail_ff = %x", decode_buf_tail_ff);
	end
*/

	always_ff @ (posedge clk) begin
		if (reset) begin
			fetch_addr_ff <= entry & ~63;
			decode_offset_ff <= { 26'b0, entry[5:0] }; 
			decode_buf_head_ff <= 0;
			decode_buf_tail_ff <= 0;
			rd_reqcyc_ff <= 0;
		end else begin

			if (decode_offset_ff + bytes_decoded_this_cycle - decode_buf_head_ff >= 64) begin
				decode_buf_head_ff <= (decode_buf_head_ff + 64) % DECBUF_SIZE;
			end

			decode_offset_ff <= (decode_offset_ff + bytes_decoded_this_cycle) % DECBUF_SIZE;

			if (rd_respcyc) begin
				decode_buffer_ff[decode_buf_tail_ff*8 +: 64*8] <= rd_data;
				decode_buf_tail_ff <= (decode_buf_tail_ff + 64) % DECBUF_SIZE;
				fetch_addr_ff <= fetch_addr_ff + 64;
			end

			if (rd_respcyc) begin
				rd_reqcyc_ff <= (decode_buf_tail_ff + 64 + 64) % DECBUF_SIZE != decode_buf_head_ff;
			end else begin
				rd_reqcyc_ff <= (decode_buf_tail_ff + 64) % DECBUF_SIZE != decode_buf_head_ff;
			end
		end
	end

	logic [0:(DECBUF_SIZE+15)*8-1] decode_buf_repeated;
	logic [0:15*8-1] decode_bytes;
	logic can_decode;

	assign decode_buf_repeated = { decode_buffer_ff, decode_buffer_ff[0:15*8-1] };
	assign decode_bytes = decode_buf_repeated[decode_offset_ff*8 +: 15*8];

	always_comb begin : can_decode_block
		int new_offset = decode_offset_ff + 15;
		int real_tail = (decode_buf_head_ff <= decode_buf_tail_ff) ? decode_buf_tail_ff : (DECBUF_SIZE + decode_buf_tail_ff);
		can_decode = new_offset <= real_tail;
	end

	logic can_exec_ff;

	logic[0:16*64-1] reg_file_ff;
	logic[0:16*64-1] reg_file_cb;

	fat_instruction_t fat_inst_ff;
	fat_instruction_t fat_inst_cb;

	always_comb begin
		if (can_decode) begin
			bytes_decoded_this_cycle = { 28'b0, decode(decode_bytes, fat_inst_cb) };
		end else begin
			bytes_decoded_this_cycle = 0;
			fat_inst_cb = 0;
		end
	end

	logic decode_valid_cb;
	assign decode_valid_cb = can_decode && bytes_decoded_this_cycle > 0;

	always_ff @ (posedge clk) begin
		if (reset) begin 
			can_exec_ff <= 0;
			fat_inst_ff <= 0;
		end else begin
			can_exec_ff <= decode_valid_cb;
			if (decode_valid_cb) begin
				fat_inst_ff <= fat_inst_cb;
			end
		end
	end

	logic exec_end_cb;
	always_comb begin
		if (can_exec_ff) begin
			exec_end_cb = alu(fat_inst_ff, reg_file_ff, reg_file_cb);
		end else begin
			exec_end_cb = 0;
			reg_file_cb = 0;
		end
	end

	logic exec_valid_cb;
	assign exec_valid_cb = can_exec_ff && !exec_end_cb;

	always_ff @ (posedge clk) begin
		if (reset) begin
			reg_file_ff <= 0;
		end else begin
			if (exec_valid_cb) begin
				reg_file_ff <= reg_file_cb;
			end 

			if (exec_end_cb) begin
				$finish;
			end
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
