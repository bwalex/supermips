`timescale 1ns/10ps

module cache_tb;

  parameter CPU_DATA_WIDTH  = 128;
  localparam CPU_BE_WIDTH  = CPU_DATA_WIDTH/8;

  logic clock;
  logic reset_n;

  logic [31:0] cpu_addr;
  logic        cpu_rd;
  logic        cpu_wr;
  logic [CPU_BE_WIDTH-1:0] cpu_wr_be;
  wire [CPU_DATA_WIDTH-1:0] cpu_rd_data;
  wire                      cpu_waitrequest;
  logic [CPU_DATA_WIDTH-1:0] cpu_wr_data;

  wire [31:0]  cm_addr;
  wire [ 2:0]  cm_burst_len;
  wire [31:0]  cm_rd_data;
  wire         cm_rd_valid;
  wire         cm_waitrequest;
  wire [31:0]  cm_wr_data;
  wire         cm_wr;
  wire         cm_rd;

  reg [31:0]   staging[1024*1024];
  reg [CPU_DATA_WIDTH-1:0]   valmem[1024*1024];
  logic [10:0] rand_addr; // should match size in words of valmem and memory

  integer      ntests, rdtests, wrtests;

  memory #
    (
     .MEM_FILE("seq.vmem"),
     .ADDR_WIDTH(32),
     .DATA_WIDTH(32),
     .BURSTLEN_WIDTH(3),
     .DEPTH(1024*1024) // 1M Words
     )
  m1
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

  generic_cache #
    (
     .CLINE_WIDTH(256),
     .ADDR_WIDTH(32),
     .DATA_WIDTH(CPU_DATA_WIDTH),
     .MEM_DATA_WIDTH(32),
     .NLINES(64),
     .ASSOC(4)
     )
  c1
    (
     .clock(clock),
     .reset_n(reset_n),

     .cpu_addr(cpu_addr),
     .cpu_rd(cpu_rd),
     .cpu_wr(cpu_wr),
     .cpu_wr_be(cpu_wr_be),
     .cpu_wr_data(cpu_wr_data),
     .cpu_rd_valid(cpu_rd_valid),
     .cpu_rd_data(cpu_rd_data),
     .cpu_waitrequest(cpu_waitrequest),

     .mem_addr_r(cm_addr),
     .mem_burst_len(cm_burst_len),
     .mem_rd_data(cm_rd_data),
     .mem_rd_valid(cm_rd_valid),
     .mem_waitrequest(cm_waitrequest),
     .mem_wr_data_r(cm_wr_data),
     .mem_wr_r(cm_wr),
     .mem_rd_r(cm_rd)
     );



  task cache_read(input [31:0] addr, output [CPU_DATA_WIDTH-1:0] word, output integer latency);
    @(negedge clock);
    latency  = 0;

    do begin
      cpu_rd    = 1'b1;
      cpu_addr  = addr;
      @(posedge clock);
      latency++;
    end while(cpu_waitrequest);

    cpu_rd  <= 1'b0;
    word    = cpu_rd_data;
  endtask // cache_read


  task cache_write(input [31:0] addr, input [CPU_DATA_WIDTH-1:0] word, input[CPU_BE_WIDTH-1:0] be, output integer latency);
    automatic bit [CPU_DATA_WIDTH-1:0] be_expanded;

    for (integer i = 0; i < CPU_BE_WIDTH; i++)
      be_expanded[CPU_DATA_WIDTH-1-i*8 -: 8]  = { 8{be[CPU_BE_WIDTH-1-i]} };

    @(negedge clock);
    latency  = 0;

    do begin
      cpu_wr       = 1'b1;
      cpu_wr_be    = be;
      cpu_wr_data  = word;
      cpu_addr     = addr;
      @(posedge clock);
      latency++;
    end while(cpu_waitrequest);

    // Write written word to validation memory
    valmem[addr >> 4]  <= ((valmem[addr >> 4] & ~be_expanded) | (word & be_expanded));
    cpu_wr             <= 1'b0;
  endtask // cache_write


  task rand_test;
    automatic integer lat;
    automatic logic [CPU_DATA_WIDTH-1:0] data;
    automatic logic [31:0] addr_l;
    automatic logic [CPU_BE_WIDTH-1:0] be;
    automatic bit read;

    read       = $random;
    rand_addr  = $random;

    addr_l     = 'b0;
    addr_l     = rand_addr;

    ntests++;

    if (read) begin
      rdtests++;

      cache_read(.addr(addr_l << 4), .word(data), .latency(lat));
      assert(data == valmem[addr_l]) begin
      end else begin
        $error("addr: %x, expected %x, got %x, memory %x", addr_l << 2, valmem[addr_l], data, m1.mem[addr_l]);
        $stop();
      end
    end
    else begin
      wrtests++;
      data  = $random;
      be    = $random;
      cache_write(.addr(addr_l << 4), .word(data), .be(be), .latency(lat));
`ifdef TRACE_ENABLE
      $display("Cache write at %x => %x (latency: %d cycles)", (addr_l << 2), data, lat);
`endif
    end
  endtask


  // 100 MHz clock
  always
  begin
         clock = 0;
    #5   clock = 1;
    #5   clock = 0;
  end

  initial begin
    ntests       = 0;
    rdtests      = 0;
    wrtests      = 0;

    cpu_rd       = 1'b0;
    cpu_wr       = 1'b0;
    reset_n      = 1;
    #5  reset_n  = 0;
    #16 reset_n  = 1;
    $readmemh("seq.vmem", staging);
    for (integer i = 0; i < 1024*1024; i += 4)
      valmem[i>>2] = {staging[i], staging[i+1], staging[i+2], staging[i+3] };
    @(posedge clock);
    @(posedge clock);

    while(1) begin
      rand_test();
      if ((ntests % 10000) == 0) begin
        $display("Ran %d random tests (%d read, %d write)", ntests, rdtests, wrtests);
        $display("Access: %d", c1.stat_access);
        $display("Hit:    %d", c1.stat_access-c1.stat_misses);
        $display("Miss:   %d", c1.stat_misses);
        $display("Alloc:  %d", c1.stat_allocs);
        $display("Evict:  %d", c1.stat_evicts);
        $display("WBack:  %d", c1.stat_wbacks);
      end
    end
  end


endmodule
