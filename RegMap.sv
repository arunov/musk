package RegMap;

parameter REG_FILE_SIZE = 20;

typedef enum logic[7:0] {
/** do NOT change the listing order **/
	/** fake registers **/
	rnil = 8'b00000000,
	rip,
	rimm,
	rsyscall,
	// fake registers that represent contant values
	rv0,
	rv8,
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
	rha,
	rhb,
	rhc
} reg_id_t;

typedef struct packed {
	logic cf;
	logic zf;
	logic sf;
	logic of;
	logic pf;
	logic af;
	logic [63:0] val;
} reg_val_t;

typedef logic[0:8*8-1] reg_name_t;

function automatic logic reg_in_file(reg_id_t id);
	return id >= rax && id <= rhc;
endfunction

function automatic logic[7:0] reg_num(reg_id_t id);
	if (!reg_in_file(id)) begin
		$display("ERROR: reg_num: attempt to access fake register: %x", id);
		return 0;
	end
	return {1'b0, id[6:0]};
endfunction

function automatic reg_name_t reg_id2name(reg_id_t id);

	reg_name_t [0:255] map = 0;

	/** fake registers **/
	map[rnil] = "%rnil";
	map[rip] = "%rip";
	map[rimm] = "%rimm";
	map[rsyscall] = "%rsyscall";
	map[rv0] = "%rv0";
	map[rv8] = "%rv8";
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
	map[rha] = "%rha";
	map[rhb] = "%rhb";
	map[rhc] = "%rhc";

	if (map[id] == 0) begin
		$display("ERROR: no mapping for reg_id2name %x: ", id);
		return 0;
	end

	return map[id];

endfunction

function automatic reg_id_t reg_name2id(reg_name_t name);

	case (name)
		/** fake registers **/
		"%rnil": return rnil;
		"%rip": return rip;
		"%rimm": return rimm;
		"%rsyscall": return rsyscall;
		"%rv0": return rv0;
		"%rv8": return rv8;
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
		"%rha": return rha;
		"%rhb": return rhb;
		"%rhc": return rhc;
		default : begin
			$display("ERROR: no mapping for reg_name2id %s: ", name);
			return 0;
		end
	endcase

endfunction

function automatic void print_reg_file(reg_val_t[0:REG_FILE_SIZE-1] reg_file);
		$display("RAX = %x", reg_file[0].val);
		$display("RCX = %x", reg_file[1].val);
		$display("RDX = %x", reg_file[2].val);
		$display("RBX = %x", reg_file[3].val);
		$display("RSP = %x", reg_file[4].val);
		$display("RBP = %x", reg_file[5].val);
		$display("RSI = %x", reg_file[6].val);
		$display("RDI = %x", reg_file[7].val);
		$display("R8 = %x", reg_file[8].val);
		$display("R9 = %x", reg_file[9].val);
		$display("R10 = %x", reg_file[10].val);
		$display("R11 = %x", reg_file[11].val);
		$display("R12 = %x", reg_file[12].val);
		$display("R13 = %x", reg_file[13].val);
		$display("R14 = %x", reg_file[14].val);
		$display("R15 = %x", reg_file[15].val);
		$display("RFLAGS = %x", reg_file[16].val);
		$display("RHA = %x", reg_file[17].val);
		$display("RHB = %x", reg_file[18].val);
		$display("RHC = %x", reg_file[19].val);
endfunction

endpackage
