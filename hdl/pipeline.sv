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

  localparam IQ_INS_COUNT   = 4;
  localparam IQ_EXT_COUNT   = 4;
  localparam ROB_INS_COUNT  = 4;
  localparam ROB_EXT_COUNT  = 4;

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [4:0]            A_reg [4];              // From ID of id.v
  wire [31:0]           A_val [INS_COUNT];      // From ROB of rob.v
  wire                  A_val_valid [INS_COUNT];// From ROB of rob.v
  wire [4:0]            B_reg [4];              // From ID of id.v
  wire [31:0]           B_val [INS_COUNT];      // From ROB of rob.v
  wire                  B_val_valid [INS_COUNT];// From ROB of rob.v
  wire [4:0]            as_areg [4];            // From ISS of iss.v
  wire [31:0]           as_aval [INS_COUNT];    // From ROB of rob.v
  wire                  as_aval_present [INS_COUNT];// From ROB of rob.v
  wire                  as_aval_valid [INS_COUNT];// From ROB of rob.v
  wire [4:0]            as_breg [4];            // From ISS of iss.v
  wire [31:0]           as_bval [INS_COUNT];    // From ROB of rob.v
  wire                  as_bval_present [INS_COUNT];// From ROB of rob.v
  wire                  as_bval_valid [INS_COUNT];// From ROB of rob.v
  wire [3:0]            as_query_idx [4];       // From ISS of iss.v
  wire                  branch_stall;           // From IF of ifetch.v
  wire [ADDR_WIDTH-1:0] cache_addr;             // From IF of ifetch.v, ..., Couldn't Merge
  wire                  cache_rd;               // From IF of ifetch.v, ...
  wire                  cache_wr;               // From LS of ls_wrapper.v
  wire [3:0]            cache_wr_be;            // From LS of ls_wrapper.v
  wire [31:0]           cache_wr_data;          // From LS of ls_wrapper.v
  wire                  consume;                // From WB of wb.v
  wire [1:0]            consume_count;          // From WB of wb.v
  wire [4:0]            dest_reg [4];           // From ID of id.v
  wire                  dest_reg_valid [4];     // From ID of id.v
  wire                  empty;                  // From IQ of circ_buf.v, ...
  wire [31:0]           ex1_A;                  // From ISS of iss.v
  wire [31:0]           ex1_B;                  // From ISS of iss.v
  wire                  ex1_inst_valid;         // From ISS of iss.v
  wire [3:0]            ex1_rob_slot;           // From ISS of iss.v
  wire [31:0]           exmul1_A;               // From ISS of iss.v
  wire [31:0]           exmul1_B;               // From ISS of iss.v
  wire                  exmul1_inst_valid;      // From ISS of iss.v
  wire [3:0]            exmul1_rob_slot;        // From ISS of iss.v
  wire [1:0]            ext_consumed;           // From ISS of iss.v
  wire                  ext_enable;             // From ISS of iss.v
  wire                  ext_valid [EXT_COUNT];  // From IQ of circ_buf.v
  wire                  full;                   // From IQ of circ_buf.v, ...
  wire                  ins_enable;             // From ID of id.v
  wire [31:0]           inst_word0_r;           // From IF of ifetch.v
  wire                  inst_word0_valid_r;     // From IF of ifetch.v
  wire [31:0]           inst_word1_r;           // From IF of ifetch.v
  wire                  inst_word1_valid_r;     // From IF of ifetch.v
  wire [31:0]           inst_word2_r;           // From IF of ifetch.v
  wire                  inst_word2_valid_r;     // From IF of ifetch.v
  wire [31:0]           inst_word3_r;           // From IF of ifetch.v
  wire                  inst_word3_valid_r;     // From IF of ifetch.v
  wire [31:0]           ls_A;                   // From ISS of iss.v
  wire [31:0]           ls_B;                   // From ISS of iss.v
  wire                  ls_inst_valid;          // From ISS of iss.v
  wire [3:0]            ls_rob_slot;            // From ISS of iss.v
  wire [1:0]            new_count;              // From ID of id.v
  wire [31:0]           new_pc;                 // From ISS of iss.v
  wire                  new_pc_valid;           // From ISS of iss.v
  wire [31:0]           pc_out0_r;              // From IF of ifetch.v
  wire [31:0]           pc_out1_r;              // From IF of ifetch.v
  wire [31:0]           pc_out2_r;              // From IF of ifetch.v
  wire [31:0]           pc_out3_r;              // From IF of ifetch.v
  wire [31:0]           rd_addr [8];            // From ISS of iss.v
  wire [DATA_WIDTH_1:0] rd_data [READ_PORTS];   // From REGFILE of rfile.v
  wire                  ready;                  // From LS of ls_wrapper.v, ...
  wire                  reserve;                // From ID of id.v
  wire [1:0]            reserve_count;          // From ID of id.v
  wire [DEPTHLOG2-1:0]  reserved_slots [INS_COUNT];// From ROB of rob.v
  wire [4:0]            rfile_wr_addr [4];      // From WB of wb.v
  wire [31:0]           rfile_wr_data [4];      // From WB of wb.v
  wire                  rfile_wr_enable [4];    // From WB of wb.v
  wire [3:0]            rob_data_idx;           // From LS of ls_wrapper.v, ...
  wire                  rob_data_valid;         // From LS of ls_wrapper.v, ...
  wire                  slot_valid [EXT_COUNT]; // From ROB of rob.v
  wire                  stall;                  // From ID of id.v
  wire [DEPTHLOG2:0]    used_count;             // From IQ of circ_buf.v, ...
  wire [3:0]            wr_slot;                // From ISS of iss.v
  wire                  wr_valid;               // From ISS of iss.v
  // End of automatics


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



  id ID(
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



  circ_buf IQ(
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



  iss ISS(
          // Interfaces
          .insns                        (iq_out_elements),
          .wr_data                      (branch_rob_data),
          .ls_inst                      (iss_ls_inst),
          .ex1_inst                     (iss_ex1_inst),
          .exmul1_inst                  (is_exmul1_inst),
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



  ls_wrapper LS(
                // Interfaces
                .inst                   (iss_ls_inst),
                .rob_data               (ls_rob_data),
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



  ex_wrapper EX1(
                 // Interfaces
                 .inst                  (iss_ex1_inst),
                 .rob_data              (ex1_rob_data),
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



  ex_mul_wrapper EXMUL1(
                        // Interfaces
                        .inst           (iss_exmul1_inst),
                        .rob_data       (exmul1_rob_data),
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



  rob ROB (
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


  wb WB(
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


  rfile#(.READ_PORTS(8), .WRITE_PORTS(4))
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
