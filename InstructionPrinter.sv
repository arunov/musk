`include "PrintMacros.sv"

package InstructionPrinter;

import DecoderTypes::*;
import RegMap::*;

`define SIGN(x) (x<0? "-": "$")
`define UHEX(x) (x<0? -x: x)
`define PRT_SIGNED(num) \
	begin \
		logic signed [0:63] snum = num; \
		`ins_write3("%s0x%0x",`SIGN(snum), `UHEX(snum)); \
	end \

function logic prtOpd(/* verilator lint_off UNUSED */ operand_t opd /* verilator lint_on UNUSED */);
	if(opd.mem_rip_relative) begin
		`ins_write1("%%rip:");
		`PRT_SIGNED(opd.disp);
		return 1;
	end
	unique case(opd.opd_type)
		opdt_register: begin
			/* verilator lint_off WIDTH */
			logic[0:4*8-1] regname = reg_id2name(opd.base_reg);
			/* verilator lint_on WIDTH */
			`ins_write2("%s", regname);
		end
		opdt_immediate:
			`PRT_SIGNED(opd.immediate)
		opdt_memory: begin
			if(opd.mem_has_disp)
				`PRT_SIGNED(opd.disp)
			`ins_write1("(");
			if(opd.mem_has_base) begin
				/* verilator lint_off WIDTH */
				logic[0:4*8-1] regname = reg_id2name(opd.base_reg);
				/* verilator lint_on WIDTH */
				`ins_write2("%s", regname);
			end
			if(opd.mem_has_index || opd.scale != 0)
				`ins_write1(",");
			if(opd.mem_has_index) begin
				/* verilator lint_off WIDTH */
				logic[0:4*8-1] regname = reg_id2name(opd.base_reg);
				/* verilator lint_on WIDTH */
				`ins_write2("%s", regname);
			end
			if(opd.scale != 0) begin
				`ins_write1(",");
				`PRT_SIGNED(opd.scale)
			end
			`ins_write1(") ");
		end
		default:
			return 0;
	endcase
	return 1;
endfunction

function void prtInstr(/* verilator lint_off UNUSED */ fat_instruction_t ins /* verilator lint_on UNUSED */);
	`ins_write2("%s  \t", ins.opcode_struct.name);
	if(prtOpd(ins.operand0) && ins.operand1.opd_type != opdt_nil)
		`ins_write1(", ");
	prtOpd(ins.operand1);
endfunction

endpackage
