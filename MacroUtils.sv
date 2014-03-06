`ifndef _MACRO_UTILS_
`define _MACRO_UTILS_

`define LINTOFF(x) /* verilator lint_off x */
`define LINTON(x)  /* verilator lint_on x */

`define LINTOFF_X(x, y) `LINTOFF(x) y `LINTON(x)
`define LINTOFF_UNUSED(x) `LINTOFF_X(UNUSED, x)
`define LINTOFF_UNOPTFLAT(x) `LINTOFF_X(UNOPTFLAT, x)

`define pget_blocks(x, i, p, z) x[(i) * (z) +: (p) * (z)]
`define eget_blocks(x, i, j, z) `pget_blocks(x, i, j - i, z)
`define get_block(x, i, z) `pget_blocks(x, i, 1, z)

`define pget_bytes(x, i, p) `pget_blocks(x, i, p, 8)
`define eget_bytes(x, i, j) `eget_blocks(x, i, j, 8)
`define get_byte(x, i) `get_block(x, i, 8)

`define pget_64s(x, i, p) `pget_blocks(x, i, p, 64)
`define eget_64s(x, i, j) `eget_blocks(x, i, j, 64)
`define get_64(x, i) `get_block(x, i, 64)

`define short_print_bytes(buf, size) \
	for (int i = 0; i < size; i++) begin \
		if (`get_byte(buf, i) != 0 || i == size - 1) begin \
			for (int k = i; k < size; k++) begin \
				$write("%h ", `get_byte(buf, k)); \
			end \
			break; \
		end \
	end

`define get_reg_in_file(x) x*64+:64

`endif /*_MACRO_UTILS_ */
