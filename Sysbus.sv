/* verilator lint_off UNDRIVEN */
/* verilator lint_off UNUSED */
interface Sysbus #(DATA_WIDTH = 64, TAG_WIDTH = 1) (
	input reset
,	input clk
);


wire[DATA_WIDTH-1:0] req;
wire[TAG_WIDTH-1:0] reqtag;
wire[DATA_WIDTH-1:0] resp;
wire[TAG_WIDTH-1:0] resptag;
wire reqcyc;
wire respcyc;
wire reqack;
wire respack;

parameter
	READ   /* verilator public */ = 1'b1
,	WRITE  /* verilator public */ = 1'b0
,	MEMORY /* verilator public */ = 4'b0001
,	MMIO   /* verilator public */ = 4'b0011
,	PORT   /* verilator public */ = 4'b0100
,	IRQ    /* verilator public */ = 4'b1110;

modport Top (
	input reset
,	input clk
,	input req
,	input reqtag
,	output resp
,	output resptag
,	input reqcyc
,	output respcyc
,	output reqack
,	input respack
);

modport Bottom (
	input reset
,	input clk
,	output req
,	output reqtag
,	input resp
,	input resptag
,	output reqcyc
,	input respcyc
,	input reqack
,	output respack
);

endinterface

/* verilator lint_off DECLFILENAME */
module SysbusBottom #(DATA_WIDTH = 64, TAG_WIDTH = 1) (
/* verilator lint_on DECLFILENAME */
	Sysbus bus
,	output[DATA_WIDTH-1:0] req
,	output[TAG_WIDTH-1:0] reqtag
,	input[DATA_WIDTH-1:0] resp
,	input[TAG_WIDTH-1:0] resptag
,	output reqcyc
,	input respcyc
,	input reqack
,	output respack
);
	assign req = bus.req;
	assign reqtag = bus.reqtag;
	assign bus.resp = resp;
	assign bus.resptag = resptag;
	assign reqcyc = bus.reqcyc;
	assign bus.respcyc = respcyc;
	assign bus.reqack = reqack;
	assign respack = bus.respack;
endmodule
/* verilator lint_on UNUSED */
/* verilator lint_on UNDRIVEN */
