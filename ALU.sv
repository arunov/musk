
`include "MacroUtils.sv"

`define readval(X) \
	case (fat_inst.op``X``.bitmap) \
		`REG_BITMAP: val``X = `get_64(reg_file_in, fat_inst.op``X``.reg_id); \
		`IMM_BITMAP: val``X = fat_inst.op``X``.immediate; \
		default: val``X = fat_inst.op``X``.immediate; \
	endcase

`define dobinop(opcode, oper)	"opcode": `get_64(reg_file_out, fat_inst.opa.reg_id) = vala oper valb;
`define domovop(opcode)		"opcode": `get_64(reg_file_out, fat_inst.opa.reg_id) = valb;

package ALU;

import DECODER::fat_instruction_t;

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

	`readval(a)
	`readval(b)

	reg_file_out = reg_file_in;
	case (fat_inst.opcode_struct.name)
		`dobinop(add, +)
		`dobinop(or, |)
		`dobinop(and, &)
		`domovop(mov)
		`domovop(movabs)
		"imul": doimul(vala, valb, `get_64(reg_file_out, 0), `get_64(reg_file_out, 2));
	endcase

	return fat_inst.opcode_struct.name == "retq";

endfunction

`undef readval
`undef do_arith

endpackage
