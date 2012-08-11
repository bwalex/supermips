module ISS
(
  input         clock,
  input         reset_n,

  // IQ interface
  output        ext_enable,
  output [1:0]  ext_consumed,
  input         ext_valid[4],
  input         iq_entry_t insns[4],
  input         empty,


  // ROB Associative Lookup interface
  output [3:0]  as_query_idx[4],
  output [4:0]  as_areg[4],
  output [4:0]  as_breg[4],
  output [4:0]  as_creg[4],

  input [31:0]  as_aval[4],
  input [31:0]  as_bval[4],
  input [31:0]  as_cval[4],

  input         as_aval_valid[4],
  input         as_bval_valid[4],
  input         as_cval_valid[4],

  input         as_aval_present[4],
  input         as_bval_present[4],
  input         as_cval_present[4],

  // ROB store interface for "branch unit"
  output [3:0]  wr_slot,
  output        wr_valid,
  output [31:0] wr_data,

  // LS unit interface
  output [ 3:0] ls_rob_slot,
  output [31:0] ls_A,
  output [31:0] ls_B,
  output        dec_inst_t ls_inst,
  output        ls_inst_valid,
  input         ls_ready,

  // EX unit interface
  output [ 3:0] ex1_rob_slot,
  output [31:0] ex1_A,
  output [31:0] ex1_B,
  output [31:0] ex1_C,
  output        dec_inst_t ex1_inst,
  output        ex1_inst_valid,
  input         ex1_ready,

  // EXMUL unit interface
  output [ 3:0] exmul1_rob_slot,
  output [31:0] exmul1_A,
  output [31:0] exmul1_B,
  output [31:0] exmul1_C,
  output        dec_inst_t exmul1_inst,
  output        exmul1_inst_valid,
  input         exmul1_ready,


  // IF interface
  input         branch_stall,
  output [31:0] new_pc,
  output        new_pc_valid,

  // Register file interface
  output [31:0] rd_addr[12],
  input  [31:0] rd_data[12]
);

  dec_inst_t    di[4];
  wire [ 3:0]   rob_slot[4];
  wire [31:0]   di_A[4];
  wire [31:0]   di_B[4];
  wire [31:0]   di_C[4];
  wire          di_A_valid[4];
  wire          di_B_valid[4];
  wire          di_C_valid[4];
  wire          di_ops_ready[4];

  dec_inst_t    lsi;
  dec_inst_t    ex1i;
  dec_Inst_t    exmul1i;
  dec_inst_t    bi;

  wire [31:0]   branch_A;
  wire [31:0]   branch_B;

  wire [31:0]   pc_plus_4;
  wire [31:0]   pc_plus_8;
  wire [31:0]   new_imm_pc;
  wire          AB_equal;
  wire          A_gtz;
  wire          A_gez;
  wire          A_eqz;
  wire          B_eqz;
  wire          stall_i;
  wire          branch_cond_ok;

  assign di[0]  = insns[0].dec_inst;
  assign di[1]  = insns[1].dec_inst;
  assign di[2]  = insns[2].dec_inst;
  assign di[3]  = insns[3].dec_inst;

  assign rob_slot[0]  = insns[0].rob_slot;
  assign rob_slot[1]  = insns[1].rob_slot;
  assign rob_slot[2]  = insns[2].rob_slot;
  assign rob_slot[3]  = insns[3].rob_slot;

  assign as_query_idx[0]  = rob_slot[0];
  assign as_query_idx[1]  = rob_slot[1];
  assign as_query_idx[2]  = rob_slot[2];
  assign as_query_idx[3]  = rob_slot[3];

  assign as_areg[0]  = di[0].A_reg;
  assign as_areg[1]  = di[1].A_reg;
  assign as_areg[2]  = di[2].A_reg;
  assign as_areg[3]  = di[3].A_reg;

  assign as_breg[0]  = di[0].B_reg;
  assign as_breg[1]  = di[1].B_reg;
  assign as_breg[2]  = di[2].B_reg;
  assign as_breg[3]  = di[3].B_reg;

  assign as_creg[0]  = di[0].C_reg;
  assign as_creg[1]  = di[1].C_reg;
  assign as_creg[2]  = di[2].C_reg;
  assign as_creg[3]  = di[3].C_reg;

  assign rd_addr[ 0]  = di[0].A_reg;
  assign rd_addr[ 1]  = di[0].B_reg;
  assign rd_addr[ 2]  = di[0].C_reg;
  assign rd_addr[ 3]  = di[1].A_reg;
  assign rd_addr[ 4]  = di[1].B_reg;
  assign rd_addr[ 5]  = di[1].C_reg;
  assign rd_addr[ 6]  = di[2].A_reg;
  assign rd_addr[ 7]  = di[2].B_reg;
  assign rd_addr[ 8]  = di[2].C_reg;
  assign rd_addr[ 9]  = di[3].A_reg;
  assign rd_addr[10]  = di[3].B_reg;
  assign rd_addr[11]  = di[3].C_reg;


  genvar        i;
  generate
    for (i = 0; i < 4; i++) begin : AS_FWD
      assign di_A[i]  = (as_aval_present[i]) ? as_aval[i] : rd_data[i*3 + 0];
      assign di_B[i]  = (as_bval_present[i]) ? as_bval[i] : rd_data[i*3 + 1];
      assign di_C[i]  = (as_cval_present[i]) ? as_cval[i] : rd_data[i*3 + 2];
    end

    for (i = 0; i < 4; i++) begin : AS_FWD_VALID
      // the values are valid when they are either not in the ROB (~present) and hence
      // are in up-to-date in the register file; OR when they are both present and valid
      // in the ROB.
      assign di_A_valid[i]  = ~as_aval_present[i] | (as_aval_present[i] & as_aval_valid[i]);
      assign di_B_valid[i]  = ~as_bval_present[i] | (as_bval_present[i] & as_bval_valid[i]);
      assign di_C_valid[i]  = ~as_cval_present[i] | (as_cval_present[i] & as_cval_valid[i]);
    end

    for (i = 0; i < 4; i++) begin : OPS_READY
      // Signal whether all operands are ready. This is the case when every operand
      // is either not required (~reg_valid) or valid.
      assign di_ops_ready[i]  =  (di_A_valid[i] | ~di.A_reg_valid)
                               & (di_B_valid[i] | ~di.B_reg_valid)
                               & (di_C_valid[i] | ~di.C_reg_valid)
                               ;
    end
  endgenerate


  always_comb begin
    automatic bit b_used, ls_used, ex1_used, exmul1_used;
    automatic integer consumed;

    consumed           = 0;
    ext_consumed       = 2'd0;
    ext_enable         = 1'b0;

    b_used             = 1'b0;
    ls_used            = 1'b0;
    ex1_used           = 1'b0;
    exmul1_used        = 1'b0;

    bi                 = di[0];
    lsi                = di[0];
    ex1i               = di[0];
    exmul1i            = di[0];
    branch_A           = di_A[0];
    branch_B           = di_B[0];
    ls_A               = di_A[0];
    ls_B               = di_B[0];
    exmul1_A           = di_A[0];
    exmul1_B           = di_B[0];
    exmul1_C           = di_C[0];
    ex1_A              = di_A[0];
    ex1_B              = di_B[0];
    ex1_C              = di_C[0];

    // XXX: still need to assign rob slots
    // XXX: directly wire up to output foo_inst signals instead of using internal 'i' signals

    branch_inst_valid  = 1'b0;
    ls_inst_valid      = 1'b0;
    exmul1_inst_valid  = 1'b0;
    ex1_inst_valid     = 1'b0;

    for (integer i = 0; i < 4; i++) begin
      if (!ext_valid[i]) begin
        // If this instruction is not valid, then stop here; we cannot
        // extract out of order.
        break;
      end

      if (!di_ops_ready[i]) begin
        // If the instruction is still missing operands then we also stop
        // here since issue happens strictly in order.
        break;
      end

      if ((di[i].branch_inst | di[i].jmp_inst) && !b_used && branch_ready) begin
        b_used    = 1'b1;
        bi        = di[i];
        branch_A  = di_A[i];
        branch_B  = di_B[i];
        consumed++;
      end
      else if ((di[i].load_inst | di[i].store_inst) && !ls_used && ls_ready) begin
        ls_used  = 1'b1;
        lsi      = di[i];
        ls_A     = di_A[i];
        ls_B     = di_B[i];
        consumed++;
      end
      else if (di[i].muldiv_inst && !ex1mul_used && exmul1_ready) begin
        exmul1_used  = 1'b1;
        exmul1i      = di[i];
        exmul1_A     = di_A[i];
        exmul1_B     = di_B[i];
        exmul1_C     = di_C[i];
        consumed++;
      end
      else if (di[i].alu_inst && !ex1_used && ex1_ready) begin
        ex1_used  = 1'b1;
        ex1i      = di[i];
        ex1_A     = di_A[i];
        ex1_B     = di_B[i];
        ex1_C     = di_C[i];
        consumed++;
      end
      else if (di[i].alu_inst && !exmul1_used && exmul1_ready) begin
        ex1mul_used  = 1'b1;
        ex1muli      = di[i];
        exmul1_A     = di_A[i];
        exmul1_B     = di_B[i];
        exmul1_C     = di_C[i];
        consumed++;
      end
      else begin
        // If none of the execution units is available in this cycle
        // for this instruction then we stop here since we are issuing
        // strictly in order.
        break;
      end
      end // for (integer i = 0; i < 4; i++)

    ext_consumed       = consumed - 1;
    ext_enable         = (consumed > 0) ? 1'b1 : 1'b0;

    branch_inst_valid  = b_used;
    ls_inst_valid      = ls_used;
    exmul1_inst_valid  = exmul1_used;
    ex1_inst_valid     = ex1_used;
  end



  // XXX: need to:
  //      cause a stall when branch is last instruction (of either the 4,
  //      or whatever number is available).
  //
  // ISS will only continue with the branching, to start with, if the
  // branch delay slot is available in the same cycle as the branch itself.
  //
  // This can be further optimized so that the branch can execute this
  // cycle if IQ already contains the BDS instruction, just not
  // pushed out this cycle. (i.e. not at the top during this cycle).
  //
  // Branching logic
  assign pc_plus_4  = bi.pc + 4;
  assign pc_plus_8  = bi.pc + 8;

  assign AB_equal  = (A_forwarded == B_forwarded);
  assign A_gtz     = A_gez & ~A_eqz;
  assign A_gez     = (A_forwarded[31] == 1'b0);

  assign A_eqz     = (A_forwarded == 0);
  assign B_eqz     = (B_forwarded == 0);

  assign new_pc    = (inst_iformat | inst_jformat) ? bi.branch_target : A_forwarded;

  assign new_pc_valid    = (bi.jmp_inst | (bi.branch_inst & bi.branch_cond_ok)) & bi_ops_valid;
  assign branch_cond_ok  = (bi.branch_cond == COND_UNCONDITIONAL)
                         | (bi.branch_cond == COND_EQ && AB_equal)
                         | (bi.branch_cond == COND_NE && ~AB_equal)
                         | (bi.branch_cond == COND_GT && A_gtz)
                         | (bi.branch_cond == COND_GE && A_gez)
                         | (bi.branch_cond == COND_LT && ~A_gez)
                         | (bi.branch_cond == COND_LE && ~A_gtz);


endmodule