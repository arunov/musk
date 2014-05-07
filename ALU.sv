package ALU;

import DecoderTypes::*;
import RegMap::*;

function automatic logic parity(logic[7:0] val);
	return ~(val[7] ^ val[6] ^ val[5] ^ val[4] ^ val[3] ^ val[2] ^ val[1] ^ val[0]);
endfunction

function automatic logic[127:0] signed_mul(logic[63:0] v0, logic[63:0] v1);
	logic [63:0] zeros = 64'h0;
	logic [63:0] ones = ~zeros;
	signed logic[127:0] sv0 = v0[63] == 0 ? {zeros, v0} : {ones, v0};
	signed logic[127:0] sv1 = v1[63] == 0 ? {zeros, v1} : {ones, v1};
	signed logic[127:0] res = sv0 * sv1;
	return res;
endfunction

function automatic logic signed_mul_has_carry(logic[127:0] val);
	logic [63:0] zeros = 64'h0;
	logic [63:0] ones = ~zeros;
	if (val[127:64] != zeros && val[127:64] != ones) return 1;
	if (val[127:64] == zeros && val[63] == 1) return 1;
	if (val[127:64] == ones && val[63] == 0) return 1;
	return 0;
endfunction

/** macros used by entry points **/
`define COMFUN(opc) \
function automatic reg_val_t compute_``opc(/* verilator lint_off UNUSED */ micro_op_t mop /* verilator lint_on UNUSED */); \
	reg_val_t res = 0;

`define ENDCOMFUN return res; endfunction

/** start of entry points **/
COMFUN(m_lea)
	res.val = mop.src0_val.val + (mop.src1_val.val << mop.scale) + mop.disp;
ENDCOMFUN

COMFUN(m_cpy)
	res.val = mop.src0_val.val;
ENDCOMFUN

COMFUN(m_cpy_f)
	// combine the value of src0 and flags of src1
	res = mop.src1_val;
	res.val = mop.src0_val.val;
ENDCOMFUN

COMFUN(m_add)
	logic [64:0] rw    = {1'b0, mop.src0_val.val} + {1'b0, mop.src1_val.val};
	logic [4:0]  bcdrw = {1'b0, v0[3:0]} + {1'b0, v1[3:0]};
	res.val = rw[63:0];
	res.cf  = rw[64] == 1;
	res.zf  = res.val == 0;
	res.sf  = res.val[63];
	res.pf  = parity(res.val[7:0]);
	res.af  = bcdrw[4] == 1;
	res.of  = rw[63] != rw[64];
ENDCOMFUN

COMFUN(m_sub)
	logic [64:0] rw    = {1'b0, mop.src0_val.val} - {1'b0, mop.src1_val.val};
	logic [4:0]  bcdrw = {1'b0, v0[3:0]} - {1'b0, v1[3:0]};
	res.val = rw[63:0];
	res.cf  = rw[64] == 1;
	res.zf  = res.val == 0;
	res.sf  = res.val[63];
	res.pf  = parity(res.val[7:0]);
	res.af  = bcdrw[4] == 1;
	res.of  = rw[63] != rw[64];
ENDCOMFUN

COMFUN(m_and)
	logic[63:0] r = mop.src0_val.val & mop.src1_val.val;
	res.val = r;
	res.cf = 0;
	res.zf = r == 0;
	res.sf = r[63];
	res.pf = parity(r[7:0]);
	res.af = 0;
	res.of = 0;
ENDCOMFUN

COMFUN(m_or)
	logic[63:0] r = mop.src0_val.val | mop.src1_val.val;
	res.val = r;
	res.cf = 0;
	res.zf = r == 0;
	res.sf = r[63];
	res.pf = parity(r[7:0]);
	res.af = 0;
	res.of = 0;
ENDCOMFUN

COMFUN(m_xor)
	logic[63:0] r = mop.src0_val.val ^ mop.src1_val.val;
	res.val = r;
	res.cf = 0;
	res.zf = r == 0;
	res.sf = r[63];
	res.pf = parity(r[7:0]);
	res.af = 0;
	res.of = 0;
ENDCOMFUN

COMFUN(m_shl)
	logic[5:0] cnt = mop.src1_val.val[5:0];
	if (cnt == 0) begin
		res = mop.src0_val;
	end else begin
		logic[64:0] rw = {1'b0, mop.src0_val.val} << cnt;
		res.val = rw[63:0];
		res.cf  = rw[64];
		res.zf  = res.val == 0;
		res.sf  = res.val[63];
		res.pf  = parity(res.val[7:0]);
		res.af  = 0;
		res.of  = cnt == 1 ? res.val[63] ^ res.cf : 0;
	end
ENDCOMFUN

COMFUN(m_shr)
	logic[5:0] cnt = mop.src1_val.val[5:0];
	if (cnt == 0) begin
		res = mop.src0_val;
	end else begin
		logic[64:0] rw = {mop.src0_val.val, 1'b0} >> cnt;
		res.val = rw[64:1];
		res.cf  = rw[0];
		res.zf  = res.val == 0;
		res.sf  = res.val[63];
		res.pf  = parity(res.val[7:0]);
		res.af  = 0;
		res.of  = cnt == 1 ? mop.src0_val.val[63] : 0;
	end
ENDCOMFUN

COMFUN(m_imul_l)
	logic[127:0] rw = signed_mul(mop.src0_val.val, mop.src1_val.val);
	res.val = rw[63:0];
	res.cf = signed_mul_has_carry(rw);
	res.zf = 0;
	res.sf = 0;
	res.pf = 0;
	res.af = 0;
	res.of = res.cf;
ENDCOMFUN

COMFUN(m_imul_h)
	logic[127:0] rw = signed_mul(mop.src0_val.val, mop.src1_val.val);
	res.val = rw[127:64];
	res.cf = signed_mul_has_carry(rw);
	res.zf = 0;
	res.sf = 0;
	res.pf = 0;
	res.af = 0;
	res.of = res.cf;
ENDCOMFUN

/** end of entry points **/

`define COMPUTE(opc) opc : res_mop.dst_val = compute_``opc(mop);

function automatic micro_op_t alu(/* verilator lint_off UNUSED */ micro_op_t mop /* verilator lint_on UNUSED */); 

	micro_op_t res_mop = mop;

	case (mop.opcode)
		COMPUTE(m_lea)
		COMPUTE(m_cpy)
		COMPUTE(m_cpy_f)
		COMPUTE(m_add)
		COMPUTE(m_and)
		COMPUTE(m_or)
		COMPUTE(m_shl)
		COMPUTE(m_shr)
		COMPUTE(m_sub)
		COMPUTE(m_xor)
		COMPUTE(m_imul_l)
		COMPUTE(m_imul_h)
		default : begin
			$display("ERROR: alu: unsupported opcode: %x", mop.opcode);
			$finish;
		end
	endcase

	return res_mop;

endfunction

endpackage
