
package MuskCoreUtils;

import DecoderTypes::*;
import RegMap::*;

function automatic logic score_board_check_one(
	logic[0:REG_FILE_SIZE-1] sb, 
	reg_id_t id
);
	if (reg_in_file(id)) begin
		if (sb[reg_num(id)]) return 0;
	end
	return 1;
endfunction

function automatic logic score_board_check(
	logic[0:REG_FILE_SIZE-1] sb, 
	/* verilator lint_off UNUSED */
	micro_op_t mop
	/* verilator lint_on UNUSED */
);
	return score_board_check_one(sb, mop.src0_id) &&
		score_board_check_one(sb, mop.src1_id) &&
		score_board_check_one(sb, mop.dst_id);
endfunction

function automatic logic[0:REG_FILE_SIZE-1] make_sb_mask(reg_id_t id);
	logic[0:REG_FILE_SIZE-1] mask = 0;
	if (reg_in_file(id)) begin
		mask[reg_num(id)] = 1;
	end
	return mask;
endfunction

function automatic reg_val_t read_reg(
	reg_val_t[0:REG_FILE_SIZE-1] reg_file, 
	/* verilator lint_off UNUSED */
	micro_op_t mop, 
	/* verilator lint_on UNUSED */
	reg_id_t id
);
	reg_val_t rval = 0;

	case (id)
		rnil : rval.val = 0;
		rip : rval.val = mop.rip_val;
		rimm : rval.val = mop.immediate;
		rv0 : rval.val = 0;
		rv8 : rval.val = 8;
		default : begin
			if (reg_in_file(id)) begin
				rval = reg_file[reg_num(id)];
			end else begin
				$display("ERROR: read_reg: invalid reg id: %x", id);
			end
		end
	endcase

	return rval;
endfunction

function automatic void load_reg_vals(reg_val_t[0:REG_FILE_SIZE-1] reg_file, inout micro_op_t mop);
        mop.src0_val = read_reg(reg_file, mop, mop.src0_id);
        mop.src1_val = read_reg(reg_file, mop, mop.src1_id);
endfunction

endpackage
