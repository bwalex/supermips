import pipTypes::*;


module pipeline#(
  parameter ADDR_WIDTH = 32,
            DATA_WIDTH = 32,
            BE_WIDTH = DATA_WIDTH/8
)(
  input                   clock,
  input                   reset_n,

  // from/to IF
  output [ADDR_WIDTH-1:0] icache_addr,//
  output                  icache_rd,//
  input [DATA_WIDTH-1:0]  icache_data,//
  input                   icache_waitrequest,//

  // from/to MEM
  output [ADDR_WIDTH-1:0] dcache_addr,//
  output                  dcache_rd,//
  output                  dcache_wr,//
  output [DATA_WIDTH-1:0] dcache_wr_data,//
  output [  BE_WIDTH-1:0] dcache_wr_be,//
  input [DATA_WIDTH-1:0]  dcache_data,//
  input                   dcache_waitrequest//
);

  localparam IQ_DEPTH       = 16;
  localparam ROB_DEPTH      = 16;

  localparam IQ_INS_COUNT   = 4;
  localparam IQ_EXT_COUNT   = 4;

  localparam ROB_INS_COUNT  = 4;
  localparam ROB_EXT_COUNT  = 4;
  localparam ROB_AS_COUNT   = 4;
  localparam ROB_WR_COUNT   = 4;

  localparam RFILE_RD_PORTS = 8;
  localparam RFILE_WR_PORTS = ROB_EXT_COUNT;

  localparam ROB_DEPTHLOG2      = $clog2(ROB_DEPTH);
  localparam IQ_DEPTHLOG2       = $clog2(IQ_DEPTH);
  localparam IQ_EXT_DEPTHLOG2   = $clog2(IQ_EXT_COUNT);
  localparam ROB_EXT_DEPTHLOG2  = $clog2(ROB_EXT_COUNT);


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

  // Outputs from ID
  wire                         id_stall;
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
  dec_inst_t                   iss_ex1_inst;
  dec_inst_t                   iss_exmul1_inst;
  wire [ROB_DEPTHLOG2-1:0]     issrob_as_query_idx[ROB_AS_COUNT];
  wire [ 4:0]                  issrob_as_areg[ROB_AS_COUNT];
  wire [ 4:0]                  issrob_as_breg[ROB_AS_COUNT];
  wire [ROB_DEPTHLOG2-1:0]     iss_ls_rob_slot;
  wire [31:0]                  iss_ls_A;
  wire [31:0]                  iss_ls_B;
  wire                         iss_ls_inst_valid;
  wire [ROB_DEPTHLOG2-1:0]     iss_ex1_rob_slot;
  wire [31:0]                  iss_ex1_A;
  wire [31:0]                  iss_ex1_B;
  wire                         iss_ex1_inst_valid;
  wire [ROB_DEPTHLOG2-1:0]     iss_exmul1_rob_slot;
  wire [31:0]                  iss_exmul1_A;
  wire [31:0]                  iss_exmul1_B;
  wire                         iss_exmul1_inst_valid;

  // Outputs from branch unit
  rob_entry_t                  branch_rob_data;
  wire [ROB_DEPTHLOG2-1:0]     branch_rob_wr_slot;
  wire                         branch_rob_wr_valid;
  wire                         branch_load_pc;
  wire                         branch_new_pc;

  // Outputs from LS
  wire                         ls_ready;
  rob_entry_t                  ls_rob_wr_data;
  wire                         ls_rob_wr_valid;
  wire [ROB_DEPTHLOG2-1:0]     ls_rob_wr_slot;

  // Outputs from EX1
  wire                         ex1_ready;
  rob_entry_t                  ex1_rob_wr_data;
  wire                         ex1_rob_wr_valid;
  wire [ROB_DEPTHLOG2-1:0]     ex1_rob_wr_slot;


  // Outputs from EXMUL1
  wire                         exmul1_ready;
  rob_entry_t                  exmul1_rob_wr_data;
  wire                         exmul1_rob_wr_valid;
  wire [ROB_DEPTHLOG2-1:0]     exmul1_rob_wr_slot;

  // Outputs from ROB
  rob_entry_t                  rob_slot_data[ROB_EXT_COUNT];
  wire [ROB_DEPTHLOG2-1:0]     rob_reserved_slots;
  wire                         rob_full;
  wire [31:0]                  rob_as_aval[ROB_AS_COUNT];
  wire [31:0]                  rob_as_bval[ROB_AS_COUNT];
  wire                         rob_as_aval_valid[ROB_AS_COUNT];
  wire                         rob_as_bval_valid[ROB_AS_COUNT];
  wire                         rob_as_aval_present[ROB_AS_COUNT];
  wire                         rob_as_bval_present[ROB_AS_COUNT];
  wire                         rob_slot_valid[ROB_EXT_COUNT];
  wire [ROB_DEPTHLOG2:0]       rob_used_count;

  // Outputs from WB
  wire                         wrrob_consume;
  wire [ROB_EXT_DEPTHLOG2-1:0] wrrob_consume_count;

  // Aggregated EX/LS/etc outputs to ROB
  rob_entry_t                  ex_rob_wr_data[ROB_WR_COUNT];
  wire [ROB_DEPTHLOG2-1:0]     ex_rob_wr_slot[ROB_WR_COUNT];
  wire                         ex_rob_wr_valid[ROB_WR_COUNT];


  assign ex_rob_wr_data[0]   = ls_rob_wr_data;
  assign ex_rob_wr_data[1]   = ex1_rob_wr_data;
  assign ex_rob_wr_data[2]   = exmul1_rob_wr_data;
  assign ex_rob_wr_data[3]   = branch_rob_data;
  assign ex_rob_wr_slot[0]   = ls_rob_wr_slot;
  assign ex_rob_wr_slot[1]   = ex1_rob_wr_slot;
  assign ex_rob_wr_slot[2]   = exmul1_rob_wr_slot;
  assign ex_rob_wr_slot[3]   = branch_rob_wr_slot;
  assign ex_rob_wr_valid[0]  = ls_rob_wr_valid;
  assign ex_rob_wr_valid[1]  = ex1_rob_wr_valid;
  assign ex_rob_wr_valid[2]  = exmul1_rob_wr_valid;
  assign ex_rob_wr_valid[3]  = branch_rob_wr_valid;


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
        // Outputs
        .stall                          (id_stall),
        .dest_reg                       (idrob_dest_reg),
        .dest_reg_valid                 (idrob_dest_reg_valid),
        .reserve                        (idrob_reserve),
        .reserve_count                  (idrob_reserve_count),
        .ins_enable                     (idiq_ins_enable),
        .new_count                      (idiq_new_count),
        // Inputs
        .inst_word                      (if_inst_word_r),
        .inst_pc                        (if_pc_out_r),
        .inst_word_valid                (if_inst_word_valid_r),
        .reserved_slots                 (rob_reserved_slots),
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
              .flush                    (branch_load_pc));



  iss#(
       .ROB_DEPTHLOG2(ROB_DEPTHLOG2))
  ISS(
          // Interfaces
          .insns                        (iq_out_elements),
          .wr_data                      (branch_rob_data),
          .ls_inst                      (iss_ls_inst),
          .ex1_inst                     (iss_ex1_inst),
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
          .ls_inst_valid                (iss_ls_inst_valid),
          .ex1_rob_slot                 (iss_ex1_rob_slot),
          .ex1_A                        (iss_ex1_A),
          .ex1_B                        (iss_ex1_B),
          .ex1_inst_valid               (iss_ex1_inst_valid),
          .exmul1_rob_slot              (iss_exmul1_rob_slot),
          .exmul1_A                     (iss_exmul1_A),
          .exmul1_B                     (iss_exmul1_B),
          .exmul1_inst_valid            (iss_exmul1_inst_valid),
          .new_pc                       (branch_new_pc),
          .new_pc_valid                 (branch_load_pc),
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
          .ls_ready                     (ls_ready),
          .ex1_ready                    (ex1_ready),
          .exmul1_ready                 (exmul1_ready),
          .branch_stall                 (if_branch_stall),
          .rd_data                      (rfile_rd_data));



  ls_wrapper#(
    .ROB_DEPTHLOG2(ROB_DEPTHLOG2))
  LS(
                // Interfaces
                .inst                   (iss_ls_inst),
                .rob_data               (ls_rob_wr_data),
                // Outputs
                .ready                  (ls_ready),
                .rob_data_valid         (ls_rob_wr_valid),
                .rob_data_idx           (ls_rob_wr_slot),
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
                .rob_slot               (iss_ls_rob_slot),
                .cache_data             (dcache_data),
                .cache_waitrequest      (dcache_waitrequest));



  ex_wrapper#(
              .ROB_DEPTHLOG2(ROB_DEPTHLOG2))
  EX1(
                 // Interfaces
                 .inst                  (iss_ex1_inst),
                 .rob_data              (ex1_rob_wr_data),
                 // Outputs
                 .ready                 (ex1_ready),
                 .rob_data_valid        (ex1_rob_wr_valid),
                 .rob_data_idx          (ex1_rob_wr_slot),
                 // Inputs
                 .clock                 (clock),
                 .reset_n               (reset_n),
                 .inst_valid            (iss_ex1_inst_valid),
                 .A                     (iss_ex1_A),
                 .B                     (iss_ex1_B),
                 .rob_slot              (iss_ex1_rob_slot));



  ex_mul_wrapper#(
                  .ROB_DEPTHLOG2(ROB_DEPTHLOG2))
  EXMUL1(
                        // Interfaces
                        .inst           (iss_exmul1_inst),
                        .rob_data       (exmul1_wr_rob_data),
                        // Outputs
                        .ready          (exmul1_ready),
                        .rob_data_valid (exmul1_rob_wr_valid),
                        .rob_data_idx   (exmul1_rob_wr_slot),
                        // Inputs
                        .clock          (clock),
                        .reset_n        (reset_n),
                        .inst_valid     (iss_exmul1_inst_valid),
                        .A              (iss_exmul1_A),
                        .B              (iss_exmul1_B),
                        .rob_slot       (iss_exmul1_rob_slot));



  rob#(
       .DEPTH(ROB_DEPTH),
       .INS_COUNT(ROB_INS_COUNT),
       .EXT_COUNT(ROB_EXT_COUNT),
       .AS_COUNT(ROB_AS_COUNT),
       .WR_COUNT(ROB_WR_COUNT))
  ROB (
           // Interfaces
           .write_data                  (ex_rob_wr_data),
           .slot_data                   (rob_slot_data),
           // Outputs
           .reserved_slots              (rob_reserved_slots),
           .full                        (rob_full),

           .as_aval                     (rob_as_aval),
           .as_bval                     (rob_as_bval),
           .as_aval_valid               (rob_as_aval_valid),
           .as_bval_valid               (rob_as_bval_valid),
           .as_aval_present             (rob_as_aval_present),
           .as_bval_present             (rob_as_bval_present),
           .slot_valid                  (rob_slot_valid),
           .empty                       (rob_empty),
           .used_count                  (rob_used_count),
           // Inputs
           .clock                       (clock),
           .reset_n                     (reset_n),
           .reserve                     (idrob_reserve),
           .reserve_count               (idrob_reserve_count),
           .dest_reg                    (idrob_dest_reg),
           .dest_reg_valid              (idrob_dest_reg_valid),
           .as_query_idx                (issrob_as_query_idx),
           .as_areg                     (issrob_as_areg),
           .as_breg                     (issrob_as_breg),
           .write_slot                  (ex_rob_wr_slot),
           .write_valid                 (ex_rob_wr_valid),
           .consume                     (wrrob_consume),
           .consume_count               (wrrob_consume_count),
           .flush                       (branch_load_pc),
           .flush_idx                   (branch_rob_wr_slot));


  wb#(
      .RETIRE_COUNT(ROB_EXT_COUNT))
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
