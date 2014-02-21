`ifndef _OPCODE_MAP_
`define _OPCODE_MAP_

`include "MacroUtils.sv"
`include "DecoderTypes.sv"

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

/* Use _ to represent an empty mode */

`MAP_BEGIN(opcode_map1)

	`M(01, add, Ev_Gv)
	`M(03, add, Gv_Ev)
	`M(05, add, rAX_Iz)
	`M(09, or,  Gv_Ev)
	`M(0B, or,  Ev_Gv)
	`M(0D, or,  rAX_Iz)

	`M(11, adc, Ev_Gv)
	`M(13, adc, Gv_Ev)
	`M(15, adc, rAX_Iz)
	`M(19, sbb, Gv_Ev)
	`M(1B, sbb, Gv_Ev)
	`M(1D, sbb, rAX_Iz)

	`M(21, and, Ev_Gv)
	`M(23, and, Gv_Ev)
	`M(25, and, rAX_Iz)
	`M(29, sub, Ev_Gv)
	`M(2B, sub, Gv_Ev)
	`M(2D, sub, rAX_Iz)

	`M(31, xor, Ev_Gv)
	`M(33, xor, Gv_Ev)
	`M(35, xor, rAX_Iz)
	`M(39, cmp, Ev_Gv)
	`M(3B, cmp, Gv_Ev)
	`M(3D, cmp, rAX_Iz)

	`M(50, push, rAX$r8)
	`M(51, push, rCX$r9)
	`M(52, push, rDX$r10)
	`M(53, push, rBX$r11)
	`M(54, push, rSP$r12)
	`M(55, push, rBP$r13)
	`M(56, push, rSI$r14)
	`M(57, push, rDI$r15)
	`M(58, pop, rAX$r8)
	`M(59, pop, rCX$r9)
	`M(5A, pop, rDX$r10)
	`M(5B, pop, rBX$r11)
	`M(5C, pop, rSP$r12)
	`M(5D, pop, rBP$r13)
	`M(5E, pop, rSI$r14)
	`M(5F, pop, rDI$r15)

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

	`G(C1, 2, Ev_Ib)
	`M(C3, retq, _)
	`G(C7, 11, Ev_Iz)

	`G(D1, 2, Ev_1)
	`G(D3, 2, Ev_CL)

	`G(F7, 3, Ev)
	`G(FF, 5, _)

`MAP_END

`MAP_BEGIN(opcode_map2)
	`M(05, syscall, _)
`MAP_END

`MAP_BEGIN(opcode_map3)
`MAP_END

`MAP_BEGIN(opcode_map4)
`MAP_END

`undef M
`undef G
`undef MAP_BEGIN
`undef MAP_END

`define GMC(g, t, n, m, c) {24'h``c, 5'h``g, 8'b``t}: begin res.name = "n"; res.mode = "m"; end
`define GM(g, t, n, m) `GMC(g, t, n, m, ?)

function automatic opcode_struct_t opcode_group_map(logic [0:3*8-1] opcode, logic[4:0] group, logic[7:0] key);
	opcode_struct_t res = 0;
	casez ({opcode, group, key})

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

	`GMC(3, ??000???, test, Ev_Iz, F7)
	`GM(3, ??010???, not, _)
	`GM(3, ??011???, neg, _)
	`GMC(3, ??100???, mul, Ev_rAX, F7)
	`GMC(3, ??101???, imul, Ev_rAX, F7)
	`GMC(3, ??110???, div, Ev_rAX, F7)
	`GMC(3, ??111???, idiv, Ev_rAX, F7)

	`GM(5, ??000???, inc, Ev)
	`GM(5, ??001???, dec, Ev)
	`GM(5, ??010???, call, Ev)
	`GM(5, ??011???, call, Ep)
	`GM(5, ??100???, jmp, Ev)
	`GM(5, ??101???, jmp, Mp)
	`GM(5, ??110???, push, Ev)

	`GMC(11, ??000???, mov, EV_Iz, C7)

	endcase
	return res;
endfunction

`undef GMC
`undef GM

/* op_struct.name will be zero when something goes wrong */
/* returns the number of bytes in opcode, excluding ModRM, even if it's used */
function automatic logic[3:0] fill_opcode_struct(logic[0:4*8-1] op_bytes, output opcode_struct_t op_struct);

	logic[3:0] idx = 0;
	logic[7:0] modrm = 0;
	`LINTOFF_UNUSED(opcode_struct_t tmp = 0);

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
		tmp = opcode_group_map(op_struct.opcode, op_struct.group, modrm);
		op_struct.name = tmp.name;
		/* group-map mode overrides opcode-map mode */
		if (tmp.mode != "_") begin
			op_struct.mode = tmp.mode;
		end
	end

	return idx;
endfunction

`endif /* _OPCODE_MAP_ */
