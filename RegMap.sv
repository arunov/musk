package RegMap;

parameter REG_FILE_SIZE = 18;

typedef enum logic[7:0] {
/** do NOT change the listing order **/
	/** fake registers **/
	rnil = 8'b00000000,
	rip,
	rimm,
	/** real registers **/
	rax  = 8'b10000000,
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

function automatic logic[7:0] reg_num(reg_id_t id);
	if (id < rax) begin
		$display("ERROR: reg_num: attempt to access fake register");
	end
	return {1'b0, id[6:0]};
endfunction

function automatic reg_name_t reg_id2name(reg_id_t id);

	reg_name_t [0:255] map = 0;

	/** fake registers **/
	map[rnil] = "%rnil";
	map[rip] = "%rip";
	map[rimm] = "%rimm";
	/** real registers **/
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

	if (map[id] == 0) $display("ERROR: no mapping for reg_id2name %x: ", id);

	return map[id];

endfunction

function automatic reg_id_t reg_name2id(reg_name_t name);

	case (name)
		/** fake registers **/
		"%rnil": return rnil;
		"%rip": return rip;
		"%rimm": return rimm;
		/** real registers **/
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
