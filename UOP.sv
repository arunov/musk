`ifndef __UOP_SV
`define __UOP_SV

`include "DecoderTypes.sv"

/* Uop queue */
// number of input and output microinstructions
`define IN_UOP 5
`define OUT_UOP 1

// size of queue
`define QU_UOP 16

// number of bits for queue index
typedef logic[3:0] uop_index_t;
typedef uop_index_t uop_size_t;
typedef uop_index_t uop_color_t;

typedef struct packed{
	opcode_name_t name;
	decode_buff_t dest;
	decode_buff_t src;
	uop_color_t color;
} uop_ins_t;

`endif // __UOP_SV

