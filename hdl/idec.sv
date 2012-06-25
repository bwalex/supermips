import pipTypes::*;

module idec #(
  parameter ALU_OP_WIDTH = 12,
            LS_OP_WIDTH = 4
)(
  input                         clock,
  input                         reset_n,

  input [31:0]                  pc,
  input [31:0]                  inst_word,

  output [ 4:0]                 rfile_rd_addr1,
  output [ 4:0]                 rfile_rd_addr2,

  input [31:0]                  rfile_rd_data1,
  input [31:0]                  rfile_rd_data2,

  input [ 4:0]                  id_ex_dest_reg,
  input [ 4:0]                  ex_mem_dest_reg,
  input                         id_ex_dest_reg_valid,
  input                         ex_mem_dest_reg_valid,
  input                         id_ex_load_inst,

  output                        stall,
  output [11:0]                 opc,

  output [31:0]                 A,
  output [31:0]                 B,
  output reg [ 4:0]             A_reg,
  output reg                    A_reg_valid,
  output fwd_t                  A_fwd_from,
  output reg [ 4:0]             B_reg,
  output reg                    B_reg_valid,
  output reg                    B_need_late,
  output fwd_t                  B_fwd_from,
  output [31:0]                 imm,
  output                        imm_valid,
  output reg [ 4:0]             shamt,
  output alu_op_t               alu_op,
  output alu_res_t              alu_res_sel,
  output reg                    alu_set_u,

  output ls_op_t                ls_op,
  output reg                    ls_sext,

  output cond_t                 jmp_cond,

  output reg                    alu_inst,
  output reg                    load_inst,
  output reg                    store_inst,
  output reg                    jmp_inst,

  output reg [ 4:0]             dest_reg,
  output reg                    dest_reg_valid
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
  reg                        imm_lsl_2;
  wire [31:0]                imm_extended;

  wire                       A_reg_match_id_ex;
  wire                       A_reg_match_ex_mem;
  wire                       B_reg_match_id_ex;
  wire                       B_reg_match_ex_mem;


  // Forwarding and stalling logic
  assign A_reg_match_id_ex  = id_ex_dest_reg_valid  && A_reg_valid && (A_reg == id_ex_dest_reg);
  assign B_reg_match_id_ex  = id_ex_dest_reg_valid  && B_reg_valid && (B_reg == id_ex_dest_reg);

  assign A_reg_match_ex_mem = ex_mem_dest_reg_valid && A_reg_valid && (A_reg == ex_mem_dest_reg);
  assign B_reg_match_ex_mem = ex_mem_dest_reg_valid && B_reg_valid && (B_reg == ex_mem_dest_reg);

  assign A_fwd_from  =  (A_reg_match_id_ex)  ? FWD_FROM_EXMEM
                      : (A_reg_match_ex_mem) ? FWD_FROM_MEMWB
                      :                        FWD_NONE;

  // Forwarding of B has special case of requiring B late, and B also available late
  assign B_fwd_from  =  (B_reg_match_id_ex)  ? (id_ex_load_inst ? FWD_FROM_MEMWB_LATE : FWD_FROM_EXMEM)
                      : (B_reg_match_ex_mem) ? FWD_FROM_MEMWB
                      :                        FWD_NONE;

  // Stall when depending on a load instruction currently in the EX stage
  assign stall  = id_ex_load_inst && (A_reg_match_id_ex || (~B_need_late && B_reg_match_id_ex));



  // XXX: could use A_reg, B_reg (more "correct") but
  //      using inst_{rs,rt} is good enough and is
  //      faster.
  assign rfile_rd_addr1  = inst_rs;
  assign rfile_rd_addr2  = inst_rt;

  assign inst_opc   = inst_word[31:26];
  assign inst_rs    = inst_word[25:21];
  assign inst_rt    = inst_word[20:16];
  assign inst_rd    = inst_word[15:11];
  assign inst_imm   = inst_word[15: 0];
  assign inst_addr  = inst_word[25: 0];
  assign inst_shamt = inst_word[10: 6];
  assign inst_funct = inst_word[ 5: 0];

  assign opc  = { inst_opc, inst_funct };


  always_comb begin
    A_reg           = inst_rs;
    A_reg_valid     = 1'b0;
    B_reg           = inst_rt;
    B_reg_valid     = 1'b0;
    B_need_late     = 1'b0;
    dest_reg        = inst_rt;
    shamt           = 0;
    alu_inst        = 1'b0;
    load_inst       = 1'b0;
    store_inst      = 1'b0;
    jmp_inst        = 1'b0;
    dest_reg_valid  = 1'b1;
    imm_sext        = 1'b0;
    imm_lsl_2       = 1'b0;
    inst_rformat    = 1'b0;
    inst_iformat    = 1'b1;
    inst_jformat    = 1'b0;
    alu_op          = OP_PASS_A;
    alu_set_u       = 1'b0;
    alu_res_sel     = RES_ALU;
    ls_op           = OP_LS_WORD;
    ls_sext         = 1'b0;
    jmp_cond        = COND_UNCONDITIONAL;


    case (inst_opc)
      6'h00: begin
        inst_rformat    = 1'b1;
        inst_iformat    = 1'b0;
        dest_reg        = inst_rd;

        shamt           = inst_shamt;

        case (inst_funct)
          6'd00: begin // sll
            alu_inst     = 1'b1;
            alu_op       = OP_SLL;
            B_reg_valid  = 1'b1;
          end
          6'd02: begin // srl
            alu_inst     = 1'b1;
            alu_op       = OP_SRL;
            B_reg_valid  = 1'b1;
          end
          6'd03: begin // sra
            alu_inst     = 1'b1;
            alu_op       = OP_SRA;
            B_reg_valid  = 1'b1;
          end
          6'd04: begin // sllv
            alu_inst     = 1'b1;
            alu_op       = OP_SLL;
            A_reg_valid  = 1'b1;
            B_reg_valid  = 1'b1;
          end
          6'd06: begin // srlv
            alu_inst     = 1'b1;
            alu_op       = OP_SRL;
            A_reg_valid  = 1'b1;
            B_reg_valid  = 1'b1;
          end
          6'd07: begin // srav
            alu_inst     = 1'b1;
            alu_op       = OP_SRA;
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
            A_reg_valid  = 1'b1;
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

          default: begin
            dest_reg_valid  = 1'b0;
            load_inst       = 1'b0;
            store_inst      = 1'b0;
            $display("Unknown instruction: opc: %x, funct: %d", inst_opc, inst_funct);
          end
        endcase // case (inst_funct)
      end // case: 6'h00

      6'h01: begin
        case (inst_rt)
          default: begin
            dest_reg_valid = 1'b0;
            load_inst      = 1'b0;
            store_inst     = 1'b0;
            $display("Unknown instruction: opc: %x, rt: %d", inst_opc, inst_rt);
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
        jmp_inst     = 1'b1;
      end

      6'h04: begin // beq
        dest_reg_valid = 1'b0;
        jmp_inst       = 1'b1;
        jmp_cond       = COND_EQ;
        A_reg_valid    = 1'b1;
        B_reg_valid    = 1'b1;
        alu_op         = OP_SUB;
      end

      6'h05: begin // bne
        dest_reg_valid = 1'b0;
        jmp_inst       = 1'b1;
        jmp_cond       = COND_NE;
        A_reg_valid    = 1'b1;
        B_reg_valid    = 1'b1;
        alu_op         = OP_SUB;
      end

      6'h06: begin // blez
        dest_reg_valid = 1'b0;
        jmp_inst       = 1'b1;
        jmp_cond       = COND_LE;
        A_reg_valid    = 1'b1;
        B_reg_valid    = 1'b1;
        alu_op         = OP_SUB;
      end

      6'h07: begin // bgtz
        dest_reg_valid = 1'b0;
        jmp_inst       = 1'b1;
        jmp_cond       = COND_GT;
        A_reg_valid    = 1'b1;
        B_reg_valid    = 1'b1;
        alu_op         = OP_SUB;
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
        B_need_late     = 1'b1; // Only need B in MEM stage, not EX/ALU
        dest_reg_valid  = 1'b0;
        ls_op           = OP_LS_BYTE;
      end

      6'h29: begin // sh
        alu_op          = OP_ADD;
        imm_sext        = 1'b1;
        store_inst      = 1'b1;
        A_reg_valid     = 1'b1;
        B_reg_valid     = 1'b1;
        B_need_late     = 1'b1; // Only need B in MEM stage, not EX/ALU
        dest_reg_valid  = 1'b0;
        ls_op           = OP_LS_HALFWORD;
      end

      6'h2b: begin // sw
        alu_op          = OP_ADD;
        imm_sext        = 1'b1;
        store_inst      = 1'b1;
        A_reg_valid     = 1'b1;
        B_reg_valid     = 1'b1;
        B_need_late     = 1'b1; // Only need B in MEM stage, not EX/ALU
        dest_reg_valid  = 1'b0;
      end

      default: begin
        dest_reg_valid  = 1'b0;
        load_inst       = 1'b0;
        store_inst      = 1'b0;
        $display("Unknown instruction: opc: %x", inst_opc);
      end
    endcase // case (inst_opc)

    if (stall) begin
      $display("Introducing a bubble and stalling.");
      dest_reg_valid  = 1'b0;
      load_inst       = 1'b0;
      store_inst      = 1'b0;
      jmp_inst        = 1'b0;
    end
  end


  // imm_lsl_2 always uses sign extension.
  assign imm_extended  = (imm_lsl_2) ? { {14{inst_imm[15]}}, inst_imm, 2'db00 }
                                     : (imm_sext ) ? { {16{inst_imm[15]}}, inst_imm }
                                                   : { 16'd0, inst_imm };


  assign A   = rfile_rd_data1;
  assign B   = rfile_rd_data2;
  assign imm  = imm_extended;

  assign imm_valid  = inst_iformat;
endmodule
