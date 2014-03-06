
`include "MacroUtils.sv"
`include "DecoderTypes.sv"


`define readval(X) \
	case (fat_inst.op``X``.bitmap) \
		`REG_BITMAP: val``X = reg_file_out[`get_reg_in_file(fat_inst.op``X``.reg_id)]; \
		`IMM_BITMAP: val``X = fat_inst.op``X``.immediate; \
		default: val``X = fat_inst.op``X``.immediate; \
	endcase

`define dobinop(opcode, oper) "opcode": reg_file_out[`get_reg_in_file(fat_inst.opa.reg_id)] = vala oper valb;

function automatic logic ALU(
	`LINTOFF_UNUSED(fat_instruction_t fat_inst),
	logic[0:16*64-1] reg_file_in, 
	`LINTOFF_UNOPTFLAT(output logic[0:16*64-1] reg_file_out));

	logic[63:0] vala, valb;

	`readval(a)
	`readval(b)

	reg_file_out = reg_file_in;

	case (fat_inst.opcode_struct.name)
		`dobinop(imul, *)
		`dobinop(add, +)
		`dobinop(or, |)
		"mov": reg_file_out[`get_reg_in_file(fat_inst.opa.reg_id)] = valb;
		"movabs": reg_file_out[`get_reg_in_file(fat_inst.opa.reg_id)] = valb;
		default: reg_file_out = reg_file_in;
	endcase


	//$display("%s", fat_inst.opcode_struct.name);
	return fat_inst.opcode_struct.name == "retq";

endfunction

`undef readval
`undef do_arith
