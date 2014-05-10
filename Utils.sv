`include "MacroUtils.sv"

package Utils;

`define LE_NBYTES_TO_VAL(N) \
	logic [0:N*8-1] be_bytes; \
	logic [63:0] val = 0; \
	int i; \
	for (i = 0; i < N; i++) begin \
		`get_byte(be_bytes, N - 1 - i) = `get_byte(le_bytes, i); \
	end \
	if (be_bytes[0] == 1) val = 64'hffffffffffffffff; \
	val[N*8-1:0] = be_bytes; \
	return val; \

`define VAL_TO_LE_NBYTES(N) \
	logic [0:N*8-1] le_bytes; \
	logic [0:N*8-1] be_bytes = val[N*8-1:0]; \
	int i; \
	for (i = 0; i < N; i++) begin \
		`get_byte(le_bytes, i) = `get_byte(be_bytes, N - 1 - i); \
	end \
	return le_bytes; \

/*** convert little endian bytes to 64 bit value, with sign extension ***/
function automatic logic [63:0] le_1bytes_to_val(logic[0:1*8-1] le_bytes);
	`LE_NBYTES_TO_VAL(1)
endfunction

function automatic logic [63:0] le_2bytes_to_val(logic[0:2*8-1] le_bytes);
	`LE_NBYTES_TO_VAL(2)
endfunction

function automatic logic [63:0] le_4bytes_to_val(logic[0:4*8-1] le_bytes);
	`LE_NBYTES_TO_VAL(4)
endfunction

function automatic logic [63:0] le_8bytes_to_val(logic[0:8*8-1] le_bytes);
	`LE_NBYTES_TO_VAL(8)
endfunction

/*** convert 64 bit value to little endian bytes ***/
function automatic logic [0:8*8-1] val_to_le_8bytes(logic[63:0] val);
	`VAL_TO_LE_NBYTES(8)
endfunction

endpackage
