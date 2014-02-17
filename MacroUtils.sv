`ifndef _MACRO_UTILS_
`define _MACRO_UTILS_

`define LINTOFF(x) /* verilator lint_off x */
`define LINTON(x)  /* verilator lint_on x */

`define LINTOFF_UNUSED(x) `LINTOFF(UNUSED) x `LINTON(UNUSED)

`endif /*_MACRO_UTILS_ */
