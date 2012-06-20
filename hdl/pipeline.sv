module pipeline#(
  parameter ADDR_WIDTH = 32,
            DATA_WIDTH = 32
)(
  input                   clock,
  input                   reset_n,

  // from/to IF
  output [ADDR_WIDTH-1:0] icache_addr,
  output                  icache_rd,
  input [DATA_WIDTH-1:0]  icache_data,
  input                   icache_waitrequest,

  // from/to ID
  output [ 4:0]           rfile_rd_addr1,
  output [ 4:0]           rfile_rd_addr2,
  input [31:0]            rfile_rd_data1,
  input [31:0]            rfile_rd_data2,

  // from/to MEM
  output [ADDR_WIDTH-1:0] dcache_addr,
  output                  dcache_rd,
  output                  dcache_wr,
  output [DATA_WIDTH-1:0] dcache_wr_data,
  input [DATA_WIDTH-1:0]  dcache_data,
  input                   dcache_waitrequest,

  // from/to WB
  output [ 4:0]           rfile_wr_addr1,
  output                  rfile_wr_enable1,
  output [31:0]           rfile_wr_data1
);

  // Exports from IF
  wire [31:0] if_pc;
  wire [31:0] if_inst_word;

  // Exports from ID
  wire [31:0] id_A;
  wire [31:0] id_B;
  wire [ 4:0] id_A_reg;
  wire [ 4:0] id_B_reg;
  wire        id_B_imm;
  wire [ 4:0] id_shamt;
  wire [11:0] id_alu_op;
  wire        id_alu_inst;
  wire        id_load_inst;
  wire        id_store_inst;
  wire        id_jmp_inst;
  wire [ 4:0] id_dest_reg;
  wire        id_dest_reg_valid;

  // Exports from EX
  wire [31:0] ex_result;

  // Exports from MEM
  wire [31:0] mem_result;


  // Pipeline register interconnect signals
  wire [31:0] if_pc_r;
  wire [31:0] if_inst_word_r;

  wire [31:0] id_pc_r;
  wire [31:0] id_A_r;
  wire [31:0] id_B_r;
  wire [ 4:0] id_A_reg_r;
  wire [ 4:0] id_B_reg_r;
  wire        id_B_imm_r;
  wire [ 4:0] id_shamt_r;
  wire [11:0] id_alu_op_r;
  wire        id_alu_inst_r;
  wire        id_load_inst_r;
  wire        id_store_inst_r;
  wire        id_jmp_inst_r;
  wire [ 4:0] id_dest_reg_r;
  wire        id_dest_reg_valid_r;

  wire [31:0] ex_pc_r;
  wire        ex_load_inst_r;
  wire        ex_store_inst_r;
  wire        ex_jmp_inst_r;
  wire [31:0] ex_result_r;
  wire [ 4:0] ex_dest_reg_r;
  wire        ex_dest_reg_valid_r;

  wire [31:0] mem_pc_r;
  wire [31:0] mem_result_r;
  wire [ 4:0] mem_dest_reg_r;
  wire        mem_dest_reg_valid_r;




  ifetch IF(
            // Inputs
            .clock(clock),
            .reset_n(reset_n),
            .cache_data(icache_data),
            .cache_waitrequest(icache_waitrequest),
            .load_pc(1'b0),
            .new_pc(32'b0),
            // Outputs
            .cache_addr(icache_addr[31:0]),
            .cache_rd(icache_rd),
            .inst_word(if_inst_word),
            .pc_out(if_pc)
            );

  idec ID(
          // Inputs
          .clock(clock),
          .reset_n(reset_n),
          .pc(if_pc_r),
          .inst_word(if_inst_word_r),
          .rfile_rd_data1(rfile_rd_data1),
          .rfile_rd_data2(rfile_rd_data2),
          // Outputs
          .rfile_rd_addr1(rfile_rd_addr1),
          .rfile_rd_addr2(rfile_rd_addr2),
          .A(id_A),
          .B(id_B),
          .A_reg(id_A_reg),
          .B_reg(id_B_reg),
          .B_imm(id_B_imm),
          .shamt(id_shamt),
          .alu_op(id_alu_op),
          .alu_inst(id_alu_inst),
          .load_inst(id_load_inst),
          .store_inst(id_store_inst),
          .jmp_inst(id_jmp_inst),
          .dest_reg(id_dest_reg),
          .dest_reg_valid(id_dest_reg_valid)
          );

  ex EX(
        .clock(clock),
        .reset_n(reset_n),
        .pc(id_pc_r),
        .A(id_A_r),
        .B(id_B_r),
        .A_reg(id_A_reg_r),
        .B_reg(id_B_reg_r),
        .B_imm(id_B_imm_r),
        .shamt(id_shamt_r),
        .alu_op(id_alu_op_r),
        .alu_inst(id_alu_inst_r),
        .load_inst(id_load_inst_r),
        .store_inst(id_store_inst_r),
        .jmp_inst(id_jmp_inst_r),
        .dest_reg(id_dest_reg_r),
        .dest_reg_valid(id_dest_reg_valid_r),
        .result(ex_result)
        );

  mem MEM(
          .clock(clock),
          .reset_n(reset_n),
          .cache_rd(dcache_rd),
          .cache_wr(dcache_wr),
          .cache_addr(dcache_addr),
          .cache_wr_data(dcache_wr_data),
          .cache_data(dcache_data),
          .cache_waitrequest(dcache_waitrequest),
          .load_inst(ex_load_inst_r),
          .store_inst(ex_store_inst_r),
          .dest_reg(ex_dest_reg_r),
          .dest_reg_valid(ex_dest_reg_valid_r),
          .alu_result(ex_result_r),
          .result(mem_result)
          );

  wb WB(
        .clock(clock),
        .reset_n(reset_n),
        .result(mem_result_r),
        .dest_reg(mem_dest_reg_r),
        .dest_reg_valid(mem_dest_reg_valid_r),
        .rfile_wr_addr1(rfile_wr_addr1),
        .rfile_wr_enable1(rfile_wr_enable1),
        .rfile_wr_data1(rfile_wr_data1)
        );



  pipreg_if_id R_IF_ID(
                       // Inputs
                       .clock(clock),
                       .reset_n(reset_n),
                       .if_pc(if_pc),
                       .if_inst_word(if_inst_word),
                       // Outputs
                       .id_pc(if_pc_r),
                       .id_inst_word(if_inst_word_r)
                       );

  pipreg_id_ex R_ID_EX(
                       // Inputs
                       .clock(clock),
                       .reset_n(reset_n),
                       .id_pc(if_pc_r),
                       .id_A(id_A),
                       .id_B(id_B),
                       .id_A_reg(id_A_reg),
                       .id_B_reg(id_B_reg),
                       .id_B_imm(id_B_imm),
                       .id_shamt(id_shamt),
                       .id_alu_op(id_alu_op),
                       .id_alu_inst(id_alu_inst),
                       .id_load_inst(id_load_inst),
                       .id_store_inst(id_store_inst),
                       .id_jmp_inst(id_jmp_inst),
                       .id_dest_reg(id_dest_reg),
                       .id_dest_reg_valid(id_dest_reg_valid),
                       // Outputs
                       .ex_pc(id_pc_r),
                       .ex_A(id_A_r),
                       .ex_B(id_B_r),
                       .ex_A_reg(id_A_reg_r),
                       .ex_B_reg(id_B_reg_r),
                       .ex_B_imm(id_B_imm_r),
                       .ex_shamt(id_shamt_r),
                       .ex_alu_op(id_alu_op_r),
                       .ex_alu_inst(id_alu_inst_r),
                       .ex_load_inst(id_load_inst_r),
                       .ex_store_inst(id_store_inst_r),
                       .ex_jmp_inst(id_jmp_inst_r),
                       .ex_dest_reg(id_dest_reg_r),
                       .ex_dest_reg_valid(id_dest_reg_valid_r)
                       );

  pipreg_ex_mem R_EX_MEM(
                         // Inputs
                         .clock(clock),
                         .reset_n(reset_n),
                         .ex_pc(id_pc_r),
                         .ex_load_inst(id_load_inst_r),
                         .ex_store_inst(id_store_inst_r),
                         .ex_jmp_inst(id_jmp_inst_r),
                         .ex_result(ex_result),
                         .ex_dest_reg(id_dest_reg_r),
                         .ex_dest_reg_valid(id_dest_reg_valid_r),
                         // Outputs
                         .mem_pc(ex_pc_r),
                         .mem_load_inst(ex_load_inst_r),
                         .mem_store_inst(ex_store_inst_r),
                         .mem_jmp_inst(ex_jmp_inst_r),
                         .mem_result(ex_result_r),
                         .mem_dest_reg(ex_dest_reg_r),
                         .mem_dest_reg_valid(ex_dest_reg_valid_r)
                         );

  pipreg_mem_wb R_MEM_WB(
                         // Inputs
                         .clock(clock),
                         .reset_n(reset_n),
                         .mem_pc(ex_pc_r),
                         .mem_result(mem_result),
                         .mem_dest_reg(ex_dest_reg_r),
                         .mem_dest_reg_valid(ex_dest_reg_valid_r),
                         // Outputs
                         .wb_pc(mem_pc_r),
                         .wb_result(mem_result_r),
                         .wb_dest_reg(mem_dest_reg_r),
                         .wb_dest_reg_valid(mem_dest_reg_valid_r)
                         );


endmodule
