`ifndef _DECODER_
`define _DECODER_

`include "MacroUtils.sv"
`include "DecoderTypes.sv"
`include "OpcodeMap.sv"
`include "OperandDecoder.sv"

function automatic logic is_lock_repeat_prefix(logic[7:0] val);
	return val == 'hF0 || val == 'hF3 || val == 'hF2;
endfunction

function automatic logic is_segment_branch_prefix(logic[7:0] val);
	return val == 'h2E || val == 'h3E || val == 'h26 || val == 'h64 || val == 'h65 || val == 'h36;
endfunction

function automatic logic is_operand_size_prefix(logic[7:0] val);
	return val == 'h66;
endfunction

function automatic logic is_address_size_prefix(logic[7:0] val);
	return val == 'h67;
endfunction

function automatic logic is_rex_prefix(`LINTOFF_UNUSED(logic[7:0] val));
	return val[7:4] == 'h4;
endfunction

function automatic logic handle_legacy_prefix(logic[7:0] val, inout fat_instruction_t ins);
	if (is_lock_repeat_prefix(val)) begin
		ins.lock_repeat_prefix = val;
		return 1;
	end else if (is_segment_branch_prefix(val)) begin
		ins.segment_branch_prefix = val;
		return 1;
	end else if (is_operand_size_prefix(val)) begin
		ins.operand_size_prefix = val;
		return 1;
	end else if (is_address_size_prefix(val)) begin
		ins.address_size_prefix = val;
		return 1;
	end else begin
		return 0;
	end
endfunction

`define ADVANCE_DC_POINTER(x) \
	byte_index += (x); \
	cur_byte = `get_byte(dc_bytes, byte_index);

`define SKIP_AND_EXIT \
	$display("skip one byte: %h", `get_byte(dc_bytes_copy, 0)); \
	return 1;

function automatic logic[3:0] decode(logic[0:15*8-1] dc_bytes);

	logic[0:15*8-1] dc_bytes_copy = dc_bytes;
	logic[3:0] byte_index = 0;
	logic[3:0] opcode_byte_cnt = 0;
	logic[3:0] operand_byte_cnt = 0;
	logic[7:0] cur_byte = 0;
	fat_instruction_t ins = 0;

	$write("bytes: %h: ", dc_bytes);

	cur_byte = `get_byte(dc_bytes, byte_index);
 
	// Handle legacy prefixes, 4 of them at most.
	repeat (4) begin
		if (handle_legacy_prefix(cur_byte, ins)) begin
			`ADVANCE_DC_POINTER(1)
		end else begin
			break;
		end
	end

	// Check REX prefix.
	if (is_rex_prefix(cur_byte)) begin
		ins.rex_prefix = cur_byte;
		`ADVANCE_DC_POINTER(1)
	end

	/* 4 bytes are passed because ModRM may be needed */
	opcode_byte_cnt = fill_opcode_struct(`pget_bytes(dc_bytes, byte_index, 4), ins.opcode_struct);

	// Check if opcode is invalid
	if (ins.opcode_struct.name == 0) begin
		$write("invalid opcode: ");
		`short_print_bytes(ins.opcode_struct.opcode, 3);
		$write(": ");
		`SKIP_AND_EXIT;
	end

	`ADVANCE_DC_POINTER(opcode_byte_cnt)

	// This is to make sure when we take 10 bytes, we don't go out of bound.
	dc_bytes <<= byte_index * 8;
	
	operand_byte_cnt = decode_operands(ins, `eget_bytes(dc_bytes, 0, 10));

	$write("\t\t;;;; ");
	if (operand_byte_cnt > 10) begin
		$write("invalid operands: %h: ", `eget_bytes(dc_bytes, 0, 10));
		`SKIP_AND_EXIT
	end

	/* Prevent missing count of ModRM */
	if (!ins.operands_use_modrm && ins.opcode_struct.group != 0) begin
		`ADVANCE_DC_POINTER(1)
	end

	`ADVANCE_DC_POINTER(operand_byte_cnt)

	$write("%d bytes decoded: ", byte_index);
	`short_print_bytes(dc_bytes_copy, byte_index);
	$display("");

	return byte_index;

endfunction

`undef ADVANCE_DC_POINTER
`undef SKIP_AND_EXIT

`endif /* _DECODER_ */
