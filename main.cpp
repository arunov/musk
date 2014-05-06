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
