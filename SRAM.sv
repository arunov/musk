module SRAM(
    input                   clk
,   input   [logDepth-1:0]  readAddr
,   output  [   width-1:0]  readData
,   input   [logDepth-1:0]  writeAddr
,   input   [   width-1:0]  writeData
,   input   [width/wordsize-1:0]   writeEnable
);
	parameter   width   =512
    ,           logDepth=9
    ,           wordsize=64
    ,           ports   =1
    ,           delay   =(logDepth-8>0?logDepth-8:1)*(ports>1?(ports>2?(ports>3?100:20):14):10)/10-1;

	logic[width-1:0] mem[(1<<logDepth)-1:0];

	logic[width-1:0] readpipe[delay-1];

	initial begin
		$display("Initializing %0dKB (%0dx%0d) memory, delay = %0d", (width+7)/8*(1<<logDepth)/1024, width, (1<<logDepth), delay);
		assert(ports == 1) else $fatal("multi-ported SRAM not supported");
	end

	integer i;

	always @ (posedge clk) begin

		if (delay > 0)  begin
			readpipe[0]     <= mem[readAddr];
			readData        <= readpipe[delay-1];
			for(i=1; i<delay; ++i)
				readpipe[i] <= readpipe[i-1];
			end
		else            begin
			readData        <= mem[readAddr];
		end

		for ( i=0; i<width/wordsize; i=i+1 ) begin
			if (writeEnable[i]) begin
				mem[writeAddr][i*wordsize+:wordsize] <= writeData[i*wordsize+:wordsize];
			end
		end
	end
endmodule
