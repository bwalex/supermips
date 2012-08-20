import pipTypes::*;

module iss#(
            parameter ROB_DEPTHLOG2 = 4
            )
(
  input                          clock,
  input                          reset_n,

  // IQ interface
  output reg                     ext_enable,
  output reg [1:0]               ext_consumed,
  input                          ext_valid[4],
  input                          iq_entry_t insns[4],
  input                          empty,


  // ROB Associative Lookup interface
  output [ROB_DEPTHLOG2-1:0]     as_query_idx[4],
  output [4:0]                   as_areg[4],
  output [4:0]                   as_breg[4],

  input [31:0]                   as_aval[4],
  input [31:0]                   as_bval[4],

  input                          as_aval_valid[4],
  input                          as_bval_valid[4],

  input                          as_aval_present[4],
  input                          as_bval_present[4],

  // ROB store interface for "branch unit"
  output [ROB_DEPTHLOG2-1:0]     wr_slot,
  output                         wr_valid,
  output                         rob_entry_t wr_data,

  // LS unit interface
  output reg [ROB_DEPTHLOG2-1:0] ls_rob_slot,
  output reg [31:0]              ls_A,
  output reg [31:0]              ls_B,
  output                         dec_inst_t ls_inst,
  output reg                     ls_inst_valid,
  input                          ls_ready,

  // EX unit interface
  output reg [ROB_DEPTHLOG2-1:0] ex1_rob_slot,
  output reg [31:0]              ex1_A,
  output reg [31:0]              ex1_B,
  output                         dec_inst_t ex1_inst,
  output reg                     ex1_inst_valid,
  input                          ex1_ready,

  // EXMUL unit interface
  output reg [ROB_DEPTHLOG2-1:0] exmul1_rob_slot,
  output reg [31:0]              exmul1_A,
  output reg [31:0]              exmul1_B,
  output                         dec_inst_t exmul1_inst,
  output reg                     exmul1_inst_valid,
  input                          exmul1_ready,


  // IF interface
  input                          branch_stall,
  output [31:0]                  new_pc,
  output                         new_pc_valid,
  output                         branch_flush,

  // Register file interface
  output [ 4:0]                  rd_addr[8],
  input [31:0]                   rd_data[8]
);

  dec_inst_t    di[4];
  wire [ROB_DEPTHLOG2-1:0]       rob_slot[4];
  wire [31:0]   di_A[4];
  wire [31:0]   di_B[4];
  wire          di_A_valid[4];
  wire          di_B_valid[4];
  wire          di_ops_ready[4];

  dec_inst_t    lsi;
  dec_inst_t    ex1i;
  dec_inst_t    exmul1i;
  dec_inst_t    bi;

  reg [31:0]    branch_A;
  reg [31:0]    branch_B;
  reg [ROB_DEPTHLOG2-1:0] branch_rob_slot;
  reg           bi_inst_valid;

  dec_inst_t    bi_retained;
  reg           bi_inst_valid_retained;
  reg  [31:0]   branch_A_retained;
  reg  [31:0]   branch_B_retained;
  reg  [ROB_DEPTHLOG2-1:0]   branch_rob_slot_retained;
  reg           branch_stall_d1;
  wire          branch_ready;

  dec_inst_t    bi_act;
  wire          bi_inst_valid_act;
  wire [31:0]   branch_A_act;
  wire [31:0]   branch_B_act;
  wire [ROB_DEPTHLOG2-1:0] branch_rob_slot_act;

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

  assign rd_addr[0]  = di[0].A_reg;
  assign rd_addr[1]  = di[0].B_reg;
  assign rd_addr[2]  = di[1].A_reg;
  assign rd_addr[3]  = di[1].B_reg;
  assign rd_addr[4]  = di[2].A_reg;
  assign rd_addr[5]  = di[2].B_reg;
  assign rd_addr[6]  = di[3].A_reg;
  assign rd_addr[7]  = di[3].B_reg;


  genvar        i;
  generate
    for (i = 0; i < 4; i++) begin : AS_FWD
      assign di_A[i]  = (as_aval_present[i]) ? as_aval[i] : rd_data[i*2 + 0];
      assign di_B[i]  = (as_bval_present[i]) ? as_bval[i] : rd_data[i*2 + 1];
    end

    for (i = 0; i < 4; i++) begin : AS_FWD_VALID
      // the values are valid when they are either not in the ROB (~present) and hence
      // are in up-to-date in the register file; OR when they are both present and valid
      // in the ROB.
      assign di_A_valid[i]  = ~as_aval_present[i] | (as_aval_present[i] & as_aval_valid[i]);
      assign di_B_valid[i]  = ~as_bval_present[i] | (as_bval_present[i] & as_bval_valid[i]);
    end

    for (i = 0; i < 4; i++) begin : OPS_READY
      // Signal whether all operands are ready. This is the case when every operand
      // is either not required (~reg_valid) or valid.
      assign di_ops_ready[i]  =  (di_A_valid[i] | ~di[i].A_reg_valid)
                               & (di_B_valid[i] | ~di[i].B_reg_valid)
                               ;
    end
  endgenerate


  always_comb begin
    automatic bit b_used, ls_used, ex1_used, exmul1_used;
    automatic integer consumed;

    consumed           = 0;

    b_used             = 1'b0;
    ls_used            = 1'b0;
    ex1_used           = 1'b0;
    exmul1_used        = 1'b0;

    bi                 = di[0];
    ls_inst            = di[0];
    ex1_inst           = di[0];
    exmul1_inst        = di[0];
    branch_A           = di_A[0];
    branch_B           = di_B[0];
    branch_rob_slot    = rob_slot[0];
    ls_A               = di_A[0];
    ls_B               = di_B[0];
    ls_rob_slot        = rob_slot[0];
    exmul1_A           = di_A[0];
    exmul1_B           = di_B[0];
    exmul1_rob_slot    = rob_slot[0];
    ex1_A              = di_A[0];
    ex1_B              = di_B[0];
    ex1_rob_slot       = rob_slot[0];


    // XXX: directly wire up to output foo_inst signals instead of using internal '_used' vars

    bi_inst_valid      = 1'b0;
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

      if ((di[i].branch_inst | di[i].jmp_inst) && !b_used && branch_ready
          // don't allow branch to proceed if we don't have the BDS insn available and ready, too
          && i != 3 && ext_valid[i+1] && di_ops_ready[i+1]) begin
        b_used           = 1'b1;
        bi               = di[i];
        branch_A         = di_A[i];
        branch_B         = di_B[i];
        branch_rob_slot  = rob_slot[i];
        consumed++;
      end
      else if ((di[i].load_inst | di[i].store_inst) && !ls_used && ls_ready) begin
        ls_used      = 1'b1;
        ls_inst      = di[i];
        ls_A         = di_A[i];
        ls_B         = di_B[i];
        ls_rob_slot  = rob_slot[i];
        consumed++;
      end
      else if (di[i].muldiv_inst && !exmul1_used && exmul1_ready) begin
        exmul1_used      = 1'b1;
        exmul1_inst      = di[i];
        exmul1_A         = di_A[i];
        exmul1_B         = di_B[i];
        exmul1_rob_slot  = rob_slot[i];
        consumed++;
      end
      else if (di[i].alu_inst && !ex1_used && ex1_ready) begin
        ex1_used      = 1'b1;
        ex1_inst      = di[i];
        ex1_A         = di_A[i];
        ex1_B         = di_B[i];
        ex1_rob_slot  = rob_slot[i];
        consumed++;
      end
      else if (di[i].alu_inst && !exmul1_used && exmul1_ready) begin
        exmul1_used      = 1'b1;
        exmul1_inst      = di[i];
        exmul1_A         = di_A[i];
        exmul1_B         = di_B[i];
        exmul1_rob_slot  = rob_slot[i];
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

    bi_inst_valid      = b_used;
    ls_inst_valid      = ls_used;
    exmul1_inst_valid  = exmul1_used;
    ex1_inst_valid     = ex1_used;
  end



  // XXX: need to:
  //      cause a stall when branch is last instruction (of either the 4,
  //      or whatever number is available).
  //
  //      Retain bi, branch_A and branch_B when an IF-induced stall occurs.
  //
  //      Pump out the link register to ROB
  //
  // ISS will only continue with the branching, to start with, if the
  // branch delay slot is available in the same cycle as the branch itself.
  //
  // This can be further optimized so that the branch can execute this
  // cycle if IQ already contains the BDS instruction, just not
  // pushed out this cycle. (i.e. not at the top during this cycle).
  //
  // Branching logic
  assign pc_plus_4  = bi_act.pc + 4;
  assign pc_plus_8  = bi_act.pc + 8;

  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      branch_stall_d1 <= 1'b0;
    else
      branch_stall_d1 <= branch_stall;

  assign branch_ready = ~branch_stall_d1;

  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n) begin
      branch_A_retained <= 'b0;
      branch_B_retained <= 'b0;
      bi_inst_valid_retained   <= 1'b0;
      branch_rob_slot_retained <=  'b0;
    end
    else if (branch_stall & ~branch_stall_d1) begin
      bi_retained       <= bi;
      branch_A_retained <= branch_A;
      branch_B_retained <= branch_B;
      bi_inst_valid_retained   <= bi_inst_valid;
      branch_rob_slot_retained <= branch_rob_slot;
    end

  assign bi_act       = (branch_stall_d1) ? bi_retained       : bi;
  assign branch_A_act = (branch_stall_d1) ? branch_A_retained : branch_A;
  assign branch_B_act = (branch_stall_d1) ? branch_B_retained : branch_B;

  assign bi_inst_valid_act   = (branch_stall_d1) ? bi_inst_valid_retained   : bi_inst_valid;
  assign branch_rob_slot_act = (branch_stall_d1) ? branch_rob_slot_retained : branch_rob_slot;

  assign branch_flush = new_pc_valid & ~branch_stall_d1;

  assign AB_equal  = (branch_A_act == branch_B_act);
  assign A_gtz     = A_gez & ~A_eqz;
  assign A_gez     = (branch_A_act[31] == 1'b0);

  assign A_eqz     = (branch_A_act == 0);
  assign B_eqz     = (branch_B_act == 0);

  assign new_pc  = (bi_act.inst_rformat) ? branch_A_act : bi_act.branch_target;

  // new_pc_valid is effectively branch_taken and mispredicted
  // this will also cause a complete flush of the IQ, and a partial flush
  // (except for the branch and the BDS) of the ROB.
  assign new_pc_valid   =  (bi_act.jmp_inst | (bi_act.branch_inst & branch_cond_ok))
                         &  bi_inst_valid_act
                         ;

  assign branch_cond_ok =  (bi_act.branch_cond == COND_UNCONDITIONAL)
                         | (bi_act.branch_cond == COND_EQ &&  AB_equal)
                         | (bi_act.branch_cond == COND_NE && ~AB_equal)
                         | (bi_act.branch_cond == COND_GT &&  A_gtz)
                         | (bi_act.branch_cond == COND_GE &&  A_gez)
                         | (bi_act.branch_cond == COND_LT && ~A_gez)
                         | (bi_act.branch_cond == COND_LE && ~A_gtz)
                         ;


  assign wr_slot                 = branch_rob_slot_act;
  assign wr_valid                = ~branch_stall & bi_inst_valid_act;
  assign wr_data.result_lo       = pc_plus_8;
  assign wr_data.dest_reg        = bi_act.dest_reg;
  assign wr_data.dest_reg_valid  = bi_act.dest_reg_valid;
  assign wr_data.pc_valid        = new_pc_valid;




`ifdef ISS_TRACE_ENABLE
  integer trace_file;

  initial begin
    trace_file = $fopen("iss.trace", "w");
  end

  always_ff @(posedge clock) begin
    $fwrite(trace_file, "%d: ISS: ls_ready=%b, ex1_ready=%b, exmul1_ready=%b, branch_ready=%b\n",
      $time, ls_ready, ex1_ready, exmul1_ready, branch_ready);

    if (ls_inst_valid)
      $fwrite(trace_file, "%d: ISS: issuing to LS:     pc=%x, A=%x, B=%x, rob_slot=%d, iw: %x\n",
        $time, ls_inst.pc, ls_A, ls_B, ls_rob_slot, ls_inst.inst_word);

    if (ex1_inst_valid)
      $fwrite(trace_file, "%d: ISS: issuing to EX1:    pc=%x, A=%x, B=%x, rob_slot=%d, iw: %x\n",
        $time, ex1_inst.pc, ex1_A, ex1_B, ex1_rob_slot, ex1_inst.inst_word);
    
    if (exmul1_inst_valid)
      $fwrite(trace_file, "%d: ISS: issuing to EXMUL1: pc=%x, A=%x, B=%x, rob_slot=%d, iw: %x\n",
        $time, exmul1_inst.pc, exmul1_A, exmul1_B, exmul1_rob_slot, exmul1_inst.inst_word);
    
    if (bi_inst_valid)
      $fwrite(trace_file, "%d: ISS: issuing to BRANCH: pc=%x, A=%x, B=%x, rob_slot=%d, iw: %x\n",
        $time, bi.pc, branch_A, branch_B, branch_rob_slot, bi.inst_word);
  end
`endif
endmodule
