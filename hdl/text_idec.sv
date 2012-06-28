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
            $sformat(inst_str, "sll $%0d, $%0d, %0d", inst_rd, inst_rt, inst_shamt);
          end
          6'd02: begin // srl
            $sformat(inst_str, "srl $%0d, $%0d, %0d", inst_rd, inst_rt, inst_shamt);
          end
          6'd03: begin // sra
            $sformat(inst_str, "sra $%0d, $%0d, %0d", inst_rd, inst_rt, inst_shamt);
          end
          6'd04: begin // sllv
            $sformat(inst_str, "sllv $%0d, $%0d, $%0d", inst_rd, inst_rt, inst_rs);
          end
          6'd06: begin // srlv
            $sformat(inst_str, "srlv $%0d, $%0d, $%0d", inst_rd, inst_rt, inst_rs);
          end
          6'd07: begin // srav
            $sformat(inst_str, "srav $%0d, $%0d, $%0d", inst_rd, inst_rt, inst_rs);
          end
          6'd08: begin // jr
            $sformat(inst_str, "jr $%0d", inst_rs);
          end
          6'd09: begin // jalr
            $sformat(inst_str, "jalr $%0d, $%0d", inst_rs, inst_rd);
          end
          6'd32: begin // add
            $sformat(inst_str, "add $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          6'd33: begin // addu
            $sformat(inst_str, "addu $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          6'd34: begin // sub
            $sformat(inst_str, "sub $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          6'd35: begin // subu
            $sformat(inst_str, "sub $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          6'd36: begin // and
            $sformat(inst_str, "and $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          6'd37: begin // or
            $sformat(inst_str, "or $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          6'd38: begin // xor
            $sformat(inst_str, "xor $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          6'd39: begin // nor
            $sformat(inst_str, "nor $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          6'd42: begin // slt
            $sformat(inst_str, "slt $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          6'd43: begin // sltu
            $sformat(inst_str, "sltu $%0d, $%0d, $%0d", inst_rd, inst_rs, inst_rt);
          end
          default: begin
            $display("Unknown instruction: opc: %x, funct: %0d", inst_opc, inst_funct);
          end
        endcase // case (inst_funct)
      end // case: 6'h00

      6'h01: begin
        case (inst_rt)
          5'h00: begin // bltz
            $sformat(inst_str, "bltz $%0d, 0x%x", inst_rs, inst_imm);
          end
          5'h01: begin // bgez
            $sformat(inst_str, "bgez $%0d, 0x%x", inst_rs, inst_imm);
          end
          5'h10: begin // bltzal
            $sformat(inst_str, "bltzal $%0d, 0x%x", inst_rs, inst_imm);
          end
          5'h11: begin // bgezal
            $sformat(inst_str, "bgezal $%0d, 0x%x", inst_rs, inst_imm);
          end
          default: begin
            $display("Unknown instruction: opc: %x, rt: %0d", inst_opc, inst_rt);
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
        $sformat(inst_str, "beq $%0d, $%0d, 0x%x", inst_rs, inst_rt, inst_imm);
      end

      6'h05: begin // bne
        $sformat(inst_str, "bne $%0d, $%0d, 0x%x", inst_rs, inst_rt, inst_imm);
      end

      6'h06: begin // blez
        $sformat(inst_str, "blez $%0d, 0x%x", inst_rs, inst_imm);
      end

      6'h07: begin // bgtz
        $sformat(inst_str, "bgtz $%0d, 0x%x", inst_rs, inst_imm);
      end

      6'h08: begin // addi
        $sformat(inst_str, "addi $%0d, $%0d, 0x%x", inst_rt, inst_rs, inst_imm);
      end

      6'h09: begin // addiu
        $sformat(inst_str, "addiu $%0d, $%0d, 0x%x", inst_rt, inst_rs, inst_imm);
      end

      6'h0a: begin // slti
        $sformat(inst_str, "slti $%0d, $%0d, 0x%x", inst_rt, inst_rs, inst_imm);
      end

      6'h0b: begin // sltiu
        $sformat(inst_str, "sltiu $%0d, $%0d, 0x%x", inst_rt, inst_rs, inst_imm);
      end

      6'h0c: begin // andi
        $sformat(inst_str, "andi $%0d, $%0d, 0x%x", inst_rt, inst_rs, inst_imm);
      end

      6'h0d: begin // ori
        $sformat(inst_str, "ori $%0d, $%0d, 0x%x", inst_rt, inst_rs, inst_imm);
      end

      6'h0e: begin // xori
        $sformat(inst_str, "xori $%0d, $%0d, 0x%x", inst_rt, inst_rs, inst_imm);
      end

      6'h0f: begin // lui
        $sformat(inst_str, "lui $%0d, 0x%x", inst_rt, inst_imm);
      end

      6'h20: begin // lb
        $sformat(inst_str, "lb, $%0d, ($%0d + ...0x%x)", inst_rt, inst_rs, inst_imm);
      end

      6'h21: begin // lh
        $sformat(inst_str, "lh, $%0d, ($%0d + ...0x%x)", inst_rt, inst_rs, inst_imm);
      end

      6'h23: begin // lw
        $sformat(inst_str, "lw, $%0d, ($%0d + ...0x%x)", inst_rt, inst_rs, inst_imm);
      end

      6'h24: begin // lbu
        $sformat(inst_str, "lbu, $%0d, ($%0d + ...0x%x)", inst_rt, inst_rs, inst_imm);
      end

      6'h25: begin //lhu
        $sformat(inst_str, "lhu, $%0d, ($%0d + ...0x%x)", inst_rt, inst_rs, inst_imm);
      end

      6'h28: begin // sb
        $sformat(inst_str, "sb, $%0d, ($%0d + ...0x%x)", inst_rt, inst_rs, inst_imm);
      end

      6'h29: begin // sh
        $sformat(inst_str, "sh, $%0d, ($%0d + ...0x%x)", inst_rt, inst_rs, inst_imm);
      end

      6'h2b: begin // sw
        $sformat(inst_str, "sw, $%0d, ($%0d + ...0x%x)", inst_rt, inst_rs, inst_imm);
      end

      default: begin
        $display("Unknown instruction: opc: %x", inst_opc);
      end
    endcase // case (inst_opc)
  end // always_comb

endmodule
