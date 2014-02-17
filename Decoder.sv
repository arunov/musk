`include "MacroUtils.sv"

typedef logic[0:32*8-1] opcode_name_t;
typedef logic[0:9*8-1] opcode_mode_t;
typedef enum {OP_MPX_NIL = 0, OP_MPX_66H, OP_MPX_F2H, OP_MPX_F3H} opcode_mprefix_t;

typedef struct packed {
	opcode_name_t name;
	opcode_mode_t mode;
	opcode_mprefix_t mprefix;
} opcode_struct_t;

typedef struct packed {
	logic[0:7] lock_repeat_prefix;
	logic[0:7] segment_branch_prefix;
	logic[0:7] operand_size_prefix;
	logic[0:7] address_size_prefix;
	logic[0:7] rex_prefix;
	opcode_struct_t opcode_struct;
} fat_instruction_t;

`include "OpcodeMap1.sv"
`include "OpcodeMap2.sv"
`include "OpcodeMap3.sv"
`include "OpcodeMap4.sv"

function automatic logic is_lock_repeat_prefix(logic[0:7] val);
	return val == 'hF0 || val == 'hF3 || val == 'hF2;
endfunction

function automatic logic is_segment_branch_prefix(logic[0:7] val);
	return val == 'h2E || val == 'h3E || val == 'h26 || val == 'h64 || val == 'h65 || val == 'h36;
endfunction

function automatic logic is_operand_size_prefix(logic[0:7] val);
	return val == 'h66;
endfunction

function automatic logic is_address_size_prefix(logic[0:7] val);
	return val == 'h67;
endfunction

function automatic logic is_rex_prefix(`LINTOFF_UNUSED(logic[0:7] val));
	return val[0:3] == 'h4;
endfunction

function automatic logic handle_legacy_prefix(logic[0:7] val, inout fat_instruction_t ins);
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

function automatic logic[3:0] fill_opcode_struct(logic[0:3*8-1] op_bytes, output opcode_struct_t op_struct);
	if (op_bytes[0:7] == 'h0F) begin
		if (op_bytes[8:15] == 'h3A) begin
			op_struct = opcode_map4(op_bytes[16:23]);
			return 3;
		end else if (op_bytes[8:15] == 'h38) begin
			op_struct = opcode_map3(op_bytes[16:23]);
			return 3;
		end else begin
			op_struct = opcode_map2(op_bytes[8:15]);
			return 2;
		end
	end else begin
		op_struct = opcode_map1(op_bytes[0:7]);
		return 1;
	end
endfunction

function automatic logic[0:7] get_dc_byte(logic[0:15*8-1] dc_bytes, logic[3:0] byte_index);
	return dc_bytes[byte_index*8+:8];
endfunction

`define ADVANCE_DC_POINTER(x) \
	byte_index = byte_index + (x); \
	cur_byte = get_dc_byte(dc_bytes, byte_index);

`define SKIP_AND_EXIT \
	$display("skip one byte: %h", cur_byte); \
	return 1;

function automatic logic[3:0] decode(logic[0:15*8-1] dc_bytes);

	logic[3:0] byte_index = 0;
	logic[3:0] op_size = 0;
	logic[0:7] cur_byte = 0;
	fat_instruction_t ins = 0;

	cur_byte = get_dc_byte(dc_bytes, byte_index);

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

	op_size = fill_opcode_struct(dc_bytes[byte_index*8+:8*3], ins.opcode_struct);
	
	// Check if opcode is invalid
	if (ins.opcode_struct == 0) begin
		$display("invalid opcode: first %h bytes of: %h", op_size, dc_bytes[byte_index*8+:8*3]);
		`SKIP_AND_EXIT;
	end
	
	`ADVANCE_DC_POINTER(op_size);

	$display("%h bytes decoded", byte_index);
	return byte_index;

endfunction

`undef ADVANCE_DC_POINTER
`undef SKIP_AND_EXIT
