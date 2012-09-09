HDL_BASE?=../hdl
SIM_BASE?=../sim
SOFTWARE_BASE?=../software
TRICK_ITERATIONS?=100
PROG?=coremark.vmem
MEM_FILE?=$(SOFTWARE_BASE)/$(PROG)
VCS_FLAGS?=
TRACE?=DISABLE
EX_UNITS?=1
IQ_DEPTH?=16
ROB_DEPTH?=32
ROB_FORWARDING?=ENABLE
RETIRE_COUNT?=4
CACHE?=REAL
OOO?=DISABLE
FIVE_STAGE?=DISABLE
OUTPUT_DIR?=.

all:
	echo "Targets: ncv, ncv_batch, modelsim, vcs, vcs_coverage"

modelsim:
	qhsim -do "source load_sim.tcl"

modelsim_clean:
	rm -f vsim.wlf transcript modelsim.ini
	rm -rf libraries

out_dir:
	mkdir -p $(OUTPUT_DIR)
	echo "" > $(OUTPUT_DIR)/SETTINGS
	echo "MEM_FILE:       $(MEM_FILE)"          >> $(OUTPUT_DIR)/SETTINGS
	echo "ITERATIONS:     $(TRICK_ITERATIONS)"  >> $(OUTPUT_DIR)/SETTINGS
	echo "TRACE:          $(TRACE)"             >> $(OUTPUT_DIR)/SETTINGS
	echo "VCS_FLAGS:      $(VCS_FLAGS)"         >> $(OUTPUT_DIR)/SETTINGS
	echo "CACHE:          $(CACHE)"             >> $(OUTPUT_DIR)/SETTINGS
	echo "EX_UNITS:       $(EX_UNITS)"          >> $(OUTPUT_DIR)/SETTINGS
	echo "IQ_DEPTH:       $(IQ_DEPTH)"          >> $(OUTPUT_DIR)/SETTINGS
	echo "ROB_DEPTH:      $(ROB_DEPTH)"         >> $(OUTPUT_DIR)/SETTINGS
	echo "RETIRE_COUNT:   $(RETIRE_COUNT)"      >> $(OUTPUT_DIR)/SETTINGS
	echo "ROB_FORWARDING: $(ROB_FORWARDING)"    >> $(OUTPUT_DIR)/SETTINGS
	echo "OOO:            $(OOO)"               >> $(OUTPUT_DIR)/SETTINGS
	echo "FIVE_STAGE:     $(FIVE_STAGE)"        >> $(OUTPUT_DIR)/SETTINGS

vcs: out_dir
	# Not including text_idec, as it VCS doesn't support a string as a non-ref port
	#
	# For some weird reason, vcs doesn't like overriding string parameters via
	# -pvalue; not even after escaping the string all over.
	@echo assign "\"$(MEM_FILE)\"" top/MEM_FILE      > .vcs.params
	@echo assign $(EX_UNITS)     top/EX_UNITS     >> .vcs.params
	@echo assign $(IQ_DEPTH)     top/IQ_DEPTH     >> .vcs.params
	@echo assign $(ROB_DEPTH)    top/ROB_DEPTH    >> .vcs.params
	@echo assign $(RETIRE_COUNT) top/RETIRE_COUNT >> .vcs.params
	@echo "all:" > $(OUTPUT_DIR)/Makefile
	@echo "	./simv.bin | tee OUTPUT" >> $(OUTPUT_DIR)/Makefile
	vcs $(VCS_FLAGS) -sverilog \
		+define+$(CACHE)_CACHE \
		+define+ROB_TRACE_$(TRACE) \
		+define+IQ_TRACE_$(TRACE) \
		+define+ISS_TRACE_$(TRACE) \
		+define+ID_TRACE_$(TRACE) \
		+define+LS_TRACE_$(TRACE) \
		+define+CACHE_TRACE_$(TRACE) \
		+define+ROB_FORWARDING_$(ROB_FORWARDING) \
		+define+OOO_$(OOO) \
		+define+FIVE_STAGE_$(FIVE_STAGE) \
		-parameters ./.vcs.params \
		-pvalue+top/CPU/LS/MEM/trickbox/ITERATIONS=$(TRICK_ITERATIONS) \
		-o $(OUTPUT_DIR)/simv.bin \
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
	make -C $(OUTPUT_DIR) all

vcs_coverage: out_dir
	# Not including text_idec, as it VCS doesn't support a string as a non-ref port
	#
	# For some weird reason, vcs doesn't like overriding string parameters via
	# -pvalue; not even after escaping the string all over.
	@echo assign "\"$(MEM_FILE)\"" top/MEM_FILE      > .vcs.params
	@echo assign $(EX_UNITS)     top/EX_UNITS     >> .vcs.params
	@echo assign $(IQ_DEPTH)     top/IQ_DEPTH     >> .vcs.params
	@echo assign $(ROB_DEPTH)    top/ROB_DEPTH    >> .vcs.params
	@echo assign $(RETIRE_COUNT) top/RETIRE_COUNT >> .vcs.params
	@echo "all:" > $(OUTPUT_DIR)/Makefile
	@echo "	./simv.bin -cm line -cm cond -cm branch -cm tgl | tee OUTPUT" >> $(OUTPUT_DIR)/Makefile
	vcs $(VCS_FLAGS) -sverilog \
		-cm line \
		-cm cond \
		-cm branch \
		-cm tgl \
		+define+$(CACHE)_CACHE \
		+define+IQ_TRACE_$(TRACE) \
		+define+ISS_TRACE_$(TRACE) \
		+define+ID_TRACE_$(TRACE) \
		+define+LS_TRACE_$(TRACE) \
		+define+CACHE_TRACE_$(TRACE) \
		+define+ROB_FORWARDING_$(ROB_FORWARDING) \
		+define+OOO_$(OOO) \
		+define+FIVE_STAGE_$(FIVE_STAGE) \
		-parameters ./.vcs.params \
		-pvalue+top/CPU/LS/MEM/trickbox/ITERATIONS=$(TRICK_ITERATIONS) \
		-o $(OUTPUT_DIR)/simv.bin \
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
	make -C $(OUTPUT_DIR) all


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
