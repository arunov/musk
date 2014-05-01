package InstructionPrinter;

import DecoderTypes::*;
import RegMap::*;

function prtOpd(operand_t opd);
	if(opd.mem_rip_relative) begin
		$write("%rip(0x%x)", opd.immediate);
		return;
	end
	unique case(opd.opd_type)
		opdt_register:
			$write("%s", reg_id2name(opd.base_reg));
		opdt_immediate:
			$write("0x%x", opd.immediate);
		opdt_memory:
			if(opd.mem_has_disp)
				$write("0x%x", opd.immediate);
			$write("(");
			if(opd.mem_has_base)
				$write("%s", opd.base_reg);
			$write(",");
			if(opd.mem_has_index)
				$write("%s", opd.index_reg);
			$write(",");
			//if(opd.mem_has_scale)
				$write("0x%x", opd.scale);
			$write(")");
		default:
	endcase
	return;
endfunction

function prtInstr(fat_instruction_t ins);
	$write("%s ", ins.opcode_struct.name);
	prtOpd(ins.operand0);
	$write(", ");
	prtOpd(ins.operand1);
endfunction

endpackage
