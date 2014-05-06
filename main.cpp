#include <iostream>
#include <string.h>
#include "Vtop.h"
#include "verilated.h"
#include "system.h"
#if VM_TRACE
# include <verilated_vcd_c.h>	// Trace file format header
#endif

char *global_ram;
uint64_t global_ramsize;
uint64_t global_ram_brkptr;

int main(int argc, char* argv[]) {
	Verilated::commandArgs(argc, argv);

	const char* ramelf = NULL;
	if (argc>0) ramelf = argv[1];

	Vtop top;
	System sys(&top, 1*G, ramelf, ps_per_clock);

	global_ram = (char *)sys.get_ram_address();
	global_ramsize = 1*G;
	global_ram_brkptr = sys.get_max_elf_addr();

	// adding program arguments
	uint64_t rsp_offset = 0x7C00;
	uint64_t args_bump_ptr = 0x8000;
	int i;
	*(uint64_t *)(global_ram+rsp_offset) = argc-1;	/* argc */
	rsp_offset += 8;
	for (i=0; i<(argc-1); i++) {
		strcpy(global_ram+args_bump_ptr, argv[i+1]);
		*(uint64_t *)(global_ram+rsp_offset+i*8) = args_bump_ptr;	/* argv[i] */
		args_bump_ptr += ((strlen(argv[i+1])+16)&(~7));
	}
	*(uint64_t *)(global_ram+rsp_offset+i*8) = 0;	/* last argument */

	//cerr << "Printing all arguments..." << endl;
	//for (int j=0; j<argc; j++) {
	//	cerr << argv[j] << endl;
	//}
	cerr << "Printing all arguments of program..." << endl;
	for (int j=0; j<argc-1; j++) {
		cerr << hex << (char *)(*(uint64_t *)(global_ram+rsp_offset+j*8)+(uint64_t)global_ram) << endl;
		// cerr << (char *)*((uint64_t *)(global_ram+rsp_offset) + j) << endl;
	}

	VerilatedVcdC* tfp = NULL;
#if VM_TRACE			// If verilator was invoked with --trace
	Verilated::traceEverOn(true);
	VL_PRINTF("Enabling waves...\n");
	tfp = new VerilatedVcdC;
	assert(tfp);
	top.trace (tfp, 99);	// Trace 99 levels of hierarchy
	tfp->spTrace()->set_time_resolution("1 ps");
	tfp->open ("../trace.vcd");	// Open the dump file
#endif

#define TICK() do {                    \
		top.clk = !top.clk;                \
		top.eval();                        \
		if (tfp) tfp->dump(main_time);     \
		main_time += ps_per_clock/4;       \
		sys.tick(top.clk);                 \
		top.eval();                        \
		if (tfp) tfp->dump(main_time);     \
		main_time += ps_per_clock/4;       \
	} while(0)

	top.reset = 1;
	top.clk = 0;
	TICK(); // 1
	TICK(); // 0
	TICK(); // 1
	top.reset = 0;

	const char* SHOWCONSOLE = getenv("SHOWCONSOLE");
	if (SHOWCONSOLE?(atoi(SHOWCONSOLE)!=0):0) sys.console();

	while(main_time/ps_per_clock < 2000*K && !Verilated::gotFinish()) {
		TICK();
	}

	top.final();

#if VM_TRACE
	if (tfp) tfp->close();
	delete tfp;
#endif

	return 0;
}
