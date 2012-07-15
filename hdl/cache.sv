module generic_cache #(
  parameter            CLINE_WIDTH = 128,
                       ADDR_WIDTH = 32,
                       DATA_WIDTH = 32,
                       MEM_DATA_WIDTH = 32,
                       NLINES = 256,
                       NWORDS = CLINE_WIDTH/DATA_WIDTH,
                       MEM_NWORDS = CLINE_WIDTH/MEM_DATA_WIDTH,
                       NWORDSLOG2 = $clog2(NWORDS),
                       MEM_NWORDSLOG2        = $clog2(MEM_NWORDS),
                       MEM_ADDR_BITWIDTH     = $clog2(MEM_DATA_WIDTH/8),
                       LFSR_SEED             = 11'd101,
                       ASSOC                 = 4,
                       CLINE_WIDTH_BYTES     = CLINE_WIDTH/8,
                       DATA_WIDTH_BYTES      = DATA_WIDTH/8,
                       MEM_DATA_WIDTH_BYTES  = MEM_DATA_WIDTH/8,
                       BE_WIDTH              = DATA_WIDTH_BYTES
)(
  input                       clock,
  input                       reset_n,

  input [ADDR_WIDTH-1:0]      cpu_addr,
  input                       cpu_rd,
  input                       cpu_wr,
  input [BE_WIDTH-1:0]        cpu_wr_be,
  output                      cpu_rd_valid,
  output [DATA_WIDTH-1:0]     cpu_rd_data,
  output                      cpu_waitrequest,

  output [ADDR_WIDTH-1:0]     mem_addr_r,
  output [MEM_NWORDSLOG2-1:0] mem_burst_len,
  input [MEM_DATA_WIDTH-1:0]  mem_rd_data,
  input                       mem_rd_valid,
  input                       mem_waitrequest,
  output [CLINE_WIDTH-1:0]    mem_wr_data_r,
  output reg                  mem_wr_r,
  output reg                  mem_rd_r
);

  localparam LINE_ADDR_WIDTH  = $clog2(NLINES);
  localparam LINE_WIDTH  = $clog2(CLINE_WIDTH);

  localparam TAG_WIDTH  = ADDR_WIDTH - LINE_ADDR_WIDTH - LINE_WIDTH;


  typedef enum {
    IDLE,
    WRITEBACK,
    ALLOCATE
  } cctl_state_t;

  typedef struct packed {
    bit                 valid;
    bit                 dirty;
    bit [TAG_WIDTH-1:0] tag;
  } tagmem_t;


  reg [ADDR_WIDTH-1:0]        mem_addr_r;

  reg [10:0]                  lfsr;
  reg                         lfsr_enable;
  wire [1:0]                  rand_bits;
  reg [CLINE_WIDTH-1:0]       cpu_rd_line;

  reg [MEM_NWORDSLOG2-1:0]    mem_word_count;
  reg                         mem_word_count_load;
  wire                        mem_word_count_dec;

  wire [CLINE_WIDTH-1:0]      be_expanded;

  tagmem_t                    tag_banks[NLINES][ASSOC];
  reg [CLINE_WIDTH-1:0]       data_banks[NLINES][ASSOC];
  reg [$clog2(ASSOC)-1:0]     bank_sel;

  reg                         tag_write;
  reg                         data_write_cpu;
  reg                         data_write_mem;

  tagmem_t                    new_tag;
  reg [CLINE_WIDTH-1:0]       new_data;

  reg [NWORDSLOG2-1:0]        wr_count;
  reg [NWORDSLOG2-1:0]        rd_count;

  wire [FULL_CLINE_WIDTH-1:0] bank_cur_cline[ASSOC];

  wire [LINE_ADDR_WIDTH-1:0]  cpu_line_addr;
  wire [TAG_WIDTH-1:0]        cpu_addr_tag;
  wire [NWORDSLOG2-1:0]       cpu_block_idx;

  wire                        cache_miss;
  wire                        cache_evict;

  wire                        bank_line_valid[ASSOC];
  wire                        bank_line_dirty[ASSOC];
  wire                        bank_hit[ASSOC];

  wire                        cache_hit;

  cctl_state_t                state;
  cctl_state_t                next_state;

  /*
   11-bit LFSR with basic equation x^11 + x^9 + 1, modified to generate two bits of entropy per cycle using a leap-forward structure.
   */
  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      lfsr     <= LFSR_SEED;
    else if (lfsr_enable) begin
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
    else if (mem_word_count_load)
      rd_count <= 0;
    else if (mem_rd_valid)
      rd_count <= rd_count + 1;



  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      wr_count <= 0;
    else if (mem_word_count_load)
      wr_count <= 0;
    else if (~mem_waitrequest)
      wr_count <= wr_count + 1;



  assign cpu_line_addr = cpu_addr[ADDR_WIDTH-TAG_WIDTH-1 -: LINE_ADDR_WIDTH];
  assign cpu_addr_tag  = cpu_addr[ADDR_WIDTH-1 -: TAG_WIDTH];
  assign cpu_block_idx  = cpu_addr[NWORDSLOG2-1:0];


  genvar i;
  generate
    for (i = 0; i < ASSOC; i++) begin: BANKS
      assign bank_cur_cline[i]  =  data_banks[i][cpu_line_addr];
      assign bank_line_valid[i] =  tag_banks[i][cpu_line_addr].valid;
      assign bank_line_dirty[i] =  tag_banks[i][cpu_line_addr].dirty;
      assign bank_hit[i]        =  bank_line_valid[i]
                                & (tag_banks[i][cpu_line_addr].tag == cpu_addr_tag);
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
    bit found    = 1'b0;

    for (integer k = 0; k < ASSOC; k++)
      if (~tag_banks[k][cpu_line_addr].valid) begin
        bank_sel  = k;
        found     = 1'b1;
        break;
      end

    if (!found) begin
      integer k  = rand_bits;

      do begin
        if (k == ASSOC-1)
          k  = 0;
        else
          k += 1;

        if (~tag_banks[k][cpu_line_addr].dirty) begin
          bank_sel  = k;
          found     = 1'b1;
          break;
        end
      end while (k != rand_bits);
    end

    if (!found)
      bank_sel  = rand_bits;

    // XXX: can use case(1'b1) instead in general, when not parameterized?
    for (integer k = 0; k < ASSOC; k++)
      if (bank_hit[k]) begin
        bank_sel     = k;
        cpu_rd_line  = bank_cur_cline[k];
        break;
      end
  end

  /* MUX right word from line to output */
  assign cpu_rd_data  = cpu_rd_line[CLINE_WIDTH
                                    - ((NWORDSLOG2 == 0) ? 0 : DATA_WIDTH*cpu_block_idx)
                                    -: DATA_WIDTH];

  assign mem_wr_data  = cpu_rd_line[CLINE_WIDTH
                                    - ((NWORDSLOG2 == 0) ? 0 : DATA_WIDTH*wr_count)
                                    -: DATA_WIDTH];

  // DATA memory writes
  always_ff @(posedge clock)
    if (data_write_cpu)
      data_banks[bank_sel][cpu_line_addr][CLINE_WIDTH
                                          - ((NWORDSLOG2 == 0) ? 0 : DATA_WIDTH*cpu_block_idx)
                                          -: DATA_WIDTH] <=  (cpu_rd_data  & ~be_expanded)
                                                           | (cpu_wr_data  &  be_expanded);
    else if (data_write_mem)
      data_banks[bank_sel][cpu_line_addr][CLINE_WIDTH
                                          - ((MEM_NWORDSLOG2 == 0) ? 0 : MEM_DATA_WIDTH*rd_count)
                                          -: MEM_DATA_WIDTH] <= mem_rd_data;


  // TAG memory writes
  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      for (integer i = 0; i < ASSOC; i++)
        for (integer j = 0; j < NLINES; j++) begin
          tag_banks[i][j].valid  = 1'b0;
          tag_banks[i][j].dirty  = 1'b0;
        end
    else if (tag_write)
      tag_banks[bank_sel][cpu_line_addr] <= new_tag;


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      state <= IDLE;
    else
      state <= next_state;


  always_comb
    begin
      next_state           = state;
      new_tag.tag          = cpu_addr_tag;
      new_tag.valid        = 1'b0;
      new_tag.dirty        = 1'b0;
      tag_write            = 1'b0;
      data_write_cpu       = 1'b0;
      data_write_mem       = 1'b0;
      lfsr_enable          = 1'b0;
      mem_word_count_load  = 1'b0;
      mem_rd               = 1'b0;
      mem_wr               = 1'b0;
      inc_addr             = 1'b0;
      load_cpu_addr        = 1'b0;
      load_wrap_addr       = 1'b0;


      case (state)
        IDLE: begin
          if (cpu_rd | cpu_wr) begin
            if (cache_hit)
              if (cpu_wr) begin
                data_write_cpu  = 1'b1;
                tag_write       = 1'b1;
                new_tag.valid   = 1'b1;
                new_tag.dirty   = 1'b1;
              end
            else if (  tag_banks[bank_sel][cpu_line_addr].dirty
                     & tag_banks[bank_sel][cpu_line_addr].valid ) begin
              next_state      = WRITEBACK;
              mem_wr          = 1'b1;
              load_wrap_addr  = 1'b1;

              // In this case, we consumed some entropy, so generate new one
              lfsr_enable     = 1'b1;

              new_tag.valid   = 1'b0;
              new_tag.dirty   = 1'b1;
              tag_write       = 1'b1;
            end
            else begin
              mem_word_count_load  = 1'b1;
              mem_rd               = 1'b1;
              next_state           = ALLOCATE;
              data_write_mem       = 1'b1;
              load_cpu_addr        = 1'b1;
            end
        end

        ALLOCATE: begin
          if (mem_waitrequest)
            mem_rd        = 1'b1;

          data_write_mem  = 1'b1;

          // XXX: Disable early-valid - too problematic for now
//          if (rd_count*MEM_DATA_WIDTH >= DATA_WIDTH) begin
//            tag_write      = 1'b1;
//            new_tag.dirty  = 1'b0;
//            new_tag.valid  = 1'b1;
//          end
          if (rd_count == MEM_NWORDS) begin
            tag_write      = 1'b1;
            new_tag.dirty  = 1'b0;
            new_tag.valid  = 1'b1;

            next_state     = IDLE;
          end
        end

        WRITEBACK: begin
          inc_addr  = ~mem_waitrequest;

          if (wr_count == MEM_NWORDS) begin // XXX: NWORDS -1 ?
            mem_word_count_load  = 1'b1;
            mem_rd               = 1'b1;
            next_state           = ALLOCATE;
            data_write_mem       = 1'b1;
            load_cpu_addr        = 1'b1;
          else
            mem_wr  = 1'b1;
        end
      endcase
    end


  assign mem_burst_len = MEM_NWORDS - 1; /* since 0 means 1 */

  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n) begin
      mem_wr_r      <= 1'b0;
      mem_rd_r      <= 1'b0;
      mem_wr_data_r <= 'b0;
    end
    else begin
      mem_wr_r      <= mem_wr;
      mem_rd_r      <= mem_rd;
      mem_wr_data_r <= mem_wr_data;
    end



  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      mem_addr_r <= 'b0;
    else if (load_cpu_addr)
      mem_addr_r <= cpu_addr;
    else if (load_wrap_addr)
      mem_addr_r <= { cpu_addr[ADDR_WIDTH-1:MEM_ADDR_BITWIDTH], {MEM_ADDR_BITWIDTH{1'b0}} };
    else if (inc_addr)
      mem_addr_r  <= mem_addr_r + MEM_DATA_WIDTH_BYTES;


  // Either read or write
  assert property (~(cpu_wr & cpu_rd));

  // Either memory read or write
  assert property (~(mem_rd & mem_wr));

endmodule
