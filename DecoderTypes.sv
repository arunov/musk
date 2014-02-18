`ifndef _DECODER_TYPES_
`define _DECODER_TYPES_

typedef logic[0:32*8-1] opcode_name_t;
typedef logic[0:32*8-1] opcode_mode_t;
typedef enum {OP_MPX_NIL = 0, OP_MPX_66H, OP_MPX_F2H, OP_MPX_F3H} opcode_mprefix_t;

typedef struct packed {
	logic[0:3*8-1] opcode;
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

`endif /* _DECODER_TYPES_ */
