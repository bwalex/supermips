simvision {
  # Open new waveform window

    window new WaveWindow  -name  "Waves for SuperMIPS"
    window  geometry  "Waves for SuperMIPS"  1010x410+0+25
    waveform  using  "Waves for SuperMIPS"

  # Add basic signals to wave window

    waveform  add  -signals  top.clock
    waveform  add  -signals  top.reset_n

    catch {group new -name IF -overlay 0}
    catch {group new -name ID -overlay 0}
    catch {group new -name EX -overlay 0}
    catch {group new -name MEM -overlay 0}
    catch {group new -name WB -overlay 0}
    catch {group new -name RFILE -overlay 0}

    group using IF
    group insert \
        top.CPU.IF.pc \
        top.CPU.stall_if


    set groupId0 [waveform add -groups IF]
    set gpGlist0 [waveform hierarchy contents $groupId0]
    set gpID0 [lindex $gpGlist0 0]
    foreach {name attrs} [subst -nobackslashes -nocommands {
        {simulator::top.CPU.IF.pc[31:0]} {-radix %x}
        simulator::top.CPU.stall_if {}
    }] {
        set expected [ join [waveform signals -format fullpath $gpID0] ]
        if {[string equal $name $expected]} {
            if {$attrs != ""} {
                eval waveform format $gpID0 $attrs
            }
        }
        set gpGlist0 [lrange $gpGlist0 1 end]
        set gpID0 [lindex $gpGlist0 0]
    }
    waveform hierarchy expand $groupId0



    group using ID
    group insert \
        top.CPU.if_pc_r \
        top.CPU.if_inst_word_r \
        top.CPU.id_A_fwd_from \
        top.CPU.id_B_fwd_from \
        top.CPU.id_A \
        top.CPU.id_B \
        top.CPU.id_B_need_late \
        top.CPU.id_A_reg_valid \
        top.CPU.id_A_reg \
        top.CPU.id_B_reg \
        top.CPU.id_B_reg_valid \
        top.CPU.id_alu_inst \
        top.CPU.id_alu_op \
        top.CPU.id_alu_res_sel \
        top.CPU.id_alu_set_u \
        top.CPU.id_dest_reg \
        top.CPU.id_dest_reg_valid \
        top.CPU.id_imm \
        top.CPU.id_imm_valid \
        top.CPU.id_jmp_inst \
        top.CPU.id_load_inst \
        top.CPU.id_ls_op \
        top.CPU.id_ls_sext \
        top.CPU.id_shamt \
        top.CPU.id_stall \
        top.CPU.id_store_inst


    set groupId0 [waveform add -groups ID]
    set gpGlist0 [waveform hierarchy contents $groupId0]
    set gpID0 [lindex $gpGlist0 0]
    foreach {name attrs} [subst -nobackslashes -nocommands {
        {simulator::top.CPU.if_pc_r} {}
        {simulator::top.CPU.if_inst_word_r} {}
        simulator::top.CPU.id_A_fwd_from {}
        simulator::top.CPU.id_B_fwd_from {}
        {simulator::top.CPU.id_A} {-radix %x}
        {simulator::top.CPU.id_B} {-radix %x}
        simulator::top.CPU.id_B_need_late {}
        simulator::top.CPU.id_A_reg_valid {}
        {simulator::top.CPU.id_A_reg} {-radix %d}
        {simulator::top.CPU.id_B_reg} {-radix %d}
        simulator::top.CPU.id_B_reg_valid {}
        simulator::top.CPU.id_alu_inst {}
        simulator::top.CPU.id_alu_op {}
        simulator::top.CPU.id_alu_res_sel {}
        simulator::top.CPU.id_alu_set_u {}
        {simulator::top.CPU.id_dest_reg} {-radix %d}
        simulator::top.CPU.id_dest_reg_valid {}
        {simulator::top.CPU.id_imm} {-radix %x}
        simulator::top.CPU.id_imm_valid {}
        simulator::top.CPU.id_jmp_inst {}
        simulator::top.CPU.id_load_inst {}
        simulator::top.CPU.id_ls_op {}
        simulator::top.CPU.id_ls_sext {}
        {simulator::top.CPU.id_shamt} {-radix %d}
        simulator::top.CPU.id_stall {}
        simulator::top.CPU.id_store_inst {}
    }] {
        set expected [ join [waveform signals -format fullpath $gpID0] ]
        if {[string equal $name $expected]} {
            if {$attrs != ""} {
                eval waveform format $gpID0 $attrs
            }
        }
        set gpGlist0 [lrange $gpGlist0 1 end]
        set gpID0 [lindex $gpGlist0 0]
    }
    waveform hierarchy expand $groupId0




 # =========================================================================
 # Register Window

  # Open new register window

    window new RegisterWindow  -name  "Registers for SuperMIPS"
    window  geometry  "Registers for SuperMIPS"  1280x700+0+500
    register  using  "Registers for SuperMIPS"

    register addtype -type rectangle -x0  40  -y0 0 -x1  280 -y1 420 -outline white
    register addtype -type rectangle -x0  280 -y0 0 -x1  520 -y1 420 -outline white
    register addtype -type rectangle -x0  520 -y0 0 -x1  760 -y1 420 -outline white
    register addtype -type rectangle -x0  760 -y0 0 -x1 1000 -y1 420 -outline white
    register addtype -type rectangle -x0 1000 -y0 0 -x1 1240 -y1 420 -outline white

    register addtype -type text -text IF  -x0  140 -y0 -20 -fill white -fontsize regfont-18
    register addtype -type text -text ID  -x0  380 -y0 -20 -fill white -fontsize regfont-18
    register addtype -type text -text EX  -x0  620 -y0 -20 -fill white -fontsize regfont-18
    register addtype -type text -text MEM -x0  860 -y0 -20 -fill white -fontsize regfont-18
    register addtype -type text -text WB  -x0 1100 -y0 -20 -fill white -fontsize regfont-18
}
