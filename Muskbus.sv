/* verilator lint_off UNUSED */
interface Muskbus;

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
