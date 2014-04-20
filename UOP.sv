import DECODER::*;

package UOP;

parameter
	IN_UOP = 4'd5,
	OUT_UOP = 4'd1,
	QU_UOP = 4'd16;

/* Uop queue */
// number of input and output microinstructions
//`define IN_UOP 5
//`define OUT_UOP 1

// size of queue
//`define QU_UOP 16

// number of bits for queue index
typedef logic[3:0] uop_index_t;
typedef uop_index_t uop_size_t;
typedef uop_index_t uop_color_t;

typedef struct packed {
	DECODER::opcode_name_t name;
	DECODER::decode_buff_t dest;
	DECODER::decode_buff_t src;
	uop_color_t color;
} uop_ins_t;

endpackage

