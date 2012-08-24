# Set hierarchy variables
set TOP_LEVEL_NAME "top"
set HDL_BASE "../hdl"
set SIM_BASE "../sim"
set VLOG_FLAGS "+define+REAL_CACHE+ROB_TRACE_DISABLE+IQ_TRACE_ENABLE+clogb2=\$clog2"
set VSIM_FLAGS "-gtop/MEM_FILE=\"../software/dhry.vmem\""

proc ensure_lib { lib } { if ![file isdirectory $lib] { vlib $lib } }
ensure_lib ./libraries/
ensure_lib ./libraries/work/
vmap work ./libraries/work/

# Compile the additional test files
vlog $VLOG_FLAGS -sv	$HDL_BASE/types.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/ex.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/exmul.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/generic_shifter.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/idec.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/id.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/ifetch.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/agu.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/mem.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/cache.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/mem_arb.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/memory.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/pipeline.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/iss.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/ls_wrapper.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/ex_wrapper.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/ex_mul_wrapper.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/circ_buf.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/rob.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/rfile.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/tcm.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/wb.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/trickbox.sv
vlog $VLOG_FLAGS -sv	$HDL_BASE/top.sv

# Elaborate the top-level design
vsim $VSIM_FLAGS -t ps -L work $TOP_LEVEL_NAME

# Load the waveform "do file" macro script
#do ./wave.do
