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

typedef logic[15:0] DFUN_RET_TYPE; 

/* A DFUN returns the number of bytes consumed, EXCLUDING ModRM. Or some value greater than 10 for error */
`define DFUN(x) \
function automatic DFUN_RET_TYPE x(`LINTOFF(UNUSED) fat_instruction_t ins, logic[7:0] modrm, logic[3:0] index, logic[0:10*8-1] opd_bytes `LINTON(UNUSED));

`define ENDDFUN endfunction

`define CALL_DFUN(x) (x(ins, modrm, index, opd_bytes))

`define COMBO_1_DFUNS(x) \
`DFUN(x) \
	return `CALL_DFUN(handle``x); \
`ENDDFUN

`define COMBO_2_DFUNS(x, y) \
`DFUN(x``_``y) \
	DFUN_RET_TYPE cnt = `CALL_DFUN(handle``x); \
	if (cnt > 10) begin return 11; end \
	index += cnt; \
	$write(", "); \
	return cnt + `CALL_DFUN(handle``y); \
`ENDDFUN

`define DFUNR1$R2(reg_def, reg_def_print, reg_alt, reg_alt_print) \
`DFUN(handle``reg_def``$``reg_alt) \
	if(ins.rex_prefix == 0 || ins.rex_prefix[0] == 0) begin \
		$write(reg_def_print); \
	end else if(ins.rex_prefix[0] == 1) begin \
		$write(reg_alt_print); \
	end \
	return 0; \
`ENDDFUN \
\
`COMBO_1_DFUNS(reg_def``$``reg_alt) \
`COMBO_2_DFUNS(reg_def``$``reg_alt, Iv)

/* operand handling utilities */
`define resolve_index(sindex, content)\
	if(sindex != 3'b100) begin\
		$write(content, general_register_names({ins.rex_prefix[1],sindex})); \
	end

`define resolve_base(base, count) \
	if(base == 3'b101 && modrm[7:6] == 2'b00) begin\
		print_abs(index+1, opd_bytes, 32); \
		count += 4;\
	end \
	else $write("(%s)", general_register_names({ins.rex_prefix[1],base}));

`DFUN(resolve_sib)
	/*TODO: TEST properly*/
	logic[7:0] sib = `pget_bytes(opd_bytes, index, 1);
	logic[1:0] scale = sib[1:0];
	logic[2:0] sindex = sib[4:2];
	logic[2:0] base = sib[7:5];
	DFUN_RET_TYPE count = 0;
	unique case(scale)
		2'b00:begin `resolve_index(sindex, "(%s)") end
		2'b01:begin `resolve_index(sindex, "(%s*2)") end
		2'b10:begin `resolve_index(sindex, "(%s*4)") end
		2'b11:begin `resolve_index(sindex, "(%s*8)") end
	endcase
	//base can have disp_32 when base=101 and mod=0, disp count should be accounted
	`resolve_base(base,count)
	//count increment 1 for SIB itself
	return count + 1; 
`ENDDFUN

`undef resolve_index
`undef resolve_base

/*
`DFUN(resolve_disp_32)
	//SIP relative addressing
	print_abs(1, opd_bytes, 32);
	$write("(%%rip)");
	return 4; //todo: the interface is wrong
`ENDDFUN
*/

`define SIGN(x) (x<0? "-": "$")
`define UHEX(x) (x<0? -x: x)

/* Reverses bytes from val and stores it in rval */
`define reverse_bytes(val, rval, num_bytes) \
	for(int i=0; i<num_bytes; i++) begin \
		rval[i*8+:8] = val[((num_bytes-i)*8-1)-:8]; \
	end

/* used for printing both displacmenet and immediate operands*/
/* verilator lint_off width */
function automatic void print_abs(logic[3:0] index, logic[0:10*8-1]  opd_bytes, logic[0:5] num_bits );
	logic[63:0] disp = `pget_bytes(opd_bytes, index, 8);
	logic signed[7:0] disp_8;
	logic signed[15:0] disp_16;
	logic signed[15:0] rdisp_16;
	logic signed[31:0] disp_32;
	logic signed[31:0] rdisp_32;
	logic signed[63:0] disp_64;
	logic signed[63:0] rdisp_64;
	logic signed[63:0] b_disp;
	//todo:at present implements -ve notation, sign extend?
	unique case(num_bits)
		 8: begin
			disp_8 = disp[63:63-8+1];
			b_disp = disp_8;
			end	
		16: begin
			disp_16 = disp[63:63-16+1];
			/* bytes read from opd_bytes stream is in reverse order */
			`reverse_bytes(disp_16, rdisp_16, 2);
			b_disp = rdisp_16;
			end
		32: begin
			disp_32 = disp[63:63-32+1];
			`reverse_bytes(disp_32, rdisp_32, 4);
			b_disp = rdisp_32;
			end	
		64: begin
			disp_64 = disp[63:0];
			`reverse_bytes(disp_64, rdisp_64, 8);
			b_disp = rdisp_64;
			end	
	endcase
	$write("%s0x%0x",`SIGN(b_disp), `UHEX(b_disp));
endfunction
/* verilator lint_off width *///todo:

`DFUN(handleEv)

	logic rex_b = ins.rex_prefix[0];
	logic[1:0] mod = modrm[7:6];
	logic[2:0] rm = modrm[2:0];
	DFUN_RET_TYPE num = 16'h0;

	unique case (mod)
		2'b00:
			unique case (rm)
				3'b100: num += `CALL_DFUN(resolve_sib);
				3'b101: begin 
						print_abs(index, opd_bytes, 32);
						num += 4;
					end
				default:begin
						$write("(%s) ", general_register_names({rex_b, rm}));
					end
			endcase	
		2'b01:
			unique case (rm)
				3'b100: begin //Has SIB
						num += `CALL_DFUN(resolve_sib);
						//num -> SIB + 1 for modrm byte
						//Donot print displacemnt if already printed by SIB TODO
						if(num == 1) print_abs(index + 1, opd_bytes, 8);
					end
				default:begin //No SIB
						print_abs(index, opd_bytes, 8);
						$write("(%s) ",general_register_names({rex_b, rm}));
						num += 1;//8 bit displacement 
					end
			endcase
		2'b10:
			unique case (rm)
				3'b100: begin //Has SIB
						num += `CALL_DFUN(resolve_sib);
						if(num == 1) print_abs(index + 1, opd_bytes, 32);//todo: what if sib already printed the displacemnt
						end
				default:begin //No SIB
						print_abs(index, opd_bytes, 32);
						$write("(%s)",general_register_names({rex_b, rm}));
						num += 4; //32 bit displacemnt
						end
			endcase
		2'b11:
			$write("%s",general_register_names({rex_b, rm}));
	endcase
	return num;
`ENDDFUN

`DFUN(handleGv)
	// Assumption: Gv uses only MODRM.reg
	$write("%s", general_register_names({ins.rex_prefix[2], modrm[5:3]}));
	return 0;
`ENDDFUN

/*  We might not need index in DFUn */

`DFUN(handleIb)
	print_abs(index, opd_bytes, 8);
	return 1; //1 byte
`ENDDFUN

`DFUN(handleIz)
	//z- rex_w = 1 => 32 bit, otherwise 16
	logic[5:0] operand_size;
	bit rex_w = ins.rex_prefix[3];
	
	if(rex_w == 1'b1) operand_size = 32;
	else begin//operand size determined by CS.D??
		if(ins.operand_size_prefix == 0) operand_size = 32; //no override
		else operand_size = 16;
	end
	
	print_abs(index, opd_bytes, operand_size);
	return operand_size/5'h8;
`ENDDFUN

`DFUN(handleIv)
	//z- rex_w = 1 => 64 bit, otherwise 16/32
	logic[5:0] operand_size;
	logic rex_w = ins.rex_prefix[3];
	
	if(rex_w == 1'b1) begin operand_size = 6'd64; end
	else begin//operand size determined by CS.D??
		if(ins.operand_size_prefix == 0) operand_size = 6'd32; //no override
		else operand_size = 6'd16;
	end

	print_abs(index, opd_bytes, operand_size);
	return operand_size/5'h8;
`ENDDFUN

`DFUN(handleM)
	if (modrm[7:6] == 2'b11) begin
		return 11;
	end
	return `CALL_DFUN(handleEv);
`ENDDFUN

/*
`DFUN(handleEp)
	// (No) - Instruction prefix - REX.W - Effective operand size - pointer size
	// -------------------------------------------------------------------------
	// (1)  - don't care         - 1     - 64                     - 80
	// (2)  - no 66h             - 0     - 32                     - 48
	// (3)  - yes 66h            - 0     - 16                     - 32
`ENDDFUN

`DFUN(handleYb)
	$write("%%es:(%%rdi)");
	return 0;
`ENDDFUN

`DFUN(handleDX)
	$write("(%%dx)");
	return 0;
`ENDDFUN

`DFUN(handleXz)
	$write("(%%ds:(%%rsi))");
	return 0;
`ENDDFUN
*/


/* R1$R2 handlers and entry points */

`DFUNR1$R2(rAX, "%%rax", r8,  "%%r8" )
`DFUNR1$R2(rCX, "%%rcx", r9,  "%%r9" )
`DFUNR1$R2(rDX, "%%rdx", r10, "%%r10")
`DFUNR1$R2(rBX, "%%rbx", r11, "%%r11")
`DFUNR1$R2(rSP, "%%rsp", r12, "%%r12")
`DFUNR1$R2(rBP, "%%rbp", r13, "%%r13")
`DFUNR1$R2(rSI, "%%rsi", r14, "%%r14")
`DFUNR1$R2(rDI, "%%rdi", r15, "%%r15")


/* operand handling entry points */

`COMBO_1_DFUNS(Ev)
`COMBO_2_DFUNS(Ev, Gv)
`COMBO_2_DFUNS(Ev, Iv)
`COMBO_2_DFUNS(Ev, Ib)
`COMBO_2_DFUNS(Ev, Iz)

`COMBO_2_DFUNS(Gv, Ev)
`COMBO_2_DFUNS(Gv, M)


`DFUN(Jz)
	$write("%%rip:");
	return `CALL_DFUN(handleIz);
`ENDDFUN

`DFUN(Jb)
	$write("%%rip:");
	return `CALL_DFUN(handleIb);
`ENDDFUN

`DFUN(_)
	return 0;
`ENDDFUN

`undef DFUN
`undef ENDDFUN
`undef CALL_DFUN
`undef COMBO_1_DFUNS
`undef COMBO_2_DFUNS
`undef DFUNR1$R2

`define FULLD(x, x_str, mm) x_str: \
begin \
	ins.operands_use_modrm=(mm); \
	if (mm) begin modrm = `get_byte(opd_bytes, 0); index++; end \
	cnt = (mm) + x(ins, modrm, index, opd_bytes); \
end

`define D(x, mm) `FULLD(x, "x", mm)

`define DRR(r) \
	`FULLD(r, "r", 0) \
	`FULLD(r``_Iv, {"r","_Iv"}, 0)

/* If there is error, some value greater than 10 is returned. Otherwise, the number of bytes consumed is returned. */
function automatic logic[3:0] decode_operands(inout `LINTOFF_UNUSED(fat_instruction_t ins), input logic[0:10*8-1] opd_bytes);
	
	logic[15:0] cnt = 0;
	logic[7:0] modrm = 0;
	logic[3:0] index = 0;

	$write("%s  \t", ins.opcode_struct.name);

	case (ins.opcode_struct.mode)
		/* R$R cases */
		`DRR(rAX$r8)
		`DRR(rCX$r9)
		`DRR(rDX$r10)
		`DRR(rBX$r11)
		`DRR(rSP$r12)
		`DRR(rBP$r13)
		`DRR(rSI$r14)
		`DRR(rDI$r15)
		/* other cases */
		`D(Ev, 1)
		`D(Ev_Gv, 1)
		`D(Ev_Ib, 1)
		`D(Ev_Iz, 1)
		`D(Gv_Ev, 1)
		`D(Gv_M, 1)
		`D(Jz, 0)
		`D(Jb, 0)
		`D(_, 0)
		default: cnt = 11; // >10 means error
	endcase

	if (cnt > 10) begin
		return 11;
	end else begin
		return cnt[3:0];
	end

endfunction

`undef FULLD
`undef D
`undef DRR

`endif /* _OPERAND_DECODER_ */
