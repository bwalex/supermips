# Set hierarchy variables
set TOP_LEVEL_NAME "top"
set HDL_BASE "../hdl"
set SIM_BASE "../sim"
set VLOG_FLAGS "+define+TRACE_ENABLE"

proc ensure_lib { lib } { if ![file isdirectory $lib] { vlib $lib } }
ensure_lib ./libraries/
ensure_lib ./libraries/work/
vmap work ./libraries/work/

# Compile the additional test files
vlog $VLOG_FLAGS -sv $HDL_BASE/types.sv
vlog $VLOG_FLAGS -sv $HDL_BASE/ex.sv
vlog $VLOG_FLAGS -sv $HDL_BASE/generic_shifter.sv
vlog $VLOG_FLAGS -sv $HDL_BASE/idec.sv
vlog $VLOG_FLAGS -sv $HDL_BASE/ifetch.sv
vlog $VLOG_FLAGS -sv $HDL_BASE/mem.sv
vlog $VLOG_FLAGS -sv $HDL_BASE/pipeline.sv
vlog $VLOG_FLAGS -sv $HDL_BASE/pipreg_ex_mem.sv
vlog $VLOG_FLAGS -sv $HDL_BASE/pipreg_id_ex.sv
vlog $VLOG_FLAGS -sv $HDL_BASE/pipreg_if_id.sv
vlog $VLOG_FLAGS -sv $HDL_BASE/pipreg_mem_wb.sv
vlog $VLOG_FLAGS -sv $HDL_BASE/rfile.sv
vlog $VLOG_FLAGS -sv $HDL_BASE/tcm.sv
vlog $VLOG_FLAGS -sv $HDL_BASE/wb.sv
vlog $VLOG_FLAGS -sv $HDL_BASE/text_idec.sv
vlog $VLOG_FLAGS -sv $HDL_BASE/trickbox.sv
vlog $VLOG_FLAGS -sv $HDL_BASE/top.sv

# Elaborate the top-level design
vsim -t ps -L work $TOP_LEVEL_NAME

# Load the waveform "do file" macro script
do ./wave.do
