package InstructionPrinter;

import DecoderTypes::*;
import RegMap::*;

function logic prtOpd(/* verilator lint_off UNUSED */ operand_t opd /* verilator lint_on UNUSED */);
	if(opd.mem_rip_relative) begin
		$write("%%rip(0x%x)", opd.immediate);
		return 1;
	end
	unique case(opd.opd_type)
		opdt_register: begin
			/* verilator lint_off WIDTH */
			logic[0:4*8-1] regname = reg_id2name(opd.base_reg);
			/* verilator lint_on WIDTH */
			$write("%s", regname);
		end
		opdt_immediate:
			$write("0x%x", opd.immediate);
		opdt_memory: begin
			if(opd.mem_has_disp)
				$write("0x%x", opd.immediate);
			$write("(");
			if(opd.mem_has_base) begin
				/* verilator lint_off WIDTH */
				logic[0:4*8-1] regname = reg_id2name(opd.base_reg);
				/* verilator lint_on WIDTH */
				$write("%s", regname);
			end
			$write(",");
			if(opd.mem_has_index) begin
				/* verilator lint_off WIDTH */
				logic[0:4*8-1] regname = reg_id2name(opd.base_reg);
				/* verilator lint_on WIDTH */
				$write("%s", regname);
			end
			$write(",");
			//if(opd.mem_has_scale)
				$write("0x%x", opd.scale);
			$write(")");
		end
		default:
			return 0;
	endcase
	return 1;
endfunction

function void prtInstr(/* verilator lint_off UNUSED */ fat_instruction_t ins /* verilator lint_on UNUSED */);
	$write("%s  \t", ins.opcode_struct.name);
	if(prtOpd(ins.operand0) && ins.operand1.opd_type != opdt_nil)
		$write(", ");
	prtOpd(ins.operand1);
endfunction

endpackage
