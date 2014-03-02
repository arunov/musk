module SRAM(input[width-1:0] writeData, output[width-1:0] readData, input[logDepth-1:0] writeAddr, input[logDepth-1:0] readAddr, input writeEnable, input clk);
	parameter width=16, logDepth=9, ports=1, delay=(logDepth-8>0?logDepth-8:1)*(ports>1?(ports>2?(ports>3?100:20):14):10)/10-1;

	logic[width-1:0] mem[(1<<logDepth)-1:0];

	logic[width-1:0] readpipe[delay-1];

	initial begin
		$display("Initializing %0dKB (%0dx%0d) memory, delay = %0d", (width+7)/8*(1<<logDepth)/1024, width, (1<<logDepth), delay);
		assert(ports == 1) else $fatal("multi-ported SRAM not supported");
	end

	always @ (posedge clk) begin
		if (delay > 0) begin
			readpipe[0] <= mem[readAddr];
			for(int i=1; i<delay; ++i) readpipe[i] <= readpipe[i-1];
			readData <= readpipe[delay-1];
		end else
		begin
			readData <= mem[readAddr];
		end
		if (writeEnable)
			mem[writeAddr] <= writeData;
	end
endmodule
