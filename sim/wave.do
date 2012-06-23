add wave -noupdate -divider CLK_RESET
add wave -noupdate /top/clock
add wave -noupdate /top/reset_n



add wave -noupdate -divider IF
add wave -noupdate -radix hexadecimal /top/CPU/IF/pc
add wave -noupdate /top/CPU/stall_if



add wave -noupdate -divider ID
add wave -noupdate -radix hexadecimal /top/CPU/if_pc_r
add wave -noupdate -radix hexadecimal /top/CPU/if_inst_word_r
add wave -noupdate /top/CPU/id_A_fwd_from
add wave -noupdate /top/CPU/id_B_fwd_from
add wave -noupdate -radix hexadecimal  /top/CPU/id_A
add wave -noupdate -radix decimal      /top/CPU/id_A_reg
add wave -noupdate /top/CPU/id_A_reg_valid
add wave -noupdate -radix hexadecimal  /top/CPU/id_B
add wave -noupdate -radix decimal      /top/CPU/id_B_reg
add wave -noupdate /top/CPU/id_B_reg_valid
add wave -noupdate -radix hexadecimal  /top/CPU/id_imm
add wave -noupdate /top/CPU/id_imm_valid
add wave -noupdate /top/CPU/id_alu_inst
add wave -noupdate /top/CPU/id_load_inst
add wave -noupdate /top/CPU/id_store_inst
add wave -noupdate /top/CPU/id_jmp_inst
add wave -noupdate -radix decimal      /top/CPU/id_dest_reg
add wave -noupdate /top/CPU/id_dest_reg_valid
add wave -noupdate /top/CPU/id_alu_op
add wave -noupdate /top/CPU/id_alu_res_sel
add wave -noupdate /top/CPU/id_alu_set_u
add wave -noupdate /top/CPU/id_ls_op
add wave -noupdate /top/CPU/id_ls_sext



add wave -noupdate -divider EX
add wave -noupdate -radix hexadecimal /top/CPU/id_pc_r
add wave -noupdate -radix hexadecimal /top/CPU/id_inst_word_r



add wave -noupdate -divider MEM
add wave -noupdate -radix hexadecimal /top/CPU/ex_pc_r
add wave -noupdate -radix hexadecimal /top/CPU/ex_inst_word_r



add wave -noupdate -divider WB
add wave -noupdate -radix hexadecimal /top/CPU/mem_pc_r
add wave -noupdate -radix hexadecimal /top/CPU/mem_inst_word_r
add wave -noupdate -radix decimal     /top/CPU/WB/dest_reg
add wave -noupdate -radix decimal     /top/CPU/WB/dest_reg_valid
add wave -noupdate -radix hexadecimal /top/CPU/WB/result
