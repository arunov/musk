package InstructionPrinter;

import DecoderTypes::*;
import RegMap::*;

function prtInstr(fat_instruction_t ins);
	$WRITE("%s", opcode_struct.name);
	

endfunction

endpackage
