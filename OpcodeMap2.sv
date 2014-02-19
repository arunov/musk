`ifndef _OPCODE_MAP2_
`define _OPCODE_MAP2_

`include "DecoderTypes.sv"

`define M(c, n, m) map['h``c].name = "n"; map['h``c].mode = "m";

function automatic opcode_struct_t opcode_map2(logic[7:0] key);

	opcode_struct_t[0:255] map = 0;

	return map[key];

endfunction

`undef M

`endif /* _OPCODE_MAP2_ */