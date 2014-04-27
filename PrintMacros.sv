`ifndef _PRINT_MACROS_
`define _PRINT_MACROS_


/* Print out decoded instruction */
`define _INS_WRITE_
`ifdef _INS_WRITE_

  `define ins_write1(a) $write(a);
  `define ins_write2(a,b) $write(a,b);
  `define ins_write3(a,b,c) $write(a,b,c);

  // Print bytes in buf, leading zeros will be ignored.
  `define ins_short_print_bytes(buf, sz) \
    begin \
	/* verilator lint_off WIDTH */ int size = sz; /* verilator lint_on WIDTH */ \
	for (int i = 0; i < size; i++) begin \
		if (`get_byte(buf, i) != 0 || i == size - 1) begin \
			for (int k = i; k < size; k++) begin \
				$write("%h ", `get_byte(buf, k)); \
			end \
			break; \
		end \
	end \
    end

`else /* _INS_WRITE_ */

  `define ins_write1(a) ;
  `define ins_write2(a,b) ;
  `define ins_write3(a,b,c) ;
  `define ins_short_print_bytes(buf, size) ;

`endif /* _INS_WRITE_ */


`endif /* _PRINT_MACROS_ */
