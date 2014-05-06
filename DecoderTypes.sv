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
	logic[1:0] scale;
	logic[63:0] disp;
	logic[63:0] immediate; 
	logic[63:0] rip_val;
} fat_instruction_t;

/*** 
The processing of a micro op will go through 4 stages: 
register read, execute, memory access, register write.

Currently, besides m_syscall, none of these micro ops need to check src or dst ids during 
'execute' and 'memory access'. Should we make this a rule?

All registers are prefixed with flag bits.
***/

typedef enum logic[7:0] {
	m_lea,   // (base, index, res)
	m_ld,    // (src_addr, rnil, dst)
	m_st,    // (src, dst_addr, rnil)
	m_cpy,   // (src, rnil, dest)
	m_add,   // (op0, op1, res) ; set flags
	m_and,   // (op0, op1, res) ; set flags
	m_or,    // (op0, op1, res) ; set flags
	m_shl,   // (op0, op1, res) ; set flags
	m_shr,   // (op0, op1, res) ; set flags
	m_sub,   // (op0, op1, res) ; set flags
	m_xor,   // (op0, op1, res) ; set flags
	m_imul_l,    // (op0, op1, res); lower half of multiplication ; set flags
	m_imul_h,    // (op0, op1, res); higher half of multiplication ; set flags
	M_JMIN,  // Just a marker
	m_jnb,   // (target, rflags, rnil)
	m_jz,    // (target, rflags, rnil)
	m_jnle,  // (target, rflags, rnil)
	m_jnl,   // (target, rflags, rnil)
	m_jl,    // (target, rflags, rnil)
	m_jle,   // (target, rflags, rnil)
	m_jne,   // (target, rflags, rnil)
	m_jmp,   // (target, rnil, rnil) 
	M_JMAX,  // Just a marker
	m_syscall // very special
} micro_opcode_t;

typedef struct packed {
	micro_opcode_t opcode;
	reg_id_t src0_id;
	reg_id_t src1_id;
	reg_id_t dst_id;
	logic[63:0] src0_val;
	logic[63:0] src1_val;
	logic[63:0] dst_val;
	logic[1:0] scale;
	logic[63:0] disp;
	logic[63:0] immediate;
	logic[63:0] rip_val;
} micro_op_t;

endpackage
