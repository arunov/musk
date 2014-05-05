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
	opdt_memory
} operand_type_t;

typedef struct packed {
	operand_type_t opd_type;
	reg_id_t base_reg;
	reg_id_t index_reg;
	logic[1:0] scale;
	logic[63:0] disp;
	logic[63:0] immediate; 
} operand_t;

typedef struct packed {
	logic[63:0] rip_val;
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
	m_ld,
	m_st,
	m_add,
	m_and,
	m_imul,
	M_JMIN,
	m_jnb,
	m_jz,
	m_jnle,
	m_jnl,
	m_jl,
	m_jle,
	m_jmp,
	m_jne,
	M_JMAX,
	m_lea,
	m_or,
	m_shl,
	m_shr,
	m_sub,
	m_syscall,
	m_xor
} micro_opcode_t;

typedef struct packed {
	logic[63:0] rip_val;
	micro_opcode_t opcode;
	reg_id_t src0_id;
	reg_id_t src1_id;
	reg_id_t src2_id;
	reg_id_t dst0_id;
	reg_id_t dst1_id;
	reg_id_t dst2_id;
	logic[63:0] src0_val;
	logic[63:0] src1_val;
	logic[63:0] src2_val;
	logic[63:0] dst0_val;
	logic[63:0] dst1_val;
	logic[63:0] dst2_val;
	logic[1:0] scale;
	logic[63:0] disp;
	logic[63:0] immediate;
} micro_op_t;

endpackage
