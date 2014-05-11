module SetAssocReadCache (
	input reset,
	input clk,
	/* verilator lint_off UNDRIVEN */
	/* verilator lint_off UNUSED */
	Muskbus.Top bus,
	/* verilator lint_on UNUSED */
	/* verilator lint_on UNDRIVEN */
	input logic reqcyc,
	/* verilator lint_off UNUSED */
	input logic [63:0] addr,
	/* verilator lint_on UNUSED */
	output logic respcyc,
	output logic [0:64*8-1] data
);
	parameter ways = 4
	,	indexBits = 10
	// TODO (2) necessitates defining numFrames rather than calculating it in code
	// numFrames = 2 to the power indexBits
	//,	numFrames = 1024
	// ----------------------------
	// number of bits for cache address = log(size/width)
	// size = ways * frames * block_size
	// width = 512
	,	cacheAddrSize = 9;

/*
 * N-way Set Associative Cache
 *
 * addr is divided into tag, index, and block offset.
 * block offset is fixed at 6 bits (block size = 64 bytes).
 * number of index bits is configurable.
 * upper remaining bits form tag.
 *
 * size of cache = ways * 2^indexBits * blockSize
 * 
 * size of cache has to be within 512 * 512 to avoid delay on cahce hit
 *
 * 512 * 512 <= ways * 2^indexBits * 64
 * 512 * 8 <= ways * 2^indexBits
 *
 * TODO (1) Check if cycles are being wasted!
 */

	`define frames (1 << indexBits)
	`define cache_frame_idx(way, frame) ((way) * `frames + (frame))
	`define cache_addr(way, frame) (`cache_frame_idx(way, frame) * 64)

	logic [cacheAddrSize-1:0] readAddr;
	logic [0:64*8-1] readData;
	logic [cacheAddrSize-1:0] writeAddr;
	logic [0:64*8-1] writeData;
	logic [7:0] writeEnable;

	SRAM #(.logDepth(cacheAddrSize))
	cache(clk, reset, readAddr, readData, writeAddr, writeData, writeEnable);

	enum {idle, read_cache, write_cache} state, state_cb;

	typedef struct packed {
		logic present;
		logic [63-(indexBits+6):0] tag;
	} metadata_t;

	//metadata_t metadate_zero = {0,0};

	metadata_t metadata[ways:0][`frames-1:0];
	int rrcounter, rrcounter_cb;
	logic cache_hit;
	logic [indexBits-1:0] index;
	assign index = addr[indexBits+5:6];
	logic [63-(indexBits+6):0] reqtag;
	assign reqtag = addr[63:(indexBits+6)];

	logic memreqcyc;
	logic [63:0] memaddr;
	logic memrespcyc;
	logic [0:64*8-1] memdata;
	MuskbusReader memaccess(reset, clk, bus, memreqcyc, memaddr, memrespcyc, memdata);

	always_ff @ (posedge clk) begin
		if(reset) begin
			// TODO (2) Unsupported: Delayed assignment to array inside for loops (non-delayed is ok - see docs)
			// Related but not quite!: http://www.veripool.org/issues/677-Verilator-unable-to-unroll-for-loop-causing-BLKLOOPINIT-error
			// Solution: Moved reset code to always_comb
			/*
			int wi;
			int fi;
			for(wi = 0; wi < ways; wi ++) begin
				for(fi = 0; fi < numFrames * ways; ++fi) begin
					metadata[wi][fi].present <= 1'b0;
				end
			end
			*/
			rrcounter <= 0;
			state <= idle;
		end
		else begin
			rrcounter <= rrcounter_cb;
			state <= state_cb;
			respcyc <= 1'b0;
			if(state == idle && reqcyc) begin
				state <= read_cache;
			end
			if(state_cb == read_cache && cache_hit) begin
				respcyc <= 1'b1;
			end
		end
	end

	always_comb begin
		int free_way_num = 0;
		writeEnable = 8'b0;
		cache_hit = 1'b0;
		memreqcyc = 1'b0;
		state_cb = state;
		rrcounter_cb = rrcounter;
		if(reset) begin
			int wi, fi;
			//$display("reset");
			for(wi = 0; wi < ways; wi ++) begin
				for(fi = 0; fi < `frames; fi ++) begin
					metadata[wi][fi].present = 1'b0;
				end
			end
		end
		else begin
			unique case(state_cb)
				read_cache: begin
					int wi;
					logic [cacheAddrSize-1:0] cacheAddr;
					if(respcyc) begin
						state_cb = idle;
					end
					for(wi = 0; wi < ways; wi ++) begin
						if(metadata[wi][index].present && (metadata[wi][index].tag == reqtag))
						begin
							/* verilator lint_off WIDTH */
							cacheAddr = `cache_addr(wi, index);
							/* verilator lint_on WIDTH */
							readAddr = cacheAddr;
							data = readData;
							cache_hit = 1'b1;
						end
					end

					if(!cache_hit) begin
						logic free_way_found = 1'b0;
						for(wi = 0; wi < ways; wi ++) begin
							if(metadata[wi][index].present == 1'b0) begin
								//$display("free way found, way %d, index %x", wi, index);
								free_way_found = 1'b1;
								free_way_num = wi;
							end
						end

						if(!free_way_found) begin
							free_way_found = 1'b1;
							free_way_num = rrcounter % ways;
							rrcounter_cb = rrcounter + 1;
							//$display("free way not found, way %d, index %x", free_way_num, index);
						end

						if(!cache_hit && free_way_found) begin
							state_cb = write_cache;
							memaddr = {addr[63:6], 6'h0};
							/* verilator lint_off WIDTH */
							cacheAddr = `cache_addr(free_way_num, index);
							/* verilator lint_on WIDTH */
							memreqcyc = 1'b1;
						end
					end
				end
				write_cache: begin
					if(memrespcyc) begin
						logic [cacheAddrSize-1:0] cacheAddr;
						/* verilator lint_off WIDTH */
						cacheAddr = `cache_addr(free_way_num, index);
						/* verilator lint_on WIDTH */
						writeAddr = cacheAddr;
						writeData = memdata;
						writeEnable = 8'b11111111;
						metadata[free_way_num][index].tag = reqtag;
						metadata[free_way_num][index].present = 1'b1;
						state_cb = read_cache;
					end
				end
				default: begin
					state_cb = state;
				end
			endcase
		end
	end
endmodule
