`include "PrintMacros.sv"

package InstructionPrinter;

import DecoderTypes::*;
import RegMap::*;

`define SIGN(x) (x<0? "-": "$")
`define UHEX(x) (x<0? -x: x)
`define PRT_SIGNED(num) \
	begin \
		logic signed [0:63] snum = num; \
		$write("%s0x%0x",`SIGN(snum), `UHEX(snum)); \
	end \

function logic prtOpd(/* verilator lint_off UNUSED */ fat_instruction_t ins, operand_t opd /* verilator lint_on UNUSED */);
	unique case(opd.opd_type)
		opdt_register: begin
			if (opd.base_reg != rimm) begin
				/* verilator lint_off WIDTH */
				logic[0:4*8-1] regname = reg_id2name(opd.base_reg);
				/* verilator lint_on WIDTH */
				$write("%s", regname);
			end else begin
				`PRT_SIGNED(ins.immediate)
			end
		end
		opdt_memory: begin
			if(ins.disp != 0)
				`PRT_SIGNED(ins.disp)
			$write("(");
			if(opd.base_reg != rnil) begin
				/* verilator lint_off WIDTH */
				logic[0:4*8-1] regname = reg_id2name(opd.base_reg);
				/* verilator lint_on WIDTH */
				$write("%s", regname);
			end
			if(opd.index_reg != rnil || ins.scale != 0)
				$write(",");
			if(opd.index_reg != rnil) begin
				/* verilator lint_off WIDTH */
				logic[0:4*8-1] regname = reg_id2name(opd.base_reg);
				/* verilator lint_on WIDTH */
				$write("%s", regname);
			end
			if(ins.scale != 0) begin
				logic [63:0] ss = 1 << ins.scale;
				$write(",");
				`PRT_SIGNED(ss)
			end
			$write(") ");
		end
		default:
			return 0;
	endcase
	return 1;
endfunction

function void prtInstr(/* verilator lint_off UNUSED */ fat_instruction_t ins /* verilator lint_on UNUSED */);
	$write("%s  \t", ins.opcode_struct.name);
	if(prtOpd(ins, ins.operand0) && ins.operand1.opd_type != opdt_nil)
		$write(", ");
	prtOpd(ins, ins.operand1);
endfunction

endpackage
