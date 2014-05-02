`include "MacroUtils.sv"
`include "PrintMacros.sv"

package OperandDecoder;

import DecoderTypes::*;
import RegMap::*;

/*** start of simple functions ***/

parameter REX_W = 3, REX_R = 2, REX_X = 1, REX_B = 0;

function automatic void fillFixedReg(
	/* verilator lint_off UNUSED */
	/* verilator lint_off UNDRIVEN */
	output operand_t operand,
	/* verilator lint_on UNDRIVEN */
	input logic[7:0] rex,
	input reg_id_t r0,
	input reg_id_t r1
	/* verilator lint_on UNUSED */
);
	operand.opd_type = opdt_register;
	operand.base_reg = rex[REX_R] == 0 ? r0 : r1;
endfunction

function automatic int operand_size( /* verilator lint_off UNUSED */ fat_instruction_t ins /* verilator lint_on UNUSED */);
	if (ins.rex_prefix[REX_W]) begin
		return 64;
	end else begin
		return ins.operand_size_prefix != 0 ? 16 : 32;
	end
endfunction

function automatic int crackSIB(
	/* verilator lint_off UNUSED */
	/* verilator lint_off UNDRIVEN */
	output operand_t operand,
	/* verilator lint_on UNDRIVEN */
	input fat_instruction_t ins,
	input logic[7:0] modrm,
	input logic[7:0] sib,
	input int index,
	input logic[0:10*8-1] opd_bytes
	/* verilator lint_on UNUSED */
);
	operand.opd_type = opdt_memory;

	if (!(sib[2:0] == 3'b101 && modrm[7:6] == 2'b00)) begin
		operand.mem_has_base = 1;
		operand.base_reg = {4'b0, ins.rex_prefix[REX_B], sib[2:0]};
	end

	if (!(sib[5:3] == 3'b100)) begin
		operand.mem_has_index = 1;
		operand.index_reg = {4'b0, ins.rex_prefix[REX_X], sib[5:3]};
	end

	operand.scale = 1 << sib[7:6];

	if (modrm[7:6] == 2'b00 && sib[2:0] == 3'b101) begin
		operand.mem_has_disp = 1;
		operand.disp = Utils::le_4bytes_to_val(`pget_bytes(opd_bytes, index, 4));
		return 4;
	end

	unique case (modrm[7:6])
		2'b00 : return 0;
		2'b01 : begin
			operand.mem_has_disp = 1;
			operand.disp = Utils::le_1bytes_to_val(`get_byte(opd_bytes, index));
			return 1;
		end
		2'b10 : begin
			operand.mem_has_disp = 1;
			operand.disp = Utils::le_4bytes_to_val(`pget_bytes(opd_bytes, index, 4));
			return 4;
		end
		2'b11 : return 0;
	endcase
endfunction

/*** end of simple functions ***/

/*** Macros for defining handlers ***/
`define HANDLER(fun) \
function automatic int handle``fun( \
	/* verilator lint_off UNUSED */ \
	/* verilator lint_off UNDRIVEN */\
	output operand_t operand, \
	/* verilator lint_on UNDRIVEN */\
	input fat_instruction_t ins, \
	input logic[7:0] modrm, \
	input int index, \
	input logic[0:10*8-1] opd_bytes \
	/* verilator lint_on UNUSED */ \
);
`define ENDHANDLER endfunction

/*** start of handlers ***/
`HANDLER(Ib)
	operand.opd_type = opdt_immediate;
	operand.immediate = Utils::le_1bytes_to_val(`get_byte(opd_bytes, index));
	return 1;
`ENDHANDLER

`HANDLER(Iz)
	operand.opd_type = opdt_immediate;
	operand.immediate = Utils::le_4bytes_to_val(`pget_bytes(opd_bytes, index, 4));
	return 4;
`ENDHANDLER

`HANDLER(Iv)
	int op_size = operand_size(ins);
	operand.opd_type = opdt_immediate;
	case (op_size)
		16 : begin
			operand.immediate = Utils::le_2bytes_to_val(`pget_bytes(opd_bytes, index, 2));
			return 2;
		end
		32 : begin
			operand.immediate = Utils::le_4bytes_to_val(`pget_bytes(opd_bytes, index, 4));
			return 4;
		end
		64 : begin
			operand.immediate = Utils::le_8bytes_to_val(`pget_bytes(opd_bytes, index, 8));
			return 8;
		end
		default: begin
			$display("ERROR: operand size: %d", op_size);
			return -1;
		end
	endcase
`ENDHANDLER

`HANDLER(Gv)
	operand.opd_type = opdt_register;
	operand.base_reg = {4'b0, ins.rex_prefix[REX_R], modrm[5:3]};
	return 0;
`ENDHANDLER

`HANDLER(Ev)
	if (modrm[7:6] != 2'b11 && modrm[2:0] == 3'b100) begin // has SIB byte
		logic [7:0] sib = `get_byte(opd_bytes, index);
		return crackSIB(operand, ins, modrm, sib, index+1, opd_bytes);
	end

	if (modrm[7:6] == 2'b00 && modrm[2:0] == 3'b101) begin // rip relative
		operand.opd_type = opdt_memory;
		operand.mem_rip_relative = 1;
		operand.disp = Utils::le_4bytes_to_val(`pget_bytes(opd_bytes, index, 4));
		return 4;
	end

	operand.base_reg = {4'b0, ins.rex_prefix[REX_B], modrm[2:0]};
	unique case (modrm[7:6])
		2'b00: begin
			operand.opd_type = opdt_memory;
			operand.mem_has_base = 1;
			return 0;
		end
		2'b01: begin
			operand.opd_type = opdt_memory;
			operand.mem_has_base = 1;
			operand.mem_has_disp = 1;
			operand.disp = Utils::le_1bytes_to_val(`get_byte(opd_bytes, index));
			return 1;
		end
		2'b10: begin
			operand.opd_type = opdt_memory;
			operand.mem_has_base = 1;
			operand.mem_has_disp = 1;
			operand.disp = Utils::le_4bytes_to_val(`pget_bytes(opd_bytes, index, 4));
			return 4;
		end
		2'b11: begin
			operand.opd_type = opdt_register;
			return 0;
		end
	endcase
`ENDHANDLER

`HANDLER(M)
	if (modrm[7:6] == 2'b11) begin // Not addressing memory
		return -1;
	end else begin
		return handleEv(operand, ins, modrm, index, opd_bytes);
	end
`ENDHANDLER

`HANDLER(rax)
	operand.opd_type = opdt_register;
	operand.base_reg = rax;
	return 0;
`ENDHANDLER

/*** end of handlers ***/

/*** Macros for defining entry points ***/

/* A DFUN returns the number of bytes consumed. Or -1 for error */
`define DFUN(fun) \
function automatic int fun( \
	/* verilator lint_off UNUSED */ \
	inout fat_instruction_t ins, \
	input logic[7:0] modrm, \
	input int index, \
	input logic[0:10*8-1] opd_bytes \
	/* verilator lint_on UNUSED */ \
);
`define ENDDFUN endfunction

`define COMPOSE(hd0, hd1) \
	int cnt0, cnt1; \
	cnt0 = handle``hd0(ins.operand0, ins, modrm, index, opd_bytes); \
	if (cnt0 < 0) return -1; \
	cnt1 = handle``hd1(ins.operand1, ins, modrm, index + cnt0, opd_bytes); \
	if (cnt1 < 0) return -1; \
	return cnt0 + cnt1;

/*** start of entry points ***/

`DFUN(rax$r8)
	fillFixedReg(ins.operand0, ins.rex_prefix, rax, r8); 
	return 0;
`ENDDFUN

`DFUN(rcx$r9)
	fillFixedReg(ins.operand0, ins.rex_prefix, rcx, r9); 
	return 0;
`ENDDFUN

`DFUN(rdx$r10)
	fillFixedReg(ins.operand0, ins.rex_prefix, rdx, r10); 
	return 0;
`ENDDFUN

`DFUN(rbx$r11)
	fillFixedReg(ins.operand0, ins.rex_prefix, rbx, r11); 
	return 0;
`ENDDFUN

`DFUN(rsp$r12)
	fillFixedReg(ins.operand0, ins.rex_prefix, rsp, r12); 
	return 0;
`ENDDFUN

`DFUN(rbp$r13)
	fillFixedReg(ins.operand0, ins.rex_prefix, rbp, r13); 
	return 0;
`ENDDFUN

`DFUN(rsi$r14)
	fillFixedReg(ins.operand0, ins.rex_prefix, rsi, r14); 
	return 0;
`ENDDFUN

`DFUN(rdi$r15)
	fillFixedReg(ins.operand0, ins.rex_prefix, rdi, r15); 
	return 0;
`ENDDFUN

`DFUN(rax$r8_Iv)
	fillFixedReg(ins.operand0, ins.rex_prefix, rax, r8); 
	return handleIv(ins.operand1, ins, modrm, index, opd_bytes);
`ENDDFUN

`DFUN(rcx$r9_Iv)
	fillFixedReg(ins.operand0, ins.rex_prefix, rcx, r9); 
	return handleIv(ins.operand1, ins, modrm, index, opd_bytes);
`ENDDFUN

`DFUN(rdx$r10_Iv)
	fillFixedReg(ins.operand0, ins.rex_prefix, rdx, r10); 
	return handleIv(ins.operand1, ins, modrm, index, opd_bytes);
`ENDDFUN

`DFUN(rbx$r11_Iv)
	fillFixedReg(ins.operand0, ins.rex_prefix, rbx, r11); 
	return handleIv(ins.operand1, ins, modrm, index, opd_bytes);
`ENDDFUN

`DFUN(rsp$r12_Iv)
	fillFixedReg(ins.operand0, ins.rex_prefix, rsp, r12); 
	return handleIv(ins.operand1, ins, modrm, index, opd_bytes);
`ENDDFUN

`DFUN(rbp$r13_Iv)
	fillFixedReg(ins.operand0, ins.rex_prefix, rbp, r13); 
	return handleIv(ins.operand1, ins, modrm, index, opd_bytes);
`ENDDFUN

`DFUN(rsi$r14_Iv)
	fillFixedReg(ins.operand0, ins.rex_prefix, rsi, r14); 
	return handleIv(ins.operand1, ins, modrm, index, opd_bytes);
`ENDDFUN

`DFUN(rdi$r15_Iv)
	fillFixedReg(ins.operand0, ins.rex_prefix, rdi, r15); 
	return handleIv(ins.operand1, ins, modrm, index, opd_bytes);
`ENDDFUN

`DFUN(Ev)
	return handleEv(ins.operand0, ins, modrm, index, opd_bytes);
`ENDDFUN

`DFUN(Ev_Gv)
	`COMPOSE(Ev, Gv);
`ENDDFUN

`DFUN(Ev_Ib)
	`COMPOSE(Ev, Ib);
`ENDDFUN

`DFUN(Ev_Iz)
	`COMPOSE(Ev, Iz);
`ENDDFUN

`DFUN(Gv_Ev)
	`COMPOSE(Gv, Ev);
`ENDDFUN

`DFUN(Gv_M)
	`COMPOSE(Gv, M);
`ENDDFUN

`DFUN(Ev_rax)
	`COMPOSE(Ev, rax);
`ENDDFUN

`DFUN(rax_Iz)
	`COMPOSE(rax, Iz);
`ENDDFUN

`DFUN(Jz)
	ins.operand0.opd_type = opdt_memory;
	ins.operand0.mem_rip_relative = 1;
	ins.operand0.disp = Utils::le_4bytes_to_val(`pget_bytes(opd_bytes, index, 4));
	return 4;
`ENDDFUN

`DFUN(Jb)
	ins.operand0.opd_type = opdt_memory;
	ins.operand0.mem_rip_relative = 1;
	ins.operand0.disp = Utils::le_1bytes_to_val(`get_byte(opd_bytes, index));
	return 1;
`ENDDFUN

`DFUN(_)
	return 0;
`ENDDFUN

/*** end of entry points ***/

function automatic logic has_modrm( /* verilator lint_off UNUSED */ fat_instruction_t ins /* verilator lint_on UNUSED */);

	if (ins.opcode_struct.group != 0) return 1;

	case (ins.opcode_struct.mode)
		"Ev": return 1;
		"Ev_Gv": return 1;
		"Ev_Ib": return 1;
		"Ev_Iz": return 1;
		"Ev_rax": return 1;
		"Gv_Ev": return 1;
		"Gv_M": return 1;
		default: return 0;
	endcase

endfunction

`define D(mode) "mode" : cnt = mode(ins, modrm, index, opd_bytes);

/* Return -1 if error. Otherwise, the number of bytes consumed is returned. */
function automatic int decode_operands(
	/* verilator lint_off UNUSED */
	inout fat_instruction_t ins,
	/* verilator lint_on UNUSED */
	input logic[0:10*8-1] opd_bytes
);

	logic[7:0] modrm = 0;
	int index = 0;
	int cnt = 0;

	if (has_modrm(ins)) begin
		modrm = `get_byte(opd_bytes, 0);
		index = 1;
	end

	case (ins.opcode_struct.mode)
		`D(rax$r8)
		`D(rcx$r9)
		`D(rdx$r10)
		`D(rbx$r11)
		`D(rsp$r12)
		`D(rbp$r13)
		`D(rsi$r14)
		`D(rdi$r15)
		`D(rax$r8_Iv)
		`D(rcx$r9_Iv)
		`D(rdx$r10_Iv)
		`D(rbx$r11_Iv)
		`D(rsp$r12_Iv)
		`D(rbp$r13_Iv)
		`D(rsi$r14_Iv)
		`D(rdi$r15_Iv)
		`D(Ev)
		`D(Ev_Gv)
		`D(Ev_Ib)
		`D(Ev_Iz)
		`D(Gv_Ev)
		`D(Gv_M)
		`D(Ev_rax)
		`D(rax_Iz)
		`D(Jz)
		`D(Jb)
		`D(_)
		default: begin 
			$display("ERROR: opcode mode unsupported: %s", ins.opcode_struct.mode);
			return -1;
		end
	endcase

	if (cnt < 0) begin
		return -1;
	end else begin
		return index + cnt;
	end

endfunction

endpackage
