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

  // from/to ID
  output [ 4:0]           rfile_rd_addr1,//
  output [ 4:0]           rfile_rd_addr2,//
  input [31:0]            rfile_rd_data1,//
  input [31:0]            rfile_rd_data2,//

  // from/to MEM
  output [ADDR_WIDTH-1:0] dcache_addr,//
  output                  dcache_rd,//
  output                  dcache_wr,//
  output [DATA_WIDTH-1:0] dcache_wr_data,//
  output [  BE_WIDTH-1:0] dcache_wr_be,//
  input [DATA_WIDTH-1:0]  dcache_data,//
  input                   dcache_waitrequest,//

  // from/to WB
  output [ 4:0]           rfile_wr_addr1,//
  output                  rfile_wr_enable1,//
  output [31:0]           rfile_wr_data1//
);


  // Stall/bubbling signals
  wire                    stall_if;
  wire                    stall_id;
  wire                    stall_ex;
  wire                    stall_mem;

  wire                    id_ex_dest_reg_valid_i;
  wire                    id_ex_load_inst_i;
  wire                    id_ex_store_inst_i;
  wire                    id_ex_jmp_inst_i;
  wire                    id_ex_alu_inst_i;
  wire                    id_ex_branch_inst_i;

  muldiv_op_t             id_ex_muldiv_op_i;

  wire                    ex_mem_load_inst_i;
  wire                    ex_mem_store_inst_i;
  wire                    ex_mem_dest_reg_valid_i;

  wire                    mem_wb_dest_reg_valid_i;


  // Exports from IF
  wire [31:0] if_pc;//
  wire [31:0] if_inst_word;//

  // Exports from ID
  wire [31:0] id_A;//
  wire [31:0] id_B;//
  wire [11:0] id_opc;//
  wire [ 4:0] id_A_reg;//
  wire [ 4:0] id_B_reg;//
  wire        id_A_reg_valid;//
  wire        id_B_reg_valid;//
  wire        id_B_need_late;//
  wire [31:0] id_imm;//
  wire        id_imm_valid;//
  wire [ 4:0] id_shamt;//
  wire        id_alu_inst;//
  muldiv_op_t id_muldiv_op;
  wire        id_muldiv_op_u;
  wire        id_load_inst;//
  wire        id_store_inst;//
  wire        id_jmp_inst;//
  wire        id_branch_inst;//
  cond_t      id_branch_cond;//
  wire [ 4:0] id_dest_reg;//
  wire        id_dest_reg_valid;//
  wire        id_alu_set_u;//
  wire        id_ls_sext;//
  alu_op_t    id_alu_op;//
  alu_res_t   id_alu_res_sel;//
  ls_op_t     id_ls_op;//
  wire        id_stall;//


  // Exports from EX
  wire [31:0] ex_result;//
  wire [31:0] ex_result_2;//
  wire [31:0] ex_new_pc;//
  wire        ex_new_pc_valid;//
  wire        ex_inval_dest_reg;
  wire        ex_new_dest_reg_valid;
  wire        ex_stall;


  // Exports from MEM
  wire [31:0] mem_result;//
  wire        mem_stall;//


  // Pipeline register interconnect signals
  wire [31:0] if_pc_r;//
  wire [31:0] if_inst_word_r;//

  wire [31:0] id_pc_r;//
  wire [31:0] id_inst_word_r;//
  wire [11:0] id_opc_r;//
  wire [31:0] id_A_r;//
  wire [31:0] id_B_r;//
  wire [ 4:0] id_A_reg_r;//
  wire [ 4:0] id_B_reg_r;//
  wire        id_A_reg_valid_r;//
  wire        id_B_reg_valid_r;//
  wire        id_B_need_late_r;//
  wire [31:0] id_imm_r;//
  wire        id_imm_valid_r;//
  wire [ 4:0] id_shamt_r;//
  wire        id_alu_inst_r;//
  muldiv_op_t id_muldiv_op_r;
  wire        id_muldiv_op_u_r;
  wire        id_load_inst_r;//
  wire        id_store_inst_r;//
  wire        id_jmp_inst_r;//
  wire        id_branch_inst_r;//
  cond_t      id_branch_cond_r;//
  wire [ 4:0] id_dest_reg_r;//
  wire        id_dest_reg_valid_r;//
  wire        id_alu_set_u_r;//
  wire        id_ls_sext_r;//
  alu_op_t    id_alu_op_r;//
  alu_res_t   id_alu_res_sel_r;//
  ls_op_t     id_ls_op_r;//


  wire [31:0] ex_pc_r;//
  wire [31:0] ex_inst_word_r;//
  wire [11:0] ex_opc_r;//
  wire        ex_load_inst_r;//
  wire        ex_store_inst_r;//
  wire        ex_jmp_inst_r;//
  wire [31:0] ex_result_r;//
  wire [31:0] ex_result_2_r;//
  wire [ 4:0] ex_result_2_reg_r;
  wire        ex_result_2_reg_valid_r;
  wire [ 4:0] ex_dest_reg_r;//
  wire        ex_dest_reg_valid_r;//
  wire        ex_ls_sext_r;//
  ls_op_t     ex_ls_op_r;//

  wire [31:0] mem_pc_r;//
  wire [31:0] mem_inst_word_r;//
  wire [11:0] mem_opc_r;//
  wire [31:0] mem_result_r;//
  wire [ 4:0] mem_dest_reg_r;//
  wire        mem_dest_reg_valid_r;//



  assign stall_mem  = 1'b0;
  assign stall_ex   = mem_stall; // stall ex -> mem pipeline register
  assign stall_id   = mem_stall | ex_stall;
  assign stall_if   = mem_stall | ex_stall | id_stall;

  // Signals requiring gating: dest_reg_valid, load_inst, store_inst, jmp_inst, alu_inst
  // Stages able to stall: (IF), ID, MEM   (in the future EX, if it has iterative ops)
  // this generates bubbles, effectively
  assign id_ex_dest_reg_valid_i  = id_dest_reg_valid    & ~id_stall;
  assign id_ex_load_inst_i       = id_load_inst         & ~id_stall;
  assign id_ex_store_inst_i      = id_store_inst        & ~id_stall;
  assign id_ex_jmp_inst_i        = id_jmp_inst          & ~id_stall;
  assign id_ex_alu_inst_i        = id_alu_inst          & ~id_stall;
  assign id_ex_branch_inst_i     = id_branch_inst       & ~id_stall;
  // XXX: need to "gate" muldiv_op
  assign id_ex_muldiv_op_i       = (~id_stall) ? id_muldiv_op : OP_NONE; // XXX: can I do this with a non-wire?

  // XXX: need to "gate" other ex -> mem signals
  //       - id_load_inst_r
  //       - id_store_inst_r
  //       - id_dest_reg_valid_r (or rather ex_new_dest_reg_valid)
  assign ex_mem_load_inst_i      = id_load_inst_r        & ~ex_stall;
  assign ex_mem_store_inst_i     = id_store_inst_r       & ~ex_stall;
  assign ex_mem_dest_reg_valid_i = ex_new_dest_reg_valid & ~ex_stall;

  assign mem_wb_dest_reg_valid_i = ex_dest_reg_valid_r  & ~mem_stall;



  // Allow EX stage to invalidate destination register (used for MOVZ,MOVN)
  assign ex_new_dest_reg_valid  = id_dest_reg_valid_r & ~ex_inval_dest_reg;


  ifetch IF(
            // Outputs
            .cache_addr                 (icache_addr),
            .cache_rd                   (icache_rd),
            .inst_word                  (if_inst_word),
            .pc_out                     (if_pc),
            // Inputs
            .clock                      (clock),
            .reset_n                    (reset_n),
            .cache_data                 (icache_data),
            .cache_waitrequest          (icache_waitrequest),
            .stall                      (stall_if),
            .load_pc                    (ex_new_pc_valid),
            .new_pc                     (ex_new_pc));

  idec ID(
          // Interfaces
          .alu_op                       (id_alu_op),
          .alu_res_sel                  (id_alu_res_sel),
          .muldiv_op                    (id_muldiv_op),
          .ls_op                        (id_ls_op),
          // Outputs
          .stall                        (id_stall),
          .rfile_rd_addr1               (rfile_rd_addr1),
          .rfile_rd_addr2               (rfile_rd_addr2),
          .opc                          (id_opc),
          .A                            (id_A),
          .B                            (id_B),
          .A_reg                        (id_A_reg),
          .A_reg_valid                  (id_A_reg_valid),
          .B_reg                        (id_B_reg),
          .B_reg_valid                  (id_B_reg_valid),
          .B_need_late                  (id_B_need_late),
          .imm                          (id_imm),
          .imm_valid                    (id_imm_valid),
          .shamt                        (id_shamt),
          .alu_set_u                    (id_alu_set_u),
          .ls_sext                      (id_ls_sext),
          .alu_inst                     (id_alu_inst),
          .muldiv_op_u                  (id_muldiv_op_u),
          .load_inst                    (id_load_inst),
          .store_inst                   (id_store_inst),
          .jmp_inst                     (id_jmp_inst),
          .branch_inst                  (id_branch_inst),
          .branch_cond                  (id_branch_cond),
          .dest_reg                     (id_dest_reg),
          .dest_reg_valid               (id_dest_reg_valid),
          // Inputs
          .clock                        (clock),
          .reset_n                      (reset_n),
          .pc                           (if_pc_r),
          .pc_plus_4                    (if_pc),
          .inst_word                    (if_inst_word_r),
          .rfile_rd_data1               (rfile_rd_data1),
          .rfile_rd_data2               (rfile_rd_data2),
          .id_ex_dest_reg               (id_dest_reg_r),
          .ex_mem_dest_reg              (ex_dest_reg_r),
          .id_ex_dest_reg_valid         (id_dest_reg_valid_r),
          .ex_mem_dest_reg_valid        (ex_dest_reg_valid_r),
          .id_ex_load_inst              (id_load_inst_r));

  ex EX(
        // Interfaces
        .alu_op                         (id_alu_op_r),
        .alu_res_sel                    (id_alu_res_sel_r),
        .muldiv_op                      (id_muldiv_op_r),
        // Outputs
        .result                         (ex_result[31:0]),
        .result_2                       (ex_result_2[31:0]),
        .new_pc                         (ex_new_pc),
        .new_pc_valid                   (ex_new_pc_valid),
        .inval_dest_reg                 (ex_inval_dest_reg),
        .stall                          (ex_stall),
        // Inputs
        .clock                          (clock),
        .reset_n                        (reset_n),
        .pc                             (id_pc_r),
        .pc_plus_8                      (if_pc),
        .A_val                          (id_A_r),
        .B_val                          (id_B_r),
        .result_from_ex_mem             (ex_result_r),
        .result_from_mem_wb             (mem_result_r),
        .ex_mem_dest_reg                (ex_dest_reg_r),
        .ex_mem_dest_reg_valid          (ex_dest_reg_valid_r),
        .mem_wb_dest_reg                (mem_dest_reg_r),
        .mem_wb_dest_reg_valid          (mem_dest_reg_valid_r),
        .A_reg                          (id_A_reg_r),
        .A_reg_valid                    (id_A_reg_valid_r),
        .B_reg                          (id_B_reg_r),
        .B_reg_valid                    (id_B_reg_valid_r),
        .imm                            (id_imm_r),
        .imm_valid                      (id_imm_valid_r),
        .shamt                          (id_shamt_r),
        .alu_set_u                      (id_alu_set_u_r),
        .alu_inst                       (id_alu_inst_r),
        .muldiv_op_u                    (id_muldiv_op_u_r),
        .load_inst                      (id_load_inst_r),
        .store_inst                     (id_store_inst_r),
        .jmp_inst                       (id_jmp_inst_r),
        .branch_inst                    (id_branch_inst_r),
        .branch_cond                    (id_branch_cond_r),
        .dest_reg                       (id_dest_reg_r),
        .dest_reg_valid                 (id_dest_reg_valid_r));

  mem MEM(
          // Interfaces
          .ls_op                        (ex_ls_op_r),
          // Outputs
          .cache_rd                     (dcache_rd),
          .cache_wr                     (dcache_wr),
          .cache_addr                   (dcache_addr),
          .cache_wr_data                (dcache_wr_data),
          .cache_wr_be                  (dcache_wr_be),
          .result                       (mem_result),
          .stall                        (mem_stall),
          // Inputs
          .clock                        (clock),
          .reset_n                      (reset_n),
          .cache_data                   (dcache_data),
          .cache_waitrequest            (dcache_waitrequest),
          .load_inst                    (ex_load_inst_r),
          .store_inst                   (ex_store_inst_r),
          .ls_sext                      (ex_ls_sext_r),
          .dest_reg                     (ex_dest_reg_r),
          .dest_reg_valid               (ex_dest_reg_valid_r),
          .alu_result                   (ex_result_r),
          .result_2                     (ex_result_2_r),
          .result_2_reg                 (ex_result_2_reg_r),
          .result_2_reg_valid           (ex_result_2_reg_valid_r),
          .mem_wb_dest_reg              (mem_dest_reg_r),
          .mem_wb_dest_reg_valid        (mem_dest_reg_valid_r),
          .result_from_mem_wb           (mem_result_r));

  wb WB(
        // Outputs
        .rfile_wr_addr1                 (rfile_wr_addr1),
        .rfile_wr_enable1               (rfile_wr_enable1),
        .rfile_wr_data1                 (rfile_wr_data1),
        // Inputs
        .clock                          (clock),
        .reset_n                        (reset_n),
        .result                         (mem_result_r),
        .dest_reg                       (mem_dest_reg_r),
        .dest_reg_valid                 (mem_dest_reg_valid_r));



  pipreg_if_id R_IF_ID(
                       // Outputs
                       .id_pc           (if_pc_r),
                       .id_inst_word    (if_inst_word_r),
                       // Inputs
                       .if_pc           (if_pc),
                       .if_inst_word    (if_inst_word),
                       .stall           (stall_if),
                       .clock           (clock),
                       .reset_n         (reset_n));

  pipreg_id_ex R_ID_EX(
                       // Interfaces
                       .id_alu_op       (id_alu_op),
                       .id_alu_res_sel  (id_alu_res_sel),
                       .id_muldiv_op    (id_ex_muldiv_op_i),
                       .id_ls_op        (id_ls_op),
                       .ex_alu_op       (id_alu_op_r),
                       .ex_alu_res_sel  (id_alu_res_sel_r),
                       .ex_muldiv_op    (id_muldiv_op_r),
                       .ex_ls_op        (id_ls_op_r),
                       // Outputs
                       .ex_pc           (id_pc_r),
                       .ex_inst_word    (id_inst_word_r),
                       .ex_opc          (id_opc_r),
                       .ex_A            (id_A_r),
                       .ex_B            (id_B_r),
                       .ex_A_reg        (id_A_reg_r),
                       .ex_A_reg_valid  (id_A_reg_valid_r),
                       .ex_B_reg        (id_B_reg_r),
                       .ex_B_reg_valid  (id_B_reg_valid_r),
                       .ex_B_need_late  (id_B_need_late_r),
                       .ex_imm          (id_imm_r),
                       .ex_imm_valid    (id_imm_valid_r),
                       .ex_shamt        (id_shamt_r),
                       .ex_alu_inst     (id_alu_inst_r),
                       .ex_alu_set_u    (id_alu_set_u_r),
                       .ex_muldiv_op_u  (id_muldiv_op_u_r),
                       .ex_ls_sext      (id_ls_sext_r),
                       .ex_load_inst    (id_load_inst_r),
                       .ex_store_inst   (id_store_inst_r),
                       .ex_jmp_inst     (id_jmp_inst_r),
                       .ex_branch_inst  (id_branch_inst_r),
                       .ex_branch_cond  (id_branch_cond_r),
                       .ex_dest_reg     (id_dest_reg_r),
                       .ex_dest_reg_valid(id_dest_reg_valid_r),
                       // Inputs
                       .id_pc           (if_pc_r),
                       .id_inst_word    (if_inst_word_r),
                       .id_opc          (id_opc),
                       .id_A            (id_A),
                       .id_B            (id_B),
                       .id_A_reg        (id_A_reg),
                       .id_A_reg_valid  (id_A_reg_valid),
                       .id_B_reg        (id_B_reg),
                       .id_B_reg_valid  (id_B_reg_valid),
                       .id_B_need_late  (id_B_need_late),
                       .id_imm          (id_imm),
                       .id_imm_valid    (id_imm_valid),
                       .id_shamt        (id_shamt),
                       .id_alu_inst     (id_ex_alu_inst_i),
                       .id_alu_set_u    (id_alu_set_u),
                       .id_muldiv_op_u  (id_muldiv_op_u),
                       .id_ls_sext      (id_ls_sext),
                       .id_load_inst    (id_ex_load_inst_i),
                       .id_store_inst   (id_ex_store_inst_i),
                       .id_jmp_inst     (id_ex_jmp_inst_i),
                       .id_branch_inst  (id_ex_branch_inst_i),
                       .id_branch_cond  (id_branch_cond),
                       .id_dest_reg     (id_dest_reg),
                       .id_dest_reg_valid(id_ex_dest_reg_valid_i),
                       .stall           (stall_id),
                       .clock           (clock),
                       .reset_n         (reset_n));

  pipreg_ex_mem R_EX_MEM(
                         // Interfaces
                         .ex_ls_op              (id_ls_op_r),
                         .mem_ls_op             (ex_ls_op_r),
                         // Outputs
                         .mem_pc                (ex_pc_r),
                         .mem_inst_word         (ex_inst_word_r),
                         .mem_opc               (ex_opc_r),
                         .mem_ls_sext           (ex_ls_sext_r),
                         .mem_load_inst         (ex_load_inst_r),
                         .mem_store_inst        (ex_store_inst_r),
                         .mem_jmp_inst          (ex_jmp_inst_r),
                         .mem_result            (ex_result_r),
                         .mem_result_2          (ex_result_2_r),
                         .mem_result_2_reg      (ex_result_2_reg_r),
                         .mem_result_2_reg_valid(ex_result_2_reg_valid_r),
                         .mem_dest_reg          (ex_dest_reg_r),
                         .mem_dest_reg_valid    (ex_dest_reg_valid_r),
                         // Inputs
                         .ex_pc                 (id_pc_r),
                         .ex_inst_word          (id_inst_word_r),
                         .ex_opc                (id_opc_r),
                         .ex_ls_sext            (id_ls_sext_r),
                         .ex_load_inst          (ex_mem_load_inst_i),
                         .ex_store_inst         (ex_mem_store_inst_i),
                         .ex_jmp_inst           (id_jmp_inst_r),
                         .ex_result             (ex_result),
                         .ex_result_2           (ex_result_2),
                         .ex_result_2_reg       (id_B_reg_r),
                         .ex_result_2_reg_valid (id_B_reg_valid_r),
                         .ex_dest_reg           (id_dest_reg_r),
                         .ex_dest_reg_valid     (ex_mem_dest_reg_valid_i),
                         .stall                 (stall_ex),
                         .clock                 (clock),
                         .reset_n               (reset_n));

  pipreg_mem_wb R_MEM_WB(
                         // Outputs
                         .wb_pc                 (mem_pc_r),
                         .wb_inst_word          (mem_inst_word_r),
                         .wb_opc                (mem_opc_r),
                         .wb_result             (mem_result_r),
                         .wb_dest_reg           (mem_dest_reg_r),
                         .wb_dest_reg_valid     (mem_dest_reg_valid_r),
                         // Inputs
                         .mem_pc                (ex_pc_r),
                         .mem_inst_word         (ex_inst_word_r),
                         .mem_opc               (ex_opc_r),
                         .mem_result            (mem_result),
                         .mem_dest_reg          (ex_dest_reg_r),
                         .mem_dest_reg_valid    (mem_wb_dest_reg_valid_i),
                         .stall                 (stall_mem),
                         .clock                 (clock),
                         .reset_n               (reset_n));


endmodule
