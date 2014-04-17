package MUSKBUS;

parameter
	READ = 1'b1,
	WRITE = 1'b0,
	MEMORY = 4'b0001,
	MMIO = 4'b0011,
	PORT = 4'b0100,
	IRQ = 4'b1110,
	DATA_WIDTH = 64,
	TAG_WIDTH = 13;
	READ_MEM_TAG = { READ, MEMORY, 8'b0 };
	WRITE_MEM_TAG = { WRITE, MEMORY, 8'b0 };

typedef struct packed {
	logic bid;
	logic reqcyc;
	logic [TAG_WIDTH-1:0] reqtag;
	logic [DATA_WIDTH-1:0] req;
} req_t;

typedef struct packed {
	logic respcyc;
	//logic [TAG_WIDTH-1:0] resptag;
	logic [DATA_WIDTH-1:0] resp;
} resp_t;

endpackage
