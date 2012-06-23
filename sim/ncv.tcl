simvision {

    mmap new -reuse -name {MIPS opcodes} -radix %x -contents {
    {%b=000000????????????????????000000 -label {SLL (%x)}}
    {%b=000000????????????????????000010 -label {SRL (%x)}}
    {%b=000000????????????????????000011 -label {SRLA (%x)}}
    {%b=000000????????????????????000100 -label {SLLV (%x)}}
    {%b=000000????????????????????000110 -label {SRLV (%x)}}
    {%b=000000????????????????????000111 -label {SRAV (%x)}}
    {%b=000000????????????????????001000 -label {JR (%x)}}
    {%b=000000????????????????????001001 -label {JALR (%x)}}
    {%b=000000????????????????????001010 -label {MOVZ (%x)}}
    {%b=000000????????????????????001011 -label {MOVN (%x)}}
    {%b=000000????????????????????001100 -label {SYSCALL (%x)}}
    {%b=000000????????????????????001101 -label {BREAK (%x)}}
    {%b=000000????????????????????001111 -label {SYNC (%x)}}
    {%b=000000????????????????????010000 -label {MFHI (%x)}}
    {%b=000000????????????????????010001 -label {MTHI (%x)}}
    {%b=000000????????????????????010010 -label {MFLO (%x)}}
    {%b=000000????????????????????010011 -label {MTLO (%x)}}
    {%b=000000????????????????????011000 -label {MULT (%x)}}
    {%b=000000????????????????????011001 -label {MULTU (%x)}}
    {%b=000000????????????????????011010 -label {DIV (%x)}}
    {%b=000000????????????????????011011 -label {DIVU (%x)}}
    {%b=000000????????????????????100000 -label {ADD (%x)}}
    {%b=000000????????????????????100001 -label {ADDU (%x)}}
    {%b=000000????????????????????100010 -label {SUB (%x)}}
    {%b=000000????????????????????100011 -label {SUBU (%x)}}
    {%b=000000????????????????????100100 -label {AND (%x)}}
    {%b=000000????????????????????100101 -label {OR (%x)}}
    {%b=000000????????????????????100110 -label {XOR (%x)}}
    {%b=000000????????????????????100111 -label {NOR (%x)}}
    {%b=000000????????????????????101010 -label {SLT (%x)}}
    {%b=000000????????????????????101011 -label {SLTU (%x)}}
    {%b=000000????????????????????110000 -label {TGE (%x)}}
    {%b=000000????????????????????110001 -label {TGEU (%x)}}
    {%b=000000????????????????????110010 -label {TLT (%x)}}
    {%b=000000????????????????????110011 -label {TLTU (%x)}}
    {%b=000000????????????????????110100 -label {TEQ (%x)}}
    {%b=000000????????????????????110110 -label {TNE (%x)}}
    {%b=001000?????????????????????????? -label {ADDI (%x)}}
    {%b=001001?????????????????????????? -label {ADDIU (%x)}}
    {%b=001010?????????????????????????? -label {SLTI (%x)}}
    {%b=001011?????????????????????????? -label {SLTIU (%x)}}
    {%b=001100?????????????????????????? -label {ANDI (%x)}}
    {%b=001101?????????????????????????? -label {ORI (%x)}}
    {%b=001110?????????????????????????? -label {XORI (%x)}}
    {%b=001111?????????????????????????? -label {LUI (%x)}}
    {%b=100000?????????????????????????? -label {LB (%x)}}
    {%b=100001?????????????????????????? -label {LH (%x)}}
    {%b=100010?????????????????????????? -label {LWL (%x)}}
    {%b=100011?????????????????????????? -label {LW (%x)}}
    {%b=100100?????????????????????????? -label {LBU (%x)}}
    {%b=100101?????????????????????????? -label {LHU (%x)}}
    {%b=100110?????????????????????????? -label {LWR (%x)}}
    {%b=101000?????????????????????????? -label {SB (%x)}}
    {%b=101001?????????????????????????? -label {SH (%x)}}
    {%b=101010?????????????????????????? -label {SWL (%x)}}
    {%b=101011?????????????????????????? -label {SW (%x)}}
    {%b=101110?????????????????????????? -label {SWR (%x)}}
    {%b=101111?????????????????????????? -label {CACHE (%x)}}
    {%x=* -label %x}
    }







  # Open new waveform window

    window new WaveWindow  -name  "Waves for SuperMIPS"
    window  geometry  "Waves for SuperMIPS"  1010x410+0+25
    waveform  using  "Waves for SuperMIPS"

    waveform  add  -signals  top.clock
    waveform  add  -signals  top.reset_n


    catch {group new -name IF -overlay 0}
    catch {group new -name ID -overlay 0}
    catch {group new -name EX -overlay 0}
    catch {group new -name MEM -overlay 0}
    catch {group new -name WB -overlay 0}
    catch {group new -name RFILE -overlay 0}


    group using IF
    set groupId0 [waveform add -groups IF]
    foreach {name attrs} [subst -nobackslashes -nocommands {
        top.CPU.IF.pc {-radix %x}
        top.CPU.IF.inst_word {-radix %d}
        top.CPU.stall_if {}
    }] {
        group insert $name
        if {$attrs != ""} {
            set gpGlist0 [waveform hierarchy contents $groupId0]
            set gpID0 [lindex $gpGlist0 end]
            eval waveform format $gpID0 $attrs
        }
    }
    waveform hierarchy expand $groupId0



    group using ID
    set groupId0 [waveform add -groups ID]
    foreach {name attrs} [subst -nobackslashes -nocommands {
        top.CPU.if_pc_r {}
        top.CPU.if_inst_word_r {}
        top.CPU.id_A_fwd_from {}
        top.CPU.id_B_fwd_from {}
        top.CPU.id_A {-radix %x}
        top.CPU.id_B {-radix %x}
        top.CPU.id_B_need_late {}
        top.CPU.id_A_reg_valid {}
        top.CPU.id_A_reg {-radix %d}
        top.CPU.id_B_reg {-radix %d}
        top.CPU.id_B_reg_valid {}
        top.CPU.id_alu_inst {}
        top.CPU.id_alu_op {}
        top.CPU.id_alu_res_sel {}
        top.CPU.id_alu_set_u {}
        top.CPU.id_dest_reg {-radix %d}
        top.CPU.id_dest_reg_valid {}
        top.CPU.id_imm {-radix %x}
        top.CPU.id_imm_valid {}
        top.CPU.id_jmp_inst {}
        top.CPU.id_load_inst {}
        top.CPU.id_ls_op {}
        top.CPU.id_ls_sext {}
        top.CPU.id_shamt {-radix %d}
        top.CPU.id_stall {}
        top.CPU.id_store_inst {}
    }] {
        group insert $name
        if {$attrs != ""} {
            set gpGlist0 [waveform hierarchy contents $groupId0]
            set gpID0 [lindex $gpGlist0 end]
            eval waveform format $gpID0 $attrs
        }
    }
    waveform hierarchy expand $groupId0




 # =========================================================================
 # Register Window

  # Open new register window

    window new RegisterWindow  -name  "Registers for SuperMIPS"
    window  geometry  "Registers for SuperMIPS"  1280x700+0+500
    register  using  "Registers for SuperMIPS"


    register addtype -page Page-1 -type rectangle -x0 40.0 -y0 10.0 -x1 280.0 -y1 430.0 -fill #000000 -outline white
    register addtype -page Page-1 -type rectangle -x0 280.0 -y0 10.0 -x1 520.0 -y1 430.0 -fill #000000 -outline white
    register addtype -page Page-1 -type rectangle -x0 520.0 -y0 10.0 -x1 760.0 -y1 430.0 -fill #000000 -outline white
    register addtype -page Page-1 -type rectangle -x0 760.0 -y0 10.0 -x1 1000.0 -y1 430.0 -fill #000000 -outline white
    register addtype -page Page-1 -type rectangle -x0 1000.0 -y0 10.0 -x1 1240.0 -y1 430.0 -fill #000000 -outline white

    register addtype -page Page-1 -type text -text IF -x0 140 -y0 -20 -fill white -fontsize regfont-18
    register addtype -page Page-1 -type text -text ID -x0 380 -y0 -20 -fill white -fontsize regfont-18
    register addtype -page Page-1 -type text -text EX -x0 620.0 -y0 -20.0 -fill white -fontsize regfont-18
    register addtype -page Page-1 -type text -text MEM -x0 860 -y0 -20 -fill white -fontsize regfont-18
    register addtype -page Page-1 -type text -text WB -x0 1100 -y0 -20 -fill white -fontsize regfont-18

    register addtype -page Page-1 -type signalname -x0 86.0 -y0 443.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[0]} ]
    register addtype -page Page-1 -type signalname -x0 87.0 -y0 460.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[1]} ]
    register addtype -page Page-1 -type signalname -x0 86.0 -y0 477.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[2]} ]
    register addtype -page Page-1 -type signalname -x0 86.0 -y0 494.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[3]} ]
    register addtype -page Page-1 -type signalname -x0 86.0 -y0 511.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[4]} ]
    register addtype -page Page-1 -type signalname -x0 86.0 -y0 528.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[5]} ]
    register addtype -page Page-1 -type signalname -x0 86.0 -y0 545.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[6]} ]
    register addtype -page Page-1 -type signalname -x0 86.0 -y0 562.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[7]} ]
    register addtype -page Page-1 -type signalname -x0 285.0 -y0 443.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[8]} ]
    register addtype -page Page-1 -type signalname -x0 285.0 -y0 460.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[9]} ]
    register addtype -page Page-1 -type signalname -x0 285.0 -y0 477.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[10]} ]
    register addtype -page Page-1 -type signalname -x0 285.0 -y0 494.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[11]} ]
    register addtype -page Page-1 -type signalname -x0 285.0 -y0 511.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[12]} ]
    register addtype -page Page-1 -type signalname -x0 285.0 -y0 528.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[13]} ]
    register addtype -page Page-1 -type signalname -x0 285.0 -y0 545.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[14]} ]
    register addtype -page Page-1 -type signalname -x0 285.0 -y0 562.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[15]} ]
    register addtype -page Page-1 -type signalname -x0 497.0 -y0 442.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[16]} ]
    register addtype -page Page-1 -type signalname -x0 497.0 -y0 459.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[17]} ]
    register addtype -page Page-1 -type signalname -x0 497.0 -y0 476.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[18]} ]
    register addtype -page Page-1 -type signalname -x0 497.0 -y0 493.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[19]} ]
    register addtype -page Page-1 -type signalname -x0 497.0 -y0 510.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[20]} ]
    register addtype -page Page-1 -type signalname -x0 497.0 -y0 527.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[21]} ]
    register addtype -page Page-1 -type signalname -x0 497.0 -y0 544.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[22]} ]
    register addtype -page Page-1 -type signalname -x0 497.0 -y0 561.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[23]} ]
    register addtype -page Page-1 -type signalname -x0 717.0 -y0 442.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[24]} ]
    register addtype -page Page-1 -type signalname -x0 717.0 -y0 459.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[25]} ]
    register addtype -page Page-1 -type signalname -x0 717.0 -y0 476.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[26]} ]
    register addtype -page Page-1 -type signalname -x0 717.0 -y0 493.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[27]} ]
    register addtype -page Page-1 -type signalname -x0 717.0 -y0 510.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[28]} ]
    register addtype -page Page-1 -type signalname -x0 717.0 -y0 527.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[29]} ]
    register addtype -page Page-1 -type signalname -x0 717.0 -y0 544.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[30]} ]
    register addtype -page Page-1 -type signalname -x0 717.0 -y0 561.0 -fontsize regfont-12 -fill white [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[31]} ]
    register addtype -page Page-1 -type signalvalue -x0 165.0 -y0 443.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[0]} ]
    register addtype -page Page-1 -type signalvalue -x0 166.0 -y0 460.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[1]} ]
    register addtype -page Page-1 -type signalvalue -x0 165.0 -y0 477.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[2]} ]
    register addtype -page Page-1 -type signalvalue -x0 165.0 -y0 494.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[3]} ]
    register addtype -page Page-1 -type signalvalue -x0 165.0 -y0 511.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[4]} ]
    register addtype -page Page-1 -type signalvalue -x0 165.0 -y0 528.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[5]} ]
    register addtype -page Page-1 -type signalvalue -x0 165.0 -y0 545.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[6]} ]
    register addtype -page Page-1 -type signalvalue -x0 165.0 -y0 562.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[7]} ]
    register addtype -page Page-1 -type signalvalue -x0 364.0 -y0 443.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[8]} ]
    register addtype -page Page-1 -type signalvalue -x0 364.0 -y0 460.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[9]} ]
    register addtype -page Page-1 -type signalvalue -x0 364.0 -y0 477.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[10]} ]
    register addtype -page Page-1 -type signalvalue -x0 364.0 -y0 494.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[11]} ]
    register addtype -page Page-1 -type signalvalue -x0 364.0 -y0 511.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[12]} ]
    register addtype -page Page-1 -type signalvalue -x0 364.0 -y0 528.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[13]} ]
    register addtype -page Page-1 -type signalvalue -x0 364.0 -y0 545.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[14]} ]
    register addtype -page Page-1 -type signalvalue -x0 364.0 -y0 562.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[15]} ]
    register addtype -page Page-1 -type signalvalue -x0 576.0 -y0 442.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[16]} ]
    register addtype -page Page-1 -type signalvalue -x0 576.0 -y0 459.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[17]} ]
    register addtype -page Page-1 -type signalvalue -x0 576.0 -y0 476.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[18]} ]
    register addtype -page Page-1 -type signalvalue -x0 576.0 -y0 493.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[19]} ]
    register addtype -page Page-1 -type signalvalue -x0 576.0 -y0 510.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[20]} ]
    register addtype -page Page-1 -type signalvalue -x0 576.0 -y0 527.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[21]} ]
    register addtype -page Page-1 -type signalvalue -x0 576.0 -y0 544.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[22]} ]
    register addtype -page Page-1 -type signalvalue -x0 576.0 -y0 561.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[23]} ]
    register addtype -page Page-1 -type signalvalue -x0 796.0 -y0 442.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[24]} ]
    register addtype -page Page-1 -type signalvalue -x0 796.0 -y0 459.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[25]} ]
    register addtype -page Page-1 -type signalvalue -x0 796.0 -y0 476.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[26]} ]
    register addtype -page Page-1 -type signalvalue -x0 796.0 -y0 493.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[27]} ]
    register addtype -page Page-1 -type signalvalue -x0 796.0 -y0 510.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[28]} ]
    register addtype -page Page-1 -type signalvalue -x0 796.0 -y0 527.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[29]} ]
    register addtype -page Page-1 -type signalvalue -x0 796.0 -y0 544.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[30]} ]
    register addtype -page Page-1 -type signalvalue -x0 796.0 -y0 561.0 -fontsize regfont-12 -fill white -radix {} [subst -nobackslashes -nocommands {simulator::top.REGFILE.regfile[31]} ]

    register addtype -page Page-1 -type text -x0 77.0 -y0 29.0 -fontsize regfont-12 -fill #ffff00 -text { PC }
    register addtype -page Page-1 -type signalvalue -x0 159.0 -y0 29.0 -fontsize regfont-12 -fill #ffff00 -radix %x [subst -nobackslashes -nocommands {simulator::top.CPU.if_pc[31:0]} ]
    register addtype -page Page-1 -type text -x0 42.0 -y0 47.0 -fontsize regfont-12 -fill #ffff00 -text { IW }
    register addtype -page Page-1 -type signalvalue -x0 163.0 -y0 47.0 -fontsize regfont-12 -fill #ffff00 -mmap {MIPS opcodes} [subst -nobackslashes -nocommands {simulator::top.CPU.if_inst_word[31:0]} ]

    register addtype -page Page-1 -type text -x0 302.0 -y0 25.0 -fontsize regfont-12 -fill #ffff00 { PC }
    register addtype -page Page-1 -type signalvalue -x0 395.0 -y0 25.0 -fontsize regfont-12 -fill #ffff00 -radix {} [subst -nobackslashes -nocommands {simulator::top.CPU.if_pc_r[31:0]} ]
    register addtype -page Page-1 -type text -x0 286.0 -y0 48.0 -fontsize regfont-12 -fill #ffff00 { IW }
    register addtype -page Page-1 -type signalvalue -x0 418.0 -y0 48.0 -fontsize regfont-12 -fill #ffff00 -mmap {MIPS opcodes} [subst -nobackslashes -nocommands {simulator::top.CPU.if_inst_word_r[31:0]} ]

}
