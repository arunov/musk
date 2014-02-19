`ifndef _OPCODE_MAP1_
`define _OPCODE_MAP1_

`include "DecoderTypes.sv"

`define M(c, n, m) map['h``c].name = "n"; map['h``c].mode = "m";

function automatic opcode_struct_t opcode_map1(logic[0:7] key);

	opcode_struct_t[0:255] map = 0;

	`M(01, add, EvGv)
	`M(03, add, GvEv)
	`M(09, or,  GvEv)
	`M(0B, or,  EvGv)
	`M(11, adc, EvGv)
	`M(13, adc, GvEv)
	`M(19, sbb, GvEv)
	`M(1B, sbb, GvEv)
	`M(21, and, EvGv)
	`M(23, and, GvEv)
	`M(29, sub, EvGv)
	`M(2B, sub, GvEv)
	`M(31, xor, EvGv)
	`M(33, xor, GvEv)
	`M(39, cmp, EvGv)
	`M(3B, cmp, GvEv)
	`M(85, test, EvGv)
	`M(89, mov, EvGv)
	`M(8B, cmp, GvEv)

	return map[key];

endfunction

`undef M

`endif /* _OPCODE_MAP1_ */
