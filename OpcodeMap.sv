`ifndef _OPCODE_MAP_
`define _OPCODE_MAP_

`include "MacroUtils.sv"
`include "DecoderTypes.sv"

`define QM(c, n, m) map['h``c].name = n; map['h``c].mode = m;
`define M(c, n, m) map['h``c].name = "n"; map['h``c].mode = "m";

function automatic opcode_struct_t opcode_map1(logic[7:0] key);

	opcode_struct_t[0:255] map = 0;

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
	`M(5e, pop, rSIr14)
	`M(85, test, EvGv)
	`M(89, mov, EvGv)
	`M(8B, cmp, GvEv)

	`M(81, and, EvIz)
	`M(83, and, EvIb)

	`M(C3, retq, _)

	return map[key];

endfunction

function automatic opcode_struct_t opcode_map2(logic[7:0] key);

	opcode_struct_t[0:255] map = 0;

	`M(05, syscall, _)

	return map[key];

endfunction


function automatic opcode_struct_t opcode_map3(logic[7:0] key);

	opcode_struct_t[0:255] map = 0;

	return map[key];

endfunction


function automatic opcode_struct_t opcode_map4(logic[7:0] key);

	opcode_struct_t[0:255] map = 0;

	return map[key];

endfunction

`undef M
`undef QM

function automatic logic[3:0] fill_opcode_struct(logic[0:3*8-1] op_bytes, output opcode_struct_t op_struct);
	if (`get_byte(op_bytes, 0) == 'h0F) begin
		if (`get_byte(op_bytes, 1) == 'h3A) begin
			op_struct = opcode_map4(`get_byte(op_bytes, 2));
			`eget_bytes(op_struct.opcode, 0, 3) = `eget_bytes(op_bytes, 0, 3);
			return 3;
		end else if (`get_byte(op_bytes, 1) == 'h38) begin
			op_struct = opcode_map3(`get_byte(op_bytes, 2));
			`eget_bytes(op_struct.opcode, 0, 3) = `eget_bytes(op_bytes, 0, 3);
			return 3;
		end else begin
			op_struct = opcode_map2(`get_byte(op_bytes, 1));
			`eget_bytes(op_struct.opcode, 1, 3) = `eget_bytes(op_bytes, 0, 2);
			return 2;
		end
	end else begin
		op_struct = opcode_map1(`get_byte(op_bytes, 0));
		`eget_bytes(op_struct.opcode, 2, 3) = `eget_bytes(op_bytes, 0, 1);
		return 1;
	end
endfunction

`endif /* _OPCODE_MAP_ */
