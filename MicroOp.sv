package MicroOp;

import DecoderTypes::*;
import RegMap::*;

parameter MAX_MOP_CNT = 4;

function automatic micro_op_t crackMemAddr(operand_t opd);
	micro_op_t mop = 0;
	mop.src0_id = opd.base_reg;
	mop.src1_id = opd.index_reg;
	mop.scale = opd.scale;
	mop.disp = opd.disp;
	return mop;
endfunction

function automatic micro_op_t mop_ld(reg_id_t dst, operand_t opd);
	micro_op_t mop = crackMemAddr(opd);
	mop.opcode = m_ld;
	mop.dst0_id = dst;
	return mop;
endfunction

function automatic micro_op_t mop_st(operand_t opd, reg_id_t src);
	micro_op_t mop = crackMemAddr(opd);
	mop.opcode = m_st;
	mop.src2_id = src;
	return mop;
endfunction

function automatic micro_op_t mop_r0(micro_opcode_t mopcode, reg_id_t reg0);
	micro_op_t mop;
	mop.opcode = mopcode;
	mop.src0_id = reg0;
	return mop;
endfunction

function automatic micro_op_t mop_imm(micro_opcode_t mopcode, logic [63:0] immediate);
	micro_op_t mop;
	mop.opcode = mopcode;
	mop.src0_mst = mst_immediate;
	mop.immediate = immediate;
	return mop;
endfunction

function automatic micro_op_t mop_r0_r1_out_r0(micro_opcode_t mopcode, reg_id_t reg0, reg_id_t reg1);
	micro_op_t mop;
	mop.opcode = mopcode;
	mop.src0_mst = mst_register;
	mop.src0_reg_id = reg0;
	mop.src1_mst = mst_register;
	mop.src1_reg_id = reg1;
	mop.has_dst0 = 1;
	mop.dst0_reg_id = reg0;
	return mop;
endfunction

function automatic micro_op_t mop_r0_imm_out_r0(micro_opcode_t mopcode, reg_id_t reg0, logic [63:0] immediate);
	micro_op_t mop;
	mop.opcode = mopcode;
	mop.src0_mst = mst_register;
	mop.src0_reg_id = reg0;
	mop.src1_mst = mst_immediate;
	mop.immediate = immediate;
	mop.has_dst0 = 1;
	mop.dst0_reg_id = reg0;
	return mop;
endfunction

/*** an instruction of this kind takes two inputs, no rflags, write to location of first input ***/
function automatic int ins_opd0_opd1_out_opd0(micro_opcode_t mopcode, fat_instruction_t ins, output micro_op_t[0:MAX_MOP_CNT-1] mops);
	if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_register) begin
		mops[0] = mop_r0_r1_out_r0(mopcode, ins.operand0.base_reg, ins.operand1.base_reg);
		return 1;
	end
	if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_immediate) begin
		mops[0] = mop_r0_imm_out_r0(mopcode, ins.operand0.base_reg, ins.operand1.immediate);
		return 1;
	end
	if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_memory) begin
		mops[0] = mop_ld(rh0, ins.operand1);
		mops[1] = mop_r0_r1_out_r0(mopcode, ins.operand0.base_reg, rh0);
		return 2;
	end
	if (ins.operand0.opd_type == opdt_memory && ins.operand1.opd_type == opdt_register) begin
		mops[0] = mop_ld(rh0, ins.operand0);
		mops[1] = mop_r0_r1_out_r0(mopcode, rh0, ins.operand1.base_reg);
		mops[2] = mop_st(ins.operand0, rh0);
		return 3;
	end
	if (ins.operand0.opd_type == opdt_memory && ins.operand1.opd_type == opdt_immediate) begin
		mops[0] = mop_ld(rh0, ins.operand0);
		mops[1] = mop_r0_imm_out_r0(mopcode, rh0, ins.operand1.immediate);
		mops[2] = mop_st(ins.operand0, rh0);
		return 3;
	end
	$display("ERROR: ins_opd0_opd1_out_opd0_rflags: invalid operand type combination: %x, %x", ins.operand0.opd_type, ins.operand1.opd_type);
	return -1;
endfunction

/*** an instruction of this kind takes two inputs, no rflags, write to location of first input and rflags ***/
function automatic int ins_opd0_opd1_out_opd0_rflags(micro_opcode_t mopcode, fat_instruction_t ins, output micro_op_t[0:MAX_MOP_CNT-1] mops);
	int cnt = ins_opd0_opd1_out_opd0(mopcode, ins, mops);
	if (cnt == 1) begin
		mops[0].has_dst1 = 1;
		mops[0].dst1_reg_id = rflags;
	end else if (cnt > 1) begin
		mops[1].has_dst1 = 1;
		mops[1].dst1_reg_id = rflags;
	end
	return cnt;
endfunction

/*** an instruction of this kind takes two inputs, no rflags, ignore result, write to rflags ***/
function automatic int ins_opd0_opd1_out_x_rflags(micro_opcode_t mopcode, fat_instruction_t ins, output micro_op_t[0:MAX_MOP_CNT-1] mops);
	int cnt = ins_opd0_opd1_out_opd0_rflags(mopcode, ins, mops);
	if (cnt == 1) begin
		mops[0].has_dst0 = 0;
		mops[0].dst0_reg_id = 0;
	end else if (cnt > 1) begin
		mops[1].has_dst0 = 0;
		mops[1].dst0_reg_id = 0;
	end
	return cnt;
endfunction

/*** used by mul and imul ***/
function automatic int ins_rax_opd0_out_rax_rdx_rflags(micro_opcode_t mopcode, fat_instruction_t ins, output micro_op_t[0:MAX_MOP_CNT-1] mops);
	if (ins.operand0.opd_type == opdt_register) begin
		mops[0] = mop_r0_r1_out_r0(mopcode, rax, ins.operand0.base_reg);
		mops[0].has_dst1 = 1;
		mops[0].dst1_reg_id = rdx;
		mops[0].has_dst2 = 1;
		mops[0].dst2_reg_id = rflags;
		return 1;
	end
	if (ins.operand0.opd_type == opdt_memory) begin
		mops[0] = mop_ld(rh0, ins.operand0);
		mops[1] = mop_r0_r1_out_r0(mopcode, rax, rh0);
		mops[1].has_dst1 = 1;
		mops[1].dst1_reg_id = rdx;
		mops[1].has_dst2 = 1;
		mops[1].dst2_reg_id = rflags;
		return 2;
	end
	$display("ERROR: ins_rax_opd0out_rax_rdx_rflags: invalid operand type: %x", ins.operand0.opd_type);
	return -1;
endfunction

/*** used by branch instructions ***/
function automatic int ins_branch(micro_opcode_t mopcode, fat_instruction_t ins, output micro_op_t[0:MAX_MOP_CNT-1]);
	if (ins.operand0.opd_type == opdt_register) begin
	end
	if (ins.operand0.opd_type == opdt_immediate) begin
	end
	if (ins.operand0.opd_type == opdt_memory) begin
	end
	$display("ERROR: ins_branch: invalid operand type: %x", ins.operand0.opd_type);
	return -1;
endfunction

/*** macros for entry points ***/
`define MOPFUN(fun) \
function automatic int fun(fat_instruction_t ins, output micro_op_t[0:MAX_MOP_CNT-1] mops);

`define ENDMOPFUN endfunction

/*** begin of entry points ***/
`MOPFUN(add)
	return ins_opd0_opd1_out_opd0_rflags(m_add, ins, mops);
`ENDMOPFUN

`MOPFUN(and)
	return ins_opd0_opd1_out_opd0_rflags(m_and, ins, mops);
`ENDMOPFUN

`MOPFUN(callq)
`ENDMOPFUN

`MOPFUN(cmp)
	return ins_opd0_opd1_out_x_rflags(m_sub, ins, mops);
`ENDMOPFUN

`MOPFUN(imul)
	if (ins.opcode_struct.opcode == 24'hF7) begin // one operand
		return ins_rax_opd0_out_rax_rdx_rflags(m_imul, ins, mops);
	end else if (ins.opcode_struct.opcode == 24'h0FAF) begin // two operands
		return ins_opd0_opd1_out_opd0_rflags(m_imul, ins, mops);
	end else begin // three operands, not supported
		$display("ERROR: micro op: three operand imul not supported yet.");
		return -1;
	end
`ENDMOPFUN

`MOPFUN(jnb)
	return 1;
`ENDMOPFUN

`MOPFUN(jz)
	return 1;
`ENDMOPFUN

`MOPFUN(jnle)
	return 1;
`ENDMOPFUN

`MOPFUN(jnl)
	return 1;
`ENDMOPFUN

`MOPFUN(jl)
	return 1;
`ENDMOPFUN

`MOPFUN(jle)
	return 1;
`ENDMOPFUN

`MOPFUN(jmp)
	return 1;
`ENDMOPFUN

`MOPFUN(jne)
	return 1;
`ENDMOPFUN

`MOPFUN(lea)
	return 1;
`ENDMOPFUN

`MOPFUN(mov)
`ENDMOPFUN

`MOPFUN(nop)
	return 0;
`ENDMOPFUN

`MOPFUN(or)
	return ins_opd0_opd1_out_opd0_rflags(m_or, ins, mops);
`ENDMOPFUN

`MOPFUN(pop)
`ENDMOPFUN

`MOPFUN(push)
`ENDMOPFUN

`MOPFUN(retq)
`ENDMOPFUN

`MOPFUN(shl)
	return ins_opd0_opd1_out_opd0_rflags(m_shl, ins, mops);
`ENDMOPFUN

`MOPFUN(shr)
	return ins_opd0_opd1_out_opd0_rflags(m_shr, ins, mops);
`ENDMOPFUN

`MOPFUN(sub)
	return ins_opd0_opd1_out_opd0_rflags(m_sub, ins, mops);
`ENDMOPFUN

`MOPFUN(syscall)
`ENDMOPFUN

`MOPFUN(test)
	return ins_opd0_opd1_out_x_rflags(m_and, ins, mops);
`ENDMOPFUN

`MOPFUN(xor)
	return ins_opd0_opd1_out_opd0_rflags(m_xor, ins, mops);
`ENDMOPFUN

/*** end of entry points ***/


`define MOP(name) "name" : return name(ins, mops);

/** return the number of micro ops generated, or -1 for error **/
function automatic int gen_micro_ops(fat_instruction_t ins, output micro_op_t[0:MAX_MOP_CNT-1] mops);

	mops = 0;

	int i;
	for (i = 0; i < MAX_MOP_CNT; i++) begin
		mops[i].rip_val = ins.rip_val;
	end

	case (ins.opcode_struct_t.name) begin
		`MOP(add)
		`MOP(and)
		`MOP(callq)
		`MOP(cmp)
		`MOP(imul)
		`MOP(jnb)
		`MOP(jz)
		`MOP(jnle)
		`MOP(jnl)
		`MOP(jl)
		`MOP(jle)
		`MOP(jmp)
		`MOP(jne)
		`MOP(lea)
		`MOP(mov)
		`MOP(nop)
		`MOP(or)
		`MOP(pop)
		`MOP(push)
		`MOP(retq)
		`MOP(shl)
		`MOP(shr)
		`MOP(sub)
		`MOP(syscall)
		`MOP(test)
		`MOP(xor)
		default : begin
			$display("ERROR: instuction not supported: %s", ins.opcode_struct_t.name);
			return -1;
		end
	end
endpackage
