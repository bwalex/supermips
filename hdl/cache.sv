module generic_cache #(
  parameter CLINE_WIDTH = 128,
            ADDR_WIDTH  = 32,
            DATA_WIDTH  = 32,
            NLINES      = 256,
            NWORDS      = CLINE_WIDTH/DATA_WIDTH,
            NWORDSLOG2  = $clog2(NWORDS)
)(
  input                    clock,
  input                    reset_n,

  input [ADDR_WIDTH-1:0]   cpu_addr,
  input                    cpu_rd,
  input                    cpu_wr,
  output                   cpu_rd_valid,
  output [CLINE_WIDTH-1:0] cpu_rd_line,
  output                   cpu_waitrequest,

  output [ADDR_WIDTH-1:0]  mem_addr,
  output [NWORDSLOG2-1:0]  mem_burst_len,
  input [DATA_WIDTH-1:0]   mem_rd_data,
  input                    mem_rd_valid,
  input                    mem_waitrequest,
  output [CLINE_WIDTH-1:0] mem_wr_data,
  output                   mem_wr,
  output                   mem_rd
);

  localparam LINE_ADDR_WIDTH  = $clog2(NLINES);
  localparam LINE_WIDTH  = $clog2(CLINE_WIDTH);

  localparam TAG_WIDTH  = ADDR_WIDTH - LINE_ADDR_WIDTH - LINE_WIDTH;

  localparam FULL_CLINE_WIDTH = CLINE_WIDTH + TAG_WIDTH + 1;

  // XXX: Implement set-associativity
  reg [FULL_CLINE_WIDTH-1:0]  clines [NLINES];

  reg [NWORDSLOG2-1:0]        wr_count;
  reg [NWORDSLOG2-1:0]        rd_count;

  wire [FULL_CLINE_WIDTH-1:0] cur_cline;
  wire [LINE_ADDR_WIDTH-1:0]  cpu_line_addr;
  wire [TAG_WIDTH-1:0]        cpu_addr_tag;
  wire                        cache_miss;
  wire                        cache_evict;
  wire                        cache_line_tag_miss;
  wire                        cache_line_valid;


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      rd_count <= 0;
    else if (mem_rd_valid)
      rd_count <= rd_count + 1;


  assign cpu_line_addr = cpu_addr[ADDR_WIDTH-TAG_WIDTH-1 -: LINE_ADDR_WIDTH];
  assign cpu_addr_tag  = cpu_addr[ADDR_WIDTH-1 -: TAG_WIDTH];
  assign cur_cline  = clines[cpu_line_addr];

  assign cache_line_valid    = cur_cline[FULL_CLINE_WIDTH-1];
  assign cache_line_tag_miss = (cur_cline[FULL_CLINE_WIDTH-2 -: TAG_WIDTH] != cpu_addr_tag);

  assign cache_miss  = ~cache_line_valid | cache_line_tag_miss;
  assign cache_evict =  cache_line_valid & cache_line_tag_miss;

  assign cpu_waitrequest  = cache_miss;
  // XXX: redundant?
  assign cpu_rd_valid  = ~cache_miss;

  assign cpu_rd_line  = cur_cline[FULL_CLINE_WIDTH-1-TAG_WIDTH-1:0];

  assign mem_burst_len = NWORDS;
  assign mem_addr      = cpu_addr[ADDR_WIDTH-1:LINE_WIDTH]; /* XXX? */
  assign mem_rd        = cpu_rd & ~cache_miss;
  // Write-back cache
  assign mem_wr        = cache_evict;



  // XXX: THIS IS VERY MUCH WIP - lots of stuff to implement

  // XXX: add prefetching

  // Either read or write
  assert property (cpu_wr ^ cpu_rd);

  // XXX: cache consistency with self-modifying code?
  //      need cache region invalidation, or complete cache invalidation
endmodule