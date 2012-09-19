HDL_BASE?=../hdl
SIM_BASE?=../sim
SOFTWARE_BASE?=../software
TRICK_ITERATIONS?=100
PROG?=coremark.vmem
MEM_FILE?="\"$(SOFTWARE_BASE)/$(PROG)\""
VCS_FLAGS?=
TRACE?=DISABLE
CACHE?=REAL

all:
	echo "Targets: ncv, ncv_batch, modelsim, vcs"

modelsim:
	qhsim -do "source load_sim.tcl"

modelsim_clean:
	rm -f vsim.wlf transcript
	rm -rf libraries

vcs:
	# Not including text_idec, as it VCS doesn't support a string as a non-ref port
	#
	# For some weird reason, vcs doesn't like overriding string parameters via
	# -pvalue; not even after escaping the string all over.
	@echo assign $(MEM_FILE) top/MEM_FILE > .vcs.params
	vcs $(VCS_FLAGS) -sverilog \
		+define+$(CACHE)_CACHE \
		+define+TRACE_$(TRACE) \
		-parameters ./.vcs.params \
		-pvalue+top/CPU/MEM/trickbox/ITERATIONS=$(TRICK_ITERATIONS) \
		$(SIM_BASE)/vcs_helpers.sv \
		$(HDL_BASE)/top.sv \
		$(HDL_BASE)/types.sv \
		$(HDL_BASE)/generic_shifter.sv \
		$(HDL_BASE)/ex.sv \
		$(HDL_BASE)/idec.sv \
		$(HDL_BASE)/ifetch.sv \
		$(HDL_BASE)/mem.sv \
		$(HDL_BASE)/pipeline.sv \
		$(HDL_BASE)/pipreg_ex_mem.sv \
		$(HDL_BASE)/pipreg_id_ex.sv \
		$(HDL_BASE)/pipreg_if_id.sv \
		$(HDL_BASE)/pipreg_mem_wb.sv \
		$(HDL_BASE)/rfile.sv \
		$(HDL_BASE)/tcm.sv \
		$(HDL_BASE)/memory.sv \
		$(HDL_BASE)/cache.sv \
		$(HDL_BASE)/mem_arb.sv \
		$(HDL_BASE)/trickbox.sv \
		$(HDL_BASE)/wb.sv
	./simv


vcs_coverage:
	# Not including text_idec, as it VCS doesn't support a string as a non-ref port
	#
	# For some weird reason, vcs doesn't like overriding string parameters via
	# -pvalue; not even after escaping the string all over.
	@echo assign $(MEM_FILE) top/MEM_FILE > .vcs.params
	vcs $(VCS_FLAGS) -sverilog \
		-cm line \
		-cm cond \
		-cm branch \
		-cm tgl \
		+define+$(CACHE)_CACHE \
		+define+TRACE_$(TRACE) \
		-parameters ./.vcs.params \
		-pvalue+top/CPU/MEM/trickbox/ITERATIONS=$(TRICK_ITERATIONS) \
		$(SIM_BASE)/vcs_helpers.sv \
		$(HDL_BASE)/top.sv \
		$(HDL_BASE)/types.sv \
		$(HDL_BASE)/generic_shifter.sv \
		$(HDL_BASE)/ex.sv \
		$(HDL_BASE)/idec.sv \
		$(HDL_BASE)/ifetch.sv \
		$(HDL_BASE)/mem.sv \
		$(HDL_BASE)/pipeline.sv \
		$(HDL_BASE)/pipreg_ex_mem.sv \
		$(HDL_BASE)/pipreg_id_ex.sv \
		$(HDL_BASE)/pipreg_if_id.sv \
		$(HDL_BASE)/pipreg_mem_wb.sv \
		$(HDL_BASE)/rfile.sv \
		$(HDL_BASE)/tcm.sv \
		$(HDL_BASE)/memory.sv \
		$(HDL_BASE)/cache.sv \
		$(HDL_BASE)/mem_arb.sv \
		$(HDL_BASE)/trickbox.sv \
		$(HDL_BASE)/wb.sv
	./simv -cm line -cm cond -cm branch -cm tgl




vcs_clean:
	rm -rf simv DVEfiles inter.vpd csrc simv.daidir simv.vdb ucli.key

ncv:
	ncverilog -sv +access+rc +gui +ncaccess+rc \
		+define+TEXT_IDEC_ENABLE \
		+define+TRACE_$(TRACE) \
		+define+$(CACHE)_CACHE \
		+defparam+top.CPU.MEM.trickbox.ITERATIONS=$(TRICK_ITERATIONS) \
		+defparam+top.MEM_FILE=$(MEM_FILE) \
		+tcl+ncv.tcl \
		$(SIM_BASE)/ncv_helpers.sv \
		$(HDL_BASE)/types.sv \
		$(HDL_BASE)/top.sv \
		$(HDL_BASE)/text_idec.sv \
		$(HDL_BASE)/generic_shifter.sv \
		$(HDL_BASE)/ex.sv \
		$(HDL_BASE)/idec.sv \
		$(HDL_BASE)/ifetch.sv \
		$(HDL_BASE)/mem.sv \
		$(HDL_BASE)/pipeline.sv \
		$(HDL_BASE)/pipreg_ex_mem.sv \
		$(HDL_BASE)/pipreg_id_ex.sv \
		$(HDL_BASE)/pipreg_if_id.sv \
		$(HDL_BASE)/pipreg_mem_wb.sv \
		$(HDL_BASE)/rfile.sv \
		$(HDL_BASE)/tcm.sv \
		$(HDL_BASE)/memory.sv \
		$(HDL_BASE)/cache.sv \
		$(HDL_BASE)/mem_arb.sv \
		$(HDL_BASE)/trickbox.sv \
		$(HDL_BASE)/wb.sv

ncv_batch:
	ncverilog -sv +access+r +ncbatch \
		+define+TEXT_IDEC_$(TRACE) \
		+define+$(CACHE)_CACHE \
		+define+TRACE_$(TRACE) \
		+defparam+top.CPU.MEM.trickbox.ITERATIONS=$(TRICK_ITERATIONS) \
		+defparam+top.MEM_FILE=$(MEM_FILE) \
		$(SIM_BASE)/ncv_helpers.sv \
		$(HDL_BASE)/types.sv \
		$(HDL_BASE)/top.sv \
		$(HDL_BASE)/text_idec.sv \
		$(HDL_BASE)/generic_shifter.sv \
		$(HDL_BASE)/ex.sv \
		$(HDL_BASE)/idec.sv \
		$(HDL_BASE)/ifetch.sv \
		$(HDL_BASE)/mem.sv \
		$(HDL_BASE)/pipeline.sv \
		$(HDL_BASE)/pipreg_ex_mem.sv \
		$(HDL_BASE)/pipreg_id_ex.sv \
		$(HDL_BASE)/pipreg_if_id.sv \
		$(HDL_BASE)/pipreg_mem_wb.sv \
		$(HDL_BASE)/rfile.sv \
		$(HDL_BASE)/tcm.sv \
		$(HDL_BASE)/memory.sv \
		$(HDL_BASE)/cache.sv \
		$(HDL_BASE)/mem_arb.sv \
		$(HDL_BASE)/trickbox.sv \
		$(HDL_BASE)/wb.sv

ncv_clean:
	rm -rf INCA_libs ncverilog.key ncverilog.log simvision* waves.shm


clean: modelsim_clean ncv_clean
	@echo "Clean!"

realclean: clean
	rm -f *~ *.bak
	rm -f modelsim.ini
