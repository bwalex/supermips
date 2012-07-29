onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /rob_tb/clock
add wave -noupdate /rob_tb/reset_n
add wave -noupdate /rob_tb/reserve_en
add wave -noupdate /rob_tb/reserve_count
add wave -noupdate -radix hexadecimal /rob_tb/reserved_slots
add wave -noupdate -radix hexadecimal /rob_tb/write_slot
add wave -noupdate /rob_tb/write_valid
add wave -noupdate -radix unsigned /rob_tb/write_data
add wave -noupdate /rob_tb/consume_en
add wave -noupdate /rob_tb/consume_count
add wave -noupdate -radix hexadecimal /rob_tb/slot_data
add wave -noupdate /rob_tb/slot_valid
add wave -noupdate /rob_tb/empty
add wave -noupdate /rob_tb/full
add wave -noupdate -radix unsigned /rob_tb/cb1/ext_ptr
add wave -noupdate -radix unsigned /rob_tb/cb1/ins_ptr
add wave -noupdate -radix hexadecimal /rob_tb/cb1/buffer
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {21000 ps} 0}
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
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
WaveRestoreZoom {50250 ps} {155250 ps}
