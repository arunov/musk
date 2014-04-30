
package DecoderTypes;

typedef logic[0:16*8-1] opcode_name_t;
typedef logic[0:16*8-1] opcode_mode_t;

typedef struct packed {
	logic[0:3*8-1] opcode;
	opcode_name_t name;
	opcode_mode_t mode;
	int group;
} opcode_struct_t;

typedef enum {
	opdt_nil = 0,
	opdt_register,
	opdt_immediate,
	opdt_base,
	opdt_index,
	opdt_disp,
	opdt_base_index,
	opdt_base_disp,
	opdt_index_disp,
	opdt_base_index_disp,
	opdt_rip_disp
} operand_type_t;

typedef struct packed {
	logic[7:0] lock_repeat_prefix;
	logic[7:0] segment_branch_prefix;
	logic[7:0] operand_size_prefix;
	logic[7:0] address_size_prefix;
	logic[7:0] rex_prefix;
	opcode_struct_t opcode_struct;
	operand_type_t operand0_type;
	operand_type_t operand1_type;
	reg_id_t reg0;
	reg_id_t reg1;
	reg_id_t index_reg;
	logic[63:0] scale;
	logic[63:0] disp;
	logic[63:0] immediate; 
} fat_instruction_t;

endpackage
