
package DecoderTypes;

import RegMap::*;

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
	opdt_memory
} operand_type_t;

typedef struct packed {
	operand_type_t opd_type;
	reg_id_t base_reg;
	reg_id_t index_reg;
	logic mem_has_disp;
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

typedef enum logic[7:0] {
	m_lea,
	m_ld,
	m_st,
	m_add,
	m_adc,
	m_sub,
	m_sbb,
	m_mul,
	m_imul,
	m_div,
	m_idiv
	m_neg,
	m_and,
	m_or,
	m_xor,
	m_not,
	m_cmp,
	m_test,
	m_jo,
	m_jno,
	m_jb,
	m_jnb,
	m_jz,
	m_jnz,
	m_jbe,
	m_jnbe,
	m_js,
	m_jns,
	m_jp,
	m_jnp,
	m_jl,
	m_jnl,
	m_jle,
	m_jnle,
	m_jmp,
	m_xchg,
	m_rol,
	m_ror,
	m_rcl,
	m_rcr,
	m_shl,
	m_shr,
	m_sar,
	m_nop,
	m_syscall,
} micro_opcode_t opcode;

typedef struct packed {
	logic[63:0] rip_val;
	micro_opcode_t opcode;
	reg_id_t src0_id;
	reg_id_t src1_id;
	reg_id_t dest0_id;
	reg_id_t dest1_id;
	reg_id_t dest2_id;
	logic[63:0] src0_val;
	logic[63:0] src1_val;
	logic[63:0] dest0_val;
	logic[63:0] dest1_val;
	logic[63:0] dest2_val;
} micro_op_t;

endpackage
