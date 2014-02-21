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

`define DFUN_RET_TYPE logic[15:0]
`define DFUN(x) function automatic `DFUN_RET_TYPE x(`LINTOFF(UNUSED) fat_instruction_t ins, logic[3:0] index, logic[0:10*8-1] opd_bytes `LINTON(UNUSED));
`define ENDDFUN endfunction
`define CALL_DFUN(x) (x(ins, index, opd_bytes))

`define DFUNR1$R2(reg_def, reg_def_print, reg_alt, reg_alt_print) `DFUN(reg_def``$``reg_alt) \
	if(ins.rex_prefix == 0 || ins.rex_prefix[0] == 0) begin \
		$write(reg_def_print); \
	end else if(ins.rex_prefix[0] == 1) begin \
		$write(reg_alt_print); \
	end \
	return 0; \
`ENDDFUN

/* operand handling utilities */

`define resolve_index(sindex, content)\
				if(sindex != 3'b100) begin\
					$write(content, general_register_names({ins.rex_prefix[1],sindex})); \
				end

`define resolve_base(base, count) \
		if(base == 3'b101 && opd_bytes[0:1] == 2'b00) begin\
			print_abs(index+1, opd_bytes, 32); \
			count += 32/8;\
		end \
		else $write("(%s)", general_register_names({ins.rex_prefix[1],base}));

`DFUN(resolve_sib)
	/*TODO: TEST properly*/
	logic[7:0] sib = `pget_bytes(opd_bytes, index, 1);
	logic[1:0] scale = sib[1:0];
	logic[2:0] sindex = sib[4:2];
	logic[2:0] base = sib[7:5];
	`DFUN_RET_TYPE count = 0;
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

`DFUN(resolve_disp_32)
	//$write("%x ",disp);
	return 0; //todo: the interface is wrong
`ENDDFUN

`define SIGN(x) (x<0? "-": "")
`define UHEX(x) (x<0? -x: x)

/* Used for printing both displacmenet and immediate operands*/
/* verilator lint_off UNDRIVEN */
/* verilator lint_off UNSIGNED */
/* verilator lint_off WIDTH */
function automatic print_abs(logic[0:3] index, logic[0:10*8-1]  opd_bytes, logic[0:5] num_bits `LINTON(UNUSED));
	logic[63:0] disp = `pget_bytes(opd_bytes, index, 8);
	logic signed[7:0] disp_8;
	logic signed[15:0] disp_16;
	logic signed[31:0] disp_32;
	logic signed[63:0] disp_64;
	logic signed[63:0] b_disp;
	//TODO:At present implements -ve notation, sign extend?
	unique case(num_bits)
		8:begin
			disp_8 = disp[63:63-8+1];
			b_disp = disp_8;
			end	
		16: begin
			disp_16 = disp[63:63-16+1];
			b_disp = disp_16;
			end
		32: begin
			disp_32 = disp[63:63-32+1];
			b_disp = disp_32;
			end	
		64: begin
			disp_64 = disp[63:0];
			b_disp = disp_64;
			end	
	endcase
	//$write("%0x ",b_disp);
	$write("%s0x%0x",`SIGN(b_disp), `UHEX(b_disp));
endfunction

`DFUN(handleEv)
	//bit rex_r = rex[2];
	bit rex_b = ins.rex_prefix[0];
	`DFUN_RET_TYPE num = 16'h0;
	unique case (opd_bytes[0:1])
		2'b00:
			unique case (opd_bytes[5:7])
				3'b100: num += `CALL_DFUN(resolve_sib);
				3'b101: num += `CALL_DFUN(resolve_disp_32);
				default:begin
						$write("(%s) ",general_register_names({rex_b, opd_bytes[5:7]}));
						end
			endcase	
		2'b01:
			unique case (opd_bytes[5:7])
				3'b100: begin //Has SIB
						num += `CALL_DFUN(resolve_sib);
						//num -> SIB + 1 for modrm byte
						//Donot print displacemnt if already printed by SIB TODO
						if(num == 1) print_abs(num+1, opd_bytes, 8);
						end
				default:begin //No SIB
						print_abs(1, opd_bytes, 8);
						$write("(%s) ",general_register_names({rex_b, opd_bytes[5:7]}));
						num += 1;//8 bit displacement 
						end
			endcase
		2'b10:
			unique case (opd_bytes[5:7])
				3'b100: begin //Has SIB
						num += `CALL_DFUN(resolve_sib);
						if(num == 1) print_abs(num+1, opd_bytes, 32);//todo: what if sib already printed the displacemnt
						end
				default:begin //No SIB
						print_abs(1, opd_bytes, 32);
						$write("(%s)",general_register_names({rex_b, opd_bytes[5:7]}));
						num += 4; //32 bit displacemnt
						end
			endcase
		2'b11:
			$write("%s",general_register_names({rex_b, opd_bytes[5:7]}));
	endcase
	return num;
`ENDDFUN

`DFUN(handleGv)
	// Assumption: Gv uses only MODRM.reg
	$write("%s", general_register_names({ins.rex_prefix[2], opd_bytes[2:4]}));
	return 0;
`ENDDFUN

/*  We might not need index in DFUn */

`DFUN(handleIb)
	print_abs(index, opd_bytes, 8);
	return 1; //1 byte
`ENDDFUN

`DFUN(handleIz)
	//z- rex_w = 1 => 32 bit, otherwise 16
	bit rex_w = ins.rex_prefix[3];
	if(rex_w == 1'b1) begin
		print_abs(index, opd_bytes, 32);
		return 32/8;
		end
	else begin//operand size determined by CS.D??
		if(ins.operand_size_prefix == 0) begin//no override
			print_abs(index, opd_bytes, 32);
			return 32/8;
			end
		else begin
			print_abs(index, opd_bytes, 16);
			return 16/8;
			end
		end
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

/* operand handling entry points */
`DFUN(Ev)
	return 1 + `CALL_DFUN(handleEv);
`ENDDFUN

`DFUN(Ev_Gv)
	`DFUN_RET_TYPE cnt1, cnt2;
	cnt1 = `CALL_DFUN(handleEv);
	$write(", ");
	cnt2 = `CALL_DFUN(handleGv);
	return 1 + cnt1 + cnt2;
`ENDDFUN

`DFUN(Ev_Ib)
	`DFUN_RET_TYPE cnt1, cnt2;
	logic[3:0] index; 
	cnt1 = `CALL_DFUN(handleEv);
	$write(", ");
	index = cnt1[3:0] + 1; //immediate comes after all the previous decoded bytes
	cnt2 = `CALL_DFUN(handleIb);
	return 1 + cnt1 + cnt2;
`ENDDFUN

`DFUN(Ev_Iz)
	`DFUN_RET_TYPE cnt1, cnt2;
	logic[3:0] index; 
	cnt1 = `CALL_DFUN(handleEv);
	$write(", ");
	index = cnt1[3:0] + 1; //immediate comes after all the previous decoded bytes
	cnt2 = `CALL_DFUN(handleIz);
	return 1 + cnt1 + cnt2;
`ENDDFUN

`DFUN(Gv_Ev)
	`DFUN_RET_TYPE cnt1, cnt2;
	cnt1 = `CALL_DFUN(handleGv);
	$write(", ");
	cnt2 = `CALL_DFUN(handleEv);
	return 1 + cnt1 + cnt2;
`ENDDFUN

`DFUNR1$R2(rAX, "%%rax", r8,  "%%r8" )
`DFUNR1$R2(rBX, "%%rbx", r11, "%%r11")
`DFUNR1$R2(rCX, "%%rcx", r9,  "%%r9" )
`DFUNR1$R2(rDX, "%%rdx", r10, "%%r10")
`DFUNR1$R2(rSP, "%%rsp", r12, "%%r12")
`DFUNR1$R2(rBP, "%%rbp", r13, "%%r13")
`DFUNR1$R2(rSI, "%%rsi", r14, "%%r14")
`DFUNR1$R2(rDI, "%%rdi", r15, "%%r15")

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
`undef DFUN_RET_TYPE
`undef DFUNR1$R2

`define D(x) "x": cnt = x(ins, 0, opd_bytes);

/* If there is error, some value greater than 10 is returned. Otherwise, the number of bytes consumed is returned. */
function automatic logic[3:0] decode_operands(`LINTOFF_UNUSED(fat_instruction_t ins), logic[0:10*8-1] opd_bytes);
	
	logic[15:0] cnt = 0;
	$write("%s\t", ins.opcode_struct.name);

	case (ins.opcode_struct.mode)
		`D(Ev)
		`D(Ev_Gv)
		`D(Gv_Ev)
		`D(Ev_Ib)
		`D(Ev_Iz)
		`D(rSI$r14)
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
