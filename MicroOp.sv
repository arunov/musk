package MicroOp;

import DecoderTypes::*;
import RegMap::*;

parameter MAX_MOP_CNT = 8;

function automatic micro_op_t make_mop(micro_opcode_t opc, reg_id_t src0, reg_id_t src1, reg_id_t dst);
	micro_op_t mop = 0;
	mop.opcode = opc;
	mop.src0_id = src0;
	mop.src1_id = src1;
	mop.dst_id = dst;
	return mop;
endfunction

function automatic int crack_opd0_opd1_out_opd0_rflags(micro_opcode_t mopcode, fat_instruction_t ins, int idx, output micro_op_t[0:MAX_MOP_CNT-1] mops);
	if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_register) begin 
		mops[idx] = make_mop(mopcode, ins.operand0.base_reg, ins.operand1.base_reg, ins.operand0.base_reg); 
		mops[idx+1] = make_mop(m_cpy, ins.operand0.base_reg, rnil, rflags); 
		return 2;
	end else if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_memory) begin 
		mops[idx] = make_mop(m_lea, ins.operand1.base_reg, ins.operand1.index_reg, rh0);
		mops[idx+1] = make_mop(m_ld, rh0, rnil, rh1);
		mops[idx+2] = make_mop(mopcode, ins.operand0.base_reg, rh1, ins.operand0.base_reg); 
		mops[idx+3] = make_mop(m_cpy, ins.operand0.base_reg, rnil, rflags); 
		return 4;
	end else if (ins.operand0.opd_type == opdt_memory && ins.operand1.opd_type == opdt_register) begin 
		mops[idx] = make_mop(m_lea, ins.operand0.base_reg, ins.operand0.index_reg, rh0);
		mops[idx+1] = make_mop(m_ld, rh0, rnil, rh1);
		mops[idx+2] = make_mop(mopcode, rh1, ins.operand1.base_reg, rh1); 
		mops[idx+3] = make_mop(m_cpy, rh1, rnil, rflags); 
		mops[idx+4] = make_mop(m_st, rh0, rh1, rnil); 
		return 5;
	end else begin 
		$display("ERROR: crack_opd0_opd1_out_opd0_rflags: invalid combo: %x, %x", ins.operand0.opd_type, ins.operand1.opd_type); 
		return -1;
	end
endfunction

function automatic int crack_opd0_opd1_out_x(micro_opcode_t mopcode, fat_instruction_t ins, reg_id_t x_reg);
	int cnt = 0;
	if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_register) begin 
		mops[0] = make_mop(mopcode, ins.operand0.base_reg, ins.operand1.base_reg, x_reg); 
		return 1;
	end else if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_memory) begin 
		mops[0] = make_mop(m_lea, ins.operand1.base_reg, ins.operand1.index_reg, rh0);
		mops[1] = make_mop(m_ld, rh0, rnil, rh1);
		mops[2] = make_mop(mopcode, ins.operand0.base_reg, rh1, x_reg); 
		return 3;
	end else if (ins.operand0.opd_type == opdt_memory && ins.operand1.opd_type == opdt_register) begin 
		mops[0] = make_mop(m_lea, ins.operand0.base_reg, ins.operand0.index_reg, rh0);
		mops[1] = make_mop(m_ld, rh0, rnil, rh1);
		mops[2] = make_mop(mopcode, rh1, ins.operand1.base_reg, x_reg); 
		return 3;
	end else begin 
		$display("ERROR: crack_opd0_opd1_out_x: invalid combo: %x, %x", ins.operand0.opd_type, ins.operand1.opd_type); 
		return -1;
	end
endfunction

/*** macros for entry points ***/
`define MOPFUN(fun) function automatic int fun(fat_instruction_t ins, output micro_op_t[0:MAX_MOP_CNT-1] mops);
`define ENDMOPFUN   endfunction

/*** begin of entry points ***/
`MOPFUN(add)
	return crack_opd0_opd1_out_opd0_rflags(m_add, ins);
`ENDMOPFUN

`MOPFUN(and)
	return crack_opd0_opd1_out_opd0_rflags(m_and, ins);
`ENDMOPFUN

`MOPFUN(callq)
`ENDMOPFUN

`MOPFUN(cmp)
	return crack_opd0_opd1_out_x(m_sub, ins, rflags);
`ENDMOPFUN

`MOPFUN(imul)
	if (ins.opcode_struct.opcode == 24'hF7) begin // one operand
		`crack_opd0_out_x(m_imul, mf_rax_r0_out_rax_rdx_rflags)
	end else if (ins.opcode_struct.opcode == 24'h0FAF) begin // two operands
		return crack_opd0_opd1_out_opd0_rflags(m_imul_l, ins);
	end else begin // three operands
		
	end
`ENDMOPFUN

`MOPFUN(jnb)
	`crack_opd0_out_x(m_jnb, mf_r0_out_x)
`ENDMOPFUN

`MOPFUN(jz)
	`crack_opd0_out_x(m_jz, mf_r0_out_x)
`ENDMOPFUN

`MOPFUN(jnle)
	`crack_opd0_out_x(m_jnle, mf_r0_out_x)
`ENDMOPFUN

`MOPFUN(jnl)
	`crack_opd0_out_x(m_jnl, mf_r0_out_x)
`ENDMOPFUN

`MOPFUN(jl)
	`crack_opd0_out_x(m_jl, mf_r0_out_x)
`ENDMOPFUN

`MOPFUN(jle)
	`crack_opd0_out_x(m_jle, mf_r0_out_x)
`ENDMOPFUN

`MOPFUN(jmp)
	`crack_opd0_out_x(m_jmp, mf_r0_out_x)
`ENDMOPFUN

`MOPFUN(jne)
	`crack_opd0_out_x(m_jne, mf_r0_out_x)
`ENDMOPFUN

`MOPFUN(lea)
	mops[0] = make_mop(m_lea, ins.operand1.base_reg, ins.operand1.index_reg, ins.operand0.base_reg);
	return 1;
`ENDMOPFUN

`MOPFUN(mov)
`ENDMOPFUN

`MOPFUN(nop)
	return 0;
`ENDMOPFUN

`MOPFUN(or)
	return crack_opd0_opd1_out_opd0_rflags(m_or, ins);
`ENDMOPFUN

`MOPFUN(pop)
`ENDMOPFUN

`MOPFUN(push)
`ENDMOPFUN

`MOPFUN(retq)
`ENDMOPFUN

`MOPFUN(shl)
	return crack_opd0_opd1_out_opd0_rflags(m_shl, ins);
`ENDMOPFUN

`MOPFUN(shr)
	return crack_opd0_opd1_out_opd0_rflags(m_shr, ins);
`ENDMOPFUN

`MOPFUN(sub)
	return crack_opd0_opd1_out_opd0_rflags(m_sub, ins);
`ENDMOPFUN

`MOPFUN(syscall)
`ENDMOPFUN

`MOPFUN(test)
	return crack_opd0_opd1_out_x(m_and, rflags);
`ENDMOPFUN

`MOPFUN(xor)
	return crack_opd0_opd1_out_opd0_rflags(m_xor, ins);
`ENDMOPFUN

/*** end of entry points ***/


`define MOP(name) "name" : cnt = name(ins, mops);

/** Return the number of micro ops generated, or -1 for error. **/
function automatic int gen_micro_ops(fat_instruction_t ins, output micro_op_t[0:MAX_MOP_CNT-1] mops);

	int cnt = 0;

	mops = 0;
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

	int i = 0;
	for (i = 0; i < MAX_MOP_CNT; i++) begin
		mops[i].rip_val = ins.rip_val;
		mops[i].scale = ins.scale;
		mops[i].disp = ins.disp;
		mops[i].immediate = ins.immediate;
	end

	return cnt;
endpackage
