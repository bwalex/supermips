module generic_cache #(
  parameter CLINE_WIDTH = 128,
            ADDR_WIDTH  = 32,
            DATA_WIDTH  = 32,
            NLINES      = 256,
            NWORDS      = CLINE_WIDTH/DATA_WIDTH,
            NWORDSLOG2  = $clog2(NWORDS),
            LFSR_SEED   = 11'd101,
            ASSOC       = 4,
            CLINE_WIDTH_BYTES = CLINE_WIDTH/8,
            BE_WIDTH = CLINE_WIDTH_BYTES
)(
  input                    clock,
  input                    reset_n,

  input [ADDR_WIDTH-1:0]   cpu_addr,
  input                    cpu_rd,
  input                    cpu_wr,
  input [BE_WIDTH-1:0]     cpu_wr_be,
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

  localparam FULL_CLINE_WIDTH = CLINE_WIDTH + TAG_WIDTH + 1/*VALID*/ + 1/*DIRTY*/;

  reg [10:0]                  lfsr;
  wire [1:0]                  rand_bits;

  wire [CLINE_WIDTH-1:0]      be_expanded;

  reg [FULL_CLINE_WIDTH-1:0]  banks[NLINES][ASSOC];
  reg [$clog2(ASSOC)-1:0]     bank_sel;


  reg [NWORDSLOG2-1:0]        wr_count;
  reg [NWORDSLOG2-1:0]        rd_count;

  wire [FULL_CLINE_WIDTH-1:0] bank_cur_cline[ASSOC];

  wire [LINE_ADDR_WIDTH-1:0]  cpu_line_addr;
  wire [TAG_WIDTH-1:0]        cpu_addr_tag;
  wire                        cache_miss;
  wire                        cache_evict;

  wire                        bank_line_valid[ASSOC];

  wire                        bank_line_dirty[ASSOC];

  wire                        bank_hit[ASSOC];

  wire                        cache_hit;

  /*
   11-bit LFSR with basic equation x^11 + x^9 + 1, modified to generate two bits of entropy per cycle using a leap-forward structure.

   octave:6> A = [ 0 1 0 0 0 0 0 0 0 0 0; 0 0 1 0 0 0 0 0 0 0 0; 0 0 0 1 0 0 0 0 0 0 0; 0 0 0 0 1 0 0 0 0 0 0; 0 0 0 0 0 1 0 0 0 0 0; 0 0 0 0 0 0 1 0 0 0 0; 0 0 0 0 0 0 0 1 0 0 0; 0 0 0 0 0 0 0 0 1 0 0; 0 0 0 0 0 0 0 0 0 1 0; 0 0 0 0 0 0 0 0 0 0 1; 1 0 1 0 0 0 0 0 0 0 0]
A =
   0   1   0   0   0   0   0   0   0   0   0
   0   0   1   0   0   0   0   0   0   0   0
   0   0   0   1   0   0   0   0   0   0   0
   0   0   0   0   1   0   0   0   0   0   0
   0   0   0   0   0   1   0   0   0   0   0
   0   0   0   0   0   0   1   0   0   0   0
   0   0   0   0   0   0   0   1   0   0   0
   0   0   0   0   0   0   0   0   1   0   0
   0   0   0   0   0   0   0   0   0   1   0
   0   0   0   0   0   0   0   0   0   0   1
   1   0   1   0   0   0   0   0   0   0   0

octave:13> A^2
ans =
   0   0   1   0   0   0   0   0   0   0   0
   0   0   0   1   0   0   0   0   0   0   0
   0   0   0   0   1   0   0   0   0   0   0
   0   0   0   0   0   1   0   0   0   0   0
   0   0   0   0   0   0   1   0   0   0   0
   0   0   0   0   0   0   0   1   0   0   0
   0   0   0   0   0   0   0   0   1   0   0
   0   0   0   0   0   0   0   0   0   1   0
   0   0   0   0   0   0   0   0   0   0   1
   1   0   1   0   0   0   0   0   0   0   0
   0   1   0   1   0   0   0   0   0   0   0
*/
  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      lfsr     <= LFSR_SEED;
    else begin
      lfsr[0]  <= lfsr[2];
      lfsr[1]  <= lfsr[3];
      lfsr[2]  <= lfsr[4];
      lfsr[3]  <= lfsr[5];
      lfsr[4]  <= lfsr[6];
      lfsr[5]  <= lfsr[7];
      lfsr[6]  <= lfsr[8];
      lfsr[7]  <= lfsr[9];
      lfsr[8]  <= lfsr[10];
      lfsr[9]  <= lfsr[0]  ^ lfsr[2];
      lfsr[10] <= lfsr[1]  ^ lfsr[3];
    end

  assign rand_bits  = { lfsr[1], lfsr[0] };



  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      rd_count <= 0;
    else if (mem_rd_valid)
      rd_count <= rd_count + 1;


  assign cpu_line_addr = cpu_addr[ADDR_WIDTH-TAG_WIDTH-1 -: LINE_ADDR_WIDTH];
  assign cpu_addr_tag  = cpu_addr[ADDR_WIDTH-1 -: TAG_WIDTH];

  genvar i;
  generate
    for (i = 0; i < ASSOC; i++) begin: BANKS
      assign bank_cur_cline[i]  <=  banks[i][cpu_line_addr];
      assign bank_line_valid[i] <=  bank_cur_cline[i][FULL_CLINE_WIDTH-1];
      assign bank_line_dirty[i] <=  bank_cur_cline[i][FULL_CLINE_WIDTH-2];
      assign bank_hit[i]        <=  bank_line_valid[i]
                                 & (bank_cur_cline[i][FULL_CLINE_WIDTH-3 -: TAG_WIDTH] == cpu_addr_tag);
    end

    for (i = 0; i < BE_WIDTH; i = i+1) begin : EXP_BE
      assign be_expanded[DATA_WIDTH-1-i*8 -: 8]  = { 8{cpu_wr_be[BE_WIDTH-1-i]} };
    end
  endgenerate

  assign cache_hit  = (| bank_hit);


  assign cpu_waitrequest  = (cpu_rd | cpu_wr) & ~cache_hit;

  assign cpu_rd_valid  = cpu_rd & cache_hit;


  always_comb begin
    cpu_rd_line  = bank_cur_cline[0];
    bank_sel     = 'b0;
    for (integer k = 0; k < ASSOC; k++)
      if (bank_hit[k]) begin
        bank_sel     = k;
        cpu_rd_line  = bank1_cur_cline[k][FULL_CLINE_WIDTH-3 - TAG_WIDTH : 0];
        break;
      end
  end


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      for (integer i = 0; i < ASSOC; i++)
        for (integer j = 0; j < NLINES; j++)
          banks[i][j][FULL_CLINE_WIDTH-1 -: 2]  = 2'b00; /* Reset valid,dirty bits */
    else if (cpu_wr & cache_hit) begin
      banks[bank_sel][cpu_line_addr][CLINE_WIDTH-1:0]    <=  (bank_cur_cline[bank_sel] & ~be_expanded)
                                                           | (cpu_wr_data              &  be_expanded);

      banks[bank_sel][cpu_line_addr][FULL_CLINE_WIDTH-2] <=  1'b1; /* mark as dirty */
    end



  assign mem_burst_len = NWORDS;
  assign mem_addr      = cpu_addr[ADDR_WIDTH-1:LINE_WIDTH]; /* XXX? */
  assign mem_rd        = cpu_rd & ~cache_miss;
  // Write-back cache
  assign mem_wr        = cache_evict;



  // Either read or write
  assert property (~(cpu_wr & cpu_rd));

  // XXX: cache consistency with self-modifying code?
  //      need cache region invalidation, or complete cache invalidation
endmodule
