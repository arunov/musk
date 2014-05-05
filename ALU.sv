
`include "MacroUtils.sv"

`define dobinop(opcode, oper)	"opcode": `get_64(reg_file_out, reg_num(fat_inst.operand0.base_reg)) = vala oper valb;
`define domovop(opcode)		"opcode": `get_64(reg_file_out, reg_num(fat_inst.operand0.base_reg)) = valb;

package ALU;

import DecoderTypes::*;
import RegMap::*;

function automatic logic[63:0] readval( 
	/* verilator lint_off UNUSED */
	fat_instruction_t ins,
	operand_t operand,
	logic[0:16*64-1] reg_file 
	/* verilator lint_on UNUSED */
);
	if (operand.base_reg == rimm) return ins.immediate; 
	return `get_64(reg_file, reg_num(operand.base_reg));
endfunction

function automatic void doimul(
	input logic[63:0] vala,
	input logic[63:0] valb,
	output logic[0:63] reg_rax,
	output logic[0:63] reg_rdx);

	logic[127:0] res = {64'b0, vala} * {64'b0, valb};

	reg_rdx = res[127:64];
	reg_rax = res[63:0];

endfunction

function automatic logic alu(
	/* verilator lint_off UNUSED */
	fat_instruction_t fat_inst,
	/* verilator lint_on UNUSED */
	logic[0:16*64-1] reg_file_in, 
	output logic[0:16*64-1] reg_file_out);

	logic[63:0] vala, valb;

	if (fat_inst.opcode_struct.name == "retq" || fat_inst.opcode_struct.name == 0) return 1;

	vala = readval(fat_inst, fat_inst.operand0, reg_file_in);
	valb = readval(fat_inst, fat_inst.operand1, reg_file_in);

	reg_file_out = reg_file_in;
	case (fat_inst.opcode_struct.name)
		`dobinop(add, +)
		`dobinop(or, |)
		`dobinop(and, &)
		`domovop(mov)
		`domovop(movabs)
		"imul": doimul(vala, valb, `get_64(reg_file_out, 0), `get_64(reg_file_out, 2));
	endcase

	return 0;

endfunction

endpackage
