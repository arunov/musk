`include "MacroUtils.sv"

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

/*** CACHES ***/

	/* verilator lint_off UNDRIVEN */
	/* verilator lint_off UNUSED */
	Muskbus ibus, dbus;
	/* verilator lint_on UNUSED */
	/* verilator lint_on UNDRIVEN */

	MuskbusMux mm(reset, clk, dbus, ibus, bus);

	logic rd_reqcyc_ff, rd_respcyc;
	logic [63:0] rd_addr;
	logic [0:64*8-1] rd_data;

        /* verilator lint_off UNUSED */
        logic [0:63] write_data;
        logic writeEnable;
        logic cflush;
        /* verilator lint_on UNUSED */
        assign write_data = 64'h0;
        assign writeEnable = 1'b0;
        assign cflush = 1'b0;
	SetAssocICache reader(reset, clk, ibus, rd_reqcyc_ff, rd_addr, rd_respcyc, rd_data);
	//MuskbusReader reader(reset, clk, ibus, rd_reqcyc_ff, rd_addr, rd_respcyc, rd_data);

	CACHE::cache_cmd_t ca_req_cmd;
	logic ca_respcyc;
	logic [63:0] ca_req_addr, ca_req_data, ca_resp_data;

	//LineDCache cache(reset, clk, dbus, ca_req_cmd, ca_req_addr, ca_req_data, ca_respcyc, ca_resp_data);
	SetAssocDCache cache(reset, clk, dbus, ca_req_cmd, ca_req_addr, ca_req_data, ca_respcyc, ca_resp_data);

/*** BRANCH ***/
	logic soft_reset, jmp_reset;
	logic[63:0] soft_entry, jmp_entry;

	always_comb begin
		soft_reset = reset ? 1 : jmp_reset;
		soft_entry = reset ? entry : jmp_entry;
	end

/*** FETCH ***/

	parameter DEC_SCALE = 2;

	logic[63:0] fetch_addr_ff, pc_ff;
	int bytes_decoded_this_cycle;

	logic fq_enq, fq_deq;
	logic [0:64*8-1] fq_in_data;
	logic [0:15*8*DEC_SCALE-1] fq_out_data;
	int fq_in_cnt, fq_out_cnt, fq_used_cnt, fq_empty_cnt;

	Queue #(64*8, 15*8*DEC_SCALE, 64*8*2) fetch_queue(
		soft_reset, clk, fq_enq, fq_in_cnt, fq_in_data, fq_deq, fq_out_cnt, fq_out_data, fq_used_cnt, fq_empty_cnt
	);

	always_ff @ (posedge clk) begin
		if (soft_reset) begin
			fetch_addr_ff <= soft_entry;
			rd_reqcyc_ff <= 0;
			pc_ff <= soft_entry;
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

	parameter MOP_SCALE = 2;
	parameter DQ_IN_WIDTH = $bits(micro_op_t) * MAX_MOP_CNT * DEC_SCALE;
	parameter DQ_OUT_WIDTH = $bits(micro_op_t) * MOP_SCALE;
	parameter DQ_BUF_WIDTH = DQ_IN_WIDTH * 2;

	logic dq_enq, dq_deq;
	logic [0:DQ_IN_WIDTH-1] dq_in_data;
	logic [0:DQ_OUT_WIDTH-1] dq_out_data;
	int dq_in_cnt, dq_out_cnt, dq_used_cnt, dq_empty_cnt;

	Queue #(DQ_IN_WIDTH, DQ_OUT_WIDTH, DQ_BUF_WIDTH) decode_queue(
		soft_reset, clk, dq_enq, dq_in_cnt, dq_in_data, dq_deq, dq_out_cnt, dq_out_data, dq_used_cnt, dq_empty_cnt
	);

	always_comb begin

		int mops_made_this_cycle = 0;
		logic[0:DQ_IN_WIDTH-1] mop_bits = 0;

		bytes_decoded_this_cycle = 0;

		if (dq_empty_cnt >= DQ_IN_WIDTH) begin
			int ii = 0; 
			for (ii = 0; ii < DEC_SCALE; ii++) begin
				int decode_return = 0;
				fat_instruction_t fat_inst_cb = 0;

				if ((fq_used_cnt - bytes_decoded_this_cycle * 8) < (15 * 8)) break;

				decode_return = Decoder::decode(
					`pget_bytes(fq_out_data, bytes_decoded_this_cycle, 15), 
					pc_ff + {32'b0, bytes_decoded_this_cycle}, 
					fat_inst_cb
				);

				if (decode_return > 0) begin
					int gen_mop_ret = 0;
					logic[0:MAX_MOP_CNT*$bits(micro_op_t)-1] sub_mop_bits = 0;

					bytes_decoded_this_cycle += decode_return;

					gen_mop_ret = gen_micro_ops(fat_inst_cb, sub_mop_bits);
					`pget_blocks(mop_bits, mops_made_this_cycle, MAX_MOP_CNT, $bits(micro_op_t)) = sub_mop_bits;
					mops_made_this_cycle += gen_mop_ret;
				end else begin
					// $display("skip one byte");
					bytes_decoded_this_cycle += 1;
				end
			end
		end

		fq_deq = bytes_decoded_this_cycle > 0;
		fq_out_cnt = bytes_decoded_this_cycle * 8;

		dq_enq = mops_made_this_cycle > 0;
		dq_in_cnt = mops_made_this_cycle * $bits(micro_op_t);
		dq_in_data = mop_bits;
	end

/*** REGISTER READ AND DISPATCH ***/

	reg_val_t[0:REG_FILE_SIZE-1] reg_file_ff;
	logic[0:REG_FILE_SIZE-1] score_board_ff, new_score_board, sb_clear_mask;

	// Since structure/2-dimensional arrays are unconditionally big endian, use big endian
	// here to make sure wiring for the aps module array is correct.
	logic[MOP_SCALE-1:0] ap_in_readys, ap_busys, ap_out_readys;
	micro_op_t[MOP_SCALE-1:0] ap_in_mops;
	/*verilator lint_off UNUSED*/
	micro_op_t[MOP_SCALE-1:0] ap_out_mops;
	/*verilator lint_on UNUSED*/

	APipeline aps[MOP_SCALE-1:0](reset, clk, ap_in_readys, ap_in_mops, ap_busys, ap_out_readys, ap_out_mops);

	logic mp_in_ready, mp_busy, mp_out_ready;
	micro_op_t mp_in_mop;
	/*verilator lint_off UNUSED*/
	micro_op_t mp_out_mop;
	/*verilator lint_on UNUSED*/

	MPipeline mp(reset, clk, mp_in_ready, mp_in_mop, mp_busy, mp_out_ready, mp_out_mop, ca_req_cmd, ca_req_addr, ca_req_data, ca_respcyc, ca_resp_data);

	always_comb begin

		int ii = 0;
		micro_op_t mop = 0;

		jmp_reset = 0;
		jmp_entry = 0;
		dq_out_cnt = 0;
		new_score_board = score_board_ff;

		// Reset pipe line inputs.
		ap_in_readys = 0;
		ap_in_mops = 0;
		mp_in_ready = 0;
		mp_in_mop = 0;

		for (ii = 0; ii < MOP_SCALE; ii++) begin
			mop = `get_block(dq_out_data, ii, $bits(micro_op_t));

			if (dq_used_cnt < $bits(micro_op_t) * (ii + 1)) break; //decoder buf empty, stall
			if (!score_board_check(new_score_board, mop)) break; //register conflict, stall

			load_reg_vals(reg_file_ff, mop);

			if (mopcode_is_branch(mop.opcode)) begin
				if (mop_will_branch(mop)) begin
					// branch taken, resteer and stall if no i-cache read is in progress,
					// otherwise, just stall (do nothing)
					if (rd_reqcyc_ff == 0 || rd_respcyc) begin
						jmp_reset = 1;
						jmp_entry = mop.src0_val.val;

						// $display("branch: %x", jmp_entry);
					end
					break;
				end // branch not taken, fall through and skip the micro op
			end else if (mopcode_is_mem(mop.opcode)) begin
				if (mp_in_ready) break; //memory pipe taken, stall 
				if (mp_busy) break; //meory pipe busy, stall
				mp_in_ready = 1; // send micro op to memory pipeline
				mp_in_mop = mop;

				// print_mop(mop);
			end else begin
				if (ap_busys[ii]) break; //pipe busy, stall, in fact, this will never happen for ALU pipes :)
				ap_in_readys[ii] = 1;
				ap_in_mops[ii] = mop;

				// print_mop(mop);
			end

			dq_out_cnt += $bits(micro_op_t);
			new_score_board ^= make_sb_mask(mop.dst_id);
		end

		// Will always dequeue, but dequeued amount can be 0.
		dq_deq = 1;
	end


/*** EXECUTE AND MEMORY ACCESS ***/
	// Done in pipe line modules.


/*** REGISTER WRITE BACK ***/

	always_ff @ (posedge clk) begin
		if (reset) begin
			reg_file_ff[reg_num(rsp)].val <= 64'h7c00; // initialize rsp
		end else begin 
			int ii = 0;
			/* verilator lint_off UNUSED */
			micro_op_t mop = 0;
			/* verilator lint_on UNUSED */
			for (ii = 0; ii < MOP_SCALE; ii++) begin
				mop = ap_out_mops[ii];
				if(ap_out_readys[ii] && reg_in_file(mop.dst_id)) begin
					reg_file_ff[reg_num(mop.dst_id)] <= mop.dst_val;
				end
			end

			mop = mp_out_mop;
			if (mp_out_ready && reg_in_file(mop.dst_id)) begin
				reg_file_ff[reg_num(mop.dst_id)] <= mop.dst_val;
			end
		end
	end

	always_comb begin
		int ii;
		sb_clear_mask = 0;
		for (ii = 0; ii < MOP_SCALE; ii++) begin
			if(ap_out_readys[ii]) begin
				sb_clear_mask ^= make_sb_mask(ap_out_mops[ii].dst_id);			
			end
		end
		if (mp_out_ready) begin
			sb_clear_mask ^= make_sb_mask(mp_out_mop.dst_id);
		end
	end

/*** SCORE BOARD UPDATE ***/

	always_ff @ (posedge clk) begin
		if (reset) begin
			score_board_ff <= 0;
		end else begin
			score_board_ff <= new_score_board ^ sb_clear_mask;
		end
	end


// cse502 : Use the following as a guide to print the Register File contents.
	final begin
		print_reg_file(reg_file_ff);
	end

endmodule
