
`include "MacroUtils.sv"

`define M(c, n, m) 'h``c: begin res.name = "n"; res.mode = "m"; end
`define G(c, g, m) 'h``c: begin res.name = 0; res.mode = "m"; res.group = 'h``g; end

`define MAP_BEGIN(name) \
	function automatic opcode_struct_t name(logic[7:0] key); \
		opcode_struct_t res = 0; \
		case (key)

`define MAP_END \
		endcase \
		return res; \
	endfunction

package OpcodeMap;

import DecoderTypes::*;

/* Use _ to represent an empty mode */

`MAP_BEGIN(opcode_map1)

	`M(01, add, Ev_Gv)
	`M(03, add, Gv_Ev)
	`M(05, add, rax_Iz)
	`M(09, or,  Ev_Gv)
	`M(0B, or,  Gv_Ev)
	`M(0D, or,  rax_Iz)

	`M(11, adc, Ev_Gv)
	`M(13, adc, Gv_Ev)
	`M(15, adc, rax_Iz)
	`M(19, sbb, Gv_Ev)
	`M(1B, sbb, Gv_Ev)
	`M(1D, sbb, rax_Iz)

	`M(21, and, Ev_Gv)
	`M(23, and, Gv_Ev)
	`M(25, and, rax_Iz)
	`M(29, sub, Ev_Gv)
	`M(2B, sub, Gv_Ev)
	`M(2D, sub, rax_Iz)

	`M(31, xor, Ev_Gv)
	`M(33, xor, Gv_Ev)
	`M(35, xor, rax_Iz)
	`M(39, cmp, Ev_Gv)
	`M(3B, cmp, Gv_Ev)
	`M(3D, cmp, rax_Iz)

	`M(50, push, rax$r8)
	`M(51, push, rcx$r9)
	`M(52, push, rdx$r10)
	`M(53, push, rbx$r11)
	`M(54, push, rsp$r12)
	`M(55, push, rbp$r13)
	`M(56, push, rsi$r14)
	`M(57, push, rdi$r15)
	`M(58, pop, rax$r8)
	`M(59, pop, rcx$r9)
	`M(5A, pop, rdx$r10)
	`M(5B, pop, rbx$r11)
	`M(5C, pop, rsp$r12)
	`M(5D, pop, rbp$r13)
	`M(5E, pop, rsi$r14)
	`M(5F, pop, rdi$r15)

	`M(68, push, Iz)
	`M(69, imul, Gv_Ev_Iz)
	`M(6A, push, Ib)
	`M(6B, imul, Gv_Ev_Ib)

	`M(70, jo, Jb)
	`M(71, jno, Jb)
	`M(72, jb, Jb)
	`M(73, jnb, Jb)
	`M(74, jz, Jb)
	`M(75, jnz, Jb)
	`M(76, jbe, Jb)
	`M(77, jnbe, Jb)
	`M(78, js, Jb)
	`M(79, jns, Jb)
	`M(7A, jp, Jb)
	`M(7B, jnp, Jb)
	`M(7C, jl, Jb)
	`M(7D, jnl, Jb)
	`M(7E, jle, Jb)
	`M(7F, jnle, Jb)

	`G(81, 1, Ev_Iz)
	`G(83, 1, Ev_Ib)
	`M(85, test, Ev_Gv)
	`M(87, xchg, Ev_Gv)
	`M(89, mov, Ev_Gv)
	`M(8B, mov, Gv_Ev)
	`M(8D, lea, Gv_M)
	`G(8F, 1A, Ev)

	`M(90, nop, _)

	`M(B8, movabs, rax$r8_Iv)
	`M(B9, movabs, rcx$r9_Iv)
	`M(BA, movabs, rdx$r10_Iv)
	`M(BB, movabs, rbx$r11_Iv)
	`M(BC, movabs, rsp$r12_Iv)
	`M(BD, movabs, rbp$r13_Iv)
	`M(BE, movabs, rsi$r14_Iv)
	`M(BF, movabs, rdi$r15_Iv)

	`G(C1, 2, Ev_Ib)
	`M(C3, retq, _)
	`G(C7, 11, Ev_Iz)

	`G(D1, 2, Ev_1)
	`G(D3, 2, Ev_CL)

	`M(E8, call, Jz)
	`M(E9, jmp, Jz)
	`M(EB, jmp, Jb)

	`G(F7, 3, Ev)
	`G(FF, 5, _)

`MAP_END

`MAP_BEGIN(opcode_map2)
	`M(05, syscall, _)

	`M(80, jo, Jz)
	`M(81, jno, Jz)
	`M(82, jb, Jz)
	`M(83, jnb, Jz)
	`M(84, jz, Jz)
	`M(85, jnz, Jz)
	`M(86, jbe, Jz)
	`M(87, jnbe, Jz)
	`M(88, js, Jz)
	`M(89, jns, Jz)
	`M(8A, jp, Jz)
	`M(8B, jnp, Jz)
	`M(8C, jl, Jz)
	`M(8D, jnl, Jz)
	`M(8E, jle, Jz)
	`M(8F, jnle, Jz)

	`M(AF, imul, Gv_Ev)
`MAP_END

`MAP_BEGIN(opcode_map3)
`MAP_END

`MAP_BEGIN(opcode_map4)
`MAP_END

`define GMC(g, k, c, n, m) {32'h``g, 8'b``k, 24'h``c}: begin res.name = "n"; res.mode = "m"; end
`define GM(g, k, n, m) `GMC(g, k, ?, n, m)

function automatic opcode_struct_t group_opcode_map(int group, logic[7:0] key, logic [0:3*8-1] opcode);
	opcode_struct_t res = 0;
	casez ({group, key, opcode})

	/* within the same group, patterns with more ?'s should appear before patterns with less ?'s */

	`GM(1, ??000???, add, _)
	`GM(1, ??001???, or, _)
	`GM(1, ??010???, adc, _)
	`GM(1, ??011???, sbb, _)
	`GM(1, ??100???, and, _)
	`GM(1, ??101???, sub, _)
	`GM(1, ??110???, xor, _)
	`GM(1, ??111???, cmp, _)

	`GM(1A, ??000???, pop, _)
	
	`GM(2, ??000???, rol, _)
	`GM(2, ??001???, ror, _)
	`GM(2, ??010???, rcl, _)
	`GM(2, ??011???, rcr, _)
	`GM(2, ??100???, shl, _)
	`GM(2, ??101???, shr, _)
	`GM(2, ??111???, sar, _)

	`GMC(3, ??000???, F7, test, Ev_Iz)
	`GM(3, ??010???, not, _)
	`GM(3, ??011???, neg, _)
	`GMC(3, ??100???, F7, mul, Ev_rax)
	`GMC(3, ??101???, F7, imul, Ev_rax)
	`GMC(3, ??110???, F7, div, Ev_rax)
	`GMC(3, ??111???, F7, idiv, Ev_rax)

	`GM(5, ??000???, inc, Ev)
	`GM(5, ??001???, dec, Ev)
	`GM(5, ??010???, call, Ev)
	`GM(5, ??011???, call, Ep)
	`GM(5, ??100???, jmp, Ev)
	`GM(5, ??101???, jmp, Mp)
	`GM(5, ??110???, push, Ev)

	`GMC(11, ??000???, C7, mov, Ev_Iz)

	endcase
	return res;
endfunction

/* op_struct.name will be zero when something goes wrong */
/* returns the number of bytes in opcode, excluding ModRM, even if it's used */
function automatic int fill_opcode_struct(logic[0:4*8-1] op_bytes, output opcode_struct_t op_struct);

	int idx = 0;
	logic[7:0] modrm = 0;
	/* verilator lint_off UNUSED */
	opcode_struct_t tmp = 0;
	/* verilator lint_on UNUSED */

	op_struct = 0;

	if (`get_byte(op_bytes, 0) == 'h0F) begin
		if (`get_byte(op_bytes, 1) == 'h3A) begin
			op_struct = opcode_map4(`get_byte(op_bytes, 2));
			`eget_bytes(op_struct.opcode, 0, 3) = `eget_bytes(op_bytes, 0, 3);
			idx = 3;
		end else if (`get_byte(op_bytes, 1) == 'h38) begin
			op_struct = opcode_map3(`get_byte(op_bytes, 2));
			`eget_bytes(op_struct.opcode, 0, 3) = `eget_bytes(op_bytes, 0, 3);
			idx = 3;
		end else begin
			op_struct = opcode_map2(`get_byte(op_bytes, 1));
			`eget_bytes(op_struct.opcode, 1, 3) = `eget_bytes(op_bytes, 0, 2);
			idx = 2;
		end
	end else begin
		op_struct = opcode_map1(`get_byte(op_bytes, 0));
		`eget_bytes(op_struct.opcode, 2, 3) = `eget_bytes(op_bytes, 0, 1);
		idx = 1;
	end

	if (op_struct.group != 0) begin
		modrm = `get_byte(op_bytes, idx);
		tmp = group_opcode_map(op_struct.group, modrm, op_struct.opcode);
		op_struct.name = tmp.name;
		/* group-map mode overrides opcode-map mode */
		if (tmp.mode != "_") begin
			op_struct.mode = tmp.mode;
		end
	end

	return idx;
endfunction

endpackage;
