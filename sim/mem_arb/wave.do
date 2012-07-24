onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /mem_arb_tb/mem_arb/ADDR_WIDTH
add wave -noupdate /mem_arb_tb/mem_arb/DATA_WIDTH
add wave -noupdate /mem_arb_tb/mem_arb/BURSTLEN_WIDTH
add wave -noupdate /mem_arb_tb/mem_arb/LFSR_SEED
add wave -noupdate /mem_arb_tb/mem_arb/clock
add wave -noupdate /mem_arb_tb/mem_arb/reset_n
add wave -noupdate -radix hexadecimal /mem_arb_tb/mem_arb/c1_addr
add wave -noupdate -radix decimal /mem_arb_tb/mem_arb/c1_burst_len
add wave -noupdate -radix hexadecimal /mem_arb_tb/mem_arb/c1_data_out
add wave -noupdate -radix hexadecimal /mem_arb_tb/mem_arb/c1_data_in
add wave -noupdate /mem_arb_tb/mem_arb/c1_wr
add wave -noupdate /mem_arb_tb/mem_arb/c1_rd
add wave -noupdate /mem_arb_tb/mem_arb/c1_waitrequest
add wave -noupdate /mem_arb_tb/mem_arb/c1_rd_valid
add wave -noupdate -radix hexadecimal /mem_arb_tb/mem_arb/c2_addr
add wave -noupdate -radix decimal /mem_arb_tb/mem_arb/c2_burst_len
add wave -noupdate -radix hexadecimal /mem_arb_tb/mem_arb/c2_data_out
add wave -noupdate -radix hexadecimal /mem_arb_tb/mem_arb/c2_data_in
add wave -noupdate /mem_arb_tb/mem_arb/c2_wr
add wave -noupdate /mem_arb_tb/mem_arb/c2_rd
add wave -noupdate /mem_arb_tb/mem_arb/c2_waitrequest
add wave -noupdate /mem_arb_tb/mem_arb/c2_rd_valid
add wave -noupdate -radix hexadecimal /mem_arb_tb/mem_arb/mm_addr
add wave -noupdate -radix decimal /mem_arb_tb/mem_arb/mm_burst_len
add wave -noupdate -radix hexadecimal /mem_arb_tb/mem_arb/mm_data_in
add wave -noupdate -radix hexadecimal /mem_arb_tb/mem_arb/mm_data_out
add wave -noupdate /mem_arb_tb/mem_arb/mm_wr
add wave -noupdate /mem_arb_tb/mem_arb/mm_rd
add wave -noupdate /mem_arb_tb/mem_arb/mm_waitrequest
add wave -noupdate /mem_arb_tb/mem_arb/mm_rd_valid
add wave -noupdate /mem_arb_tb/mem_arb/sel
add wave -noupdate /mem_arb_tb/mem_arb/next_sel
add wave -noupdate /mem_arb_tb/mem_arb/rd_count
add wave -noupdate /mem_arb_tb/mem_arb/burst_len_int
add wave -noupdate /mem_arb_tb/mem_arb/rd_int
add wave -noupdate /mem_arb_tb/mem_arb/load_count
add wave -noupdate /mem_arb_tb/mem_arb/dec_count
add wave -noupdate /mem_arb_tb/mem_arb/state
add wave -noupdate /mem_arb_tb/mem_arb/next_state
add wave -noupdate /mem_arb_tb/mem_arb/lfsr_r
add wave -noupdate /mem_arb_tb/mem_arb/rand_bit
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 270
configure wave -valuecolwidth 257
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {975 ps}
