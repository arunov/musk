
import DecoderTypes::*;
import RegMap::*;

package MuskCoreUtils;

function automatic logic score_board_check(logic[0:REG_FILE_SIZE-1] sb, micro_op_t mop);
	return (!reg_in_file(mop.src0_id) || !sb[reg_num(mop.src0_id)]) &&
		(!reg_in_file(mop.src1_id) || !sb[reg_num(mop.src1_id)]) &&
		(!reg_in_file(mop.dst_id) || !sb[reg_num(mop.dst_id)]);
endfunction

function automatic logic make_dst_sb_mask(micro_op_t mop);
	logic[0:REG_FILE_SIZE-1] mask = 0;
	if (reg_in_file(mop.dst_id)) begin
		mask[reg_num(mop.dst_id)] = 1;
	end else begin
		$display("ERROR: invalid reg id: %x", mop.dst_id);
		$finish;
	end
	return mask;
endfunction

function automatic reg_val_t read_one_reg_val(reg_val_t[0:REG_FILE_SIZE-1] reg_file, micro_op_t mop, reg_id_t id);
	reg_val_t rval = 0;
	if (id == rip) rval.val = mop.rip_val;
	else if (id == rimm) rval.val = mop.immediate;
	else if (id == rv0) rval.val = 0;
	else if (id == rv8) rval.val = 8;
	else if (reg_in_file(id) rval = reg_file[reg_num(id)];
	else begin
		$display("ERROR: invalid reg id: %x", id);
		$finish;
	end
endfunction

function automatic void load_reg_vals(reg_val_t[0:REG_FILE_SIZE-1] reg_file, inout micro_op_t mop);
	if (mop.src0_id != rnil) mop.src0_val = read_one_reg_val(reg_file, mop, mop.src0_id);
	if (mop.src1_id != rnil) mop.src1_val = read_one_reg_val(reg_file, mop, mop.src1_id);
endfunction

endpackage
