package MicroOp;

import DecoderTypes::*;
import RegMap::*;

parameter MAX_MOP_CNT = 6;

function automatic reg_id_t patch_base(/* verilator lint_off UNUSED */ operand_t opd /* verilator lint_on UNUSED */);
	return opd.base_reg == rnil ? rv0 : opd.base_reg;
endfunction

function automatic reg_id_t patch_index(/* verilator lint_off UNUSED */ operand_t opd /* verilator lint_on UNUSED */);
	return opd.index_reg == rnil ? rv0 : opd.index_reg;
endfunction

`define R0  (patch_base(ins.operand0))
`define RX0 (patch_index(ins.operand0))
`define R1  (patch_base(ins.operand1))
`define RX1 (patch_index(ins.operand1))

function automatic micro_op_t make_mop(micro_opcode_t opc, reg_id_t src0, reg_id_t src1, reg_id_t dst);
	micro_op_t mop = 0;
	mop.opcode = opc;
	mop.src0_id = src0;
	mop.src1_id = src1;
	mop.dst_id = dst;
	return mop;
endfunction

function automatic int crack_opd0_opd1_out_opd0_rflags(
	input micro_opcode_t mopcode, 
	/* verilator lint_off UNUSED */
	input fat_instruction_t ins, 
	/* verilator lint_on UNUSED */
	/* verilator lint_off UNDRIVEN */
	output micro_op_t[0:MAX_MOP_CNT-1] mops
	/* verilator lint_on UNDRIVEN */
);
	if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_register) begin 
		mops[0] = make_mop(mopcode, `R0, `R1, `R0); 
		mops[1] = make_mop(m_cpy, `R0, rnil, rflags); 
		return 2;
	end
	if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_memory) begin 
		mops[0] = make_mop(m_lea, `R1, `RX1, rha);
		mops[1] = make_mop(m_ld, rha, rnil, rha);
		mops[2] = make_mop(mopcode, `R0, rha, `R0); 
		mops[3] = make_mop(m_cpy, `R0, rnil, rflags); 
		return 4;
	end
	if (ins.operand0.opd_type == opdt_memory && ins.operand1.opd_type == opdt_register) begin 
		mops[0] = make_mop(m_lea, `R0, `RX0, rha);
		mops[1] = make_mop(m_ld, rha, rnil, rhb);
		mops[2] = make_mop(mopcode, rhb, `R1, rflags); 
		mops[3] = make_mop(m_st, rflags, rha, rnil);
		return 4;
	end 
	$display("ERROR: crack_opd0_opd1_out_opd0_rflags: invalid combo: %x, %x", ins.operand0.opd_type, ins.operand1.opd_type); 
	$finish;
endfunction

function automatic int crack_opd0_opd1_out_opd0_maybe_rflags(
	input micro_opcode_t mopcode, 
	/* verilator lint_off UNUSED */
	input fat_instruction_t ins, 
	/* verilator lint_on UNUSED */
	/* verilator lint_off UNDRIVEN */
	output micro_op_t[0:MAX_MOP_CNT-1] mops
	/* verilator lint_on UNDRIVEN */
);
	if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_register) begin 
		mops[0] = make_mop(m_cpy_f, `R0, rflags, `R0); 
		mops[1] = make_mop(mopcode, `R0, `R1, `R0); 
		mops[2] = make_mop(m_cpy, `R0, rnil, rflags); 
		return 3;
	end
	if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_memory) begin 
		mops[0] = make_mop(m_lea, `R1, `RX1, rha);
		mops[1] = make_mop(m_ld, rha, rnil, rha);
		mops[2] = make_mop(m_cpy_f, `R0, rflags, `R0); 
		mops[3] = make_mop(mopcode, `R0, rha, `R0); 
		mops[4] = make_mop(m_cpy, `R0, rnil, rflags); 
		return 5;
	end
	if (ins.operand0.opd_type == opdt_memory && ins.operand1.opd_type == opdt_register) begin 
		mops[0] = make_mop(m_lea, `R0, `RX0, rha);
		mops[1] = make_mop(m_ld, rha, rnil, rhb);
		mops[2] = make_mop(m_cpy_f, rhb, rflags, rhb); 
		mops[3] = make_mop(mopcode, rhb, `R1, rflags); 
		mops[4] = make_mop(m_st, rflags, rha, rnil);
		return 5;
	end 
	$display("ERROR: crack_opd0_opd1_out_opd0_maybe_rflags: invalid combo: %x, %x", ins.operand0.opd_type, ins.operand1.opd_type); 
	$finish;
endfunction

function automatic int crack_opd0_opd1_out_rflags(
	input micro_opcode_t mopcode, 
	/* verilator lint_off UNUSED */
	input fat_instruction_t ins, 
	/* verilator lint_on UNUSED */
	/* verilator lint_off UNDRIVEN */
	output micro_op_t[0:MAX_MOP_CNT-1] mops
	/* verilator lint_on UNDRIVEN */
);
	if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_register) begin 
		mops[0] = make_mop(mopcode, `R0, `R1, rflags); 
		return 1;
	end
	if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_memory) begin 
		mops[0] = make_mop(m_lea, `R1, `RX1, rha);
		mops[1] = make_mop(m_ld, rha, rnil, rha);
		mops[2] = make_mop(mopcode, `R0, rha, rflags); 
		return 3;
	end
	if (ins.operand0.opd_type == opdt_memory && ins.operand1.opd_type == opdt_register) begin 
		mops[0] = make_mop(m_lea, `R0, `RX0, rha);
		mops[1] = make_mop(m_ld, rha, rnil, rha);
		mops[2] = make_mop(mopcode, rha, `R1, rflags); 
		return 3;
	end 
	$display("ERROR: crack_opd0_opd1_out_flags: invalid combo: %x, %x", ins.operand0.opd_type, ins.operand1.opd_type); 
	$finish;
endfunction

function automatic int crack_imul1(
	/* verilator lint_off UNUSED */
	input fat_instruction_t ins, 
	/* verilator lint_on UNUSED */
	/* verilator lint_off UNDRIVEN */
	output micro_op_t[0:MAX_MOP_CNT-1] mops
	/* verilator lint_on UNDRIVEN */
);
	if (ins.operand0.opd_type == opdt_register) begin 
		mops[0] = make_mop(m_imul_l, rax, `R0, rha);
		mops[1] = make_mop(m_imul_h, rax, `R0, rdx);
		mops[2] = make_mop(m_cpy, rha, rnil, rax);
		mops[3] = make_mop(m_cpy, rdx, rnil, rflags);
		return 4;
	end
	if (ins.operand0.opd_type == opdt_memory) begin 
		mops[0] = make_mop(m_lea, `R0, `RX0, rha);
		mops[1] = make_mop(m_ld, rha, rnil, rha);
		mops[2] = make_mop(m_imul_l, rax, rha, rhb);
		mops[3] = make_mop(m_imul_h, rax, rha, rdx);
		mops[4] = make_mop(m_cpy, rhb, rnil, rax);
		mops[5] = make_mop(m_cpy, rdx, rnil, rflags);
		return 6;
	end
	$display("ERROR: crack_imul1: invalid operand type: %x", ins.operand0.opd_type); 
	$finish;
endfunction

function automatic int crack_jcc(
	input micro_opcode_t mopcode, 
	/* verilator lint_off UNUSED */
	input fat_instruction_t ins, 
	/* verilator lint_on UNUSED */
	/* verilator lint_off UNDRIVEN */
	output micro_op_t[0:MAX_MOP_CNT-1] mops
	/* verilator lint_on UNDRIVEN */
);
	if (ins.operand0.opd_type == opdt_register && `R0 == rimm) begin // rip offset
		mops[0] = make_mop(m_add, rip, rimm, rha);
		mops[1] = make_mop(mopcode, rha, rflags, rnil);
		return 2;
	end
	if (ins.operand0.opd_type == opdt_register) begin
		mops[0] = make_mop(mopcode, `R0, rflags, rnil);
		return 1;
	end
	if (ins.operand0.opd_type == opdt_memory) begin
		mops[0] = make_mop(m_lea, `R0, `RX0, rha);
		mops[1] = make_mop(m_ld, rha, rnil, rha);
		mops[2] = make_mop(mopcode, rha, rflags, rnil);
		return 3;
	end
	$display("ERROR: crack_jcc: invalid operand type: %x", ins.operand0.opd_type); 
	$finish;
endfunction


/*** macros for entry points ***/
`define MOPFUN(fun) \
function automatic int ins_``fun( \
	/* verilator lint_off UNUSED */ \
	input fat_instruction_t ins, \
	/* verilator lint_on UNUSED */ \
	/* verilator lint_off UNDRIVEN */ \
	output micro_op_t[0:MAX_MOP_CNT-1] mops \
	/* verilator lint_on UNDRIVEN */ \
);

`define ENDMOPFUN   endfunction

/*** begin of entry points ***/
`MOPFUN(nop)
	return 0;
`ENDMOPFUN

`MOPFUN(lea)
	mops[0] = make_mop(m_lea, `R1, `RX1, `R0);
	return 1;
`ENDMOPFUN

`MOPFUN(syscall)
	mops[0] = make_mop(m_syscall, rnil, rnil, rnil);
	return 1;
`ENDMOPFUN

`MOPFUN(add)
	return crack_opd0_opd1_out_opd0_rflags(m_add, ins, mops);
`ENDMOPFUN

`MOPFUN(and)
	return crack_opd0_opd1_out_opd0_rflags(m_and, ins, mops);
`ENDMOPFUN

`MOPFUN(or)
	return crack_opd0_opd1_out_opd0_rflags(m_or, ins, mops);
`ENDMOPFUN

`MOPFUN(sub)
	return crack_opd0_opd1_out_opd0_rflags(m_sub, ins, mops);
`ENDMOPFUN

`MOPFUN(xor)
	return crack_opd0_opd1_out_opd0_rflags(m_xor, ins, mops);
`ENDMOPFUN

`MOPFUN(shl)
	return crack_opd0_opd1_out_opd0_maybe_rflags(m_shl, ins, mops);
`ENDMOPFUN

`MOPFUN(shr)
	return crack_opd0_opd1_out_opd0_maybe_rflags(m_shr, ins, mops);
`ENDMOPFUN

`MOPFUN(cmp)
	return crack_opd0_opd1_out_rflags(m_sub, ins, mops);
`ENDMOPFUN

`MOPFUN(test)
	return crack_opd0_opd1_out_rflags(m_and, ins, mops);
`ENDMOPFUN

`MOPFUN(imul)
	if (ins.opcode_struct.opcode == 24'hF7) begin
		// one operand
		return crack_imul1(ins, mops);
	end else if (ins.opcode_struct.opcode == 24'h0FAF) begin
		// two operands
		return crack_opd0_opd1_out_opd0_rflags(m_imul_l, ins, mops);
	end else begin
		// three operands
		$display("ERROR: imul: 3-operand imul not supported yet"); 
		$finish;
	end
`ENDMOPFUN

`MOPFUN(jnb)
	return crack_jcc(m_jnb, ins, mops);
`ENDMOPFUN

`MOPFUN(jz)
	return crack_jcc(m_jz, ins, mops);
`ENDMOPFUN

`MOPFUN(jnle)
	return crack_jcc(m_jnle, ins, mops);
`ENDMOPFUN

`MOPFUN(jnl)
	return crack_jcc(m_jnl, ins, mops);
`ENDMOPFUN

`MOPFUN(jl)
	return crack_jcc(m_jl, ins, mops);
`ENDMOPFUN

`MOPFUN(jle)
	return crack_jcc(m_jle, ins, mops);
`ENDMOPFUN

`MOPFUN(jne)
	return crack_jcc(m_jne, ins, mops);
`ENDMOPFUN

`MOPFUN(jmp)
	if (ins.operand0.opd_type == opdt_register && `R0 == rimm) begin // rip offset
		mops[0] = make_mop(m_add, rip, rimm, rha);
		mops[1] = make_mop(m_jmp, rha, rnil, rnil);
		return 2;
	end
	if (ins.operand0.opd_type == opdt_register) begin
		mops[0] = make_mop(m_jmp, `R0, rnil, rnil);
		return 1;
	end
	if (ins.operand0.opd_type == opdt_memory) begin
		mops[0] = make_mop(m_lea, `R0, `RX0, rha);
		mops[1] = make_mop(m_ld, rha, rnil, rha);
		mops[2] = make_mop(m_jmp, rha, rnil, rnil);
		return 3;
	end
	$display("ERROR: jmp: invalid operand type: %x", ins.operand0.opd_type); 
	$finish;
`ENDMOPFUN

`MOPFUN(mov)
	if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_register) begin 
		mops[0] = make_mop(m_cpy, `R1, rnil, `R0); 
		return 1;
	end
	if (ins.operand0.opd_type == opdt_register && ins.operand1.opd_type == opdt_memory) begin 
		mops[0] = make_mop(m_lea, `R1, `RX1, rha);
		mops[1] = make_mop(m_ld, rha, rnil, `R0);
		return 2;
	end
	if (ins.operand0.opd_type == opdt_memory && ins.operand1.opd_type == opdt_register) begin 
		mops[0] = make_mop(m_lea, `R0, `RX0, rha);
		mops[1] = make_mop(m_st, `R1, rha, rnil);
		return 2;
	end 
	$display("ERROR: mov: invalid combo: %x, %x", ins.operand0.opd_type, ins.operand1.opd_type); 
	$finish;
`ENDMOPFUN

`MOPFUN(pop)
	// See manual for when to change %rsp, this matters because %rsp can be the destination of pop.
	if (ins.operand0.opd_type == opdt_register) begin
		mops[0] = make_mop(m_ld, rsp, rnil, `R0);
		mops[1] = make_mop(m_add, rsp, rv8, rsp);
		return 2;
	end
	if (ins.operand0.opd_type == opdt_memory) begin
		mops[0] = make_mop(m_ld, rsp, rnil, rha);
		mops[1] = make_mop(m_lea, `R0, `RX0, rhb);
		mops[2] = make_mop(m_st, rha, rhb, rnil);
		mops[3] = make_mop(m_add, rsp, rv8, rsp);
		return 4;
	end
	$display("ERROR: pop: invalid operand type: %x", ins.operand0.opd_type); 
	$finish;
`ENDMOPFUN

`MOPFUN(push)
	// See manual for when to change %rsp, this matters because %rsp can be pushed onto the stack.
	mops[0] = make_mop(m_sub, rsp, rv8, rsp);
	if (ins.operand0.opd_type == opdt_register) begin
		mops[1] = make_mop(m_st, `R0, rsp, rnil);
		return 2;
	end
	if (ins.operand0.opd_type == opdt_memory) begin
		mops[1] = make_mop(m_lea, `R0, `RX0, rha);
		mops[2] = make_mop(m_ld, rha, rnil, rha);
		mops[3] = make_mop(m_st, rha, rsp, rnil);
		return 4;
	end
	$display("ERROR: push: invalid operand type: %x", ins.operand0.opd_type); 
	$finish;
`ENDMOPFUN

`MOPFUN(callq)
	// push rip
	mops[0] = make_mop(m_sub, rsp, rv8, rsp);
	mops[1] = make_mop(m_st, rip, rsp, rnil);
	// jmp
	if (ins.operand0.opd_type == opdt_register && `R0 == rimm) begin // rip offset
		mops[2] = make_mop(m_add, rip, rimm, rha);
		mops[3] = make_mop(m_jmp, rha, rnil, rnil);
		return 4;
	end
	if (ins.operand0.opd_type == opdt_register) begin
		mops[2] = make_mop(m_jmp, `R0, rnil, rnil);
		return 3;
	end
	if (ins.operand0.opd_type == opdt_memory) begin
		mops[2] = make_mop(m_lea, `R0, `RX0, rha);
		mops[3] = make_mop(m_ld, rha, rnil, rha);
		mops[4] = make_mop(m_jmp, rha, rnil, rnil);
		return 5;
	end
	$display("ERROR: callq: invalid operand type: %x", ins.operand0.opd_type); 
	$finish;
`ENDMOPFUN

`MOPFUN(retq)
	// pop rip to rha
	mops[0] = make_mop(m_ld, rsp, rnil, rha);
	mops[1] = make_mop(m_add, rsp, rv8, rsp);
	// jmp
	mops[2] = make_mop(m_jmp, rha, rnil, rnil);
	return 3;
`ENDMOPFUN

/*** end of entry points ***/


`define MOP(name) "name" : cnt = ins_``name(ins, mops);

/** Return the number of micro ops generated. **/
/** On error, program will be stopped, so no need for caller to handle error case. **/
function automatic int gen_micro_ops(fat_instruction_t ins, output micro_op_t[0:MAX_MOP_CNT-1] mops);

	int cnt = 0;
	int i = 0;

	mops = 0;
	case (ins.opcode_struct.name)
		`MOP(nop)
		`MOP(lea)
		`MOP(syscall)
		`MOP(add)
		`MOP(and)
		`MOP(or)
		`MOP(shl)
		`MOP(shr)
		`MOP(sub)
		`MOP(xor)
		`MOP(cmp)
		`MOP(test)
		`MOP(imul)
		`MOP(jnb)
		`MOP(jz)
		`MOP(jnle)
		`MOP(jnl)
		`MOP(jl)
		`MOP(jle)
		`MOP(jne)
		`MOP(jmp)
		`MOP(mov)
		`MOP(pop)
		`MOP(push)
		`MOP(callq)
		`MOP(retq)
		default : begin
			$display("ERROR: instuction not supported: %s", ins.opcode_struct.name);
			$finish;
		end
	endcase

	for (i = 0; i < MAX_MOP_CNT; i++) begin
		mops[i].rip_val = ins.rip_val;
		mops[i].scale = ins.scale;
		mops[i].disp = ins.disp;
		mops[i].immediate = ins.immediate;
	end

	return cnt;
endfunction

endpackage
