`ifndef _OPCODE_MAP4_
`define _OPCODE_MAP4_

`include "DecoderTypes.sv"

`define M(c, n, m) map['h``c].name = "n"; map['h``c].mode = "m";

function automatic opcode_struct_t opcode_map4(logic[0:7] key);

	opcode_struct_t[0:255] map = 0;

	return map[key];

endfunction

`undef M

`endif /* _OPCODE_MAP4_ */
