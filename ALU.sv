
`include "MacroUtils.sv"
`include "DecoderTypes.sv"

function automatic logic ALU(
	`LINTOFF_UNUSED(fat_instruction_t fat_inst),
	logic[0:16*64-1] reg_file_in, 
	output logic[0:16*64-1] reg_file_out);

	reg_file_out = reg_file_in + 1;
	
	$display("%s", fat_inst.opcode_struct.name);
	return fat_inst.opcode_struct.name == "retq";

endfunction
