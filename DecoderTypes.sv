
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
	operand_type_t opd_type;
	reg_id_t base_reg;
	reg_id_t index_reg;
	logic[63:0] scale;
	logic[63:0] disp;
	logic[63:0] immediate; 
} operand_t;

typedef struct packed {
	logic[7:0] lock_repeat_prefix;
	logic[7:0] segment_branch_prefix;
	logic[7:0] operand_size_prefix;
	logic[7:0] address_size_prefix;
	logic[7:0] rex_prefix;
	opcode_struct_t opcode_struct;
	operand_t operand0;
	operand_t operand1;
} fat_instruction_t;

endpackage
