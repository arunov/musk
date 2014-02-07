#include "Vtop.h"
#include "verilated.h"
#include "system.h"
#if VM_TRACE
# include <verilated_vcd_c.h>	// Trace file format header
#endif

vluint64_t main_time = 0;	// Current simulation time (64-bit unsigned)

double sc_time_stamp() {
	return main_time;
}

int main(int argc, char* argv[]) {
	Verilated::commandArgs(argc, argv);
	const int ps_per_clock = 500;

	const char* ramelf = NULL;
	if (argc>0) ramelf = argv[1];

	Vtop top;
	System sys(&top, 1*G, ramelf, ps_per_clock);

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

	while(main_time/ps_per_clock < 10*K && !Verilated::gotFinish()) {
		TICK();
	}

#if VM_TRACE
	if (tfp) tfp->close();
	delete tfp;
#endif

	return 0;
}
