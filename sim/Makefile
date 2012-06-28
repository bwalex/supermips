HDL_BASE?=../hdl

all:
	echo "Targets: ncv, modelsim"

modelsim:
	qhsim -do "source load_sim.tcl"

modelsim_clean:
	rm -f vsim.wlf transcript
	rm -rf libraries

ncv:
	ncverilog -sv +access+r +gui +ncaccess+r +tcl+ncv.tcl \
		$(HDL_BASE)/types.sv \
		$(HDL_BASE)/top.sv \
		$(HDL_BASE)/text_idec.sv \
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
		$(HDL_BASE)/wb.sv

ncv_clean:
	rm -rf INCA_libs ncverilog.key ncverilog.log simvision* waves.shm


clean: modelsim_clean ncv_clean
	@echo "Clean!"

realclean: clean
	rm -f *~ *.bak
	rm -f modelsim.ini
