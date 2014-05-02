package InstructionPrinter;

import DecoderTypes::*;
import RegMap::*;

function void prtOpd(/* verilator lint_off UNUSED */ operand_t opd /* verilator lint_on UNUSED */);
	if(opd.mem_rip_relative) begin
		$write("%%rip(0x%x)", opd.immediate);
		return;
	end
	unique case(opd.opd_type)
		opdt_register:
			$write("%s", reg_id2name(opd.base_reg));
		opdt_immediate:
			$write("0x%x", opd.immediate);
		opdt_memory: begin
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
		end
	endcase
	return;
endfunction

function void prtInstr(/* verilator lint_off UNUSED */ fat_instruction_t ins /* verilator lint_on UNUSED */);
	$write("%s ", ins.opcode_struct.name);
	prtOpd(ins.operand0);
	$write(", ");
	prtOpd(ins.operand1);
endfunction

endpackage
