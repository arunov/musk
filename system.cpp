#include <sys/mman.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>
#include <elf.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <assert.h>
#include <stdlib.h>
#include <iostream>
#include <arpa/inet.h>
#include <ncurses/ncurses.h>
#include "system.h"
#include "Vtop_top.h"

using namespace std;

#ifndef be32toh
#define be32toh(x)      ((u_int32_t)ntohl((u_int32_t)(x)))
#endif

static __inline__ u_int64_t cse502_be64toh(u_int64_t __x) { return (((u_int64_t)be32toh(__x & (u_int64_t)0xFFFFFFFFULL)) << 32) | ((u_int64_t)be32toh((__x & (u_int64_t)0xFFFFFFFF00000000ULL) >> 32)); }

uint64_t main_time = 0;	// Current simulation time (64-bit unsigned)
const int ps_per_clock = 500;
double sc_time_stamp() {
	return main_time;
}

uint64_t System::load_elf(const char* filename) {
	int fd = open(filename,O_RDONLY);
	assert(fd != -1);
	Elf64_Ehdr ehdr;
	assert(read(fd,(void*)&ehdr,sizeof(ehdr))==sizeof(ehdr));
	Elf64_Phdr phdr[10];
	int phnum = ehdr.e_phnum;
	assert(phnum < (sizeof(phdr)/sizeof(Elf64_Phdr)));
	assert(lseek(fd,ehdr.e_phoff,SEEK_SET)!=-1);
	assert(read(fd,(void*)&phdr,sizeof(phdr))==sizeof(phdr));
	for(int header=0; header<phnum ; ++header) {
		Elf64_Phdr *p = &phdr[header];
		if (p->p_type == PT_LOAD) {
			if ((p->p_vaddr + p->p_memsz) > ramsize) {
				cerr << "Not enough 'physical' ram" << endl;
				exit(-1);
			}
			memset(ram+p->p_vaddr,0,p->p_memsz);
			assert(lseek(fd,p->p_offset,SEEK_SET)!=-1);
			assert(read(fd,(void*)(ram+p->p_vaddr),p->p_filesz)==p->p_filesz);
			//cerr << "section flags " << hex << p->p_flags << endl;
		} else if (p->p_type == PT_GNU_STACK) {
			// do nothing
		} else if (p->p_type == 0x4) {
			// do nothing
		} else {
			cerr << "Unexpected ELF header " << p->p_type << endl;
			exit(-1);
		}
	}
	close(fd);
	return ehdr.e_entry;
}

void System::dram_read_complete(unsigned id, uint64_t address, uint64_t clock_cycle) {
	std::map<uint64_t, int>::iterator tag = addr_to_tag.find(address);
	assert(tag != addr_to_tag.end());
	for(int i=0; i<64; i+=8) {
		//cerr << "fill data from " << std::hex << (address+(i&63)) <<  ": " << tx_queue.rbegin()->first << " on tag " << tag->second << endl;
		tx_queue.push_back(make_pair(cse502_be64toh(*((uint64_t*)(&ram[((address&(~63))+((address+i)&63))]))),tag->second));	// critical word first
	}
	addr_to_tag.erase(tag);
}

void System::dram_write_complete(unsigned id, uint64_t address, uint64_t clock_cycle) {
}

System::System(Vtop* top, uint64_t ramsize, const char* ramelf, int ps_per_clock)
:	top(top)
,	ramsize(ramsize)
,	show_console(false)
{
	ram = (char*)malloc(ramsize);
	assert(ram);
	if (ramelf) top->entry = load_elf(ramelf);

	dramsim = DRAMSim::getMemorySystemInstance("DDR2_micron_16M_8b_x8_sg3E.ini", "system.ini", "../dramsim2", "dram_result", ramsize/M);
	DRAMSim::TransactionCompleteCB *read_cb = new DRAMSim::Callback<System, void, unsigned, uint64_t, uint64_t>(this, &System::dram_read_complete);
	DRAMSim::TransactionCompleteCB *write_cb = new DRAMSim::Callback<System, void, unsigned, uint64_t, uint64_t>(this, &System::dram_write_complete);
	dramsim->RegisterCallbacks(read_cb, NULL, NULL);
	dramsim->setCPUClockSpeed(1000ULL/ps_per_clock*1000*1000*1000);
}

void System::console() {
	show_console = true;
	if (show_console) {
		initscr();
		start_color();
		noecho();
		cbreak();
		timeout(0);
	}
}

System::~System() {
	free(ram);
	if (show_console) {
		sleep(2);
		endwin();
	}
}

enum {
	READ   = 0b1,
	WRITE  = 0b0,
	MEMORY = 0b0001,
	MMIO   = 0b0011,
	PORT   = 0b0100,
	IRQ    = 0b1110
};

void System::tick(int clk) {
	if (!clk) {
		if (top->reqcyc) {
			top->reqack = dramsim->willAcceptTransaction(); // hack: blocks ACK if /any/ memory channel can't accept transaction
			assert(!rx_count || top->reqack); // if trnasfer is in progress, can't change mind about willAcceptTransaction()
		}
		return;
	}

	if (main_time % (ps_per_clock * 1000) == 0) {
		int ch = getch();
		if (ch != ERR) {
			if (!(interrupts & (1<<IRQ_KBD))) {
				interrupts |= (1<<IRQ_KBD);
				tx_queue.push_back(make_pair(IRQ_KBD,(int)IRQ));
				keys.push(ch);
			}
		}
	}

	dramsim->update();
	if (!tx_queue.empty() && top->respack) tx_queue.pop_front();
	if (!tx_queue.empty()) {
		top->respcyc = 1;
		top->resp = tx_queue.begin()->first;
		top->resptag = tx_queue.begin()->second;
		//cerr << "responding data " << top->resp << " on tag " << std::hex << top->resptag << endl;
	} else {
		top->respcyc = 0;
		top->resp = 0xaaaaaaaaaaaaaaaaULL;
		top->resptag = 0xaaaa;
	}

	if (top->reqcyc) {
		cmd = (top->reqtag >> 8) & 0xf;
		if (rx_count) {
			switch(cmd) {
			case MEMORY:
				*((uint64_t*)(&ram[((xfer_addr&(~63))+((xfer_addr + ((8-rx_count)*8))&63))])) = cse502_be64toh(top->req);	// critical word first
				break;
			case MMIO:
				assert(xfer_addr < ramsize);
				*((uint64_t*)(&ram[xfer_addr])) = top->req;
				if (show_console)
					if ((xfer_addr - 0xb8000) < 80*25*2) {
						int screenpos = xfer_addr - 0xb8000;
						for(int shift = 0; shift < 8; shift += 2) {
							int val = (cse502_be64toh(top->req) >> (8*shift)) & 0xffff;
		//cerr << "val=" << std::hex << val << endl;
							attron(val & ~0xff);
							mvaddch(screenpos / 160, screenpos % 160 + shift/2, val & 0xff );
						}
						refresh();
					}
				break;
			}
			--rx_count;
			return;
		}
		bool isWrite = ((top->reqtag >> 12) & 1) == WRITE;
		if (cmd == MEMORY && isWrite) rx_count = 8;
		else if (cmd == MMIO && isWrite) rx_count = 1;
		else rx_count = 0;
		switch(cmd) {
		case MEMORY:
 			xfer_addr = top->req;
			assert(!(xfer_addr & 7));
			assert(
				dramsim->addTransaction(isWrite, xfer_addr)
			);
			//cerr << "add transaction " << std::hex << xfer_addr << " on tag " << top->reqtag << endl;
			if (!isWrite) addr_to_tag[xfer_addr] = top->reqtag;
			break;
		case MMIO:
			xfer_addr = top->req;
			assert(!(xfer_addr & 7));
			if (!isWrite) tx_queue.push_back(make_pair(*((uint64_t*)(&ram[xfer_addr])),top->reqtag)); // hack - real I/O takes time
			break;
		default:
			assert(0);
		};
	} else {
		top->reqack = 0;
		rx_count = 0;
	}
}
