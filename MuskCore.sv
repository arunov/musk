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

import DecoderTypes::*;
import RegMap::*;
import MuskCoreUtils::*;
import MicroOp::MAX_MOP_CNT;
import MicroOp::gen_micro_ops;

import "DPI-C" function longint syscall_cse502(input longint rax, input longint rdi, input longint rsi, input longint rdx, input longint r10, input longint r8, input longint r9);

/*** FETCH ***/

	logic[63:0] fetch_addr_ff, pc_ff, rd_addr;
	int bytes_decoded_this_cycle, decode_return;

	logic rd_reqcyc_ff, rd_respcyc;
	logic [0:64*8-1] rd_data;

	logic fq_enq, fq_deq;
	logic [0:64*8-1] fq_in_data;
	logic [0:15*8-1] fq_out_data;
	int fq_in_cnt, fq_out_cnt, fq_used_cnt, fq_empty_cnt;

	//MuskbusReader reader(reset, clk, bus, rd_reqcyc_ff, rd_addr, rd_respcyc, rd_data);
	SetAssocReadCache reader(reset, clk, bus, rd_reqcyc_ff, rd_addr, rd_respcyc, rd_data);
	Queue #(64*8, 15*8, 64*8*4) fetch_queue(reset, clk, fq_enq, fq_in_cnt, fq_in_data, fq_deq, fq_out_cnt, fq_out_data, fq_used_cnt, fq_empty_cnt);

	always_ff @ (posedge clk) begin
		if (reset) begin
			fetch_addr_ff <= entry;
			rd_reqcyc_ff <= 0;
			pc_ff <= entry;
		end else begin
			if (rd_respcyc) begin
				fetch_addr_ff <= (fetch_addr_ff & ~63) + 64;
			end

			if (rd_respcyc) begin
				rd_reqcyc_ff <= fq_empty_cnt >= 128 * 8;
			end else begin
				rd_reqcyc_ff <= fq_empty_cnt >= 64 * 8;
			end

			pc_ff <= pc_ff + {32'b0, bytes_decoded_this_cycle};
		end
	end

	assign rd_addr = fetch_addr_ff & ~63;

	always_comb begin
		fq_enq = rd_respcyc;
		fq_in_cnt = 64 * 8 - (fetch_addr_ff[5:0] * 8);
		fq_in_data = rd_data << (fetch_addr_ff[5:0] * 8);
	end

/*** DECODE ***/

	parameter SCALE_WAY_CNT = 1;
	parameter DQ_IN_WIDTH = $bits(micro_op_t) * MAX_MOP_CNT;
	parameter DQ_OUT_WIDTH = $bits(micro_op_t) * SCALE_WAY_CNT;
	parameter DQ_BUF_WIDTH = DQ_IN_WIDTH * 4;

	logic [0:15*8-1] decode_bytes;
	logic can_decode;

	logic dq_enq, dq_deq;
	logic [0:DQ_IN_WIDTH-1] dq_in_data;
	logic [0:DQ_OUT_WIDTH-1] dq_out_data;
	int dq_in_cnt, dq_out_cnt, dq_used_cnt, dq_empty_cnt;

	Queue #(DQ_IN_WIDTH, DQ_OUT_WIDTH, DQ_BUF_WIDTH) decode_queue(
		reset, clk, dq_enq, dq_in_cnt, dq_in_data, dq_deq, dq_out_cnt, dq_out_data, dq_used_cnt, dq_empty_cnt
	);

	always_comb begin
		fat_instruction_t fat_inst_cb = 0;

		decode_bytes = fq_out_data;
		can_decode = (fq_used_cnt >= 15 * 8) && (dq_empty_cnt >= DQ_IN_WIDTH);

		if (can_decode) begin
			decode_return = Decoder::decode(decode_bytes, pc_ff, fat_inst_cb);
			if (decode_return > 0) begin
				bytes_decoded_this_cycle = decode_return;
			end else begin
				$display("skip one byte: %h", `get_byte(decode_bytes, 0));
				bytes_decoded_this_cycle = 1;
				// bytes_decoded_this_cycle = 0;
			end
		end else begin
			decode_return = 0;
			bytes_decoded_this_cycle = 0;
		end

		fq_deq = bytes_decoded_this_cycle > 0;
		fq_out_cnt = bytes_decoded_this_cycle * 8;

		if (decode_return > 0) begin
			// Add micro ops to decode queue.
			dq_enq = 1;
			dq_in_cnt = gen_micro_ops(fat_inst_cb, dq_in_data) * $bits(micro_op_t);
		end else begin
			dq_enq = 0;
			dq_in_cnt = 0;
			dq_in_data = 0;
		end

	end

/*** REGISTER READ AND DISPATCH ***/

	reg_val_t[0:REG_FILE_SIZE-1] reg_file_ff;
	logic[0:REG_FILE_SIZE-1] score_board_ff, sb_set_mask, sb_clear_mask;

	logic ap0_in_ready;
	micro_op_t ap0_in_mop;
	logic ap0_busy;
	logic ap0_out_ready;
	/*verilator lint_off UNUSED*/
	micro_op_t ap0_out_mop;
	/*verilator lint_on UNUSED*/

	APipeline ap0(reset, clk, ap0_in_ready, ap0_in_mop, ap0_busy, ap0_out_ready, ap0_out_mop);

	always_comb begin
		ap0_in_mop = dq_out_data;
		ap0_in_ready = dq_used_cnt >= DQ_OUT_WIDTH && !ap0_busy && score_board_check(score_board_ff, ap0_in_mop);

		if (ap0_in_ready) begin
			load_reg_vals(reg_file_ff, ap0_in_mop);
		end

		if (ap0_in_ready) begin
			sb_set_mask = make_sb_mask(ap0_in_mop.dst_id);
		end else begin
			sb_set_mask = 0;
		end

		dq_deq = ap0_in_ready;
		dq_out_cnt = DQ_OUT_WIDTH;
	end


/*** EXECUTE AND MEMORY ACCESS ***/
	// Done in pipe line modules.


/*** REGISTER WRITE BACK ***/

	always_ff @ (posedge clk) begin
		if (reset) begin
			reg_file_ff <= 0;
		end else if(ap0_out_ready && reg_in_file(ap0_out_mop.dst_id)) begin
			reg_file_ff[reg_num(ap0_out_mop.dst_id)] <= ap0_out_mop.dst_val;
		end
	end

	always_comb begin
		if(ap0_out_ready) begin
			sb_clear_mask = make_sb_mask(ap0_out_mop.dst_id);			
		end else begin
			sb_clear_mask = 0;
		end
	end

/*** SCORE BOARD UPDATE ***/

	always_ff @ (posedge clk) begin
		if (reset) begin
			score_board_ff <= 0;
		end else begin
			score_board_ff <= score_board_ff ^ sb_set_mask ^ sb_clear_mask;
		end
	end


// cse502 : Use the following as a guide to print the Register File contents.
	final begin
		print_reg_file(reg_file_ff);
	end

endmodule
