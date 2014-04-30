
`include "MacroUtils.sv"
`include "PrintMacros.sv"

package OperandDecoder;

import DecoderTypes::*;
import RegMap::*;

`define COMBO_1_DFUNS(x)            \
`DFUN(x)                            \
    DFUN_RET_TYPE cnt;              \
	cnt = `CALL_DFUN(handle``x);    \
    ins.opa = opbuff;               \
    return cnt;                     \
`ENDDFUN

`define reset_opbuff() \
    opbuff = 0;

`define COMBO_2_DFUNS(x, y) \
`DFUN(x``_``y)                                                  \
    DFUN_RET_TYPE cnt;                                          \
	cnt = `CALL_DFUN(handle``x);                                \
    /* first operand values are stored in fat_ins structure */  \
    ins.opa = opbuff;                                           \
    `reset_opbuff();                                            \
	if (cnt > 10) begin return 11; end                          \
	index += cnt;                                               \
	`ins_write1(", ");                                               \
    cnt += `CALL_DFUN(handle``y);                               \
    /* Second operand values are stored in fat_ins structure */ \
    ins.opb = opbuff;                                           \
    return cnt;                                                 \
`ENDDFUN

`define DFUNR1$R2(reg_def, reg_def_print, reg_alt, reg_alt_print) \
`DFUN(handle``reg_def``$``reg_alt)                          \
	if(ins.rex_prefix == 0 || ins.rex_prefix[0] == 0) begin \
        `update_opbuff_reg(opbuff, get_reg_id("%reg_def"));                   \
		`ins_write1(reg_def_print);                              \
	end else if(ins.rex_prefix[0] == 1) begin               \
        `update_opbuff_reg(opbuff, get_reg_id("%reg_alt"));                   \
		`ins_write1(reg_alt_print);                              \
	end                                                     \
	return 0;                                               \
`ENDDFUN                                                    \
                                                            \
`COMBO_1_DFUNS(reg_def``$``reg_alt)                         \
`COMBO_2_DFUNS(reg_def``$``reg_alt, Iv)

`define DFUNR(regR, regR_print)                             \
`DFUN(handle``regR)                                         \
    `update_opbuff_reg(opbuff, get_reg_id("%regR"))                          \
	`ins_write1(regR_print);                                     \
`ENDDFUN

/* operand handling utilities */
`define resolve_index(sindex, content)                                      \
	if(sindex != 3'b100) begin                                              \
		`ins_write2(content, general_register_names({ins.rex_prefix[1],sindex})); \
	end

`define resolve_base(base, count)                           \
	if(base == 3'b101 && modrm[7:6] == 2'b00) begin         \
		print_abs(index+1, opd_bytes, 32);                  \
		count += 4;                                         \
	end                                                     \
	else `ins_write2("(%s)", general_register_names({ins.rex_prefix[1],base}));

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

/*
`DFUN(resolve_disp_32)
	//SIP relative addressing
	print_abs(1, opd_bytes, 32);
	`ins_write1("(%%rip)");
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
function automatic logic signed[63:0] print_abs(logic[3:0] index, logic[0:10*8-1]  opd_bytes, logic[0:5] num_bits );
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
	`ins_write3("%s0x%0x", `SIGN(b_disp), `UHEX(b_disp));
    return b_disp;
endfunction
/* verilator lint_off width *///todo:

`define update_opbuff_reg(opbuff, register)\
    opbuff.reg_id = register;\
    opbuff.bitmap[REG] = 1;\

`define update_opbuff_imm(opbuff, immediate)\
    opbuff.immediate = immediate;\
    opbuff.bitmap[IMM] = 1;\


`DFUN(handleEv)

	logic rex_b = ins.rex_prefix[0];
	logic[1:0] mod = modrm[7:6];
	logic[2:0] rm = modrm[2:0];
	DFUN_RET_TYPE num = 16'h0;
    logic[3:0] register = {rex_b, rm};

	unique case (mod)
		2'b00:
			unique case (rm)
				3'b100: num += `CALL_DFUN(resolve_sib);
				3'b101: begin 
						print_abs(index, opd_bytes, 32);
						num += 4;
					end
				default:begin
						`ins_write2("(%s) ", general_register_names(register));
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
						`ins_write2("(%s) ",general_register_names(register));
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
						`ins_write2("(%s)",general_register_names(register));
						num += 4; //32 bit displacemnt
						end
			endcase
		2'b11: begin
                `update_opbuff_reg(opbuff, register);
			    `ins_write2("%s",general_register_names(register));
            end
	endcase
	return num;
`ENDDFUN

`DFUN(handleGv)
    logic[3:0] register = {ins.rex_prefix[2], modrm[5:3]};
	// Assumption: Gv uses only MODRM.reg
	`update_opbuff_reg(opbuff, register);
	`ins_write2("%s", general_register_names(register));
	return 0;
`ENDDFUN

/*  We might not need index in DFUn */

`DFUN(handleIb)
	logic[63:0] immediate = print_abs(index, opd_bytes, 8);
    `update_opbuff_imm(opbuff, immediate);
	return 1; //1 byte
`ENDDFUN

`DFUN(handleIz)
	//z- rex_w = 1 => 32 bit, otherwise 16
	logic[5:0] operand_size;
	bit rex_w = ins.rex_prefix[3];
    logic[63:0] immediate;
	
	if(rex_w == 1'b1) operand_size = 32;
	else begin//operand size determined by CS.D??
		if(ins.operand_size_prefix == 0) operand_size = 32; //no override
		else operand_size = 16;
	end
	
	immediate = print_abs(index, opd_bytes, operand_size);
    `update_opbuff_imm(opbuff, immediate);
	return operand_size/5'h8;
`ENDDFUN

`DFUN(handleIv)
	//z- rex_w = 1 => 64 bit, otherwise 16/32
	logic[5:0] operand_size;
	logic rex_w = ins.rex_prefix[3];
    logic[63:0] immediate;
	
	if(rex_w == 1'b1) begin operand_size = 6'd64; end
	else begin//operand size determined by CS.D??
		if(ins.operand_size_prefix == 0) operand_size = 6'd32; //no override
		else operand_size = 6'd16;
	end
    immediate = print_abs(index, opd_bytes, operand_size);
    `update_opbuff_imm(opbuff, immediate);
	return operand_size/5'h8;
`ENDDFUN

`DFUN(handleM)
	if (modrm[7:6] == 2'b11) begin
		return -1;
	end
	return `CALL_DFUN(handleEv);
`ENDDFUN

/* verilator lint_off UNDRIVEN */ `DFUNR(rax, "%%rax") /* verilator lint_on UNDRIVEN */

/*
`DFUN(handleEp)
	// (No) - Instruction prefix - REX.W - Effective operand size - pointer size
	// -------------------------------------------------------------------------
	// (1)  - don't care         - 1     - 64                     - 80
	// (2)  - no 66h             - 0     - 32                     - 48
	// (3)  - yes 66h            - 0     - 16                     - 32
`ENDDFUN

`DFUN(handleYb)
	`ins_write1("%%es:(%%rdi)");
	return 0;
`ENDDFUN

`DFUN(handleDX)
	`ins_write1("(%%dx)");
	return 0;
`ENDDFUN

`DFUN(handleXz)
	`ins_write1("(%%ds:(%%rsi))");
	return 0;
`ENDDFUN
*/


/* R1$R2 handlers and entry points */

`DFUNR1$R2(rax, "%%rax", r8,  "%%r8" )
`DFUNR1$R2(rcx, "%%rcx", r9,  "%%r9" )
`DFUNR1$R2(rdx, "%%rdx", r10, "%%r10")
`DFUNR1$R2(rbx, "%%rbx", r11, "%%r11")
`DFUNR1$R2(rsp, "%%rsp", r12, "%%r12")
`DFUNR1$R2(rbp, "%%rbp", r13, "%%r13")
`DFUNR1$R2(rsi, "%%rsi", r14, "%%r14")
`DFUNR1$R2(rdi, "%%rdi", r15, "%%r15")


/* operand handling entry points */

`COMBO_1_DFUNS(Ev)
`COMBO_2_DFUNS(Ev, Gv)
`COMBO_2_DFUNS(Ev, Iv)
`COMBO_2_DFUNS(Ev, Ib)
`COMBO_2_DFUNS(Ev, Iz)

`COMBO_2_DFUNS(Gv, Ev)
`COMBO_2_DFUNS(Gv, M)
`COMBO_2_DFUNS(Ev, rax)
`COMBO_2_DFUNS(rax, Iz)

/*** start of entry points ***/

/* A DFUN returns the number of bytes consumed. Or -1 for error */
`define DFUN(fun) \
function automatic int fun( \
	/* verilator lint_off UNUSED */ \
	inout fat_instruction_t ins, \
	logic[7:0] modrm, \
	logic[0:10*8-1] opd_bytes, \
	/* verilator lint_on UNUSED */ \
);

`define ENDDFUN endfunction

`DFUN(rax$r8)
`ENDDFUN

`DFUN(rcx$r9)
`ENDDFUN

`DFUN(rdx$r10)
`ENDDFUN

`DFUN(rbx$r11)
`ENDDFUN

`DFUN(rsp$r12)
`ENDDFUN

`DFUN(rbp$r13)
`ENDDFUN

`DFUN(rsi$r14)
`ENDDFUN

`DFUN(rdi$r15)
`ENDDFUN

`DFUN(rax$r8_Iv)
`ENDDFUN

`DFUN(rcx$r9_Iv)
`ENDDFUN

`DFUN(rdx$r10_Iv)
`ENDDFUN

`DFUN(rbx$r11_Iv)
`ENDDFUN

`DFUN(rsp$r12_Iv)
`ENDDFUN

`DFUN(rbp$r13_Iv)
`ENDDFUN

`DFUN(rsi$r14_Iv)
`ENDDFUN

`DFUN(rdi$r15_Iv)
`ENDDFUN

`DFUN(Ev)
`ENDDFUN

`DFUN(Ev_Gv)
`ENDDFUN

`DFUN(Ev_Ib)
`ENDDFUN

`DFUN(Ev_Iz)
`ENDDFUN

`DFUN(Gv_Ev)
`ENDDFUN

`DFUN(Gv_M)
`ENDDFUN

`DFUN(Ev_rax)
`ENDDFUN

`DFUN(rax_Iz)
`ENDDFUN

`DFUN(Jz)
	ins.operand0_type = opdt_rip_disp;
	ins.disp = extract_val32(0, opd_bytes);
	return 4;
`ENDDFUN

`DFUN(Jb)
	ins.operand0_type = opdt_rip_disp;
	ins.disp = extract_val8(0, opd_bytes);
	return 1;
`ENDDFUN

`DFUN(_)
	return 0;
`ENDDFUN

/*** end of entry points ***/

function automatic logic has_modrm( /* verilator lint_off UNUSED */ fat_instruction_t ins /* verilator lint_on UNUSED */);

	if (ins.opcode_struct.group != 0) return 1;

	case (ins.opcode_struct.mode)
		"Ev": return 1;
		"Ev_Gv": return 1;
		"Ev_Ib": return 1;
		"Ev_Iz": return 1;
		"Ev_rax": return 1;
		"Gv_Ev": return 1;
		"Gv_M": return 1;
		default: return 0;
	endcase

endfunction

`define D(mode) "mode" : cnt = mode(ins, modrm, opd_bytes);

/* Return -1 if error. Otherwise, the number of bytes consumed is returned. */
function automatic int decode_operands(
	/* verilator lint_off UNUSED */
	inout fat_instruction_t ins,
	/* verilator lint_on UNUSED */
	input logic[0:10*8-1] opd_bytes
);

	logic[7:0] modrm = 0;
	int took_modrm = 0;
	int cnt = 0;

	if (has_modrm(ins)) begin
		modrm = `get_byte(opd_bytes, 0);
		opd_bytes <<= 8;
		took_modrm = 1;
	end

	case (ins.opcode_struct.mode)
		`D(rax$r8)
		`D(rcx$r9)
		`D(rdx$r10)
		`D(rbx$r11)
		`D(rsp$r12)
		`D(rbp$r13)
		`D(rsi$r14)
		`D(rdi$r15)
		`D(rax$r8_Iv)
		`D(rcx$r9_Iv)
		`D(rdx$r10_Iv)
		`D(rbx$r11_Iv)
		`D(rsp$r12_Iv)
		`D(rbp$r13_Iv)
		`D(rsi$r14_Iv)
		`D(rdi$r15_Iv)
		`D(Ev)
		`D(Ev_Gv)
		`D(Ev_Ib)
		`D(Ev_Iz)
		`D(Gv_Ev)
		`D(Gv_M)
		`D(Ev_rax)
		`D(rax_Iz)
		`D(Jz)
		`D(Jb)
		`D(_)
		default: begin 
			$display("ERROR: opcode mode unsupported: %s", ins.opcode_struct.mode);
			return -1;
		end
	endcase

	if (cnt < 0) begin
		return -1;
	end else begin
		return took_modrm + cnt;
	end

endfunction

endpackage
