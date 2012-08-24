import pipTypes::*;


module pipeline#(
  parameter ADDR_WIDTH = 32,
            DATA_WIDTH = 32,
            BE_WIDTH = DATA_WIDTH/8,
            EX_UNITS = 1,
            RETIRE_COUNT = 4,
            IQ_DEPTH = 16,
            ROB_DEPTH = 16
)(
  input                   clock,
  input                   reset_n,

  // from/to IF
  output [ADDR_WIDTH-1:0] icache_addr,//
  output                  icache_rd,//
  input [127:0]           icache_data,//
  input                   icache_waitrequest,//

  // from/to MEM
  output [ADDR_WIDTH-1:0] dcache_addr,//
  output                  dcache_rd,//
  output                  dcache_wr,//
  output [DATA_WIDTH-1:0] dcache_wr_data,//
  output [ BE_WIDTH-1:0]  dcache_wr_be,//
  input [DATA_WIDTH-1:0]  dcache_data,//
  input                   dcache_waitrequest//
);

  localparam ISS_PER_CYCLE  = 3+EX_UNITS;

  localparam IQ_INS_COUNT   = 4;
  localparam IQ_EXT_COUNT   = ISS_PER_CYCLE;

  localparam ROB_INS_COUNT  = 4;
  localparam ROB_EXT_COUNT  = RETIRE_COUNT;
  localparam ROB_AS_COUNT   = ISS_PER_CYCLE;
  localparam ROB_WR_COUNT   = ISS_PER_CYCLE;
  localparam ROB_LK_COUNT   = 2*ISS_PER_CYCLE;

  localparam RFILE_RD_PORTS = 2*ISS_PER_CYCLE;
  localparam RFILE_WR_PORTS = RETIRE_COUNT;

  localparam ROB_DEPTHLOG2      = `clogb2(ROB_DEPTH);
  localparam IQ_DEPTHLOG2       = `clogb2(IQ_DEPTH);
  localparam IQ_EXT_DEPTHLOG2   = `clogb2(IQ_EXT_COUNT);
  localparam ROB_EXT_DEPTHLOG2  = `clogb2(ROB_EXT_COUNT);


  // RFILE signals
  wire [ 4:0]                  rfile_rd_addr[RFILE_RD_PORTS];
  wire [31:0]                  rfile_rd_data[RFILE_RD_PORTS];
  wire [ 4:0]                  rfile_wr_addr[RFILE_WR_PORTS];
  wire [31:0]                  rfile_wr_data[RFILE_WR_PORTS];
  wire                         rfile_wr_enable[RFILE_WR_PORTS];


  // Outputs from IF
  wire [31:0]                  if_inst_word0_r;
  wire [31:0]                  if_inst_word1_r;
  wire [31:0]                  if_inst_word2_r;
  wire [31:0]                  if_inst_word3_r;
  wire                         if_inst_word0_valid_r;
  wire                         if_inst_word1_valid_r;
  wire                         if_inst_word2_valid_r;
  wire                         if_inst_word3_valid_r;
  wire [31:0]                  if_pc_out0_r;
  wire [31:0]                  if_pc_out1_r;
  wire [31:0]                  if_pc_out2_r;
  wire [31:0]                  if_pc_out3_r;
  wire                         if_branch_stall;

  wire [31:0]                  if_inst_word_r[4];
  wire                         if_inst_word_valid_r[4];
  wire [31:0]                  if_pc_out_r[4];
  wire                         if_inst_stream_r;

  // Outputs from ID
  wire                         id_stall;
  dec_inst_t                   idrob_instructions[4];
  iq_entry_t                   idiq_new_elements[4];
  wire [ 4:0]                  idrob_dest_reg[ROB_INS_COUNT];
  wire                         idrob_dest_reg_valid[ROB_INS_COUNT];
  wire                         idrob_reserve;
  wire [ 1:0]                  idrob_reserve_count;
  wire                         idiq_ins_enable;
  wire [ 1:0]                  idiq_new_count;

  // Outputs from IQ
  iq_entry_t                   iq_out_elements[IQ_EXT_COUNT];
  wire                         iq_full;
  wire                         iq_ext_valid[IQ_EXT_COUNT];
  wire                         iq_empty;
  wire [IQ_DEPTHLOG2:0]        iq_used_count;

  // Outputs from ISS
  wire                         issiq_ext_enable;
  wire [IQ_EXT_DEPTHLOG2-1:0]  issiq_ext_consumed;
  dec_inst_t                   iss_ls_inst;
  dec_inst_t                   iss_ex_inst[EX_UNITS];
  dec_inst_t                   iss_exmul1_inst;
  wire [ROB_DEPTHLOG2-1:0]     issrob_as_query_idx[ROB_AS_COUNT];
  wire [ 4:0]                  issrob_as_areg[ROB_AS_COUNT];
  wire [ 4:0]                  issrob_as_breg[ROB_AS_COUNT];
  wire [ROB_DEPTHLOG2-1:0]     iss_ls_rob_slot;
  wire [31:0]                  iss_ls_A;
  wire [31:0]                  iss_ls_B;
  fwd_info_t                   iss_ls_fwd_info;
  wire                         iss_ls_inst_valid;
  wire [ROB_DEPTHLOG2-1:0]     iss_ex_rob_slot[EX_UNITS];
  wire [31:0]                  iss_ex_A[EX_UNITS];
  wire [31:0]                  iss_ex_B[EX_UNITS];
  fwd_info_t                   iss_ex_fwd_info[EX_UNITS];
  logic                        iss_ex_inst_valid[EX_UNITS];
  wire [ROB_DEPTHLOG2-1:0]     iss_exmul1_rob_slot;
  wire [31:0]                  iss_exmul1_A;
  wire [31:0]                  iss_exmul1_B;
  fwd_info_t                   iss_exmul1_fwd_info;
  wire                         iss_exmul1_inst_valid;

  // Outputs from branch unit
  rob_entry_t                  branch_rob_data;
  wire [ROB_DEPTHLOG2-1:0]     branch_rob_wr_slot;
  wire                         branch_rob_wr_valid;
  wire                         branch_load_pc;
  wire [31:0]                  branch_new_pc;
  wire                         branch_flush;
  wire                         branch_flush_stream;
  wire [ROB_DEPTHLOG2-1:0]     branch_flush_slot;
  wire [ROB_DEPTHLOG2-1:0]     branch_rob_dt_idx_a;
  wire [ROB_DEPTHLOG2-1:0]     branch_rob_dt_idx_b;

  // Outputs from LS
  wire                         ls_ready;
  rob_entry_t                  ls_rob_wr_data;
  wire                         ls_rob_wr_valid;
  wire [ROB_DEPTHLOG2-1:0]     ls_rob_wr_slot;
  wire [ROB_DEPTHLOG2-1:0]     ls_rob_dt_idx_a;
  wire [ROB_DEPTHLOG2-1:0]     ls_rob_dt_idx_b;

  // Outputs from EX1..EX_UNITS
  logic                        ex_ready[EX_UNITS];
  rob_entry_t                  ex_rob_wr_data[EX_UNITS];
  wire                         ex_rob_wr_valid[EX_UNITS];
  wire [ROB_DEPTHLOG2-1:0]     ex_rob_wr_slot[EX_UNITS];
  wire [ROB_DEPTHLOG2-1:0]     ex_rob_dt_idx_a[EX_UNITS];
  wire [ROB_DEPTHLOG2-1:0]     ex_rob_dt_idx_b[EX_UNITS];

  // Outputs from EXMUL1
  wire                         exmul1_ready;
  rob_entry_t                  exmul1_rob_wr_data;
  wire                         exmul1_rob_wr_valid;
  wire [ROB_DEPTHLOG2-1:0]     exmul1_rob_wr_slot;
  wire [ROB_DEPTHLOG2-1:0]     exmul1_rob_dt_idx_a;
  wire [ROB_DEPTHLOG2-1:0]     exmul1_rob_dt_idx_b;

  // Outputs from ROB
  rob_entry_t                  rob_slot_data[ROB_EXT_COUNT];
  wire [ROB_DEPTHLOG2-1:0]     rob_reserved_slots[ROB_INS_COUNT];
  wire                         rob_full;
  wire [31:0]                  rob_as_aval[ROB_AS_COUNT];
  wire [31:0]                  rob_as_bval[ROB_AS_COUNT];
  wire                         rob_as_aval_valid[ROB_AS_COUNT];
  wire                         rob_as_bval_valid[ROB_AS_COUNT];
  wire                         rob_as_aval_present[ROB_AS_COUNT];
  wire                         rob_as_bval_present[ROB_AS_COUNT];
  wire                         rob_as_aval_transit[ROB_AS_COUNT];
  wire                         rob_as_bval_transit[ROB_AS_COUNT];
  wire [ROB_DEPTHLOG2-1:0]     rob_as_aval_idx[ROB_AS_COUNT];
  wire [ROB_DEPTHLOG2-1:0]     rob_as_bval_idx[ROB_AS_COUNT];
  wire                         rob_slot_valid[ROB_EXT_COUNT];
  wire                         rob_slot_kill[ROB_EXT_COUNT];
  wire [ROB_DEPTHLOG2:0]       rob_used_count;
  wire [31:0]                  rob_dt_result[ROB_LK_COUNT];

  wire [31:0]                  rob_ls_dt_result_a;
  wire [31:0]                  rob_ls_dt_result_b;
  wire [31:0]                  rob_exmul1_dt_result_a;
  wire [31:0]                  rob_exmul1_dt_result_b;
  wire [31:0]                  rob_branch_dt_result_a;
  wire [31:0]                  rob_branch_dt_result_b;
  wire [31:0]                  rob_ex_dt_result_a[EX_UNITS];
  wire [31:0]                  rob_ex_dt_result_b[EX_UNITS];

  // Outputs from WB
  wire                         wrrob_consume;
  wire [ROB_EXT_DEPTHLOG2-1:0] wrrob_consume_count;

  // Aggregated EX/LS/etc outputs to ROB
  rob_entry_t                  ex_agg_rob_wr_data[ROB_WR_COUNT];
  wire [ROB_DEPTHLOG2-1:0]     ex_agg_rob_wr_slot[ROB_WR_COUNT];
  wire                         ex_agg_rob_wr_valid[ROB_WR_COUNT];
  wire [ROB_DEPTHLOG2-1:0]     ex_agg_rob_transit_idx[ROB_WR_COUNT];
  wire                         ex_agg_rob_transit_idx_valid[ROB_WR_COUNT];
  wire [ROB_DEPTHLOG2-1:0]     ex_agg_rob_dt_idx[ROB_LK_COUNT];

  genvar                       i;

  assign ex_agg_rob_wr_data[0]   = ls_rob_wr_data;
  assign ex_agg_rob_wr_data[1]   = exmul1_rob_wr_data;
  assign ex_agg_rob_wr_data[2]  = branch_rob_data;
  generate
    for (i = 0; i < EX_UNITS; i++) begin : GEN_EX_ROB_WR_DATA
      assign ex_agg_rob_wr_data[3+i]  = ex_rob_wr_data[i];
    end
  endgenerate

  assign ex_agg_rob_wr_slot[0]   = ls_rob_wr_slot;
  assign ex_agg_rob_wr_slot[1]   = exmul1_rob_wr_slot;
  assign ex_agg_rob_wr_slot[2]   = branch_rob_wr_slot;
  generate
    for (i = 0; i < EX_UNITS; i++) begin : GEN_EX_ROB_WR_SLOT
      assign ex_agg_rob_wr_slot[3+i]  = ex_rob_wr_slot[i];
    end
  endgenerate

  assign ex_agg_rob_wr_valid[0]  = ls_rob_wr_valid;
  assign ex_agg_rob_wr_valid[1]  = exmul1_rob_wr_valid;
  assign ex_agg_rob_wr_valid[2]  = branch_rob_wr_valid;
  generate
    for (i = 0; i < EX_UNITS; i++) begin : GEN_EX_ROB_WR_VALID
      assign ex_agg_rob_wr_valid[3+i]  = ex_rob_wr_valid[i];
    end
  endgenerate

  assign ex_agg_rob_transit_idx[0]  = iss_ls_rob_slot;
  assign ex_agg_rob_transit_idx[1]  = iss_exmul1_rob_slot;
  assign ex_agg_rob_transit_idx[2]  = branch_rob_wr_slot;
  generate
    for (i = 0; i < EX_UNITS; i++) begin : GEN_EX_ROB_TRANSIT_IDX
      assign ex_agg_rob_transit_idx[3+i]  = iss_ex_rob_slot[i];
    end
  endgenerate

  // Only ALU insts are guaranteed to yield a result in exactly one cycle,
  // so don't mark any other one as in transit.
  assign ex_agg_rob_transit_idx_valid[0]  = 1'b0 & iss_ls_inst_valid;
  assign ex_agg_rob_transit_idx_valid[1]  =   iss_exmul1_inst.alu_inst
                                           & ~iss_exmul1_inst.muldiv_inst
                                           & ~iss_exmul1_inst.can_inval
                                           &  iss_exmul1_inst_valid
					   ;
  assign ex_agg_rob_transit_idx_valid[2]  = 1'b0;
  generate
    for (i = 0; i < EX_UNITS; i++) begin : GEN_EX_ROB_TRANSIT_IDX_V
      assign ex_agg_rob_transit_idx_valid[3+i]  = ~iss_ex_inst[i].can_inval
                                                 & iss_ex_inst_valid[i]
						 ;
    end
  endgenerate

  assign ex_agg_rob_dt_idx[0]  = ls_rob_dt_idx_a;
  assign ex_agg_rob_dt_idx[1]  = ls_rob_dt_idx_b;
  assign ex_agg_rob_dt_idx[2]  = exmul1_rob_dt_idx_a;
  assign ex_agg_rob_dt_idx[3]  = exmul1_rob_dt_idx_b;
  assign ex_agg_rob_dt_idx[4]  = branch_rob_dt_idx_a;
  assign ex_agg_rob_dt_idx[5]  = branch_rob_dt_idx_b;
  generate
    for (i = 0; i < EX_UNITS; i++) begin : GEN_EX_ROB_DT_QUERY_IDX
      assign ex_agg_rob_dt_idx[6+i*2]  = ex_rob_dt_idx_a[i];
      assign ex_agg_rob_dt_idx[7+i*2]  = ex_rob_dt_idx_b[i];
    end
  endgenerate

  assign rob_ls_dt_result_a      = rob_dt_result[0];
  assign rob_ls_dt_result_b      = rob_dt_result[1];
  assign rob_exmul1_dt_result_a  = rob_dt_result[2];
  assign rob_exmul1_dt_result_b  = rob_dt_result[3];
  assign rob_branch_dt_result_a  = rob_dt_result[4];
  assign rob_branch_dt_result_b  = rob_dt_result[5];
  generate
    for (i = 0; i < EX_UNITS; i++) begin : GEN_EX_ROB_DT_RES
      assign rob_ex_dt_result_a[i]  = rob_dt_result[6+i*2];
      assign rob_ex_dt_result_b[i]  = rob_dt_result[7+i*2];
    end
  endgenerate

  // Aggregate IF outputs
  assign if_inst_word_r[0]        = if_inst_word0_r;
  assign if_inst_word_r[1]        = if_inst_word1_r;
  assign if_inst_word_r[2]        = if_inst_word2_r;
  assign if_inst_word_r[3]        = if_inst_word3_r;
  assign if_inst_word_valid_r[0]  = if_inst_word0_valid_r;
  assign if_inst_word_valid_r[1]  = if_inst_word1_valid_r;
  assign if_inst_word_valid_r[2]  = if_inst_word2_valid_r;
  assign if_inst_word_valid_r[3]  = if_inst_word3_valid_r;
  assign if_pc_out_r[0]           = if_pc_out0_r;
  assign if_pc_out_r[1]           = if_pc_out1_r;
  assign if_pc_out_r[2]           = if_pc_out2_r;
  assign if_pc_out_r[3]           = if_pc_out3_r;


  ifetch IF(
            // Outputs
            .cache_addr                 (icache_addr),
            .cache_rd                   (icache_rd),
            .inst_word0_r               (if_inst_word0_r),
            .inst_word1_r               (if_inst_word1_r),
            .inst_word2_r               (if_inst_word2_r),
            .inst_word3_r               (if_inst_word3_r),
            .inst_word0_valid_r         (if_inst_word0_valid_r),
            .inst_word1_valid_r         (if_inst_word1_valid_r),
            .inst_word2_valid_r         (if_inst_word2_valid_r),
            .inst_word3_valid_r         (if_inst_word3_valid_r),
            .pc_out0_r                  (if_pc_out0_r),
            .pc_out1_r                  (if_pc_out1_r),
            .pc_out2_r                  (if_pc_out2_r),
            .pc_out3_r                  (if_pc_out3_r),
            .inst_stream_r              (if_inst_stream_r),
            .branch_stall               (if_branch_stall),
            // Inputs
            .clock                      (clock),
            .reset_n                    (reset_n),
            .cache_data                 (icache_data),
            .cache_waitrequest          (icache_waitrequest),
            .stall                      (id_stall),
            .load_pc                    (branch_load_pc),
            .new_pc                     (branch_new_pc));



  id#(
      .ROB_DEPTHLOG2(ROB_DEPTHLOG2))
  ID(
        // Interfaces
        .new_elements                   (idiq_new_elements),
        .instructions                   (idrob_instructions),
        // Outputs
        .stall                          (id_stall),
        .dest_reg                       (idrob_dest_reg),
        .dest_reg_valid                 (idrob_dest_reg_valid),
        .reserve                        (idrob_reserve),
        .reserve_count                  (idrob_reserve_count),
        .ins_enable                     (idiq_ins_enable),
        .new_count                      (idiq_new_count),
        // Inputs
        .clock                          (clock),
        .reset_n                        (reset_n),
        .inst_word                      (if_inst_word_r),
        .inst_stream                    (if_inst_stream_r),
        .inst_pc                        (if_pc_out_r),
        .inst_word_valid                (if_inst_word_valid_r),
        .reserved_slots                 (rob_reserved_slots),
        .flush                          (branch_flush),
        .flush_stream                   (branch_flush_stream),
        .rob_full                       (rob_full),
        .iq_full                        (iq_full));



  circ_buf#(
            .DEPTH(IQ_DEPTH),
            .INS_COUNT(IQ_INS_COUNT),
            .EXT_COUNT(IQ_EXT_COUNT))
  IQ(
              // Interfaces
              .new_elements             (idiq_new_elements),
              .out_elements             (iq_out_elements),
              // Outputs
              .ext_valid                (iq_ext_valid),
              .full                     (iq_full),
              .empty                    (iq_empty),
              .used_count               (iq_used_count),
              // Inputs
              .clock                    (clock),
              .reset_n                  (reset_n),
              .ins_enable               (idiq_ins_enable),
              .new_count                (idiq_new_count),
              .ext_enable               (issiq_ext_enable),
              .ext_consumed             (issiq_ext_consumed),
              .flush                    (branch_flush),
              .flush_stream             (branch_flush_stream));



  iss#(
       .ROB_DEPTHLOG2(ROB_DEPTHLOG2),
       .EX_UNITS(EX_UNITS),
       .ISSUE_PER_CYCLE(ISS_PER_CYCLE))
  ISS(
          // Interfaces
          .insns                        (iq_out_elements),
          .wr_data                      (branch_rob_data),
          .ls_inst                      (iss_ls_inst),
          .ex_inst                      (iss_ex_inst),
          .exmul1_inst                  (iss_exmul1_inst),
          // Outputs
          .ext_enable                   (issiq_ext_enable),
          .ext_consumed                 (issiq_ext_consumed),
          .as_query_idx                 (issrob_as_query_idx),
          .as_areg                      (issrob_as_areg),
          .as_breg                      (issrob_as_breg),
          .wr_slot                      (branch_rob_wr_slot),
          .wr_valid                     (branch_rob_wr_valid),
          .ls_rob_slot                  (iss_ls_rob_slot),
          .ls_A                         (iss_ls_A),
          .ls_B                         (iss_ls_B),
          .ls_fwd_info                  (iss_ls_fwd_info),
          .ls_inst_valid                (iss_ls_inst_valid),
          .ex_rob_slot                  (iss_ex_rob_slot),
          .ex_A                         (iss_ex_A),
          .ex_B                         (iss_ex_B),
          .ex_fwd_info                  (iss_ex_fwd_info),
          .ex_inst_valid                (iss_ex_inst_valid),
          .exmul1_rob_slot              (iss_exmul1_rob_slot),
          .exmul1_A                     (iss_exmul1_A),
          .exmul1_B                     (iss_exmul1_B),
          .exmul1_fwd_info              (iss_exmul1_fwd_info),
          .exmul1_inst_valid            (iss_exmul1_inst_valid),
          .new_pc                       (branch_new_pc),
          .new_pc_valid                 (branch_load_pc),
          .branch_flush                 (branch_flush),
          .branch_flush_stream          (branch_flush_stream),
          .branch_flush_slot            (branch_flush_slot),
          .rd_addr                      (rfile_rd_addr),
          // Inputs
          .clock                        (clock),
          .reset_n                      (reset_n),
          .ext_valid                    (iq_ext_valid),
          .empty                        (iq_empty),
          .as_aval                      (rob_as_aval),
          .as_bval                      (rob_as_bval),
          .as_aval_valid                (rob_as_aval_valid),
          .as_bval_valid                (rob_as_bval_valid),
          .as_aval_present              (rob_as_aval_present),
          .as_bval_present              (rob_as_bval_present),
          .as_aval_transit              (rob_as_aval_transit),
          .as_bval_transit              (rob_as_bval_transit),
          .as_aval_idx                  (rob_as_aval_idx),
          .as_bval_idx                  (rob_as_bval_idx),
          .ls_ready                     (ls_ready),
          .ex_ready                     (ex_ready),
          .exmul1_ready                 (exmul1_ready),
          .branch_stall                 (if_branch_stall),
          .rd_data                      (rfile_rd_data));



  ls_wrapper#(
    .ROB_DEPTHLOG2(ROB_DEPTHLOG2))
  LS(
                // Interfaces
                .inst                   (iss_ls_inst),
                .fwd_info               (iss_ls_fwd_info),
                .rob_data               (ls_rob_wr_data),
                // Outputs
                .ready                  (ls_ready),
                .rob_data_valid         (ls_rob_wr_valid),
                .rob_data_idx           (ls_rob_wr_slot),
                .A_lookup_idx           (ls_rob_dt_idx_a),
                .B_lookup_idx           (ls_rob_dt_idx_b),
                .cache_rd               (dcache_rd),
                .cache_wr               (dcache_wr),
                .cache_addr             (dcache_addr),
                .cache_wr_data          (dcache_wr_data),
                .cache_wr_be            (dcache_wr_be),
                // Inputs
                .clock                  (clock),
                .reset_n                (reset_n),
                .inst_valid             (iss_ls_inst_valid),
                .A                      (iss_ls_A),
                .B                      (iss_ls_B),
                .A_fwd                  (rob_ls_dt_result_a),
                .B_fwd                  (rob_ls_dt_result_b),
                .rob_slot               (iss_ls_rob_slot),
                .cache_data             (dcache_data),
                .cache_waitrequest      (dcache_waitrequest));


  generate
    for (i = 0; i < EX_UNITS; i++) begin : GEN_EX_UNITS
      ex_wrapper#(
                  .ROB_DEPTHLOG2(ROB_DEPTHLOG2))
      EX(
          // Interfaces
          .inst                  (iss_ex_inst[i]),
          .fwd_info              (iss_ex_fwd_info[i]),
          .rob_data              (ex_rob_wr_data[i]),
          // Outputs
          .ready                 (ex_ready[i]),
          .rob_data_valid        (ex_rob_wr_valid[i]),
          .rob_data_idx          (ex_rob_wr_slot[i]),
          .A_lookup_idx          (ex_rob_dt_idx_a[i]),
          .B_lookup_idx          (ex_rob_dt_idx_b[i]),
          // Inputs
          .clock                 (clock),
          .reset_n               (reset_n),
          .inst_valid            (iss_ex_inst_valid[i]),
          .A                     (iss_ex_A[i]),
          .B                     (iss_ex_B[i]),
          .A_fwd                 (rob_ex_dt_result_a[i]),
          .B_fwd                 (rob_ex_dt_result_b[i]),
          .rob_slot              (iss_ex_rob_slot[i]));
    end
  endgenerate


  ex_mul_wrapper#(
                  .ROB_DEPTHLOG2(ROB_DEPTHLOG2))
  EXMUL1(
                        // Interfaces
                        .inst           (iss_exmul1_inst),
                        .fwd_info       (iss_exmul1_fwd_info),
                        .rob_data       (exmul1_rob_wr_data),
                        // Outputs
                        .ready          (exmul1_ready),
                        .rob_data_valid (exmul1_rob_wr_valid),
                        .rob_data_idx   (exmul1_rob_wr_slot),
                        .A_lookup_idx   (exmul1_rob_dt_idx_a),
                        .B_lookup_idx   (exmul1_rob_dt_idx_b),
                        // Inputs
                        .clock          (clock),
                        .reset_n        (reset_n),
                        .inst_valid     (iss_exmul1_inst_valid),
                        .A              (iss_exmul1_A),
                        .B              (iss_exmul1_B),
                        .A_fwd          (rob_exmul1_dt_result_a),
                        .B_fwd          (rob_exmul1_dt_result_b),
                        .rob_slot       (iss_exmul1_rob_slot));



  rob#(
       .DEPTH(ROB_DEPTH),
       .INS_COUNT(ROB_INS_COUNT),
       .EXT_COUNT(ROB_EXT_COUNT),
       .AS_COUNT(ROB_AS_COUNT),
       .LK_COUNT(ROB_LK_COUNT),
       .WR_COUNT(ROB_WR_COUNT))
  ROB (
           // Interfaces
           .write_data                  (ex_agg_rob_wr_data),
           .slot_data                   (rob_slot_data),
           .instructions                (idrob_instructions),
           // Outputs
           .reserved_slots              (rob_reserved_slots),
           .full                        (rob_full),

           .as_aval                     (rob_as_aval),
           .as_bval                     (rob_as_bval),
           .as_aval_valid               (rob_as_aval_valid),
           .as_bval_valid               (rob_as_bval_valid),
           .as_aval_present             (rob_as_aval_present),
           .as_bval_present             (rob_as_bval_present),
           .as_aval_transit             (rob_as_aval_transit),
           .as_bval_transit             (rob_as_bval_transit),
           .as_aval_idx                 (rob_as_aval_idx),
           .as_bval_idx                 (rob_as_bval_idx),
           .dt_result                   (rob_dt_result),
           .slot_valid                  (rob_slot_valid),
           .slot_kill                   (rob_slot_kill),
           .empty                       (rob_empty),
           .used_count                  (rob_used_count),
           // Inputs
           .clock                       (clock),
           .reset_n                     (reset_n),
           .reserve                     (idrob_reserve),
           .reserve_count               (idrob_reserve_count),
           .dest_reg                    (idrob_dest_reg),
           .dest_reg_valid              (idrob_dest_reg_valid),
           .stream                      (if_inst_stream_r),
           .as_query_idx                (issrob_as_query_idx),
           .as_areg                     (issrob_as_areg),
           .as_breg                     (issrob_as_breg),
           .dt_query_idx                (ex_agg_rob_dt_idx),
           .write_slot                  (ex_agg_rob_wr_slot),
           .write_valid                 (ex_agg_rob_wr_valid),
           .transit_idx                 (ex_agg_rob_transit_idx),
           .transit_idx_valid           (ex_agg_rob_transit_idx_valid),
           .consume                     (wrrob_consume),
           .consume_count               (wrrob_consume_count),
           .flush                       (branch_flush),
           .flush_idx                   (branch_flush_slot));


  wb#(
      .RETIRE_COUNT(RETIRE_COUNT))
  WB(
        // Interfaces
        .slot_data                      (rob_slot_data),
        // Outputs
        .consume                        (wrrob_consume),
        .consume_count                  (wrrob_consume_count),
        .rfile_wr_addr                  (rfile_wr_addr),
        .rfile_wr_enable                (rfile_wr_enable),
        .rfile_wr_data                  (rfile_wr_data),
        // Inputs
        .clock                          (clock),
        .reset_n                        (reset_n),
        .slot_valid                     (rob_slot_valid),
        .slot_kill                      (rob_slot_kill),
        .empty                          (rob_empty));


  rfile#(
         .READ_PORTS(RFILE_RD_PORTS),
         .WRITE_PORTS(RFILE_WR_PORTS))
  REGFILE(
          // Outputs
          .rd_data                      (rfile_rd_data),
          // Inputs
          .clock                        (clock),
          .reset_n                      (reset_n),
          .rd_addr                      (rfile_rd_addr),
          .wr_addr                      (rfile_wr_addr),
          .wr_enable                    (rfile_wr_enable),
          .wr_data                      (rfile_wr_data));
endmodule
