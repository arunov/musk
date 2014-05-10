
import DecoderTypes::*;
import Decoder::decode;

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

	logic[63:0] fetch_addr_ff, rip_ff;
	int bytes_decoded_this_cycle, decode_return;

	logic rd_reqcyc_ff, rd_respcyc;
	logic [0:64*8-1] rd_data;

	logic fq_en, fq_de;
	logic [0:64*8-1] fq_in_data;
	logic [0:64*15-1] fq_out_data;
	int fq_in_cnt, fq_out_cnt, fq_used_cnt, fq_empty_cnt;

/*** FETCH ***/

	//MuskbusReader reader(reset, clk, bus, rd_reqcyc_ff, fetch_addr_ff, rd_respcyc, rd_data);
	SetAssocReadCache reader(reset, clk, bus, rd_reqcyc_ff, fetch_addr_ff, rd_respcyc, rd_data);
	Queue fetch_queue#(64*8, 15*8, 64*8*4)(reset, clk, fq_en, fq_in_cnt, fq_in_data, fq_de, fq_out_cnt, fq_out_data, fq_used_cnt, fq_empty_cnt);

	always_ff @ (posedge clk) begin
		if (reset) begin
			fetch_addr_ff <= entry & ~63;
			rd_reqcyc_ff <= 0;
			rip_ff <= entry & ~63;
		end else begin
			if (rd_respcyc) begin
				fetch_addr_ff <= fetch_addr_ff + 64;
			end

			if (rd_respcyc) begin
				rd_reqcyc_ff <= fq_empty_cnt >= 128 * 8;
			end else begin
				rd_reqcyc_ff <= fq_empty_cnt >= 64 * 8;
			end

			rip_ff <= rip_ff + bytes_decoded_this_cycle;
		end
	end

	always_comb begin
		fq_en = rd_respcyc;
		fq_in_cnt = 64 * 8 - (fetch_addr_ff[5:0] * 8);
		fq_in_data = rd_data << (fetch_addr_ff[5:0] * 8);
	end

	logic [0:15*8-1] decode_bytes;
	logic can_decode;

	always_comb begin
		fq_de = bytes_decoded_this_cycle > 0;
		fq_out_cnt = bytes_decoded_this_cycle * 8;
		decode_bytes = fq_out_data;
		can_decode = fq_empty_cnt >= 15 * 8;
	end

/*** DECODE ***/

	logic can_exec_ff;

	logic[0:16*64-1] reg_file_ff;
	logic[0:16*64-1] reg_file_cb;

	fat_instruction_t fat_inst_ff;
	fat_instruction_t fat_inst_cb;

	always_comb begin
		if (can_decode) begin
			decode_return = decode(decode_bytes, fat_inst_cb);
			if (decode_return > 0) begin
				bytes_decoded_this_cycle = decode_return;
			end else begin
				$display("skip one byte: %h", `get_byte(decode_bytes, 0));
				bytes_decoded_this_cycle = 1;
			end
		end else begin
			decode_return = 0;
			bytes_decoded_this_cycle = 0;
			fat_inst_cb = 0;
		end
	end

	logic decode_valid_cb;
	assign decode_valid_cb = can_decode && decode_return > 0;

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
