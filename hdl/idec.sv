import pipTypes::*;

module idec
(
  input [31:0]               pc,
  input [31:0]               inst_word,

  output dec_inst_t          di
);


  wire [5:0]                 inst_opc;
  wire [4:0]                 inst_rs;
  wire [4:0]                 inst_rt;
  wire [4:0]                 inst_rd;
  wire [15:0]                inst_imm;
  wire [25:0]                inst_addr;
  wire [4:0]                 inst_shamt;
  wire [5:0]                 inst_funct;

  reg                        inst_rformat;
  reg                        inst_jformat;
  reg                        inst_iformat;

  reg                        imm_sext;

  wire [31:0]                pc_plus_4;
  wire [31:0]                pc_plus_8;



  wire [31:0]                branch_target;

  reg [ 4:0]                 A_reg;
  reg                        A_reg_valid;
  reg [ 4:0]                 B_reg;
  reg                        B_reg_valid;
  reg [ 4:0]                 C_reg;
  reg                        C_reg_valid;


  reg [ 4:0]                 dest_reg;
  reg                        dest_reg_valid;

  wire [31:0]                imm;
  wire                       imm_valid;

  reg [ 4:0]                 shamt;
  reg                        shamt_valid;
  reg                        shleft;
  reg                        sharith;
  reg                        shopsela;

  alu_op_t                   alu_op;
  alu_res_t                  alu_res_sel;
  reg                        alu_set_u;

  muldiv_op_t                muldiv_op;
  reg                        muldiv_op_u;

  ls_op_t                    ls_op;
  reg                        ls_sext;

  cond_t                     branch_cond;

  reg                        alu_inst;
  reg                        muldiv_inst;
  reg                        load_inst;
  reg                        store_inst;
  reg                        jmp_inst;
  reg                        branch_inst;
  wire                       nop;



  assign inst_opc   = inst_word[31:26];
  assign inst_rs    = inst_word[25:21];
  assign inst_rt    = inst_word[20:16];
  assign inst_rd    = inst_word[15:11];
  assign inst_imm   = inst_word[15: 0];
  assign inst_addr  = inst_word[25: 0];
  assign inst_shamt = inst_word[10: 6];
  assign inst_funct = inst_word[ 5: 0];


  assign nop        = (inst_word == 32'b0);


  always_comb begin
    A_reg           = inst_rs;
    A_reg_valid     = 1'b0;
    B_reg           = inst_rt;
    B_reg_valid     = 1'b0;
    C_reg           = inst_rd;
    C_reg_valid     = 1'b0;
    dest_reg        = inst_rt;
    shamt           = inst_shamt;
    shamt_valid     = 1'b0;
    shleft          = 1'b0;
    sharith         = 1'b0;
    shopsela        = 1'b0;
    alu_inst        = 1'b0;
    muldiv_inst     = 1'b0;
    load_inst       = 1'b0;
    store_inst      = 1'b0;
    jmp_inst        = 1'b0;
    branch_inst     = 1'b0;
    dest_reg_valid  = 1'b1;
    imm_sext        = 1'b0;
    inst_rformat    = 1'b0;
    inst_iformat    = 1'b1;
    inst_jformat    = 1'b0;
    alu_op          = OP_PASS_A;
    alu_set_u       = 1'b0;
    alu_res_sel     = RES_ALU;
    muldiv_op       = OP_NONE;
    muldiv_op_u     = 1'b0;
    ls_op           = OP_LS_WORD;
    ls_sext         = 1'b0;
    branch_cond     = COND_UNCONDITIONAL;


    case (inst_opc)
      6'h00: begin
        inst_rformat    = 1'b1;
        inst_iformat    = 1'b0;
        dest_reg        = inst_rd;

        case (inst_funct)
          6'd00: begin // sll
            shamt_valid  = 1'b1;
            shleft       = 1'b1;
            alu_inst     = 1'b1;
            alu_res_sel  = RES_SHIFT;
            B_reg_valid  = 1'b1;
          end
          6'd02: begin // srl
            shamt_valid  = 1'b1;
            alu_inst     = 1'b1;
            alu_res_sel  = RES_SHIFT;
            B_reg_valid  = 1'b1;
          end
          6'd03: begin // sra
            shamt_valid  = 1'b1;
            sharith      = 1'b1;
            alu_inst     = 1'b1;
            alu_res_sel  = RES_SHIFT;
            B_reg_valid  = 1'b1;
          end
          6'd04: begin // sllv
            shleft       = 1'b1;
            alu_inst     = 1'b1;
            alu_res_sel  = RES_SHIFT;
            A_reg_valid  = 1'b1;
            B_reg_valid  = 1'b1;
          end
          6'd06: begin // srlv
            alu_inst     = 1'b1;
            alu_res_sel  = RES_SHIFT;
            A_reg_valid  = 1'b1;
            B_reg_valid  = 1'b1;
          end
          6'd07: begin // srav
            sharith      = 1'b1;
            alu_inst     = 1'b1;
            alu_res_sel  = RES_SHIFT;
            A_reg_valid  = 1'b1;
            B_reg_valid  = 1'b1;
          end
          6'd08: begin // jr
            jmp_inst        = 1'b1;
            dest_reg_valid  = 1'b0;
            A_reg_valid     = 1'b1;
          end
          6'd09: begin // jalr
            jmp_inst     = 1'b1;
            alu_op       = OP_PASS_B;
            A_reg_valid  = 1'b1;
          end
          6'd10: begin // movz
            // use three operands so it isn't speculative
            alu_inst     = 1'b1;
            alu_op       = OP_MOVZ;
            A_reg_valid  = 1'b1;
            B_reg_valid  = 1'b1;
            C_reg_valid  = 1'b1;
          end
          6'd11: begin // movn
            // use three operands so it isn't speculative
            alu_inst     = 1'b1;
            alu_op       = OP_MOVN;
            A_reg_valid  = 1'b1;
            B_reg_valid  = 1'b1;
            C_reg_valid  = 1'b1;
          end
          6'd13: begin // break
            // XXX: this is not really a break exception; it halts simulation.
            $display("BREAK!");
            $stop(); // XXX: consider $finish()
          end
          6'd16: begin // mfhi
            muldiv_inst  = 1'b1;
            muldiv_op    = OP_MFHI;
          end
          6'd17: begin // mthi
            muldiv_inst     = 1'b1;
            muldiv_op       = OP_MTHI;
            A_reg_valid     = 1'b1;
            dest_reg_valid  = 1'b0;
          end
          6'd18: begin // mflo
            muldiv_inst  = 1'b1;
            muldiv_op    = OP_MFLO;
          end
          6'd19: begin // mtlo
            muldiv_inst     = 1'b1;
            muldiv_op       = OP_MTLO;
            A_reg_valid     = 1'b1;
            dest_reg_valid  = 1'b0;
          end
          6'd24: begin // mult
            muldiv_inst     = 1'b1;
            muldiv_op       = OP_MUL;
            A_reg_valid     = 1'b1;
            B_reg_valid     = 1'b1;
            dest_reg_valid  = 1'b0;
          end
          6'd25: begin // multu
            muldiv_inst     = 1'b1;
            muldiv_op       = OP_MUL;
            muldiv_op_u     = 1'b1;
            A_reg_valid     = 1'b1;
            B_reg_valid     = 1'b1;
            dest_reg_valid  = 1'b0;
          end
          6'd26: begin // div
            muldiv_inst     = 1'b1;
            muldiv_op       = OP_DIV;
            A_reg_valid     = 1'b1;
            B_reg_valid     = 1'b1;
            dest_reg_valid  = 1'b0;
          end
          6'd27: begin // divu
            muldiv_inst     = 1'b1;
            muldiv_op       = OP_DIV;
            muldiv_op_u     = 1'b1;
            A_reg_valid     = 1'b1;
            B_reg_valid     = 1'b1;
            dest_reg_valid  = 1'b0;
          end
          6'd32: begin // add
            alu_inst  = 1'b1;
            alu_op    = OP_ADD;
            A_reg_valid  = 1'b1;
            B_reg_valid  = 1'b1;
          end
          6'd33: begin // addu
            alu_inst  = 1'b1;
            alu_op    = OP_ADD;
            A_reg_valid  = 1'b1;
            B_reg_valid  = 1'b1;
          end
          6'd34: begin // sub
            alu_inst  = 1'b1;
            alu_op    = OP_SUB;
            A_reg_valid  = 1'b1;
            B_reg_valid  = 1'b1;
          end
          6'd35: begin // subu
            alu_inst  = 1'b1;
            alu_op    = OP_SUB;
            A_reg_valid  = 1'b1;
            B_reg_valid  = 1'b1;
          end
          6'd36: begin // and
            alu_inst  = 1'b1;
            alu_op    = OP_AND;
            A_reg_valid  = 1'b1;
            B_reg_valid  = 1'b1;
          end
          6'd37: begin // or
            alu_inst  = 1'b1;
            alu_op    = OP_OR;
            A_reg_valid  = 1'b1;
            B_reg_valid  = 1'b1;
          end
          6'd38: begin // xor
            alu_inst  = 1'b1;
            alu_op    = OP_XOR;
            A_reg_valid  = 1'b1;
            B_reg_valid  = 1'b1;
          end
          6'd39: begin // nor
            alu_inst  = 1'b1;
            alu_op    = OP_NOR;
            A_reg_valid  = 1'b1;
            B_reg_valid  = 1'b1;
          end
          6'd42: begin // slt
            alu_inst     = 1'b1;
            alu_op       = OP_SUB;
            alu_res_sel  = RES_SET;
            A_reg_valid  = 1'b1;
            B_reg_valid  = 1'b1;
          end
          6'd43: begin // sltu
            alu_inst     = 1'b1;
            alu_op       = OP_SUB;
            alu_res_sel  = RES_SET;
            alu_set_u    = 1'b1;
            A_reg_valid  = 1'b1;
            B_reg_valid  = 1'b1;
          end

          6'd52: begin // teq
            // XXX: teq is not implemented, but we don't care - it's used to check for div-by-zero
          end

          default: begin
            dest_reg_valid  = 1'b0;
            load_inst       = 1'b0;
            store_inst      = 1'b0;
            $display("Unknown instruction: opc: %x, funct: %d (pc: %x)", inst_opc, inst_funct, pc);
          end
        endcase // case (inst_funct)
      end // case: 6'h00

      6'h01: begin
        case (inst_rt)
          5'h00: begin // bltz
            dest_reg_valid  = 1'b0;
            branch_inst     = 1'b1;
            branch_cond     = COND_LT;
            A_reg_valid     = 1'b1;
          end

          5'h01: begin // bgez
            dest_reg_valid  = 1'b0;
            branch_inst     = 1'b1;
            branch_cond     = COND_GE;
            A_reg_valid     = 1'b1;
          end

          5'h10: begin // bltzal
            dest_reg        = 5'd31;
            dest_reg_valid  = 1'b1;
            branch_inst     = 1'b1;
            branch_cond     = COND_LT;
            A_reg_valid     = 1'b1;
            alu_op          = OP_PASS_B;
          end

          5'h11: begin // bgezal
            dest_reg        = 5'd31;
            dest_reg_valid  = 1'b1;
            branch_inst     = 1'b1;
            branch_cond     = COND_GE;
            A_reg_valid     = 1'b1;
            alu_op          = OP_PASS_B;
          end

          default: begin
            dest_reg_valid  = 1'b0;
            load_inst       = 1'b0;
            store_inst      = 1'b0;
            $display("Unknown instruction: opc: %x, rt: %d (pc: %x)", inst_opc, inst_rt, pc);
          end
        endcase // case (inst_rt)
      end // case: 6'h01

      6'h02: begin // j
        inst_iformat   = 1'b0;
        inst_jformat   = 1'b1;
        dest_reg_valid = 1'b0;
        jmp_inst       = 1'b1;
      end

      6'h03: begin // jal
        inst_iformat = 1'b0;
        inst_jformat = 1'b1;
        dest_reg     = 5'd31;
	alu_op       = OP_PASS_B;
        jmp_inst     = 1'b1;
      end

      6'h04: begin // beq
        dest_reg_valid = 1'b0;
        branch_inst    = 1'b1;
        branch_cond    = COND_EQ;
        A_reg_valid    = 1'b1;
        B_reg_valid    = 1'b1;
      end

      6'h05: begin // bne
        dest_reg_valid = 1'b0;
        branch_inst    = 1'b1;
        branch_cond    = COND_NE;
        A_reg_valid    = 1'b1;
        B_reg_valid    = 1'b1;
      end

      6'h06: begin // blez
        dest_reg_valid = 1'b0;
        branch_inst    = 1'b1;
        branch_cond    = COND_LE;
        A_reg_valid    = 1'b1;
      end

      6'h07: begin // bgtz
        dest_reg_valid = 1'b0;
        branch_inst    = 1'b1;
        branch_cond    = COND_GT;
        A_reg_valid    = 1'b1;
      end

      6'h08: begin // addi
        imm_sext     = 1'b1;
        alu_inst     = 1'b1;
        alu_op       = OP_ADD;
        A_reg_valid  = 1'b1;
      end

      6'h09: begin // addiu
        imm_sext     = 1'b1;
        alu_inst     = 1'b1;
        alu_op       = OP_ADD;
        A_reg_valid  = 1'b1;
      end

      6'h0a: begin // slti
        imm_sext     = 1'b1;
        alu_inst     = 1'b1;
        alu_op       = OP_SUB;
        alu_res_sel  = RES_SET;
        A_reg_valid  = 1'b1;
      end

      6'h0b: begin // sltiu
        imm_sext     = 1'b1;
        alu_inst     = 1'b1;
        alu_op       = OP_SUB;
        alu_res_sel  = RES_SET;
        alu_set_u    = 1'b1;
        A_reg_valid  = 1'b1;
      end

      6'h0c: begin // andi
        alu_inst     = 1'b1;
        alu_op       = OP_AND;
        A_reg_valid  = 1'b1;
      end

      6'h0d: begin // ori
        alu_inst     = 1'b1;
        alu_op       = OP_OR;
        A_reg_valid  = 1'b1;
      end

      6'h0e: begin // xori
        alu_inst     = 1'b1;
        alu_op       = OP_XOR;
        A_reg_valid  = 1'b1;
      end

      6'h0f: begin // lui
        alu_inst  = 1'b1;
        alu_op    = OP_LUI;
      end

      6'h1c: begin
        inst_rformat  = 1'b1;
        inst_iformat  = 1'b0;
        dest_reg      = inst_rd;

        shamt         = inst_shamt;

        case (inst_funct)
          6'd00: begin // madd
            muldiv_inst     = 1'b1;
            muldiv_op       = OP_MADD;
            A_reg_valid     = 1'b1;
            B_reg_valid     = 1'b1;
            dest_reg_valid  = 1'b0;
          end

          6'd00: begin // maddu
            muldiv_inst     = 1'b1;
            muldiv_op       = OP_MADD;
            muldiv_op_u     = 1'b1;
            A_reg_valid     = 1'b1;
            B_reg_valid     = 1'b1;
            dest_reg_valid  = 1'b0;
          end

          6'd02: begin // mul
            muldiv_inst     = 1'b1;
            alu_inst        = 1'b1;
            muldiv_op       = OP_MUL;
            muldiv_op_u     = 1'b1;
            A_reg_valid     = 1'b1;
            B_reg_valid     = 1'b1;
            dest_reg_valid  = 1'b1;
            alu_op          = OP_MUL_LO;
          end

          default: begin
            dest_reg_valid  = 1'b0;
            load_inst       = 1'b0;
            store_inst      = 1'b0;
            $display("Unknown instruction: opc: %x, funct: %d (pc: %x)", inst_opc, inst_funct, pc);
          end
        endcase
      end // case: 6'h1c

      6'h1f: begin
        case (inst_funct)
          6'd00: begin // ext
            alu_inst     = 1'b1;
            shleft       = 1'b0;
            shopsela     = 1'b1;
            sharith      = 1'b0;
            shamt_valid  = 1'b1;
            alu_op       = OP_EXT;
            A_reg_valid  = 1'b1;
          end

          6'd04: begin // ins
            alu_inst     = 1'b1;
            shleft       = 1'b1;
            shopsela     = 1'b1;
            sharith      = 1'b0;
            shamt_valid  = 1'b1;
            alu_op       = OP_INS;
            A_reg_valid  = 1'b1;
            B_reg_valid  = 1'b1;
          end

          6'd32: begin
            inst_rformat  = 1'b1;
            inst_iformat  = 1'b0;
            dest_reg      = inst_rd;

            case (inst_shamt)
              5'd16: begin // seb
                alu_inst     = 1'b1;
                alu_op       = OP_SEB;
                B_reg_valid  = 1'b1;
              end

              5'd24: begin // seh
                alu_inst  = 1'b1;
                alu_op    = OP_SEH;
                B_reg_valid  = 1'b1;
              end

              default: begin
                dest_reg_valid  = 1'b0;
                load_inst       = 1'b0;
                store_inst      = 1'b0;
                $display("Unknown instruction: opc: %x, funct: %d, shamt: %d (pc: %x)", inst_opc, inst_funct, inst_shamt, pc);
              end
            endcase
          end

          default: begin
            dest_reg_valid  = 1'b0;
            load_inst       = 1'b0;
            store_inst      = 1'b0;
            $display("Unknown instruction: opc: %x, funct: %d (pc: %x)", inst_opc, inst_funct, pc);
          end
        endcase
      end // case: 6'h1f

      6'h20: begin // lb
        alu_op       = OP_ADD;
        imm_sext     = 1'b1;
        load_inst    = 1'b1;
        A_reg_valid  = 1'b1;
        ls_op        = OP_LS_BYTE;
        ls_sext      = 1'b1;
      end

      6'h21: begin // lh
        alu_op       = OP_ADD;
        imm_sext     = 1'b1;
        load_inst    = 1'b1;
        A_reg_valid  = 1'b1;
        ls_op        = OP_LS_HALFWORD;
        ls_sext      = 1'b1;
      end

      6'h23: begin // lw
        alu_op       = OP_ADD;
        imm_sext     = 1'b1;
        load_inst    = 1'b1;
        A_reg_valid  = 1'b1;
      end

      6'h24: begin // lbu
        alu_op       = OP_ADD;
        imm_sext     = 1'b1;
        load_inst    = 1'b1;
        A_reg_valid  = 1'b1;
        ls_op        = OP_LS_BYTE;
      end

      6'h25: begin //lhu
        alu_op       = OP_ADD;
        imm_sext     = 1'b1;
        load_inst    = 1'b1;
        A_reg_valid  = 1'b1;
        ls_op        = OP_LS_HALFWORD;
      end

      6'h28: begin // sb
        alu_op          = OP_ADD;
        imm_sext        = 1'b1;
        store_inst      = 1'b1;
        A_reg_valid     = 1'b1;
        B_reg_valid     = 1'b1;
        dest_reg_valid  = 1'b0;
        ls_op           = OP_LS_BYTE;
      end

      6'h29: begin // sh
        alu_op          = OP_ADD;
        imm_sext        = 1'b1;
        store_inst      = 1'b1;
        A_reg_valid     = 1'b1;
        B_reg_valid     = 1'b1;
        dest_reg_valid  = 1'b0;
        ls_op           = OP_LS_HALFWORD;
      end

      6'h2b: begin // sw
        alu_op          = OP_ADD;
        imm_sext        = 1'b1;
        store_inst      = 1'b1;
        A_reg_valid     = 1'b1;
        B_reg_valid     = 1'b1;
        dest_reg_valid  = 1'b0;
      end

      default: begin
        dest_reg_valid  = 1'b0;
        load_inst       = 1'b0;
        store_inst      = 1'b0;
        $display("Unknown instruction: opc: %x (pc: %x)", inst_opc, pc);
      end
    endcase // case (inst_opc)

    // Don't let anything write to $0 - and don't use it for forwarding, either.
    if (dest_reg == 5'd0)
      dest_reg_valid  = 1'b0;

    if (stall) begin
`ifdef TRACE_ENABLE
      $display("Introducing a bubble and stalling (pc: %x)", pc);
`endif
      dest_reg_valid  = 1'b0;
      load_inst       = 1'b0;
      store_inst      = 1'b0;
`ifdef NOT_DEFINED
      jmp_inst        = 1'b0;
      branch_inst     = 1'b0;
`endif
      muldiv_inst     = 1'b0;
      muldiv_op       = OP_NONE;
    end
  end


  assign imm  = (imm_sext)                      ? { {16{inst_imm[15]}}, inst_imm }
              :                                   { 16'd0, inst_imm };

  assign imm_valid  = inst_iformat;




  // Branching logic
  assign pc_plus_4  = pc + 4;
  assign pc_plus_8  = pc + 8;

  assign branch_target = (jmp_inst)        ? { pc_plus_4[31:28], inst_addr, 2'b00 }
                       : /* branch_inst */   pc_plus_4 + { {14{inst_imm[15]}}, inst_imm, 2'b00 };






  // Connect it all into dec_inst_t di
  always_comb
    begin
      di.pc              = pc;
      di.inst_word       = inst_word;

      di.branch_cond     = branch_cond;
      di.branch_target   = branch_target;

      di.A_reg           = A_reg;
      di.A_reg_valid     = A_reg_valid;
      di.B_reg           = B_reg;
      di.B_reg_valid     = B_reg_valid;

      di.C_reg           = C_reg;
      di.C_reg_valid     = C_reg_valid;

      di.dest_reg        = dest_reg;
      di.dest_reg_valid  = dest_reg_valid;

      di.imm             = imm;
      di.imm_valid       = imm_valid;
      di.shamt           = shamt;
      di.shamt_valid     = shamt_valid;
      di.shleft          = shleft;
      di.sharith         = sharith;
      di.shopsela        = shopsela;

      di.alu_op          = alu_op;
      di.alu_res_sel     = alu_res_sel;
      di.alu_set_u       = alu_set_u;

      di.muldiv_op       = muldiv_op;
      di.muldiv_op_u     = muldiv_op_u;

      di.ls_op           = ls_op;
      di.ls_sext         = ls_sext;

      di.alu_inst        = alu_inst;
      di.muldiv_inst     = muldiv_inst;
      di.load_inst       = load_inst;
      di.store_inst      = store_inst;
      di.jmp_inst        = jmp_inst;
      di.branch_inst     = branch_inst;
      di.nop             = nop;

      di.inst_rformat    = inst_rformat;
    end

endmodule
