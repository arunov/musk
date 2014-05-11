
import DecoderTypes::*;
import Decoder::decode;
import MicroOp::MAX_MOP_CNT;
import MicroOp::get_micro_ops;
import RegMap::*;
import MuskCoreUtil::*;

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

	logic [0:15*8-1] decode_bytes;
	logic can_decode;

	logic dq_enq, dq_deq;
	logic [0:64*8-1] dq_in_data;
	logic [0:15*8-1] dq_out_data;
	int dq_in_cnt, dq_out_cnt, dq_used_cnt, dq_empty_cnt;

	parameter SCALE_WAY_CNT = 1;
	parameter DQ_IN_WIDTH = $bits(micro_op_t) * MAX_MOP_CNT;
	parameter DQ_OUT_WIDTH = $bits(micro_op_t) * SCALE_WAY_CNT;
	parameter DQ_BUF_WIDTH = DQ_IN_WIDTH * 4;
	Queue #(DQ_IN_WIDTH, DQ_OUT_WIDTH, DQ_BUF_WIDTH) decode_queue(
		reset, clk, dq_enq, dq_in_cnt, dq_in_data, dq_deq, dq_out_cnt, dq_out_data, dq_used_cnt, dq_empty_cnt
	);

	always_comb begin
		decode_bytes = fq_out_data;
		can_decode = fq_used_cnt >= 15 * 8 && dq_empty_cnt >= DQ_IN_WIDTH;
		fq_deq = bytes_decoded_this_cycle > 0;
		fq_out_cnt = bytes_decoded_this_cycle * 8;
	end

	always_comb begin
		if (can_decode) begin
			fat_instruction_t fat_inst_cb;
			decode_return = decode(decode_bytes, pc_ff, fat_inst_cb);
			if (decode_return > 0) begin
				bytes_decoded_this_cycle = decode_return;
				// Add micro ops to decode queue.
				dq_enq = 1;
				dq_in_cnt = get_micro_ops(fat_inst_cb, dq_in_data) * $bits(micro_op_t);
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

/*** REGISTER READ AND DISPATCH ***/

	reg_val_t[0:REG_FILE_SIZE-1] reg_file_ff;
	logic[0:REG_FILE_SIZE-1] score_board_ff, sb_set_mask, sb_clear_mask;

	logic ap0_in_ready;
	micro_op_t ap0_in_mop;
	logic ap0_busy;
	logic ap0_out_ready;
	micro_op_t ap0_out_mop;

	APipeline ap0(reset, clk, ap0_in_ready, ap0_in_mop, ap0_busy, ap0_out_ready, ap0_out_mop);

	always_comb begin
		ap0_in_mop = dq_out_data;
		ap0_in_ready = dq_used_cnt >= DQ_OUT_WIDTH && score_board_check(score_board_ff, ap0_in_mop) && !ap0_busy;

		if (ap0_in_ready) begin
			load_reg_vals(reg_file_ff, ap0_in_mop);
			sb_set_mask = make_dst_sb_mask(ap0_in_mop);
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
		if(ap0_out_ready && ap0_out_mop.dst_id != rnil) begin
			reg_file_ff[reg_num(ap0_out_mop.dst_id)] <= ap0_out_mop.dst_val;
		end
	end

	always_comb begin
		if(ap0_out_ready && ap0_out_mop.dst_id != rnil) begin
			sb_clear_mask = make_dst_sb_mask(ap0_out_mop);			
		end else begin
			sb_clear_mask = 0;
		end
	end

/*** SCORE BOARD UPDATE ***/

	always_ff @ (posedge clk) begin
		score_board_ff <= score_board_ff ^ sb_set_mask ^ sb_clear_mask;
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
