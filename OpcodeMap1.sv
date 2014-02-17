
`define M(c, n, m) map['h``c].name = "n"; map['h``c].mode = "m";

function opcode_struct_t opcode_map1(logic[0:7] key);

	opcode_struct_t[0:255] map = 0;

	`M(01, add, Ev_Gv_)
	`M(03, add, Gv_Ev_)

	return map[key];

endfunction

`undef M
