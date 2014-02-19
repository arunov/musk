`ifndef _OPCODE_MAP_
`define _OPCODE_MAP_

`include "MacroUtils.sv"
`include "DecoderTypes.sv"
`include "OpcodeMap1.sv"
`include "OpcodeMap2.sv"
`include "OpcodeMap3.sv"
`include "OpcodeMap4.sv"

function automatic logic[3:0] fill_opcode_struct(logic[0:3*8-1] op_bytes, output opcode_struct_t op_struct);
	if (`get_byte(op_bytes, 0) == 'h0F) begin
		if (`get_byte(op_bytes, 1) == 'h3A) begin
			op_struct = opcode_map4(`get_byte(op_bytes, 2));
			`eget_bytes(op_struct.opcode, 0, 3) = `eget_bytes(op_bytes, 0, 3);
			return 3;
		end else if (`get_byte(op_bytes, 1) == 'h38) begin
			op_struct = opcode_map3(`get_byte(op_bytes, 2));
			`eget_bytes(op_struct.opcode, 0, 3) = `eget_bytes(op_bytes, 0, 3);
			return 3;
		end else begin
			op_struct = opcode_map2(`get_byte(op_bytes, 1));
			`eget_bytes(op_struct.opcode, 1, 3) = `eget_bytes(op_bytes, 0, 2);
			return 2;
		end
	end else begin
		op_struct = opcode_map1(`get_byte(op_bytes, 0));
		`eget_bytes(op_struct.opcode, 2, 3) = `eget_bytes(op_bytes, 0, 1);
		return 1;
	end
endfunction

`endif /* _OPCODE_MAP_ */
