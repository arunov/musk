#ifndef __SYSTEM_H
#define __SYSTEM_H
#include <map>
#include <list>
#include <queue>
#include "Vtop.h"
#include "dramsim2/DRAMSim.h"

typedef unsigned long __uint64_t;
typedef __uint64_t uint64_t;
typedef unsigned int __uint32_t;
typedef __uint32_t uint32_t;
typedef int __int32_t;
typedef __int32_t int32_t;
typedef unsigned short __uint16_t;
typedef __uint16_t uint16_t;

#define K (1024ULL)
#define M (1024ULL*1024)
#define G (1024ULL*1024*1024)

extern uint64_t main_time;
extern const int ps_per_clock;
double sc_time_stamp();

class System {
	Vtop* top;

	char* ram;
	unsigned int ramsize;
	uint64_t max_elf_addr;

	enum { IRQ_TIMER=0, IRQ_KBD=1 };
	int interrupts;
	std::queue<char> keys;

	bool show_console;

	uint64_t load_elf(const char* filename);

	int cmd, rx_count;
	uint64_t xfer_addr;
	std::map<uint64_t, int> addr_to_tag;
	std::list<std::pair<uint64_t, int> > tx_queue;

	void dram_read_complete(unsigned id, uint64_t address, uint64_t clock_cycle);
	void dram_write_complete(unsigned id, uint64_t address, uint64_t clock_cycle);
	DRAMSim::MultiChannelMemorySystem* dramsim;
public:
	System(Vtop* top, uint64_t ramsize, const char* ramelf, int ps_per_clock);
	void console();
	~System();

	void tick(int clk);
	uint64_t get_ram_address() { return (uint64_t)ram; }
	uint64_t get_max_elf_addr() {
		max_elf_addr = ((max_elf_addr+4095)/4096)*4096;
		return max_elf_addr;
	}
};

#endif
