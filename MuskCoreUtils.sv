
package MuskCoreUtils;

import DecoderTypes::*;
import RegMap::*;

import "DPI-C" function longint syscall_cse502(input longint rax, input longint rdi, input longint rsi, input longint rdx, input longint r10, input longint r8, input longint r9);

function automatic logic score_board_check_one(
	logic[0:REG_FILE_SIZE-1] sb, 
	reg_id_t id
);
	if (id == rsyscall) return sb == 0;

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
		rsyscall : begin 
			rval.val = syscall_cse502(
				reg_file[reg_num(rax)].val, 
				reg_file[reg_num(rdi)].val, 
				reg_file[reg_num(rsi)].val, 
				reg_file[reg_num(rdx)].val, 
				reg_file[reg_num(r10)].val, 
				reg_file[reg_num(r8)].val, 
				reg_file[reg_num(r9)].val);
		end
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

function automatic logic mopcode_is_mem(micro_opcode_t code);
	return code == m_ld || code == m_st || code == m_clflush;
endfunction

function automatic logic mopcode_is_branch(micro_opcode_t code);
	return code > M_JMIN && code < M_JMAX;
endfunction

function automatic logic mop_will_branch(
	/* verilator lint_off UNUSED */
	micro_op_t mop
	/* verilator lint_on UNUSED */
);

	/* verilator lint_off UNUSED */
	reg_val_t fs = mop.src1_val;
	/* verilator lint_on UNUSED */

	case (mop.opcode)
		m_jb : return fs.cf == 1;
		m_jnb : return fs.cf == 0;
		m_jz : return fs.zf == 1;
		m_jnz : return fs.zf == 0;
		m_jl : return (fs.sf ^ fs.of) == 1;
		m_jnl : return (fs.sf ^ fs.of) == 0;
		m_jle : return ((fs.sf ^ fs.of) | fs.zf) == 1;
		m_jnle : return ((fs.sf ^ fs.of) | fs.zf) == 0;
		m_jmp : return 1;
		default : begin
			$display("ERROR: mop_will_branch: unknown branch: %x", mop.opcode);
			return 0;
		end
	endcase

endfunction

endpackage
