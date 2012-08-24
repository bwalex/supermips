import pipTypes::*;

module idec #(
  parameter ALU_OP_WIDTH = 12,
            LS_OP_WIDTH = 4
)(
  input                         clock,
  input                         reset_n,

  input [31:0]                  pc,
  input [31:0]                  inst_word,

  input [31:0]                  pc_plus_4,

  input                         branch_stall,
  input                         front_stall,

  output [ 4:0]                 rfile_rd_addr1,
  output [ 4:0]                 rfile_rd_addr2,

  input [31:0]                  rfile_rd_data1,
  input [31:0]                  rfile_rd_data2,

  input [ 4:0]                  id_ex_dest_reg,
  input [ 4:0]                  ex_mem_dest_reg,
  input                         id_ex_dest_reg_valid,
  input                         ex_mem_dest_reg_valid,
  input                         id_ex_load_inst,
  input                         ex_mem_load_inst,

  input [31:0]                  result_from_ex_mem,

  output                        stall,
  output [11:0]                 opc,

  output [31:0]                 A,
  output [31:0]                 B,
  output reg [ 4:0]             A_reg,
  output reg                    A_reg_valid,
  output reg [ 4:0]             B_reg,
  output reg                    B_reg_valid,
  output reg                    B_need_late,
  output [31:0]                 imm,
  output                        imm_valid,
  output reg [ 4:0]             shamt,
  output reg                    shamt_valid,
  output reg                    shleft,
  output reg                    sharith,
  output reg                    shopsela,
  output alu_op_t               alu_op,
  output alu_res_t              alu_res_sel,
  output reg                    alu_set_u,
  output muldiv_op_t            muldiv_op,
  output reg                    muldiv_op_u,

  output ls_op_t                ls_op,
  output reg                    ls_sext,

  output cond_t                 branch_cond,

  output reg                    alu_inst,
  output reg                    muldiv_inst,
  output reg                    load_inst,
  output reg                    store_inst,
  output reg                    jmp_inst,
  output reg                    branch_inst,

  output                        nop,

  output reg [ 4:0]             dest_reg,
  output reg                    dest_reg_valid,
  output [31:0]                 new_pc,
  output                        new_pc_valid
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

  reg  [31:0]                A_forwarded;
  reg  [31:0]                B_forwarded;

  wire                       A_fwd_ex_mem;
  wire                       B_fwd_ex_mem;

  reg                        A_fwd_ex_mem_d1;
  reg                        B_fwd_ex_mem_d1;

  wire [31:0]                pc_plus_8;
  wire [31:0]                new_imm_pc;

  wire                       AB_equal;
  wire                       A_gtz;
  wire                       A_gez;
  wire                       A_eqz;
  wire                       B_eqz;

  reg  [31:0]                result_from_ex_mem_retained;
  reg                        stall_d1;

  wire                       stall_i;

  wire                       branch_cond_ok;


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n) begin
      A_fwd_ex_mem_d1 <= 1'b0;
      B_fwd_ex_mem_d1 <= 1'b0;
    end
    else if (~stall_d1) begin
      A_fwd_ex_mem_d1 <= A_fwd_ex_mem;
      B_fwd_ex_mem_d1 <= B_fwd_ex_mem;
    end


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      stall_d1 <= 1'b0;
    else
      stall_d1 <= (branch_stall & new_pc_valid & ~front_stall);


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      result_from_ex_mem_retained <= 32'b0;
    else if (stall & ~stall_d1)
      result_from_ex_mem_retained <= result_from_ex_mem;



  // Forwarding and stalling logic
  assign A_reg_match_id_ex  = id_ex_dest_reg_valid  && A_reg_valid && (A_reg == id_ex_dest_reg);
  assign B_reg_match_id_ex  = id_ex_dest_reg_valid  && B_reg_valid && (B_reg == id_ex_dest_reg);

  assign A_reg_match_ex_mem = ex_mem_dest_reg_valid && A_reg_valid && (A_reg == ex_mem_dest_reg);
  assign B_reg_match_ex_mem = ex_mem_dest_reg_valid && B_reg_valid && (B_reg == ex_mem_dest_reg);


  assign A_fwd_ex_mem  = A_reg_match_ex_mem;
  assign B_fwd_ex_mem  = B_reg_match_ex_mem;


  always_comb
    begin
      A_forwarded  = A;
      if (stall_d1) begin
        if (A_fwd_ex_mem_d1)
          A_forwarded  = result_from_ex_mem_retained;
      end
      else begin
        if (A_fwd_ex_mem)
          A_forwarded  = result_from_ex_mem;
      end
    end


  always_comb
    begin
      B_forwarded  = B;
      if (stall_d1) begin
        if (B_fwd_ex_mem_d1)
          B_forwarded  = result_from_ex_mem_retained;
      end
      else begin
        if (B_fwd_ex_mem)
          B_forwarded  = result_from_ex_mem;
      end
    end







  // Stall when depending on a load instruction currently in the EX stage
  // or on a conditional branch when the result-generating instruction is now entering EX
  // or on a conditional branch when the result-generating instruction is a load now entering MEM
  // or on a jump-register when the result-generating instruction is now entering EX
  // or on a jump-register when the result-generating instruction is a load now entering MEM
  // or when pipeline stages further down stall
  // or when ifetch stalls while we are trying to load a new pc
  assign stall_i  =  (id_ex_load_inst && (A_reg_match_id_ex || (~B_need_late && B_reg_match_id_ex)))
                   | (A_reg_match_id_ex && (branch_inst && branch_cond != COND_UNCONDITIONAL))
                   | (A_reg_match_ex_mem && ex_mem_load_inst && (branch_inst && branch_cond != COND_UNCONDITIONAL))
                   | (B_reg_match_id_ex && (branch_inst && (branch_cond == COND_EQ || branch_cond == COND_NE)))
                   | (B_reg_match_ex_mem && ex_mem_load_inst && (branch_inst && (branch_cond == COND_NE || branch_cond == COND_EQ)))
                   | (A_reg_match_id_ex && (jmp_inst & ~imm_valid))
                   | (A_reg_match_ex_mem && ex_mem_load_inst && (jmp_inst & ~imm_valid))
                   | front_stall;

  assign stall    =  stall_i
                   | (branch_stall & new_pc_valid);



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


  assign nop  = (inst_word == 32'b0);


  always_comb begin
    A_reg           = inst_rs;
    A_reg_valid     = 1'b0;
    B_reg           = inst_rt;
    B_reg_valid     = 1'b0;
    B_need_late     = 1'b0;
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
            alu_inst        = 1'b1;
            alu_op          = OP_MOVZ;
            A_reg_valid     = 1'b1;
            B_reg_valid     = 1'b1;
          end
          6'd11: begin // movn
            alu_inst        = 1'b1;
            alu_op          = OP_MOVN;
            A_reg_valid     = 1'b1;
            B_reg_valid     = 1'b1;
          end
          6'd13: begin // break
            // XXX: this is not really a break exception; it halts simulation.
            $display("BREAK!");
            $finish();
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


  assign imm  = (new_pc_valid & dest_reg_valid) ? pc_plus_8
              : (imm_sext)                      ? { {16{inst_imm[15]}}, inst_imm }
              :                                   { 16'd0, inst_imm };

  assign A   = rfile_rd_data1;
  assign B   = rfile_rd_data2;

  assign imm_valid  = inst_iformat | inst_jformat | (new_pc_valid & dest_reg_valid);










  // Branching logic
  assign pc_plus_8  = pc_plus_4 + 4;

  assign AB_equal  = (A_forwarded == B_forwarded);
  assign A_gtz     = A_gez & ~A_eqz;
  assign A_gez     = (A_forwarded[31] == 1'b0);

  assign A_eqz     = (A_forwarded == 0);
  assign B_eqz     = (B_forwarded == 0);

  assign new_imm_pc  = (jmp_inst)        ? { pc_plus_4[31:28], inst_addr, 2'b00 }
                     : /* branch_inst */   pc_plus_4 + { {14{inst_imm[15]}}, inst_imm, 2'b00 };



  assign new_pc    = (inst_iformat | inst_jformat) ? new_imm_pc : A_forwarded;

  assign new_pc_valid    = (jmp_inst | (branch_inst & branch_cond_ok)) & ~stall_i;
  assign branch_cond_ok  = (branch_cond == COND_UNCONDITIONAL)
                         | (branch_cond == COND_EQ && AB_equal)
                         | (branch_cond == COND_NE && ~AB_equal)
                         | (branch_cond == COND_GT && A_gtz)
                         | (branch_cond == COND_GE && A_gez)
                         | (branch_cond == COND_LT && ~A_gez)
                         | (branch_cond == COND_LE && ~A_gtz);

endmodule
