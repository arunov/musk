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
	`M(01, add, EvGv)
	`M(03, add, GvEv)
	`M(09, or,  GvEv)
	`M(0B, or,  EvGv)
	`M(11, adc, EvGv)
	`M(13, adc, GvEv)
	`M(19, sbb, GvEv)
	`M(1B, sbb, GvEv)
	//`M(20, and, EvGv) // Actually EbGb
	`M(21, and, EvGv)
	`M(23, and, GvEv)
	`M(29, sub, EvGv)
	`M(2B, sub, GvEv)
	`M(31, xor, EvGv)
	`M(33, xor, GvEv)
	`M(39, cmp, EvGv)
	`M(3B, cmp, GvEv)
	//`M(65, gs, _) // Instruction prefix 0x65 SEG=GS
	//`M(6C, insb, YbDX)
	//`M(6F, outsl, DXXz)
	`M(5e, pop, rSI_r14)
	`M(85, test, EvGv)
	`M(89, mov, EvGv)
	`M(8B, cmp, GvEv)
	`G(81, 1, EvIz)
	`G(83, 1, EvIb)
	`M(C3, retq, _)
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

`define GM(g, t, n, m) {5'h``g, 8'b``t}: begin res.name = "n"; res.mode = "m"; end

function automatic opcode_struct_t opcode_group_map(logic[4:0] group, logic[7:0] key);
	opcode_struct_t res = 0;
	casez ({group, key})

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
	//`GM(2, ??110???, , _)
	`GM(2, ??111???, sar, _)

	endcase
	return res;
endfunction

`undef GM

/* op_struct.name will be zero when something goes wrong */
function automatic logic[3:0] fill_opcode_struct(logic[0:4*8-1] op_bytes, output opcode_struct_t op_struct);

	logic[3:0] cnt = 0;
	`LINTOFF_UNUSED(opcode_struct_t tmp = 0);

	if (`get_byte(op_bytes, 0) == 'h0F) begin
		if (`get_byte(op_bytes, 1) == 'h3A) begin
			op_struct = opcode_map4(`get_byte(op_bytes, 2));
			`eget_bytes(op_struct.opcode, 0, 3) = `eget_bytes(op_bytes, 0, 3);
			cnt = 3;
		end else if (`get_byte(op_bytes, 1) == 'h38) begin
			op_struct = opcode_map3(`get_byte(op_bytes, 2));
			`eget_bytes(op_struct.opcode, 0, 3) = `eget_bytes(op_bytes, 0, 3);
			cnt = 3;
		end else begin
			op_struct = opcode_map2(`get_byte(op_bytes, 1));
			`eget_bytes(op_struct.opcode, 1, 3) = `eget_bytes(op_bytes, 0, 2);
			cnt = 2;
		end
	end else begin
		op_struct = opcode_map1(`get_byte(op_bytes, 0));
		`eget_bytes(op_struct.opcode, 2, 3) = `eget_bytes(op_bytes, 0, 1);
		cnt = 1;
	end

	if (op_struct.group != 0) begin
		cnt++;
		tmp = opcode_group_map(op_struct.group, `get_byte(op_bytes, 3));
		op_struct.name = tmp.name;
		if (op_struct.mode == "_") begin
			op_struct.mode = tmp.mode;
		end
	end

	return cnt;
endfunction

`endif /* _OPCODE_MAP_ */
