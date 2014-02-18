
`include "MacroUtils.sv"

`define DFUN(x) function automatic logic[3:0] x(`LINTOFF(UNUSED) logic[0:7] rex, logic[0:7] mod, logic[0:7] sib, logic[0:31] disp, logic[0:31] imm `LINTON(UNUSED));
`define ENDDFUN endfunction

`DFUN(EvGv)
	return 1;
`ENDDFUN

`DFUN(GvEv)
	return 1;
`ENDDFUN

`undef DFUN
`undef ENDDFUN

`define D(x) "x": cnt = x(ins.rex_prefix, opd_bytes[0:7], opd_bytes[8:15], opd_bytes[16:47], opd_bytes[48:79]);

function automatic logic[3:0] decode_operands(`LINTOFF_UNUSED(fat_instruction_t ins), logic[0:10*8-1] opd_bytes);
	
	logic[3:0] cnt = 0;

	case (ins.opcode_struct.mode)
		`D(EvGv)
		`D(GvEv)
		default: cnt = 11; // 11 means error
	endcase

	return cnt;
endfunction

`undef D
