HDL_BASE?=../../hdl

all:
	echo "Targets: sim"

vcs_coverage:
	vcs $(VCS_FLAGS) -sverilog \
		-cm line \
		-cm cond \
		-cm branch \
		-cm tgl \
		./cache_tb.sv \
		$(HDL_BASE)/cache.sv \
		$(HDL_BASE)/memory.sv
	./simv -cm line -cm cond -cm branch -cm tgl

sim:
	qhsim -do "source load_sim.tcl"

clean:
	rm -f vsim.wlf transcript
	rm -rf libraries

realclean: clean
	rm -f *~ *.bak
	rm -f modelsim.ini
