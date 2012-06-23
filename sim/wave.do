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

add wave -noupdate -height 15 -radix hexadecimal -childformat {{{/top/REGFILE/regfile[0]} -radix hexadecimal} {{/top/REGFILE/regfile[1]} -radix hexadecimal} {{/top/REGFILE/regfile[2]} -radix hexadecimal} {{/top/REGFILE/regfile[3]} -radix hexadecimal} {{/top/REGFILE/regfile[4]} -radix hexadecimal} {{/top/REGFILE/regfile[5]} -radix hexadecimal} {{/top/REGFILE/regfile[6]} -radix hexadecimal} {{/top/REGFILE/regfile[7]} -radix hexadecimal} {{/top/REGFILE/regfile[8]} -radix hexadecimal} {{/top/REGFILE/regfile[9]} -radix hexadecimal} {{/top/REGFILE/regfile[10]} -radix hexadecimal} {{/top/REGFILE/regfile[11]} -radix hexadecimal} {{/top/REGFILE/regfile[12]} -radix hexadecimal} {{/top/REGFILE/regfile[13]} -radix hexadecimal} {{/top/REGFILE/regfile[14]} -radix hexadecimal} {{/top/REGFILE/regfile[15]} -radix hexadecimal} {{/top/REGFILE/regfile[16]} -radix hexadecimal} {{/top/REGFILE/regfile[17]} -radix hexadecimal} {{/top/REGFILE/regfile[18]} -radix hexadecimal} {{/top/REGFILE/regfile[19]} -radix hexadecimal} {{/top/REGFILE/regfile[20]} -radix hexadecimal} {{/top/REGFILE/regfile[21]} -radix hexadecimal} {{/top/REGFILE/regfile[22]} -radix hexadecimal} {{/top/REGFILE/regfile[23]} -radix hexadecimal} {{/top/REGFILE/regfile[24]} -radix hexadecimal} {{/top/REGFILE/regfile[25]} -radix hexadecimal} {{/top/REGFILE/regfile[26]} -radix hexadecimal} {{/top/REGFILE/regfile[27]} -radix hexadecimal} {{/top/REGFILE/regfile[28]} -radix hexadecimal} {{/top/REGFILE/regfile[29]} -radix hexadecimal} {{/top/REGFILE/regfile[30]} -radix hexadecimal} {{/top/REGFILE/regfile[31]} -radix hexadecimal}} -expand -subitemconfig {{/top/REGFILE/regfile[0]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[1]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[2]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[3]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[4]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[5]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[6]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[7]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[8]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[9]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[10]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[11]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[12]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[13]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[14]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[15]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[16]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[17]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[18]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[19]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[20]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[21]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[22]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[23]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[24]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[25]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[26]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[27]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[28]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[29]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[30]} {-height 15 -radix hexadecimal} {/top/REGFILE/regfile[31]} {-height 15 -radix hexadecimal}} /top/REGFILE/regfile
