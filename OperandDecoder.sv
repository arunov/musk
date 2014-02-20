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

`define DFUN(x) function automatic logic[15:0] x(`LINTOFF(UNUSED) fat_instruction_t ins, logic[3:0] index, logic[0:10*8-1] opd_bytes `LINTON(UNUSED));
`define ENDDFUN endfunction
`define CALL_DFUN(x) (x(ins, index, opd_bytes))

/* operand handling utilities */

`DFUN(resolve_sib)
	$write("SIB");
	return 2; //todo: the interface is wrong
`ENDDFUN

`DFUN(resolve_disp_32)
	//$write("%x ",disp);
	return 0; //todo: the interface is wrong
`ENDDFUN

/* verilator lint_off UNDRIVEN */
function automatic print_displacement(logic[0:3] index, logic[0:10*8-1]  opd_bytes, logic[0:5] num_bits `LINTON(UNUSED));
	logic[0:31] disp = `pget_bytes(opd_bytes, index, 4);
	disp >>= 32-num_bits;
	$write("%0h ", disp);
endfunction

`DFUN(handleEv)
	//bit rex_r = rex[2];
	bit rex_b = ins.rex_prefix[0];
	logic[15:0] num = 16'h0;
	unique case (opd_bytes[0:1])
		2'b00:
			unique case (opd_bytes[5:7])
				3'b100: num += `CALL_DFUN(resolve_sib);
				3'b101: num += `CALL_DFUN(resolve_disp_32);
				default:begin
						num += 2;
						$write("[%s] ",general_register_names({rex_b, opd_bytes[5:7]}));
						end
			endcase	
		2'b01:
			unique case (opd_bytes[5:7])
				3'b100: begin //Has SIB
						num += `CALL_DFUN(resolve_sib);
						$write(" + ");
						print_displacement(2, opd_bytes, 8);//todo:3'b???
						end
				default:begin //No SIB
						$write("[%s] + ",general_register_names({rex_b, opd_bytes[5:7]}));
						print_displacement(1, opd_bytes, 8);
						end
			endcase
		2'b10:
			$display("indirect + disp 32");
		2'b11:
			$write("%s ",general_register_names({rex_b, opd_bytes[5:7]}));
	endcase
	return num;
`ENDDFUN

`DFUN(handleGv)
	// Assumption: Gv uses only MODRM.reg
	$write("%s ", general_register_names({ins.rex_prefix[2], opd_bytes[2:4]}));
	return 0;
`ENDDFUN

/*  We might not need index in DFUn */

function automatic print_immediate(logic[0:3] index,  logic[0:10*8-1]  opd_bytes, logic[0:5] num_bits /* verilator lint_off UNDRIVEN */ `LINTON(UNUSED));
	logic[31:0] disp = `pget_bytes(opd_bytes, index, 4);
	$write("%0x ", disp >> (32-num_bits));
endfunction

`DFUN(handleIb)
	print_immediate(index, opd_bytes, 8);
	return 1; //1 byte
`ENDDFUN

`DFUN(handleIz)
	print_immediate(index, opd_bytes, 32);
	return 4;//4 bytes
`ENDDFUN

/*
`DFUN(handleYb)
	$write("%%es:(%%rdi) ");
	return 0;
`ENDDFUN

`DFUN(handleDX)
	$write("(%%dx) ");
	return 0;
`ENDDFUN

`DFUN(handleXz)
	$write("(%%ds:(%%rsi)) ");
	return 0;
`ENDDFUN
*/

/* operand handling entry points */

`DFUN(EvGv)
	return 1 + `CALL_DFUN(handleEv) + `CALL_DFUN(handleGv);
`ENDDFUN

`DFUN(EvIb)
	logic[15:0] count = `CALL_DFUN(handleEv);
	logic[0:3] index;
	count += 1;//1 byte for the code
	//todo:exit
	index = count[3:0]; //immediate comes after all the previous decoded bytes
	count += `CALL_DFUN(handleIb);
	return count;
`ENDDFUN

`DFUN(EvIz)
	logic[15:0] count = `CALL_DFUN(handleEv);
	logic[3:0] index = count[3:0]; //Handle Iz
	//todo:error check and exit
	count += `CALL_DFUN(handleIz);
	return count + 1; //1 for the opcode 
`ENDDFUN

`DFUN(GvEv)
	return 1 + `CALL_DFUN(handleGv) + `CALL_DFUN(handleEv);
`ENDDFUN

`DFUN(rSIr14)
	//if
	return 1;
`ENDDFUN

/*
`DFUN(YbDX)
	return 0 + `CALL_DFUN(handleYb) + `CALL_DFUN(handleDX);
`ENDDFUN

`DFUN(DXXz)
	return 0 + `CALL_DFUN(handleDX) + `CALL_DFUN(handleXz);
`ENDDFUN
*/

`DFUN(_)
	return 0;
`ENDDFUN

`undef DFUN
`undef ENDDFUN
`undef CALL_DFUN

`define D(x) "x": cnt = x(ins, 0, opd_bytes);

/* If there is error, some value greater than 10 is returned. Otherwise, the number of bytes consumed is returned. */
function automatic logic[3:0] decode_operands(`LINTOFF_UNUSED(fat_instruction_t ins), logic[0:10*8-1] opd_bytes);
	
	logic[15:0] cnt = 0;
	$write("%s\t", ins.opcode_struct.name);

	case (ins.opcode_struct.mode)
		`D(EvGv)
		`D(GvEv)
		`D(EvIb)
		`D(EvIz)
		`D(rSIr14)
		`D(_)
		//`D(YbDX)
		//`D(DXXz)
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
