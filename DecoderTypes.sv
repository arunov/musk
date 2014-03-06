`ifndef _DECODER_TYPES_
`define _DECODER_TYPES_

typedef logic[0:16*8-1] opcode_name_t;
typedef logic[0:32*8-1] opcode_mode_t;

typedef struct packed {
	logic[0:3*8-1] opcode;
	opcode_name_t name;
	opcode_mode_t mode;
	logic[4:0] group;
} opcode_struct_t;

/* Structure that represents an operand */
typedef struct packed{
    logic[3:0] reg_id;
    logic[63:0] immediate;
    /* Bitmap to indicate which fields in this structure are valid*/
    logic[1:0] bitmap;
} decode_buff_t;

typedef struct packed {
	logic[7:0] lock_repeat_prefix;
	logic[7:0] segment_branch_prefix;
	logic[7:0] operand_size_prefix;
	logic[7:0] address_size_prefix;
	logic[7:0] rex_prefix;
	opcode_struct_t opcode_struct;
	logic operands_use_modrm;
    /* Placeholder for storing src and destination operands */
    decode_buff_t opa;
    decode_buff_t opb;
} fat_instruction_t;

`endif /* _DECODER_TYPES_ */
