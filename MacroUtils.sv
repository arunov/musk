`ifndef _MACRO_UTILS_
`define _MACRO_UTILS_

`define LINTOFF(x) /* verilator lint_off x */
`define LINTON(x)  /* verilator lint_on x */

`define LINTOFF_X(x, y) `LINTOFF(x) y `LINTON(x)
`define LINTOFF_UNUSED(x) `LINTOFF_X(UNUSED, x)

`endif /*_MACRO_UTILS_ */
