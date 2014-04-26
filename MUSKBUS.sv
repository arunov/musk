/* verilator lint_off UNUSED */
package MUSKBUS;

parameter
	READ = 1'b1,
	WRITE = 1'b0,
	MEMORY = 4'b0001,
	MMIO = 4'b0011,
	PORT = 4'b0100,
	IRQ = 4'b1110,
	READ_MEM_TAG = { READ, MEMORY, 8'b0 },
	WRITE_MEM_TAG = { WRITE, MEMORY, 8'b0 };

endpackage

/* verilator lint_off DECLFILENAME */
interface Muskbus;
/* verilator lint_on DECLFILENAME */

logic [63:0] req;
logic [12:0] reqtag;
logic [63:0] resp;
logic reqcyc;
logic respcyc;
logic reqack;
logic respack;
logic bid;

modport Top (
	input bid
,	input req
,	input reqtag
,	output resp
,	input reqcyc
,	output respcyc
,	output reqack
,	input respack
);

modport Bottom (
	output bid
,	output req
,	output reqtag
,	input resp
,	output reqcyc
,	input respcyc
,	input reqack
,	output respack
);

endinterface
/* verilator lint_on UNUSED */
