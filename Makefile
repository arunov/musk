.PHONY: run clean

RUNELF=$(PWD)/prog2

TRACE=--trace

VFILES=$(wildcard *.sv)
CFILES=$(wildcard *.cpp)

obj_dir/Vtop: obj_dir/Vtop.mk
	$(MAKE) -j2 -C obj_dir/ -f Vtop.mk CXX="ccache g++"

obj_dir/Vtop.mk: $(VFILES) $(CFILES)
	verilator -Wall -Wno-LITENDIAN -O3 $(TRACE) --no-skip-identical --cc top.sv --exe $(CFILES) ../dramsim2/libdramsim.so -LDFLAGS -Wl,-rpath=../dramsim2/

run: obj_dir/Vtop
	cd obj_dir/ && ./Vtop $(RUNELF)

clean:
	rm -rf obj_dir/
