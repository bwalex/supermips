HDL_BASE?=../hdl
SIM_BASE?=../sim
SOFTWARE_BASE?=../software
TRICK_ITERATIONS?=100
PROG?=coremark.vmem
MEM_FILE?="\"$(SOFTWARE_BASE)/$(PROG)\""
VCS_FLAGS?=
TRACE?=DISABLE
EX_UNITS?=1
IQ_DEPTH?=16
ROB_DEPTH?=32
ROB_FORWARDING?=ENABLE
RETIRE_COUNT?=4

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
	@echo assign $(MEM_FILE)     top/MEM_FILE      > .vcs.params
	@echo assign $(EX_UNITS)     top/EX_UNITS     >> .vcs.params
	@echo assign $(IQ_DEPTH)     top/IQ_DEPTH     >> .vcs.params
	@echo assign $(ROB_DEPTH)    top/ROB_DEPTH    >> .vcs.params
	@echo assign $(RETIRE_COUNT) top/RETIRE_COUNT >> .vcs.params
	vcs $(VCS_FLAGS) -sverilog \
		+define+REAL_CACHE \
		+define+ROB_TRACE_$(TRACE) \
		+define+IQ_TRACE_$(TRACE) \
		+define+ISS_TRACE_$(TRACE) \
		+define+ID_TRACE_$(TRACE) \
		+define+LS_TRACE_$(TRACE) \
		+define+CACHE_TRACE_$(TRACE) \
		+define+ROB_FORWARDING_$(ROB_FORWARDING) \
		-parameters ./.vcs.params \
		-pvalue+top/CPU/LS/MEM/trickbox/ITERATIONS=$(TRICK_ITERATIONS) \
		$(SIM_BASE)/vcs_helpers.sv \
		$(HDL_BASE)/top.sv \
		$(HDL_BASE)/types.sv \
		$(HDL_BASE)/generic_shifter.sv \
		$(HDL_BASE)/ex.sv \
		$(HDL_BASE)/exmul.sv \
		$(HDL_BASE)/idec.sv \
		$(HDL_BASE)/ifetch.sv \
		$(HDL_BASE)/agu.sv \
		$(HDL_BASE)/mem.sv \
		$(HDL_BASE)/pipeline.sv \
		$(HDL_BASE)/rfile.sv \
		$(HDL_BASE)/tcm.sv \
		$(HDL_BASE)/memory.sv \
		$(HDL_BASE)/cache.sv \
		$(HDL_BASE)/mem_arb.sv \
		$(HDL_BASE)/trickbox.sv \
		$(HDL_BASE)/ex_wrapper.sv \
		$(HDL_BASE)/ex_mul_wrapper.sv \
		$(HDL_BASE)/ls_wrapper.sv \
		$(HDL_BASE)/circ_buf.sv \
		$(HDL_BASE)/rob.sv \
		$(HDL_BASE)/id.sv \
		$(HDL_BASE)/iss.sv \
		$(HDL_BASE)/wb.sv
	./simv

vcs_clean:
	rm -rf simv DVEfiles inter.vpd csrc simv.daidir simv.vdb ucli.key

ncv:
	ncverilog -sv +access+rc +gui +ncaccess+rc \
		+define+REAL_CACHE \
		+define+ROB_TRACE_$(TRACE) \
		+define+IQ_TRACE_$(TRACE) \
		+define+ISS_TRACE_$(TRACE) \
		+define+ID_TRACE_$(TRACE) \
		+define+LS_TRACE_$(TRACE) \
		+define+CACHE_TRACE_$(TRACE) \
		+define+ROB_FORWARDING_$(ROB_FORWARDING) \
		+defparam+top.CPU.MEM.trickbox.ITERATIONS=$(TRICK_ITERATIONS) \
		+defparam+top.MEM_FILE=$(MEM_FILE) \
		+defparam+top.EX_UNITS=$(EX_UNITS) \
		+defparam+top.IQ_DEPTH=$(IQ_DEPTH) \
		+defparam+top.ROB_DEPTH=$(ROB_DEPTH) \
		+defparam+top.RETIRE_COUNT=$(RETIRE_COUNT) \
		$(SIM_BASE)/ncv_helpers.sv \
		$(HDL_BASE)/top.sv \
		$(HDL_BASE)/types.sv \
		$(HDL_BASE)/generic_shifter.sv \
		$(HDL_BASE)/ex.sv \
		$(HDL_BASE)/exmul.sv \
		$(HDL_BASE)/idec.sv \
		$(HDL_BASE)/ifetch.sv \
		$(HDL_BASE)/agu.sv \
		$(HDL_BASE)/mem.sv \
		$(HDL_BASE)/pipeline.sv \
		$(HDL_BASE)/rfile.sv \
		$(HDL_BASE)/tcm.sv \
		$(HDL_BASE)/memory.sv \
		$(HDL_BASE)/cache.sv \
		$(HDL_BASE)/mem_arb.sv \
		$(HDL_BASE)/trickbox.sv \
		$(HDL_BASE)/ex_wrapper.sv \
		$(HDL_BASE)/ex_mul_wrapper.sv \
		$(HDL_BASE)/ls_wrapper.sv \
		$(HDL_BASE)/circ_buf.sv \
		$(HDL_BASE)/rob.sv \
		$(HDL_BASE)/id.sv \
		$(HDL_BASE)/iss.sv \
		$(HDL_BASE)/wb.sv

ncv_batch:
	ncverilog -sv +access+r +ncbatch \
		+define+REAL_CACHE \
		+define+ROB_TRACE_$(TRACE) \
		+define+IQ_TRACE_$(TRACE) \
		+define+ISS_TRACE_$(TRACE) \
		+define+ID_TRACE_$(TRACE) \
		+define+LS_TRACE_$(TRACE) \
		+define+CACHE_TRACE_$(TRACE) \
		+define+ROB_FORWARDING_$(ROB_FORWARDING) \
		+defparam+top.CPU.MEM.trickbox.ITERATIONS=$(TRICK_ITERATIONS) \
		+defparam+top.MEM_FILE=$(MEM_FILE) \
		+defparam+top.EX_UNITS=$(EX_UNITS) \
		+defparam+top.IQ_DEPTH=$(IQ_DEPTH) \
		+defparam+top.ROB_DEPTH=$(ROB_DEPTH) \
		+defparam+top.RETIRE_COUNT=$(RETIRE_COUNT) \
		$(SIM_BASE)/ncv_helpers.sv \
		$(HDL_BASE)/top.sv \
		$(HDL_BASE)/types.sv \
		$(HDL_BASE)/generic_shifter.sv \
		$(HDL_BASE)/ex.sv \
		$(HDL_BASE)/exmul.sv \
		$(HDL_BASE)/idec.sv \
		$(HDL_BASE)/ifetch.sv \
		$(HDL_BASE)/agu.sv \
		$(HDL_BASE)/mem.sv \
		$(HDL_BASE)/pipeline.sv \
		$(HDL_BASE)/rfile.sv \
		$(HDL_BASE)/tcm.sv \
		$(HDL_BASE)/memory.sv \
		$(HDL_BASE)/cache.sv \
		$(HDL_BASE)/mem_arb.sv \
		$(HDL_BASE)/trickbox.sv \
		$(HDL_BASE)/ex_wrapper.sv \
		$(HDL_BASE)/ex_mul_wrapper.sv \
		$(HDL_BASE)/ls_wrapper.sv \
		$(HDL_BASE)/circ_buf.sv \
		$(HDL_BASE)/rob.sv \
		$(HDL_BASE)/id.sv \
		$(HDL_BASE)/iss.sv \
		$(HDL_BASE)/wb.sv


ncv_clean:
	rm -rf INCA_libs ncverilog.key ncverilog.log simvision* waves.shm


clean: modelsim_clean ncv_clean
	@echo "Clean!"

realclean: clean
	rm -f *~ *.bak
	rm -f modelsim.ini
