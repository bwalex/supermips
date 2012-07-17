`timescale 1ns/10ps

module top#(
           parameter IMEM_FILE = "../software/dhry.vmem",
           parameter DMEM_FILE = "../software/dhry.vmem"
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
  wire [31:0]           icache_data;
  wire                  icache_waitrequest;

  wire [4:0]            rfile_rd_addr1;         // From CPU of pipeline.v
  wire [4:0]            rfile_rd_addr2;         // From CPU of pipeline.v
  wire [4:0]            rfile_wr_addr1;         // From CPU of pipeline.v
  wire [31:0]           rfile_wr_data1;         // From CPU of pipeline.v
  wire                  rfile_wr_enable1;       // From CPU of pipeline.v
  // End of automatics
  wire [31:0]           rfile_rd_data1;
  wire [31:0]           rfile_rd_data2;


  pipeline CPU(
               // Outputs
               .icache_addr             (icache_addr),
               .icache_rd               (icache_rd),
               .rfile_rd_addr1          (rfile_rd_addr1),
               .rfile_rd_addr2          (rfile_rd_addr2),
               .dcache_addr             (dcache_addr),
               .dcache_rd               (dcache_rd),
               .dcache_wr               (dcache_wr),
               .dcache_wr_be            (dcache_wr_be),
               .dcache_wr_data          (dcache_wr_data),
               .rfile_wr_addr1          (rfile_wr_addr1),
               .rfile_wr_enable1        (rfile_wr_enable1),
               .rfile_wr_data1          (rfile_wr_data1),
               // Inputs
               .clock                   (clock),
               .reset_n                 (reset_n),
               .icache_data             (icache_data),
               .icache_waitrequest      (icache_waitrequest),
               .rfile_rd_data1          (rfile_rd_data1),
               .rfile_rd_data2          (rfile_rd_data2),
               .dcache_data             (dcache_data),
               .dcache_waitrequest      (dcache_waitrequest));

  rfile REGFILE(
                // Outputs
                .rd_data1               (rfile_rd_data1),
                .rd_data2               (rfile_rd_data2),
                // Inputs
                .clock                  (clock),
                .reset_n                (reset_n),
                .rd_addr1               (rfile_rd_addr1),
                .rd_addr2               (rfile_rd_addr2),
                .wr_addr1               (rfile_wr_addr1),
                .wr_enable1             (rfile_wr_enable1),
                .wr_data1               (rfile_wr_data1));

  tcm #(
            .MEM_FILE(IMEM_FILE)
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
             .MEM_FILE(DMEM_FILE)
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

  string                inst_str_if;
  string                inst_str_id;
  string                inst_str_ex;
  string                inst_str_mem;
  string                inst_str_wb;

`ifdef TRACE_ENABLE
  text_idec tdec_if(.inst_word(CPU.if_inst_word),    .pc(CPU.if_pc),    .inst_str(inst_str_if));
  text_idec tdec_id(.inst_word(CPU.if_inst_word_r),  .pc(CPU.if_pc_r),  .inst_str(inst_str_id));
  text_idec tdec_ex(.inst_word(CPU.id_inst_word_r),  .pc(CPU.id_pc_r),  .inst_str(inst_str_ex));
  text_idec tdec_mem(.inst_word(CPU.ex_inst_word_r), .pc(CPU.ex_pc_r),  .inst_str(inst_str_mem));
  text_idec tdec_wb(.inst_word(CPU.mem_inst_word_r), .pc(CPU.mem_pc_r), .inst_str(inst_str_wb));

  always @(posedge clock) begin
    if (CPU.MEM.load_inst) begin
      $display("LS trace: load (pc=%x), addr=%x => %x (%x)", CPU.ex_pc_r, CPU.MEM.cache_addr, CPU.MEM.cache_data, CPU.MEM.result);
    end
    if (CPU.MEM.store_inst) begin
      $display("LS trace: store (pc=%x), addr=%x => %x, be=%b", CPU.ex_pc_r, CPU.MEM.cache_addr, CPU.MEM.cache_wr_data, CPU.MEM.cache_wr_be);
    end
  end

  always @(posedge clock) begin
    if (CPU.WB.dest_reg_valid) begin
      $display("RFILE trace: write (pc =%x), $%d => %x", CPU.mem_pc_r, CPU.WB.dest_reg, CPU.WB.result);
    end
  end
`endif

  // 100 MHz clock
  always
  begin
         clock = 0;
    #5   clock = 1;
    #5   clock = 0;
  end

  initial begin
        reset_n = 1;
    #5  reset_n = 0;
    #16 reset_n = 1;
  end

endmodule
