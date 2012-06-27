module text_idec(
  input [31:0]      inst_word,
  output string     inst_str
);


  wire [5:0]                 inst_opc;
  wire [4:0]                 inst_rs;
  wire [4:0]                 inst_rt;
  wire [4:0]                 inst_rd;
  wire [15:0]                inst_imm;
  wire [25:0]                inst_addr;
  wire [4:0]                 inst_shamt;
  wire [5:0]                 inst_funct;


  assign inst_opc   = inst_word[31:26];
  assign inst_rs    = inst_word[25:21];
  assign inst_rt    = inst_word[20:16];
  assign inst_rd    = inst_word[15:11];
  assign inst_imm   = inst_word[15: 0];
  assign inst_addr  = inst_word[25: 0];
  assign inst_shamt = inst_word[10: 6];
  assign inst_funct = inst_word[ 5: 0];


  always_comb begin
    case (inst_opc)
      6'h00: begin
        case (inst_funct)
          6'd00: begin // sll
            $sformat(inst_str, "sll $%d, $%d, %d", inst_rd, inst_rt, shamt);
          end
          6'd02: begin // srl
            $sformat(inst_str, "srl $%d, $%d, %d", inst_rd, inst_rt, shamt);
          end
          6'd03: begin // sra
            $sformat(inst_str, "sra $%d, $%d, %d", inst_rd, inst_rt, shamt);
          end
          6'd04: begin // sllv
            $sformat(inst_str, "sllv $%d, $%d, $%d", inst_rd, inst_rt, inst_rs);
          end
          6'd06: begin // srlv
            $sformat(inst_str, "srlv $%d, $%d, $%d", inst_rd, inst_rt, inst_rs);
          end
          6'd07: begin // srav
            $sformat(inst_str, "srav $%d, $%d, $%d", inst_rd, inst_rt, inst_rs);
          end
          6'd08: begin // jr
            $sformat(inst_str, "jr $%d", inst_rs);
          end
          6'd09: begin // jalr
            $sformat(inst_str, "jalr $%d, $%d", inst_rs, inst_rd);
          end
          6'd32: begin // add
            $sformat(inst_str, "add $%d, $%d, $%d", inst_rd, inst_rs, inst_rt);
          end
          6'd33: begin // addu
            $sformat(inst_str, "addu $%d, $%d, $%d", inst_rd, inst_rs, inst_rt);
          end
          6'd34: begin // sub
            $sformat(inst_str, "sub $%d, $%d, $%d", inst_rd, inst_rs, inst_rt);
          end
          6'd35: begin // subu
            $sformat(inst_str, "sub $%d, $%d, $%d", inst_rd, inst_rs, inst_rt);
          end
          6'd36: begin // and
            $sformat(inst_str, "and $%d, $%d, $%d", inst_rd, inst_rs, inst_rt);
          end
          6'd37: begin // or
            $sformat(inst_str, "or $%d, $%d, $%d", inst_rd, inst_rs, inst_rt);
          end
          6'd38: begin // xor
            $sformat(inst_str, "xor $%d, $%d, $%d", inst_rd, inst_rs, inst_rt);
          end
          6'd39: begin // nor
            $sformat(inst_str, "nor $%d, $%d, $%d", inst_rd, inst_rs, inst_rt);
          end
          6'd42: begin // slt
            $sformat(inst_str, "slt $%d, $%d, $%d", inst_rd, inst_rs, inst_rt);
          end
          6'd43: begin // sltu
            $sformat(inst_str, "sltu $%d, $%d, $%d", inst_rd, inst_rs, inst_rt);
          end
          default: begin
            $display("Unknown instruction: opc: %x, funct: %d", inst_opc, inst_funct);
          end
        endcase // case (inst_funct)
      end // case: 6'h00

      6'h01: begin
        case (inst_rt)
          5'h00: begin // bltz
            $sformat(inst_str, "bltz $%d, 0x%x", inst_rs, inst_imm);
          end
          5'h01: begin // bgez
            $sformat(inst_str, "bgez $%d, 0x%x", inst_rs, inst_imm);
          end
          5'h10: begin // bltzal
            $sformat(inst_str, "bltzal $%d, 0x%x", inst_rs, inst_imm);
          end
          5'h11: begin // bgezal
            $sformat(inst_str, "bgezal $%d, 0x%x", inst_rs, inst_imm);
          end
          default: begin
            $display("Unknown instruction: opc: %x, rt: %d", inst_opc, inst_rt);
          end
        endcase // case (inst_rt)
      end // case: 6'h01

      6'h02: begin // j
        $sformat(inst_str, "j 0x%x", inst_addr);
      end

      6'h03: begin // jal
        $sformat(inst_str, "jal 0x%x", inst_addr);
      end

      6'h04: begin // beq
        $sformat(inst_str, "beq $%d, $%d, 0x%x", inst_rs, inst_rt, inst_imm);
      end

      6'h05: begin // bne
        $sformat(inst_str, "bne $%d, $%d, 0x%x", inst_rs, inst_rt, inst_imm);
      end

      6'h06: begin // blez
        $sformat(inst_str, "blez $%d, 0x%x", inst_rs, inst_imm);
      end

      6'h07: begin // bgtz
        $sformat(inst_str, "bgtz $%d, 0x%x", inst_rs, inst_imm);
      end

      6'h08: begin // addi
        $sformat(inst_str, "addi $%d, $%d, 0x%x", inst_rt, inst_rs, inst_imm);
      end

      6'h09: begin // addiu
        $sformat(inst_str, "addiu $%d, $%d, 0x%x", inst_rt, inst_rs, inst_imm);
      end

      6'h0a: begin // slti
        $sformat(inst_str, "slti $%d, $%d, 0x%x", inst_rt, inst_rs, inst_imm);
      end

      6'h0b: begin // sltiu
        $sformat(inst_str, "sltiu $%d, $%d, 0x%x", inst_rt, inst_rs, inst_imm);
      end

      6'h0c: begin // andi
        $sformat(inst_str, "andi $%d, $%d, 0x%x", inst_rt, inst_rs, inst_imm);
      end

      6'h0d: begin // ori
        $sformat(inst_str, "ori $%d, $%d, 0x%x", inst_rt, inst_rs, inst_imm);
      end

      6'h0e: begin // xori
        $sformat(inst_str, "xori $%d, $%d, 0x%x", inst_rt, inst_rs, inst_imm);
      end

      6'h0f: begin // lui
        $sformat(inst_str, "lui $%d, 0x%x", inst_rt, inst_imm);
      end

      6'h20: begin // lb
        $sformat(inst_str, "lb, $%d, ($%d + ...0x%x)", inst_rt, inst_rs, inst_imm);
      end

      6'h21: begin // lh
        $sformat(inst_str, "lh, $%d, ($%d + ...0x%x)", inst_rt, inst_rs, inst_imm);
      end

      6'h23: begin // lw
        $sformat(inst_str, "lw, $%d, ($%d + ...0x%x)", inst_rt, inst_rs, inst_imm);
      end

      6'h24: begin // lbu
        $sformat(inst_str, "lbu, $%d, ($%d + ...0x%x)", inst_rt, inst_rs, inst_imm);
      end

      6'h25: begin //lhu
        $sformat(inst_str, "lhu, $%d, ($%d + ...0x%x)", inst_rt, inst_rs, inst_imm);
      end

      6'h28: begin // sb
        $sformat(inst_str, "sb, $%d, ($%d + ...0x%x)", inst_rt, inst_rs, inst_imm);
      end

      6'h29: begin // sh
        $sformat(inst_str, "sh, $%d, ($%d + ...0x%x)", inst_rt, inst_rs, inst_imm);
      end

      6'h2b: begin // sw
        $sformat(inst_str, "sw, $%d, ($%d + ...0x%x)", inst_rt, inst_rs, inst_imm);
      end

      default: begin
        $display("Unknown instruction: opc: %x", inst_opc);
      end
    endcase // case (inst_opc)
  end // always_comb

endmodule
