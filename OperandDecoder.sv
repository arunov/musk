`ifndef _OPERAND_DECODER_ 
`define _OPERAND_DECODER_

`include "MacroUtils.sv"
`include "DecoderTypes.sv"

`define DFUN(x) function automatic logic[4:0] x(`LINTOFF(UNUSED) logic[0:7] rex, logic[0:7] mod, logic[0:7] sib, logic[0:31] disp, logic[0:31] imm `LINTON(UNUSED));
`define ENDDFUN endfunction
`define CALL_DFUN(x) (x(rex, mod, sib, disp, imm))

`DFUN(handleEv)
	return 1;
`ENDDFUN

`DFUN(handleGv)
	return 0;
`ENDDFUN

`DFUN(EvGv)
	return 1 + `CALL_DFUN(handleEv) + `CALL_DFUN(handleGv);
`ENDDFUN

`DFUN(GvEv)
	return 1 + `CALL_DFUN(handleGv) + `CALL_DFUN(handleEv);
`ENDDFUN

`undef DFUN
`undef ENDDFUN
`undef CALL_DFUN

`define D(x) "x": cnt = x(ins.rex_prefix, opd_bytes[0:7], opd_bytes[8:15], opd_bytes[16:47], opd_bytes[48:79]);

function automatic logic[3:0] decode_operands(`LINTOFF_UNUSED(fat_instruction_t ins), logic[0:10*8-1] opd_bytes);
	
	`LINTOFF_UNUSED(logic[4:0] cnt = 0;)

	$write("%s\t", ins.opcode_struct.name);

	case (ins.opcode_struct.mode)
		`D(EvGv)
		`D(GvEv)
		default: cnt = 11; // >10 means error
	endcase

	return cnt[3:0];
endfunction

`undef D

`endif /* _OPERAND_DECODER_ */
