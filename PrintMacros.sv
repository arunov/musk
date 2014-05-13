`ifndef _PRINT_MACROS_
`define _PRINT_MACROS_

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

`endif /* _PRINT_MACROS_ */
