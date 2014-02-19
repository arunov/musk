`ifndef _OPERAND_DECODER_ 
`define _OPERAND_DECODER_

`include "MacroUtils.sv"
`include "DecoderTypes.sv"

typedef logic[0:4*8-1] reg_name_t;

function automatic reg_name_t general_register_names(logic[3:0] index);

	reg_name_t[0:15] map = 0;

	map[0] = "%rax";
	map[1] = "%rcx";
	map[2] = "%rdx";
	map[3] = "%rbx";
	map[4] = "%rsp";
	map[5] = "%rbp";
	map[6] = "%rsi";
	map[7] = "%rdi";
	map[8] = "%r8";
	map[9] = "%r9";
	map[10] = "%r10";
	map[11] = "%r11";
	map[12] = "%r12";
	map[13] = "%r13";
	map[14] = "%r14";
	map[15] = "%r15";

	return map[index];
endfunction

`define DFUN(x) function automatic logic[15:0] x(`LINTOFF(UNUSED) logic[7:0] rex, logic[0:10*8-1] opd_bytes `LINTON(UNUSED));
`define ENDDFUN endfunction
`define CALL_DFUN(x) (x(rex, opd_bytes))

`DFUN(handleEv)
	case (mod[0:1])
		2'b00:
			$display("indirect");
		2'b01:
			$display("indirect + disp 8");
		2'b10:
			$display("indirect + disp 32");
		2'b11:
			$display("reg");
	endcase
	return 0;//todo:
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

`define D(x) "x": cnt = x(ins.rex_prefix, opd_bytes);

/* If there is error, some value greater than 10 is returned. Otherwise, the number of bytes consumed is returned. */
function automatic logic[3:0] decode_operands(`LINTOFF_UNUSED(fat_instruction_t ins), logic[0:10*8-1] opd_bytes);
	
	logic[15:0] cnt = 0;

	$write("%s\t", ins.opcode_struct.name);

	case (ins.opcode_struct.mode)
		`D(EvGv)
		`D(GvEv)
		default: cnt = 11; // >10 means error
	endcase

	if (cnt > 10) begin
		return 11;
	end else begin
		return cnt[3:0];
	end

endfunction

`undef D

`endif /* _OPERAND_DECODER_ */
