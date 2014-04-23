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
