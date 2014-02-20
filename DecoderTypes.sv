`ifndef _DECODER_TYPES_
`define _DECODER_TYPES_

typedef logic[0:32*8-1] opcode_name_t;
typedef logic[0:32*8-1] opcode_mode_t;

typedef struct packed {
	logic[0:3*8-1] opcode;
	opcode_name_t name;
	opcode_mode_t mode;
	logic[4:0] group;
} opcode_struct_t;

typedef struct packed {
	logic[7:0] lock_repeat_prefix;
	logic[7:0] segment_branch_prefix;
	logic[7:0] operand_size_prefix;
	logic[7:0] address_size_prefix;
	logic[7:0] rex_prefix;
	opcode_struct_t opcode_struct;
	logic operands_use_modrm;
} fat_instruction_t;

`endif /* _DECODER_TYPES_ */
