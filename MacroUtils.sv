`ifndef _MACRO_UTILS_
`define _MACRO_UTILS_


// Address the i'th (inclusive) to (i+p)'th (exclusive) z-bit word in buf.
`define pget_blocks(buf, i, p, z) buf[(i) * (z) +: (p) * (z)]
// Address the i'th (inclusive) to j'th (exclusive) z-bit word in buf.
`define eget_blocks(buf, i, j, z) `pget_blocks(buf, i, j - i, z)
// Address the i'th z-bit word in buf.
`define get_block(buf, i, z) `pget_blocks(buf, i, 1, z)

// Address the i'th (inclusive) to (i+p)'th (exclusive) byte in buf.
`define pget_bytes(buf, i, p) `pget_blocks(buf, i, p, 8)
// Address the i'th (inclusive) to j'th (exclusive) byte in buf.
`define eget_bytes(buf, i, j) `eget_blocks(buf, i, j, 8)
// Address the i'th byte in buf.
`define get_byte(buf, i) `get_block(buf, i, 8)

// Address the i'th (inclusive) to (i+p)'th (exclusive) 64-bit word in buf.
`define pget_64s(buf, i, p) `pget_blocks(buf, i, p, 64)
// Address the i'th (inclusive) to j'th (exclusive) 64-bit word in buf.
`define eget_64s(buf, i, j) `eget_blocks(buf, i, j, 64)
// Address the i'th 64-bit word in buf.
`define get_64(buf, i) `get_block(buf, i, 64)


`endif /* _MACRO_UTILS_ */
