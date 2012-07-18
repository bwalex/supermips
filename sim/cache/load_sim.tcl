# Set hierarchy variables
set TOP_LEVEL_NAME "cache_tb"
set HDL_BASE "../../hdl"
set SIM_BASE ".."
set VLOG_FLAGS "+define+TRACE_ENABLE"

proc ensure_lib { lib } { if ![file isdirectory $lib] { vlib $lib } }
ensure_lib ./libraries/
ensure_lib ./libraries/work/
vmap work ./libraries/work/

# Compile the additional test files
vlog $VLOG_FLAGS -sv $HDL_BASE/cache.sv
vlog $VLOG_FLAGS -sv $HDL_BASE/memory.sv
vlog $VLOG_FLAGS -sv ./cache_tb.sv

# Elaborate the top-level design
vsim -t ps -L work $TOP_LEVEL_NAME

# Load the waveform "do file" macro script
do ./wave.do
