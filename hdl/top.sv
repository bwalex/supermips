`timescale 1ns/10ps

module top#(
           parameter MEM_FILE  = "../software/coremark.vmem",
                     MEM_WIDTH = 32,
                     BURSTLEN_WIDTH = 2,
                     LSTRACE_FILE = "ls.trace",
                     RFTRACE_FILE = "rf.trace",
                     EX_UNITS = 1,
                     RETIRE_COUNT = 4,
                     IQ_DEPTH = 16,
                     ROB_DEPTH = 16
)(
);
  logic clock;
  logic reset_n;

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [31:0]           dcache_addr;            // From CPU of pipeline.v
  wire                  dcache_rd;              // From CPU of pipeline.v
  wire                  dcache_wr;              // From CPU of pipeline.v
  wire [ 3:0]           dcache_wr_be;
  wire [31:0]           dcache_wr_data;         // From CPU of pipeline.v
  wire [31:0]           dcache_data;
  wire                  dcache_waitrequest;
  wire [31:0]           icache_addr;            // From CPU of pipeline.v
  wire                  icache_rd;              // From CPU of pipeline.v
  wire [127:0]          icache_data;
  wire                  icache_waitrequest;

`ifdef REAL_CACHE
  wire [31:0]           cm_addr;
  wire [ 2:0]           cm_burst_len;
  wire [MEM_WIDTH-1:0]  cm_rd_data;
  wire                  cm_rd_valid;
  wire                  cm_waitrequest;
  wire [MEM_WIDTH-1:0]  cm_wr_data;
  wire                  cm_wr;
  wire                  cm_rd;

  wire [31:0]           icm_addr;
  wire [ 2:0]           icm_burst_len;
  wire [MEM_WIDTH-1:0]  icm_rd_data;
  wire                  icm_rd_valid;
  wire                  icm_waitrequest;
  wire [MEM_WIDTH-1:0]  icm_wr_data;
  wire                  icm_wr;
  wire                  icm_rd;

  wire [31:0]           dcm_addr;
  wire [ 1:0]           dcm_burst_len;
  wire [MEM_WIDTH-1:0]  dcm_rd_data;
  wire                  dcm_rd_valid;
  wire                  dcm_waitrequest;
  wire [MEM_WIDTH-1:0]  dcm_wr_data;
  wire                  dcm_wr;
  wire                  dcm_rd;
`endif


  pipeline #(
             .EX_UNITS(EX_UNITS),
             .RETIRE_COUNT(RETIRE_COUNT),
             .IQ_DEPTH(IQ_DEPTH),
             .ROB_DEPTH(ROB_DEPTH)
  )CPU(
               // Outputs
               .icache_addr             (icache_addr),
               .icache_rd               (icache_rd),
               .dcache_addr             (dcache_addr),
               .dcache_rd               (dcache_rd),
               .dcache_wr               (dcache_wr),
               .dcache_wr_be            (dcache_wr_be),
               .dcache_wr_data          (dcache_wr_data),
               // Inputs
               .clock                   (clock),
               .reset_n                 (reset_n),
               .icache_data             (icache_data),
               .icache_waitrequest      (icache_waitrequest),
               .dcache_data             (dcache_data),
               .dcache_waitrequest      (dcache_waitrequest));


`ifdef REAL_CACHE

  memory #
    (
     .MEM_FILE(MEM_FILE),
     .ADDR_WIDTH(32),
     .DATA_WIDTH(MEM_WIDTH),
     .BURSTLEN_WIDTH(3),
     .DEPTH(64*1024*1024) // 64M Words
     )
  memory
    (
     .clock(clock),
     .reset_n(reset_n),

     .addr(cm_addr),
     .burst_len(cm_burst_len),
     .data_out(cm_rd_data),
     .data_in(cm_wr_data),
     .wr(cm_wr),
     .rd(cm_rd),
     .waitrequest(cm_waitrequest),
     .rd_valid(cm_rd_valid)
     );


  mem_arb #
    (
     .DATA_WIDTH(MEM_WIDTH),
     .BURSTLEN_WIDTH(3)
     )
  mem_arb
    (
     .clock(clock),
     .reset_n(reset_n),

     .c1_addr(icm_addr),
     .c1_burst_len(icm_burst_len),
     .c1_data_out(icm_rd_data),
     .c1_data_in(icm_wr_data),
     .c1_wr(icm_wr),
     .c1_rd(icm_rd),
     .c1_waitrequest(icm_waitrequest),
     .c1_rd_valid(icm_rd_valid),

     .c2_addr(dcm_addr),
     .c2_burst_len({1'b0, dcm_burst_len}),
     .c2_data_out(dcm_rd_data),
     .c2_data_in(dcm_wr_data),
     .c2_wr(dcm_wr),
     .c2_rd(dcm_rd),
     .c2_waitrequest(dcm_waitrequest),
     .c2_rd_valid(dcm_rd_valid),

     .mm_addr(cm_addr),
     .mm_burst_len(cm_burst_len),
     .mm_data_in(cm_rd_data),
     .mm_data_out(cm_wr_data),
     .mm_wr(cm_wr),
     .mm_rd(cm_rd),
     .mm_waitrequest(cm_waitrequest),
     .mm_rd_valid(cm_rd_valid)
     );


  generic_cache #
    (
     .CLINE_WIDTH(256),
     .ADDR_WIDTH(32),
     .DATA_WIDTH(128),
     .MEM_DATA_WIDTH(MEM_WIDTH),
     .NLINES(64),
     .ASSOC(4)
     )
  icache
    (
     .clock(clock),
     .reset_n(reset_n),

     .cpu_addr(icache_addr),
     .cpu_rd(icache_rd),
     .cpu_wr(1'b0),
     .cpu_wr_be(32'b0),
     .cpu_wr_data('b0),
     .cpu_rd_data(icache_data),
     .cpu_waitrequest(icache_waitrequest),

     .mem_addr_r(icm_addr),
     .mem_burst_len(icm_burst_len),
     .mem_rd_data(icm_rd_data),
     .mem_rd_valid(icm_rd_valid),
     .mem_waitrequest(icm_waitrequest),
     .mem_wr_data_r(icm_wr_data),
     .mem_wr_r(icm_wr),
     .mem_rd_r(icm_rd)
     );


  generic_cache #
    (
     .CLINE_WIDTH(128),
     .ADDR_WIDTH(32),
     .DATA_WIDTH(32),
     .MEM_DATA_WIDTH(MEM_WIDTH),
     .NLINES(128),
     .ASSOC(4)
     )
  dcache
    (
     .clock(clock),
     .reset_n(reset_n),

     .cpu_addr(dcache_addr),
     .cpu_rd(dcache_rd),
     .cpu_wr(dcache_wr),
     .cpu_wr_be(dcache_wr_be),
     .cpu_wr_data(dcache_wr_data),
     .cpu_rd_data(dcache_data),
     .cpu_waitrequest(dcache_waitrequest),

     .mem_addr_r(dcm_addr),
     .mem_burst_len(dcm_burst_len),
     .mem_rd_data(dcm_rd_data),
     .mem_rd_valid(dcm_rd_valid),
     .mem_waitrequest(dcm_waitrequest),
     .mem_wr_data_r(dcm_wr_data),
     .mem_wr_r(dcm_wr),
     .mem_rd_r(dcm_rd)
     );

`else // !`ifdef REAL_CACHE

  tcm #(
            .MEM_FILE(MEM_FILE),
            .DATA_WIDTH(128)
          ) ITCM (
           // Outputs
           .cpu_rd_data                 (icache_data),
           .cpu_waitrequest             (icache_waitrequest),
           // Inputs
           .clock                       (clock),
           .reset_n                     (reset_n),
           .cpu_addr                    (icache_addr),
           .cpu_wr_data                 ('b0),
           .cpu_wr_be                   ('b0),
           .cpu_rd                      (icache_rd),
           .cpu_wr                      (1'b0));

  tcm #(
             .MEM_FILE(MEM_FILE),
             .DATA_WIDTH(32)
           ) DTCM (
           // Outputs
           .cpu_rd_data                 (dcache_data),
           .cpu_waitrequest             (dcache_waitrequest),
           // Inputs
           .clock                       (clock),
           .reset_n                     (reset_n),
           .cpu_addr                    (dcache_addr),
           .cpu_wr_data                 (dcache_wr_data),
           .cpu_wr_be                   (dcache_wr_be),
           .cpu_rd                      (dcache_rd),
           .cpu_wr                      (dcache_wr));
`endif

  string                inst_str_if;
  string                inst_str_id;
  string                inst_str_ex;
  string                inst_str_mem;
  string                inst_str_wb;


`ifdef TEXT_IDEC_ENABLE
  text_idec tdec_if(.inst_word(CPU.if_inst_word),    .pc(CPU.if_pc),    .inst_str(inst_str_if));
  text_idec tdec_id(.inst_word(CPU.if_inst_word_r),  .pc(CPU.if_pc_r),  .inst_str(inst_str_id));
  text_idec tdec_ex(.inst_word(CPU.id_inst_word_r),  .pc(CPU.id_pc_r),  .inst_str(inst_str_ex));
  text_idec tdec_mem(.inst_word(CPU.ex_inst_word_r), .pc(CPU.ex_pc_r),  .inst_str(inst_str_mem));
  text_idec tdec_wb(.inst_word(CPU.mem_inst_word_r), .pc(CPU.mem_pc_r), .inst_str(inst_str_wb));
`endif


  integer               ic_file;
  integer               dc_file;

  initial begin
    ic_file  = $fopen("icache.stats", "w");
    dc_file  = $fopen("dcache.stats", "w");
  end

  task finish_simulation;
    $display("End of simulation");

`ifdef REAL_CACHE
    $fwrite(ic_file, "access: %d\n", icache.stat_access);
    $fwrite(ic_file, "hit:    %d\n", icache.stat_access-icache.stat_misses);
    $fwrite(ic_file, "miss:   %d\n", icache.stat_misses);
    $fwrite(ic_file, "alloc:  %d\n", icache.stat_allocs);
    $fwrite(ic_file, "wback:  %d\n", icache.stat_wbacks);
    $fwrite(ic_file, "evict:  %d\n", icache.stat_evicts);

    $fwrite(dc_file, "access: %d\n", dcache.stat_access);
    $fwrite(dc_file, "hit:    %d\n", dcache.stat_access-dcache.stat_misses);
    $fwrite(dc_file, "miss:   %d\n", dcache.stat_misses);
    $fwrite(dc_file, "alloc:  %d\n", dcache.stat_allocs);
    $fwrite(dc_file, "wback:  %d\n", dcache.stat_wbacks);
    $fwrite(dc_file, "evict:  %d\n", dcache.stat_evicts);
`endif
    $finish();
  endtask

  always_ff @(posedge clock) begin
    bit [`clogb2(ROB_DEPTH)-1:0] k;

    if (CPU.ROB.consume_i) begin
      for (integer i = 0; i <= CPU.ROB.consume_count; i++) begin
        k = CPU.ROB.ext_ptr + i;
        if (!CPU.ROB.kill[k]) begin
          if (CPU.ROB.insns[k].inst_word == 32'h0000000d) begin // break
            finish_simulation();
          end
        end
      end
    end
  end


  // 100 MHz clock
  always
  begin
         clock = 0;
    #5   clock = 1;
    #5   clock = 0;
  end

  initial begin
        reset_n = 1;
    #2  reset_n = 0;
    #16 reset_n = 1;
  end

endmodule
