package RegMap;

parameter REG_CNT = 256;

typedef enum logic[7:0] {
/** do NOT change the order **/
	rax = 0,
	rcx,
	rdx,
	rbx,
	rsp,
	rbp,
	rsi,
	rdi,
	r8,
	r9,
	r10,
	r11,
	r12,
	r13,
	r14,
	r15,
	rflags,
	rh0
} reg_id_t;

typedef logic[0:8*8-1] reg_name_t;

function automatic reg_name_t reg_id2name(reg_id_t id);

	reg_name_t map[0:REG_CNT-1] = 0;

	map[rax] = "%rax";
	map[rcx] = "%rcx";
	map[rdx] = "%rdx";
	map[rbx] = "%rbx";
	map[rsp] = "%rsp";
	map[rbp] = "%rbp";
	map[rsi] = "%rsi";
	map[rdi] = "%rdi";
	map[r8] = "%r8";
	map[r9] = "%r9";
	map[r10] = "%r10";
	map[r11] = "%r11";
	map[r12] = "%r12";
	map[r13] = "%r13";
	map[r14] = "%r14";
	map[r15] = "%r15";
	map[rflags] = "%rflags";
	map[rh0] = "%rh0";

	return map[id];

endfunction

function automatic reg_id_t reg_name2id(reg_name_t name);

	case (name)
		"%rax": return rax;
		"%rcx": return rcx;
		"%rdx": return rdx;
		"%rbx": return rbx;
		"%rsp": return rsp;
		"%rbp": return rbp;
		"%rsi": return rsi;
		"%rdi": return rdi;
		"%r8": return r8;
		"%r9": return r9;
		"%r10": return r10;
		"%r11": return r11;
		"%r12": return r12;
		"%r13": return r13;
		"%r14": return r14;
		"%r15": return r15;
		"%rflags": return rflags;
		"%rh0": return rh0;
		default : begin
			$display("ERROR: no mapping for reg_name2id %s: ", name);
			return rax;
		end
	endcase

endfunction

endpackage
