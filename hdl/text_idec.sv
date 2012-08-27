module text_idec(
  input [31:0]  inst_word,
  input [31:0]  pc,
  output string inst_str,
  reg           alu_inst,
  reg           jmp_inst,
  reg           branch_inst,
  reg           load_inst,
  reg           store_inst,
  reg           muldiv_inst,
  wire          unknown_inst
);


  wire [5:0]                 inst_opc;
  wire [4:0]                 inst_rs;
  wire [4:0]                 inst_rt;
  wire [4:0]                 inst_rd;
  wire [15:0]                inst_imm;
  wire [25:0]                inst_addr;
  wire [4:0]                 inst_shamt;
  wire [5:0]                 inst_funct;
  wire [31:0]                jmp_addr;
  wire [31:0]                pc_plus_4;
  wire [4:0]                 ext_msbd;
  wire [4:0]                 ext_lsb;
  wire [15:0]                imm_sext;
  wire [31:0]                branch_addr;


  assign inst_opc   = inst_word[31:26];
  assign inst_rs    = inst_word[25:21];
  assign inst_rt    = inst_word[20:16];
  assign inst_rd    = inst_word[15:11];
  assign inst_imm   = inst_word[15: 0];
  assign inst_addr  = inst_word[25: 0];
  assign inst_shamt = inst_word[10: 6];
  assign inst_funct = inst_word[ 5: 0];
  assign ext_msbd   = inst_word[15:11];
  assign ext_lsb    = inst_word[10: 6];

  assign pc_plus_4  = pc+4;
  assign jmp_addr   = { pc_plus_4[31:28], inst_addr, 2'b00 };
  assign imm_sext   = inst_imm;
  assign branch_addr = pc_plus_4 + { {14{inst_imm[15]}}, inst_imm, 2'b00 };

  assign unknown_inst = ~(alu_inst | jmp_inst | branch_inst | load_inst | store_inst | muldiv_inst);

  always_comb begin
    alu_inst     = 1'b0;
    jmp_inst     = 1'b0;
    branch_inst  = 1'b0;
    load_inst    = 1'b0;
    store_inst   = 1'b0;
    muldiv_inst  = 1'b0;


    case (inst_opc)
      6'h00: begin
        case (inst_funct)
          6'd00: begin // sll
            alu_inst = 1'b1;
            if (inst_word == 32'b0)
              $sformat(inst_str, "nop");
            else
              $sformat(inst_str, "sll $%0d, $%0d, %0d", inst_rd, inst_rt, inst_shamt);
          end
          6'd02: begin // srl
            alu_inst = 1'b1;
            $sformat(inst_str, "srl $%0d, $%0d, %0d", inst_rd, inst_rt, inst_shamt);
          end
          6'd03: begin // sra
            alu_inst = 1'b1;
            $sformat(inst_str, "sra $%0d, $%0d, %0d", inst_rd, inst_rt, inst_shamt);
          end
          6'd04: begin // sllv
            alu_inst = 1'b1;
            $sformat(inst_str, "sllv $%0d, $%0d, $%0d", inst_rd, inst_rt, inst_rs);
          end
          6'd06: begin // srlv
            alu_inst = 1'b1;
            $sformat(inst_str, "srlv $%0d, $%0d, $%0d", inst_rd, inst_rt, inst_rs);
          end
          6'd07: begin // srav
            alu_inst = 1'b1;
            $sformat(inst_str, "srav $%0d, $%0d, $%0d", inst_rd, inst_rt, inst_rs);
          end
          6'd08: begin // jr
            jmp_inst = 1'b1;
            $sformat(inst_str, "jr $%0d", inst_rs);
          end
          6'd09: begin // jalr
            jmp_inst = 1'b1;
            $sformat(inst_str, "jalr $%0d, $%0d", inst_rs, inst_rd);
          end
          6'd10: begin // movz
            alu_inst = 1'b1;
            $sformat(inst_str, "movz $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          6'd11: begin // movn
            alu_inst = 1'b1;
            $sformat(inst_str, "movn $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          6'd13: begin // break
            $sformat(inst_str, "break");
          end
          6'd16: begin // mfhi
            muldiv_inst = 1'b1;
            $sformat(inst_str, "mfhi $%0d", inst_rd);
          end
          6'd17: begin // mthi
            muldiv_inst = 1'b1;
            $sformat(inst_str, "mthi $%0d", inst_rs);
          end
          6'd18: begin // mflo
            muldiv_inst = 1'b1;
            $sformat(inst_str, "mflo $%0d", inst_rd);
          end
          6'd19: begin // mtlo
            muldiv_inst = 1'b1;
            $sformat(inst_str, "mtlo $%0d", inst_rs);
          end
          6'd24: begin // mult
            muldiv_inst = 1'b1;
            $sformat(inst_str, "mult $%0d, $%0d", inst_rs, inst_rt);
          end
          6'd25: begin // multu
            muldiv_inst = 1'b1;
            $sformat(inst_str, "multu $%0d, $%0d", inst_rs, inst_rt);
          end
          6'd26: begin // div
            muldiv_inst = 1'b1;
            $sformat(inst_str, "div $%0d, $%0d", inst_rs, inst_rt);
          end
          6'd27: begin // divu
            muldiv_inst = 1'b1;
            $sformat(inst_str, "divu $%0d, $%0d", inst_rs, inst_rt);
          end
          6'd32: begin // add
            alu_inst = 1'b1;
            $sformat(inst_str, "add $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          6'd33: begin // addu
            alu_inst = 1'b1;
            $sformat(inst_str, "addu $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          6'd34: begin // sub
            alu_inst = 1'b1;
            $sformat(inst_str, "sub $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          6'd35: begin // subu
            alu_inst = 1'b1;
            $sformat(inst_str, "sub $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          6'd36: begin // and
            alu_inst = 1'b1;
            $sformat(inst_str, "and $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          6'd37: begin // or
            alu_inst = 1'b1;
            $sformat(inst_str, "or $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          6'd38: begin // xor
            alu_inst = 1'b1;
            $sformat(inst_str, "xor $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          6'd39: begin // nor
            alu_inst = 1'b1;
            $sformat(inst_str, "nor $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          6'd42: begin // slt
            alu_inst = 1'b1;
            $sformat(inst_str, "slt $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          6'd43: begin // sltu
            alu_inst = 1'b1;
            $sformat(inst_str, "sltu $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          6'd53: begin // teq
            alu_inst = 1'b1;
            $sformat(inst_str, "teq $%0d, $%0d, 0x%x", inst_rs, inst_rt, inst_imm[15:6]);
          end
          default: begin
            $sformat(inst_str, "Unknown instruction: opc: %x, funct: %0d", inst_opc, inst_funct);
          end
        endcase // case (inst_funct)
      end // case: 6'h00

      6'h01: begin
        case (inst_rt)
          5'h00: begin // bltz
            branch_inst = 1'b1;
            $sformat(inst_str, "bltz $%0d, 0x%x", inst_rs, branch_addr);
          end
          5'h01: begin // bgez
            branch_inst = 1'b1;
            $sformat(inst_str, "bgez $%0d, 0x%x", inst_rs, branch_addr);
          end
          5'h10: begin // bltzal
            branch_inst = 1'b1;
            $sformat(inst_str, "bltzal $%0d, 0x%x", inst_rs, branch_addr);
          end
          5'h11: begin // bgezal
            branch_inst = 1'b1;
            $sformat(inst_str, "bgezal $%0d, 0x%x", inst_rs, branch_addr);
          end
          default: begin
            $sformat(inst_str, "Unknown instruction: opc: %x, rt: %0d", inst_opc, inst_rt);
          end
        endcase // case (inst_rt)
      end // case: 6'h01

      6'h02: begin // j
        jmp_inst = 1'b1;
        $sformat(inst_str, "j 0x%x", jmp_addr);
      end

      6'h03: begin // jal
        jmp_inst = 1'b1;
        $sformat(inst_str, "jal 0x%x", jmp_addr);
      end

      6'h04: begin // beq
        branch_inst = 1'b1;
        $sformat(inst_str, "beq $%0d, $%0d, 0x%x", inst_rs, inst_rt, branch_addr);
      end

      6'h05: begin // bne
        branch_inst = 1'b1;
        $sformat(inst_str, "bne $%0d, $%0d, 0x%x", inst_rs, inst_rt, branch_addr);
      end

      6'h06: begin // blez
        branch_inst = 1'b1;
        $sformat(inst_str, "blez $%0d, 0x%x", inst_rs, branch_addr);
      end

      6'h07: begin // bgtz
        branch_inst = 1'b1;
        $sformat(inst_str, "bgtz $%0d, 0x%x", inst_rs, branch_addr);
      end

      6'h08: begin // addi
        alu_inst = 1'b1;
        $sformat(inst_str, "addi $%0d, $%0d, %d", inst_rt, inst_rs, $signed(imm_sext));
      end

      6'h09: begin // addiu
        alu_inst = 1'b1;
        $sformat(inst_str, "addiu $%0d, $%0d, %d", inst_rt, inst_rs, $signed(imm_sext));
      end

      6'h0a: begin // slti
        alu_inst = 1'b1;
        $sformat(inst_str, "slti $%0d, $%0d, 0x%x", inst_rt, inst_rs, inst_imm);
      end

      6'h0b: begin // sltiu
        alu_inst = 1'b1;
        $sformat(inst_str, "sltiu $%0d, $%0d, 0x%x", inst_rt, inst_rs, inst_imm);
      end

      6'h0c: begin // andi
        alu_inst = 1'b1;
        $sformat(inst_str, "andi $%0d, $%0d, 0x%x", inst_rt, inst_rs, inst_imm);
      end

      6'h0d: begin // ori
        alu_inst = 1'b1;
        $sformat(inst_str, "ori $%0d, $%0d, 0x%x", inst_rt, inst_rs, inst_imm);
      end

      6'h0e: begin // xori
        alu_inst = 1'b1;
        $sformat(inst_str, "xori $%0d, $%0d, 0x%x", inst_rt, inst_rs, inst_imm);
      end

      6'h0f: begin // lui
        alu_inst = 1'b1;
        $sformat(inst_str, "lui $%0d, 0x%x", inst_rt, inst_imm);
      end

      6'h1c: begin
        case (inst_funct)
          6'd00: begin // madd
            muldiv_inst = 1'b1;
            $sformat(inst_str, "madd $%0d, $%0d", inst_rs, inst_rt);
          end
          6'd01: begin // maddu
            muldiv_inst = 1'b1;
            $sformat(inst_str, "maddu $%0d, $%0d", inst_rs, inst_rt);
          end
          6'd02: begin // mul
            muldiv_inst = 1'b1;
            $sformat(inst_str, "mul $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          default: begin
            $sformat(inst_str, "Unknown instruction: opc: %x, funct: %d", inst_opc, inst_funct);
          end
        endcase
      end // case: 6'h1c

      6'h1f: begin
        case (inst_funct)
          6'd00: begin // ext
            alu_inst = 1'b1;
            $sformat(inst_str, "ext $%0d, $%0d, %d, %d", inst_rt, inst_rs, ext_lsb, ext_msbd+1);
          end
          6'd04: begin // ins
            alu_inst = 1'b1;
            $sformat(inst_str, "ins $%0d, $%0d, $%0d, %d, %d", inst_rt, inst_rt, inst_rs, ext_lsb, ext_msbd+1-ext_lsb);
          end
          6'd32: begin
            case (inst_shamt)
              5'd16: begin // seb
                alu_inst = 1'b1;
                $sformat(inst_str, "seb $%0d, $%0d", inst_rd, inst_rt);
              end
              5'd24: begin // seh
                alu_inst = 1'b1;
                $sformat(inst_str, "seh $%0d, $%0d", inst_rd, inst_rt);
              end
              default: begin
                $sformat(inst_str, "Unknown instruction: opc: %x, funct: %d, shamt: %d", inst_opc, inst_funct, inst_shamt);
              end
            endcase // case (inst_shamt)
          end // case: 6'd32
          default: begin
            $sformat(inst_str, "Unknown instruction: opc: %x, funct: %d", inst_opc, inst_funct);
          end
        endcase // case (inst_funct)
      end // case: 6'h1f

      6'h20: begin // lb
        load_inst = 1'b1;
        $sformat(inst_str, "lb, $%0d, %d($%0d)", inst_rt, $signed(imm_sext), inst_rs);
      end

      6'h21: begin // lh
        load_inst = 1'b1;
        $sformat(inst_str, "lh, $%0d, %d($%0d)", inst_rt, $signed(imm_sext), inst_rs);
      end

      6'h23: begin // lw
        load_inst = 1'b1;
        $sformat(inst_str, "lw, $%0d, %d($%0d)", inst_rt, $signed(imm_sext), inst_rs);
      end

      6'h24: begin // lbu
        load_inst = 1'b1;
        $sformat(inst_str, "lbu, $%0d, %d($%0d)", inst_rt, $signed(imm_sext), inst_rs);
      end

      6'h25: begin // lhu
        load_inst = 1'b1;
        $sformat(inst_str, "lhu, $%0d, %d($%0d)", inst_rt, $signed(imm_sext), inst_rs);
      end

      6'h28: begin // sb
        store_inst = 1'b1;
        $sformat(inst_str, "sb, $%0d, %d($%0d)", inst_rt, $signed(imm_sext), inst_rs);
      end

      6'h29: begin // sh
        store_inst = 1'b1;
        $sformat(inst_str, "sh, $%0d, %d($%0d)", inst_rt, $signed(imm_sext), inst_rs);
      end

      6'h2b: begin // sw
        store_inst = 1'b1;
        $sformat(inst_str, "sw, $%0d, %d($%0d)", inst_rt, $signed(imm_sext), inst_rs);
      end

      default: begin
        $sformat(inst_str, "Unknown instruction: opc: %x", inst_opc);
      end
    endcase // case (inst_opc)
  end // always_comb

endmodule
