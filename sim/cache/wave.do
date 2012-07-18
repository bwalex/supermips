add wave -noupdate /cache_tb/c1/clock
add wave -noupdate /cache_tb/c1/reset_n

add wave -noupdate /cache_tb/c1/lfsr
add wave -noupdate /cache_tb/c1/lfsr_enable
add wave -noupdate -radix unsigned /cache_tb/c1/bank_sel
add wave -noupdate -radix hexadecimal /cache_tb/c1/cpu_addr
add wave -noupdate /cache_tb/c1/cpu_rd
add wave -noupdate /cache_tb/c1/cpu_wr
add wave -noupdate /cache_tb/c1/cpu_wr_be
add wave -noupdate -radix hexadecimal /cache_tb/c1/cpu_wr_data
add wave -noupdate /cache_tb/c1/cpu_rd_valid
add wave -noupdate -radix hexadecimal /cache_tb/c1/cpu_rd_data
add wave -noupdate /cache_tb/c1/cpu_waitrequest
