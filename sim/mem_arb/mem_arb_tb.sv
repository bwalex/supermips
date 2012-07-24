`timescale 1ns/10ps

module mem_arb_tb;

  parameter BURSTLEN_WIDTH  = 32;
  parameter MEM_WIDTH  = 32;
  parameter CPU_DATA_WIDTH  = 32;
  localparam CPU_BE_WIDTH  = CPU_DATA_WIDTH/8;

  logic clock;
  logic reset_n;

  wire [31:0]  cm_addr;
  wire [ 1:0]  cm_burst_len;
  wire [31:0]  cm_rd_data;
  wire         cm_rd_valid;
  wire         cm_waitrequest;
  wire [31:0]  cm_wr_data;
  wire         cm_wr;
  wire         cm_rd;



  logic [31:0]           i_addr[2];
  logic [BURSTLEN_WIDTH-1:0] i_burst_len[2];
  wire  [MEM_WIDTH-1:0]  i_rd_data[2];
  wire                   i_rd_valid[2];
  wire                   i_waitrequest[2];
  logic [MEM_WIDTH-1:0]  i_wr_data[2];
  logic                  i_wr[2];
  logic                  i_rd[2];


  reg [31:0]   valmem[1024*1024];

  integer      ntests, rdtests, wrtests;

  event        start_tests;


  memory #
    (
     .MEM_FILE("seq.vmem"),
     .ADDR_WIDTH(32),
     .DATA_WIDTH(32),
     .BURSTLEN_WIDTH(2),
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


  mem_arb #
    (
     .DATA_WIDTH(32),
     .BURSTLEN_WIDTH(2)
     )
  mem_arb
    (
     .clock(clock),
     .reset_n(reset_n),

     .c1_addr(i_addr[0]),
     .c1_burst_len(i_burst_len[0]),
     .c1_data_out(i_rd_data[0]),
     .c1_data_in(i_wr_data[0]),
     .c1_wr(i_wr[0]),
     .c1_rd(i_rd[0]),
     .c1_waitrequest(i_waitrequest[0]),
     .c1_rd_valid(i_rd_valid[0]),

     .c2_addr(i_addr[1]),
     .c2_burst_len(i_burst_len[1]),
     .c2_data_out(i_rd_data[1]),
     .c2_data_in(i_wr_data[1]),
     .c2_wr(i_wr[1]),
     .c2_rd(i_rd[1]),
     .c2_waitrequest(i_waitrequest[1]),
     .c2_rd_valid(i_rd_valid[1]),

     .mm_addr(cm_addr),
     .mm_burst_len(cm_burst_len),
     .mm_data_in(cm_rd_data),
     .mm_data_out(cm_wr_data),
     .mm_wr(cm_wr),
     .mm_rd(cm_rd),
     .mm_waitrequest(cm_waitrequest),
     .mm_rd_valid(cm_rd_valid)
     );



  task automatic read(input bit port, input [31:0] addr);
    automatic bit [31:0] words[4];
    automatic integer rd_count  = 0;
    automatic integer idx       = (addr >> 2) & 2'b11;
    i_addr[port]                = addr;
    i_wr[port]                  = 1'b0;
    i_rd[port]                  = 1'b1;
    i_burst_len[port]           = 3; // XXX: fixed burst len (4)

    //$display("read(%b), addr: %x", port, addr);

    do
      @(posedge clock);
    while (i_waitrequest[port]);

    i_rd[port]  = 1'b0;

    while (rd_count != 4) begin// XXX: fixed burst len
      if (i_rd_valid[port]) begin
        rd_count++;
        words[idx]         = i_rd_data[port];
        assert(words[idx] == valmem[((addr >> 2) & { 30'hFFFFFFFF, 2'b00}) + idx]) begin
        end else begin
          $error("rd(%b): addr: %x (%x), rd_count: %d, got %x, expected %x", port, ((addr >> 2) & {30'hFFFFFFFF, 2'b00}) + idx, addr, rd_count, words[idx], valmem[((addr >> 2) & 2'b00) + idx]);
        end

        if (idx == 3)
          idx  = 0;
        else
          idx++;
      end
      @(posedge clock);
    end
  endtask // read



  task automatic write(input bit port, input [31:0] addr);
    automatic bit [31:0] words[4];
    automatic integer wr_count  = 0;
    automatic integer idx       = addr & 2'b11;

    //$display("write(%b), addr: %x", port, addr);

    i_addr[port]                = addr;
    i_wr[port]                  = 1'b1;
    i_rd[port]                  = 1'b0;
    i_burst_len[port]           = 3; // XXX: fixed burst len (4)
    for (integer i = 0; i < 4; i++)
      words[i]      = $random;

    while(wr_count != 4) begin
      i_wr_data[port] = words[wr_count];
      i_addr[port]    = addr + (wr_count << 2);
      do
        @(posedge clock);
      while (i_waitrequest[port]);
      valmem[(addr >> 2) + wr_count]  = words[wr_count];
      @(posedge clock);

      assert(m1.mem[(addr >> 2) + wr_count]  == words[wr_count]) begin
      end else begin
        $error("wr(%b): addr: %x (%x), wr_count: %d, got %x, wrote %x", port, (addr >> 2) + wr_count, addr, wr_count, m1.mem[(addr >> 2) + wr_count], words[wr_count]);
      end

      wr_count++;
    end

    i_wr[port]  = 1'b0;
  endtask // write



  task automatic test_runner(input bit port);
    automatic bit [31:0] addr;
    automatic bit wr;
    automatic bit [1:0] delay;
    automatic bit [19:0] rand_addr;
    automatic integer writes  = 0, reads = 0, total = 0;


    $display("Test runner for port %b started", port);

    while(1'b1) begin
      rand_addr  = $random;

      addr       = 32'b0 | rand_addr;
      wr         = $random;

      if (wr) begin
        write(.port(port), .addr(addr));
        writes++;
      end else begin
        read(.port(port), .addr(addr));
        reads++;
      end

      total++;

      delay      = $random;

      for (integer i = 0; i < delay; i++)
        @(posedge clock);

      if ((total % 10000)  == 0)
        $display("port %b: ran %d tests (%d read, %d write)", port, total, reads, writes);

    end
  endtask // test_runner





  // 100 MHz clock
  always
  begin
         clock = 0;
    #5   clock = 1;
    #5   clock = 0;
  end

  initial begin
    reset_n      = 1;
    #5  reset_n  = 0;
    #16 reset_n  = 1;

    $readmemh("seq.vmem", valmem);

    @(posedge clock);
    @(posedge clock);

    fork
      test_runner(.port(1'b0));
      test_runner(.port(1'b1));
    join
  end

endmodule
