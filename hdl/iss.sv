import pipTypes::*;

module iss#(
            parameter ROB_DEPTHLOG2 = 4,
                      EX_UNITS = 1,
                      ISSUE_PER_CYCLE = 4,
                      IQ_DEPTHLOG2 = 4,
                      ISS_PC_LOG2 = `clogb2(ISSUE_PER_CYCLE)
)(
  input                          clock,
  input                          reset_n,

  // IQ interface
  output reg                     ext_enable,
  output reg                     ext_consumed[ISSUE_PER_CYCLE],
  input                          ext_valid[ISSUE_PER_CYCLE],
  input                          iq_entry_t insns[ISSUE_PER_CYCLE],
  input                          empty,


  // ROB Associative Lookup interface
  output [ROB_DEPTHLOG2-1:0]     as_query_idx[ISSUE_PER_CYCLE],
  output [4:0]                   as_areg[ISSUE_PER_CYCLE],
  output [4:0]                   as_breg[ISSUE_PER_CYCLE],

  input [31:0]                   as_aval[ISSUE_PER_CYCLE],
  input [31:0]                   as_bval[ISSUE_PER_CYCLE],

  input [ROB_DEPTHLOG2-1:0]      as_aval_idx[ISSUE_PER_CYCLE],
  input [ROB_DEPTHLOG2-1:0]      as_bval_idx[ISSUE_PER_CYCLE],

  input                          as_aval_valid[ISSUE_PER_CYCLE],
  input                          as_bval_valid[ISSUE_PER_CYCLE],

  input                          as_aval_present[ISSUE_PER_CYCLE],
  input                          as_bval_present[ISSUE_PER_CYCLE],

  input                          as_aval_transit[ISSUE_PER_CYCLE],
  input                          as_bval_transit[ISSUE_PER_CYCLE],


  // ROB store interface for "branch unit"
  output [ROB_DEPTHLOG2-1:0]     wr_slot,
  output                         wr_valid,
  output                         rob_entry_t wr_data,

  // LS unit interface
  output reg [ROB_DEPTHLOG2-1:0] ls_rob_slot,
  output reg [31:0]              ls_A,
  output reg [31:0]              ls_B,
  output                         fwd_info_t ls_fwd_info,
  output                         dec_inst_t ls_inst,
  output reg                     ls_inst_valid,
  input                          ls_ready,

  // EX unit interface
  output reg [ROB_DEPTHLOG2-1:0] ex_rob_slot[EX_UNITS],
  output reg [31:0]              ex_A[EX_UNITS],
  output reg [31:0]              ex_B[EX_UNITS],
  output                         fwd_info_t ex_fwd_info[EX_UNITS],
  output                         dec_inst_t ex_inst[EX_UNITS],
  output reg                     ex_inst_valid[EX_UNITS],
  input                          ex_ready[EX_UNITS],

  // EXMUL unit interface
  output reg [ROB_DEPTHLOG2-1:0] exmul1_rob_slot,
  output reg [31:0]              exmul1_A,
  output reg [31:0]              exmul1_B,
  output                         fwd_info_t exmul1_fwd_info,
  output                         dec_inst_t exmul1_inst,
  output reg                     exmul1_inst_valid,
  input                          exmul1_ready,

  // IF interface
  input                          branch_stall,
  output [31:0]                  new_pc,
  output                         new_pc_valid,
  output                         branch_flush,
  output                         branch_flush_stream,
  output [ROB_DEPTHLOG2-1:0]     branch_flush_slot,
  output [ 6:0]                  branch_flush_iq_idx,

  // Register file interface
  output [ 4:0]                  rd_addr[ISSUE_PER_CYCLE*2],
  input [31:0]                   rd_data[ISSUE_PER_CYCLE*2]
);


  dec_inst_t    di[ISSUE_PER_CYCLE];
  wire [ROB_DEPTHLOG2-1:0]       rob_slot[ISSUE_PER_CYCLE];
  wire [31:0]   di_A[ISSUE_PER_CYCLE];
  wire [31:0]   di_B[ISSUE_PER_CYCLE];
  wire          di_A_valid[ISSUE_PER_CYCLE];
  wire          di_B_valid[ISSUE_PER_CYCLE];
  wire          di_ops_ready[ISSUE_PER_CYCLE];
  wire          di_ops_almost_ready[ISSUE_PER_CYCLE];

  dec_inst_t    bi;

  reg           ls_speculative;
  reg           ex_speculative[EX_UNITS];
  reg           exmul1_speculative;

  reg [ISS_PC_LOG2-1:0] branch_idx;
  reg           bds_issued;
  reg           bds_issued_d1;
  reg           bds_missing;
  reg           bds_missing_r;
  reg [ROB_DEPTHLOG2-1:0] bds_flush_slot;
  reg [ROB_DEPTHLOG2-1:0] bds_flush_slot_r;
  reg [6:0]   bds_flush_iq_idx;
  reg [6:0]   bds_flush_iq_idx_r;
  wire        bds_flush_stream;
  reg         bds_flush_stream_r;

  reg [31:0]    branch_A;
  reg [31:0]    branch_B;
  reg [ROB_DEPTHLOG2-1:0] branch_rob_slot;
  reg [ 6:0]   branch_iq_idx;
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

  genvar        i;

  generate
    for (i = 0; i < ISSUE_PER_CYCLE; i++) begin : GEN_DI
      assign di[i]  = insns[i].dec_inst;
    end
  endgenerate

  generate
    for (i = 0; i < ISSUE_PER_CYCLE; i++) begin : GEN_ROB_SLOT
      assign rob_slot[i]  = insns[i].rob_slot;
    end
  endgenerate

  generate
    for (i = 0; i < ISSUE_PER_CYCLE; i++) begin : GEN_AS_QUERY_IDX
      assign as_query_idx[i]  = rob_slot[i];
    end
  endgenerate

  generate
    for (i = 0; i < ISSUE_PER_CYCLE; i++) begin : GEN_AS_AREG
      assign as_areg[i]  = di[i].A_reg;
    end
  endgenerate

  generate
    for (i = 0; i < ISSUE_PER_CYCLE; i++) begin : GEN_AS_BREG
      assign as_breg[i]  = di[i].B_reg;
    end
  endgenerate

  generate
    for (i = 0; i < ISSUE_PER_CYCLE; i++) begin : GEN_RD_ADDR
      assign rd_addr[i*2  ]  = di[i].A_reg;
      assign rd_addr[i*2+1]  = di[i].B_reg;
    end
  endgenerate

  generate
    for (i = 0; i < ISSUE_PER_CYCLE; i++) begin : AS_FWD
      assign di_A[i]  = (as_aval_present[i]) ? as_aval[i] : rd_data[i*2 + 0];
      assign di_B[i]  = (as_bval_present[i]) ? as_bval[i] : rd_data[i*2 + 1];
    end
  endgenerate

  generate
    for (i = 0; i < ISSUE_PER_CYCLE; i++) begin : AS_FWD_VALID
      // the values are valid when they are either not in the ROB (~present) and hence
      // are in up-to-date in the register file; OR when they are both present and valid
      // in the ROB.
      assign di_A_valid[i]  = ~as_aval_present[i] | (as_aval_present[i] & as_aval_valid[i]);
      assign di_B_valid[i]  = ~as_bval_present[i] | (as_bval_present[i] & as_bval_valid[i]);
    end
  endgenerate

  generate
    for (i = 0; i < ISSUE_PER_CYCLE; i++) begin : OPS_READY
      // Signal whether all operands are ready. This is the case when every operand
      // is either not required (~reg_valid) or valid.
      assign di_ops_ready[i]  =  (di_A_valid[i] | ~di[i].A_reg_valid)
                               & (di_B_valid[i] | ~di[i].B_reg_valid)
                               ;
      assign di_ops_almost_ready[i]  =  (~di[i].A_reg_valid | as_aval_transit[i])
                                      & (~di[i].B_reg_valid | as_bval_transit[i])
                                      ;
    end
  endgenerate


  function bit ex_unit_ready(bit ex_used[EX_UNITS], reg ex_ready[EX_UNITS]);
    for (integer i = 0; i < EX_UNITS; i++)
      if (!ex_used[i] && ex_ready[i])
        return 1'b1;

    return 1'b0;
  endfunction // ex_unit_ready


  always_comb begin
    automatic bit b_used, ls_used, ex_used[EX_UNITS], exmul1_used, spec, can_proceed;
    automatic bit [6:0] m, n;
    automatic bit ls_skipped;
    automatic bit md_skipped;
    automatic integer consumed;

    ls_skipped          = 1'b0;
    md_skipped          = 1'b0;
    consumed            = 0;
    branch_idx          = 'b0;

    b_used              = 1'b0;
    ls_used             = 1'b0;
    for (integer i = 0; i < EX_UNITS; i++)
      ex_used[i]        = 1'b0;
    exmul1_used         = 1'b0;
    spec                = 1'b0;

    ls_speculative      = 1'b0;
    for (integer i = 0; i < EX_UNITS; i++)
      ex_speculative[i]  = 1'b0;
    exmul1_speculative   = 1'b0;

    bi                   = di[0];
    ls_inst              = di[0];
    for (integer i = 0; i < EX_UNITS; i++)
      ex_inst[i]       = di[0];
    exmul1_inst        = di[0];
    branch_A           = di_A[0];
    branch_B           = di_B[0];
    branch_rob_slot    = rob_slot[0];
    branch_iq_idx      = insns[0].idx;
    ls_A               = di_A[0];
    ls_B               = di_B[0];
    ls_rob_slot        = rob_slot[0];
    exmul1_A           = di_A[0];
    exmul1_B           = di_B[0];
    exmul1_rob_slot    = rob_slot[0];
    for (integer i = 0; i < EX_UNITS; i++) begin
      ex_A[i]          = di_A[0];
      ex_B[i]          = di_B[0];
      ex_rob_slot[i]   = rob_slot[0];
    end

    ls_fwd_info.A_fwd          = ~di_A_valid[0];
    ls_fwd_info.A_rob_slot     = as_aval_idx[0];
    ls_fwd_info.B_fwd          = ~di_B_valid[0];
    ls_fwd_info.B_rob_slot     = as_bval_idx[0];
    exmul1_fwd_info.A_fwd      = ~di_A_valid[0];
    exmul1_fwd_info.A_rob_slot = as_aval_idx[0];
    exmul1_fwd_info.B_fwd      = ~di_B_valid[0];
    exmul1_fwd_info.B_rob_slot = as_bval_idx[0];
    for (integer i = 0; i < EX_UNITS; i++) begin
      ex_fwd_info[i].A_fwd      = ~di_A_valid[0];
      ex_fwd_info[i].A_rob_slot = as_aval_idx[0];
      ex_fwd_info[i].B_fwd      = ~di_B_valid[0];
      ex_fwd_info[i].B_rob_slot = as_bval_idx[0];
    end


    // XXX: directly wire up to output foo_inst signals instead of using internal '_used' vars

      bi_inst_valid          = 1'b0;
      ls_inst_valid          = 1'b0;
      exmul1_inst_valid      = 1'b0;
    for (integer i = 0; i < EX_UNITS; i++)
      ex_inst_valid[i]  = 1'b0;

    for (integer i = 0; i < ISSUE_PER_CYCLE; i++)
      ext_consumed[i]  = 1'b0;

    for (integer i = 0; i < ISSUE_PER_CYCLE; i++) begin
      if (!ext_valid[i]) begin
        // If this instruction is not valid, then stop here; there are no
        // more instructions in the IQ.
        break;
      end

`ifndef OOO_ENABLE
      if (bds_missing_r && i > 0)
        break;
`endif

      if   (!di_ops_ready[i]
`ifdef ROB_FORWARDING_ENABLE
        && !(di_ops_almost_ready[i] && !(di[i].branch_inst || di[i].jmp_inst))
`endif
      ) begin
        // If the instruction is still missing operands then we also stop
        // here since issue happens strictly in order.
        //
        // Alternatively, if the operands are almost ready and this is not
        // going to go to the branch unit, we can issue early and set up
        // forwarding.
`ifdef OOO_ENABLE
        // Don't issue anything after a branch that could not be scheduled
        // Don't issue any loads/stores after a load/store that could not be scheduled
        // XXX: spec
        if (di[i].load_inst | di[i].store_inst)
          ls_skipped = 1'b1;

        if (di[i].muldiv_inst)
          md_skipped = 1'b1;

        if (!(di[i].branch_inst | di[i].jmp_inst))
          continue;
`endif
        break;
      end

      if (b_used && i > (branch_idx + 1)) begin
	      // Anything after the BDS is speculative
	      spec = 1'b1;
      end

      // Disallow speculative execution
      // XXX: spec
      can_proceed = 1'b0;
      m = bds_flush_iq_idx_r - ISSUE_PER_CYCLE -32;
      n = insns[i].idx-1;
      for (integer j = 0; j <= ISSUE_PER_CYCLE+32; j++) begin
        if (m == n)
	  can_proceed = 1'b1;
        m += 1;
      end
      if (bds_missing_r && !can_proceed && branch_flush_stream == insns[i].stream) begin
        $fwrite(trace_file, "cannot continue pc: %x, can_proceed=%b, n=%d, m=%d\n", di[i].pc, can_proceed,n, m);
        continue;
      end

      ext_consumed[i]  = 1'b1;

      if ((di[i].branch_inst | di[i].jmp_inst) && !b_used && branch_ready) begin
        b_used           = 1'b1;
        branch_idx       = i;
        bi               = di[i];
        branch_A         = di_A[i];
        branch_B         = di_B[i];
        branch_rob_slot  = rob_slot[i];
        branch_iq_idx    = insns[i].idx;
        consumed++;
      end
      else if ((di[i].load_inst | di[i].store_inst) && !ls_used && ls_ready && !ls_skipped) begin
        ls_used                 = 1'b1;
        ls_inst                 = di[i];
        ls_A                    = di_A[i];
        ls_B                    = di_B[i];
        ls_rob_slot             = rob_slot[i];
	      ls_speculative          = spec;
        ls_fwd_info.A_fwd       = ~di_A_valid[i];
        ls_fwd_info.B_fwd       = ~di_B_valid[i];
        ls_fwd_info.A_rob_slot  = as_aval_idx[i];
        ls_fwd_info.B_rob_slot  = as_bval_idx[i];
        consumed++;
      end
      else if (di[i].muldiv_inst && !exmul1_used && exmul1_ready && !md_skipped) begin
        exmul1_used                 = 1'b1;
        exmul1_inst                 = di[i];
        exmul1_A                    = di_A[i];
        exmul1_B                    = di_B[i];
        exmul1_rob_slot             = rob_slot[i];
        exmul1_speculative          = spec;
        exmul1_fwd_info.A_fwd       = ~di_A_valid[i];
        exmul1_fwd_info.B_fwd       = ~di_B_valid[i];
        exmul1_fwd_info.A_rob_slot  = as_aval_idx[i];
        exmul1_fwd_info.B_rob_slot  = as_bval_idx[i];
        consumed++;
      end
      else if (di[i].alu_inst && ex_unit_ready(ex_used, ex_ready)) begin
        for (integer k = 0; k < EX_UNITS; k++) begin
          if (!ex_used[k] && ex_ready[k]) begin
            ex_used[k]                 = 1'b1;
            ex_inst[k]                 = di[i];
            ex_A[k]                    = di_A[i];
            ex_B[k]                    = di_B[i];
            ex_rob_slot[k]             = rob_slot[i];
	          ex_speculative[k]          = spec;
            ex_fwd_info[k].A_fwd       = ~di_A_valid[i];
            ex_fwd_info[k].B_fwd       = ~di_B_valid[i];
            ex_fwd_info[k].A_rob_slot  = as_aval_idx[i];
            ex_fwd_info[k].B_rob_slot  = as_bval_idx[i];
            break;
          end
        end // for (integer k = 0; k < EX_UNITS; k++)
        consumed++;
      end
      else if (di[i].alu_inst && !exmul1_used && exmul1_ready) begin
        exmul1_used                 = 1'b1;
        exmul1_inst                 = di[i];
        exmul1_A                    = di_A[i];
        exmul1_B                    = di_B[i];
        exmul1_rob_slot             = rob_slot[i];
	      exmul1_speculative          = spec;
        exmul1_fwd_info.A_fwd       = ~di_A_valid[i];
        exmul1_fwd_info.B_fwd       = ~di_B_valid[i];
        exmul1_fwd_info.A_rob_slot  = as_aval_idx[i];
        exmul1_fwd_info.B_rob_slot  = as_bval_idx[i];
        consumed++;
      end
      else begin
        // If none of the execution units is available in this cycle
        // for this instruction then we stop here since we are issuing
        // strictly in order.
        ext_consumed[i]  = 1'b0;
`ifndef OOO_ENABLE
        break;
`endif
        // Don't issue anything after a branch that could not be scheduled
        // XXX: spec
        if ((di[i].branch_inst | di[i].jmp_inst) && rob_slot[i] != branch_rob_slot_act)
          break;
      end // else: !if(di[i].alu_inst && !exmul1_used && exmul1_ready)
    end // for (integer i = 0; i < ISSUE_PER_CYCLE; i++)


    ext_enable         = (consumed > 0) ? 1'b1 : 1'b0;

    bi_inst_valid      = b_used;
    ls_inst_valid      = ls_used & (~ls_speculative | ~new_pc_valid);
    exmul1_inst_valid  = exmul1_used & (~exmul1_speculative | ~new_pc_valid);
    for (integer i = 0; i < EX_UNITS; i++)
      ex_inst_valid[i]     = ex_used[i] & (~ex_speculative[i] | ~new_pc_valid);
  end // always_comb



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

  assign branch_ready = ~branch_stall_d1 & ~bds_missing_r;

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

  // Flush only in the first cycle of a taken branch, and only if we aren't missing the BDS
  //  ... or if we branched some time ago and we only now got the BDS.
  assign branch_flush  =  (new_pc_valid & ~branch_stall_d1 & ~bds_missing)
                        | (bds_missing_r & bds_issued)
                        ;
  //assign branch_flush_stream  = (bds_missing_r) ? insns[0].stream    : insns[branch_idx].stream;
  assign branch_flush_slot    = (bds_missing_r) ? bds_flush_slot_r   : bds_flush_slot;
  assign branch_flush_iq_idx  = (bds_missing_r) ? bds_flush_iq_idx_r : bds_flush_iq_idx;
  assign branch_flush_stream  = (bds_missing_r) ? bds_flush_stream_r : bds_flush_stream;

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
  assign wr_data.dest_reg_valid  = bi_act.dest_reg_valid; // XXX: addme: & new_pc_valid;
  assign wr_data.pc_valid        = new_pc_valid;


  assign bds_missing    =  new_pc_valid
                         & bi_inst_valid
                         & ((branch_idx == ISSUE_PER_CYCLE-1) | (~ext_consumed[(branch_idx == ISSUE_PER_CYCLE-1) ? 0 : branch_idx+1]))
                         ;
  assign bds_flush_slot    = branch_rob_slot;
  assign bds_flush_iq_idx  = branch_iq_idx;
  assign bds_flush_stream  = insns[branch_idx].stream;


  always_comb begin
    bds_issued      = 1'b0;
    for (integer i = 0; i < ISSUE_PER_CYCLE; i++) begin
      automatic bit [6:0] k  = bds_flush_iq_idx_r + 1;
      if (ext_consumed[i] & ext_valid[i] & (k == insns[i].idx))
        bds_issued  = 1'b1;
    end
  end

  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n) begin
      bds_missing_r      <= 1'b0;
      bds_flush_slot_r   <= 'b0;
      bds_flush_iq_idx_r <= 'b0;
      bds_flush_stream_r <= 1'b0;
    end
    else if (branch_flush) begin
      bds_missing_r      <= 1'b0;
      bds_flush_slot_r   <= 'b0;
      bds_flush_iq_idx_r <= 'b0;
      bds_flush_stream_r <= 1'b0;
    end
    else if (bds_missing) begin
      bds_missing_r      <= 1'b1;
      bds_flush_slot_r   <= bds_flush_slot;
      bds_flush_iq_idx_r <= bds_flush_iq_idx;
      bds_flush_stream_r <= bds_flush_stream;
    end



`ifdef ISS_TRACE_ENABLE
  integer trace_file;

  initial begin
    trace_file = $fopen("iss.trace", "w");
  end

  always_ff @(posedge clock) begin
    $fwrite(trace_file, "%d: ISS: bds_missing=%b, bds_missing_r=%b, bds_issued=%b, bds_flush_iq_idx_r=%d, ls_ready=%b, exmul1_ready=%b, branch_ready=%b, ",
      $time, bds_missing, bds_missing_r, bds_issued, bds_flush_iq_idx_r, ls_ready, exmul1_ready, branch_ready);
    for (integer i = 0; i < EX_UNITS; i++)
      $fwrite(trace_file, "ex%1d_ready=%b, ", i, ex_ready[i]);
    $fwrite(trace_file, "\n");

    for (integer i = 0; i < ISSUE_PER_CYCLE; i++) begin
      automatic bit [6:0] k  = bds_flush_iq_idx_r + 1;
      $fwrite(trace_file, "%d: ISS: ext_consumed[%d] = %b\n", $time, i, ext_consumed[i]);
      $fwrite(trace_file, "%d: ISS: insns       [%d].idx = %d (k=%d)\n", $time, i, insns[i].idx, k);
    end

    if (ls_inst_valid)
      $fwrite(trace_file, "%d: ISS: issuing to LS:     pc=%x, A=%x (fwd=%b), B=%x (fwd=%b), rob_slot=%d, iw: %x\n",
              $time, ls_inst.pc, ls_A, ls_fwd_info.A_fwd & ls_inst.A_reg_valid,
              ls_B, ls_fwd_info.B_fwd & ls_inst.B_reg_valid,
              ls_rob_slot, ls_inst.inst_word);

    for (integer i = 0; i < EX_UNITS; i++)
      if (ex_inst_valid[i])
        $fwrite(trace_file, "%d: ISS: issuing to EX%1d:    pc=%x, A=%x (fwd=%b), B=%x (fwd=%b), rob_slot=%d, iw: %x\n",
                $time, i, ex_inst[i].pc,
                ex_A[i], ex_fwd_info[i].A_fwd & ex_inst[i].A_reg_valid,
                ex_B[i], ex_fwd_info[i].B_fwd & ex_inst[i].B_reg_valid,
                ex_rob_slot[i], ex_inst[i].inst_word);

    if (exmul1_inst_valid)
      $fwrite(trace_file, "%d: ISS: issuing to EXMUL1: pc=%x, A=%x (fwd=%b), B=%x (fwd=%b), rob_slot=%d, iw: %x\n",
              $time, exmul1_inst.pc,
              exmul1_A, exmul1_fwd_info.A_fwd & exmul1_inst.A_reg_valid,
              exmul1_B, exmul1_fwd_info.B_fwd & exmul1_inst.B_reg_valid,
              exmul1_rob_slot, exmul1_inst.inst_word);

    if (bi_inst_valid)
      $fwrite(trace_file, "%d: ISS: issuing to BRANCH: pc=%x, A=%x, B=%x, rob_slot=%d, iw: %x\n",
              $time, bi.pc, branch_A, branch_B, branch_rob_slot, bi.inst_word);
  end
`endif
endmodule
