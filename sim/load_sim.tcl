# Set hierarchy variables
set TOP_LEVEL_NAME "top"
set HDL_BASE "../hdl"
set SIM_BASE "../sim"
set VLOG_FLAGS "+define+REAL_CACHE+ROB_TRACE_ENABLE+IQ_TRACE_ENABLE+clogb2=\$clog2"
set VSIM_FLAGS "-gtop/MEM_FILE=\"../software/dhry.vmem\""

proc ensure_lib { lib } { if ![file isdirectory $lib] { vlib $lib } }
ensure_lib ./libraries/
ensure_lib ./libraries/work/
vmap work ./libraries/work/

# Compile the additional test files
vlog $VLOG_FLAGS -sv	$SIM_BASE/modelsim_helpers.sv \
			$HDL_BASE/types.sv \
			$HDL_BASE/ex.sv \
			$HDL_BASE/exmul.sv \
			$HDL_BASE/generic_shifter.sv \
			$HDL_BASE/idec.sv \
			$HDL_BASE/id.sv \
			$HDL_BASE/ifetch.sv \
			$HDL_BASE/agu.sv \
			$HDL_BASE/mem.sv \
			$HDL_BASE/cache.sv \
			$HDL_BASE/mem_arb.sv \
			$HDL_BASE/memory.sv \
			$HDL_BASE/pipeline.sv \
			$HDL_BASE/iss.sv \
			$HDL_BASE/ls_wrapper.sv \
			$HDL_BASE/ex_wrapper.sv \
			$HDL_BASE/ex_mul_wrapper.sv \
			$HDL_BASE/circ_buf.sv \
			$HDL_BASE/rob.sv \
			$HDL_BASE/rfile.sv \
			$HDL_BASE/tcm.sv \
			$HDL_BASE/wb.sv \
			$HDL_BASE/trickbox.sv \
			$HDL_BASE/top.sv

# Elaborate the top-level design
vsim $VSIM_FLAGS -t ps -L work $TOP_LEVEL_NAME

# Load the waveform "do file" macro script
#do ./wave.do
