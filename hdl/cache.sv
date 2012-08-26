module generic_cache #(
  parameter            CLINE_WIDTH = 128,
                       ADDR_WIDTH = 32,
                       DATA_WIDTH = 32,
                       MEM_DATA_WIDTH = 32,
                       NLINES = 256,
                       NWORDS = CLINE_WIDTH/DATA_WIDTH,
                       MEM_NWORDS = CLINE_WIDTH/MEM_DATA_WIDTH,
                       MEM_D_NWORDS = (MEM_DATA_WIDTH >= DATA_WIDTH) ? 1 : DATA_WIDTH/MEM_DATA_WIDTH,
                       NWORDSLOG2 = `clogb2(NWORDS),
                       MEM_NWORDSLOG2        = (`clogb2(MEM_NWORDS) > 0) ? `clogb2(MEM_NWORDS) : 1,
                       MEM_ADDR_BITWIDTH     = `clogb2(MEM_DATA_WIDTH/8),
                       LFSR_SEED             = 11'd101,
                       ASSOC                 = 4,
                       CLINE_WIDTH_BYTES     = CLINE_WIDTH/8,
                       DATA_WIDTH_BYTES      = DATA_WIDTH/8,
                       MEM_DATA_WIDTH_BYTES  = MEM_DATA_WIDTH/8,
                       BE_WIDTH              = DATA_WIDTH_BYTES
)(
  input                           clock,
  input                           reset_n,

  input [ADDR_WIDTH-1:0]          cpu_addr,
  input                           cpu_rd,
  input                           cpu_wr,
  input [BE_WIDTH-1:0]            cpu_wr_be,
  input [DATA_WIDTH-1:0]          cpu_wr_data,
  output                          cpu_rd_valid,
  output [DATA_WIDTH-1:0]         cpu_rd_data,
  output                          cpu_waitrequest,

  output reg [ADDR_WIDTH-1:0]     mem_addr_r,
  output [MEM_NWORDSLOG2-1:0]     mem_burst_len,
  input [MEM_DATA_WIDTH-1:0]      mem_rd_data,
  input                           mem_rd_valid,
  input                           mem_waitrequest,
  output reg [MEM_DATA_WIDTH-1:0] mem_wr_data_r,
  output reg                      mem_wr_r,
  output reg                      mem_rd_r
);

  localparam LINE_ADDR_WIDTH  = `clogb2(NLINES);
  localparam CPU_BLOCK_IDX_WIDTH = `clogb2(CLINE_WIDTH) - `clogb2(DATA_WIDTH);
  localparam CPU_PRIV_WIDTH = `clogb2(DATA_WIDTH_BYTES);
  localparam LINE_WIDTH  = `clogb2(CLINE_WIDTH_BYTES);
  // [ TAG ( )  |   INDEX ( )      |    block_idx ( ) |

  localparam TAG_WIDTH  = ADDR_WIDTH - LINE_ADDR_WIDTH - CPU_BLOCK_IDX_WIDTH - CPU_PRIV_WIDTH;

  typedef enum {
    IDLE,
    WRITEBACK,
    ALLOCATE
  } cctl_state_t;

  typedef struct packed {
    bit                 valid;
    bit                 dirty;
    bit                 lfill;
    bit [TAG_WIDTH-1:0] tag;
  } tagmem_t;


  typedef struct packed {
    bit                       in_progress;
    bit [`clogb2(ASSOC)-1:0]   bank;
    bit [MEM_NWORDS-1:0]      valid;
    bit                       dirty;
    bit [TAG_WIDTH-1:0]       tag;
    bit [LINE_ADDR_WIDTH-1:0] index;

    bit [MEM_NWORDSLOG2-1:0]  mem_idx;

    bit [CLINE_WIDTH-1:0]     line;
  } lfbuf_t;


  reg [10:0]                  lfsr;
  reg                         lfsr_enable;
  wire [1:0]                  rand_bits;
  reg [CLINE_WIDTH-1:0]       cpu_rd_line;

  reg                         mem_word_count_load;

  wire [DATA_WIDTH-1:0]       be_expanded;

  // SystemVerilog's array indices are "the wrong way around" when multidimensional unpacked.
  // Unlike C, foo[a][b] is indexed as foo[a][b] not foo[b][a]...
  tagmem_t                    tag_banks[ASSOC][NLINES];
  reg [CLINE_WIDTH-1:0]       data_banks[ASSOC][NLINES];
  reg [`clogb2(ASSOC)-1:0]     bank_sel;

  reg                         tag_write;
  reg                         data_write_cpu;

  tagmem_t                    new_tag;

  reg [MEM_NWORDSLOG2:0]      wr_count;
  reg [MEM_NWORDSLOG2:0]      rd_count;

  wire [CLINE_WIDTH-1:0]      bank_cur_cline[ASSOC];

  wire [LINE_ADDR_WIDTH-1:0]  cpu_line_addr;
  wire [TAG_WIDTH-1:0]        cpu_addr_tag;
  wire [NWORDSLOG2-1:0]       cpu_block_idx;
  wire [MEM_NWORDSLOG2-1:0]   mem_block_idx;

  reg                         cache_evict;

  wire                        bank_line_valid[ASSOC];
  wire                        bank_line_dirty[ASSOC];
  wire                        bank_hit[ASSOC];

  reg                         cache_hit;

  cctl_state_t                state;
  cctl_state_t                next_state;

  reg                         mem_rd;
  reg                         mem_wr;
  reg [MEM_DATA_WIDTH-1:0]    mem_wr_data;
  reg                         inc_addr;
  reg                         load_cpu_addr;
  reg                         load_wb_wrap_addr;

  lfbuf_t                     linefillbuf;
  wire                        lfill_hit;
  wire                        lfill_all_valid;
  reg                         data_write_cpu_linefill;
  reg                         linefill_load_addr;
  wire                        linefill_inval;
  wire                        load_linefill;
  reg                         lfill_stall;

  reg                         cpu_waitrequest_d1;
  reg [63:0]                  stat_access;
  reg [63:0]                  stat_misses;
  reg [63:0]                  stat_allocs;
  reg [63:0]                  stat_wbacks;
  reg [63:0]                  stat_evicts;


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
    else if (~mem_waitrequest && mem_wr)
      wr_count <= wr_count + 1;


  assign cpu_line_addr = cpu_addr[ADDR_WIDTH-TAG_WIDTH-1 -: LINE_ADDR_WIDTH];
  assign cpu_addr_tag  = cpu_addr[ADDR_WIDTH-1 -: TAG_WIDTH];
  assign cpu_block_idx  = cpu_addr[ADDR_WIDTH-TAG_WIDTH-LINE_ADDR_WIDTH-1 -: NWORDSLOG2];

  localparam _W = (MEM_NWORDSLOG2-NWORDSLOG2 > 0) ? (MEM_NWORDSLOG2-NWORDSLOG2) : 0;
  assign mem_block_idx  = (MEM_NWORDS<=1) ? 'b0 :(MEM_NWORDSLOG2-NWORDSLOG2 > 0) ? { cpu_block_idx, {(_W){1'b0}} } : cpu_block_idx;


  genvar i;
  generate
    for (i = 0; i < ASSOC; i++) begin: BANKS
      assign bank_cur_cline[i]  =  data_banks[i][cpu_line_addr];
      assign bank_line_valid[i] =  tag_banks[i][cpu_line_addr].valid;
      assign bank_line_dirty[i] =  tag_banks[i][cpu_line_addr].dirty;
      assign bank_hit[i]        =  bank_line_valid[i]
                                & (~tag_banks[i][cpu_line_addr].lfill)
                                & (tag_banks[i][cpu_line_addr].tag == cpu_addr_tag);
    end

    for (i = 0; i < BE_WIDTH; i = i+1) begin : EXP_BE
      assign be_expanded[DATA_WIDTH-1-i*8 -: 8]  = { 8{cpu_wr_be[BE_WIDTH-1-i]} };
    end
  endgenerate

  always_comb begin
    cache_hit       = lfill_hit;
    for (integer i = 0; i < ASSOC; i++)
      cache_hit  = cache_hit | bank_hit[i];
  end


  assign cpu_waitrequest  = (cpu_rd | cpu_wr) & ~cache_hit;

  assign cpu_rd_valid  = cpu_rd & cache_hit;

  bit found;

  always_comb begin
    found                = 1'b0;
    cpu_rd_line          = bank_cur_cline[0];
    bank_sel             = 'b0;


    for (integer k = 0; k < ASSOC; k++)
      if (~tag_banks[k][cpu_line_addr].valid & ~tag_banks[k][cpu_line_addr].lfill) begin
        bank_sel  = k;
        found     = 1'b1;
        break;
      end

    // Make sure we evict a random line, not always the first one; we do so
    // by starting at a random index looking for a non-dirty line in the set.
    if (!found) begin
      for (bit [1:0] j = rand_bits+1; j != rand_bits; j++) begin
        if (~tag_banks[j][cpu_line_addr].dirty & ~tag_banks[j][cpu_line_addr].lfill) begin
          bank_sel  = j;
          found     = 1'b1;
          break;
        end
      end
    end

    // If all the lines in the set are dirty, just pick a line at random.
    if (!found)
      bank_sel  = rand_bits; // XXX: could optimize to never choose the line with lfill set

    // XXX: can use case(1'b1) instead in general, when not parameterized?
    for (integer k = 0; k < ASSOC; k++)
      if (bank_hit[k]) begin
        bank_sel     = k;
        cpu_rd_line  = bank_cur_cline[k];
        break;
      end
  end

  /* MUX right word from line or linefill buffer to output */
    assign cpu_rd_data  = (lfill_hit)
                         ? linefillbuf.line[CLINE_WIDTH -1
                                            - ((NWORDSLOG2 == 0) ? 0 : DATA_WIDTH*cpu_block_idx)
                                            -: DATA_WIDTH]
                         : cpu_rd_line[CLINE_WIDTH -1
                                       - ((NWORDSLOG2 == 0) ? 0 : DATA_WIDTH*cpu_block_idx)
                                       -: DATA_WIDTH];


  assign mem_wr_data  = data_banks[bank_sel][cpu_line_addr][CLINE_WIDTH -1
                                    - ((MEM_NWORDSLOG2 == 0) ? 0 : MEM_DATA_WIDTH*wr_count)
                                    -: MEM_DATA_WIDTH];

  // DATA memory writes
  always_ff @(posedge clock) begin
    if (data_write_cpu)
      data_banks[bank_sel][cpu_line_addr][CLINE_WIDTH -1
                                          - ((NWORDSLOG2 == 0) ? 0 : DATA_WIDTH*cpu_block_idx)
                                          -: DATA_WIDTH] <=  (cpu_rd_data  & ~be_expanded)
                                                           | (cpu_wr_data  &  be_expanded);
    if (load_linefill & cpu_wr & lfill_hit) begin
`ifdef CACHE_TRACE_ENABLE
      $fwrite(trace_file, "Loading linefill buffer (%x) into [%d:%d] with simultaneous write\n", linefillbuf.line, linefillbuf.bank, linefillbuf.index);
`endif
      for (integer i = 0; i < NWORDS; i++) begin
        data_banks[linefillbuf.bank][linefillbuf.index][CLINE_WIDTH-1-i*DATA_WIDTH
                                                        -: DATA_WIDTH] <= (cpu_block_idx == i)
          ?   (linefillbuf.line[CLINE_WIDTH-1-i*DATA_WIDTH -: DATA_WIDTH] & ~be_expanded)
            | (cpu_wr_data                                                &  be_expanded)
          :    linefillbuf.line[CLINE_WIDTH-1-i*DATA_WIDTH -: DATA_WIDTH];
      end
    end
    else if (load_linefill) begin
`ifdef CACHE_TRACE_ENABLE
      $fwrite(trace_file, "Loading linefill buffer (%x) into [%d:%d]\n", linefillbuf.line, linefillbuf.bank, linefillbuf.index);
`endif
      data_banks[linefillbuf.bank][linefillbuf.index] <= linefillbuf.line;
    end
  end



  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n) begin
      linefillbuf.valid       <= {MEM_NWORDS{1'b0}};
      linefillbuf.in_progress <= 1'b0;
    end
    else begin
      if (linefill_inval) begin
        linefillbuf.valid       <= {MEM_NWORDS{1'b0}};
        linefillbuf.dirty       <= 1'b0;
        linefillbuf.in_progress <= 1'b0;
      end

      if (linefill_load_addr) begin
        linefillbuf.valid       <= {MEM_NWORDS{1'b0}};
        linefillbuf.bank        <= bank_sel;
        linefillbuf.index       <= cpu_line_addr;
        linefillbuf.tag         <= cpu_addr_tag;
        linefillbuf.mem_idx     <= mem_block_idx;
        linefillbuf.dirty       <= 1'b0;
        linefillbuf.in_progress <= 1'b1;
      end

      if (mem_rd_valid) begin
        linefillbuf.line[CLINE_WIDTH -1
                         - ((MEM_NWORDSLOG2 == 0) ? 0 : MEM_DATA_WIDTH*linefillbuf.mem_idx)
                         -: MEM_DATA_WIDTH] <= mem_rd_data;

        if ((linefillbuf.mem_idx & (MEM_NWORDS - 1))  == (MEM_NWORDS - 1))
          linefillbuf.mem_idx <= 0;
        else
          linefillbuf.mem_idx <= linefillbuf.mem_idx + 1;

        linefillbuf.valid[linefillbuf.mem_idx] <= 1'b1;
      end // if (mem_rd_valid)

      if (data_write_cpu_linefill) begin
        linefillbuf.line[CLINE_WIDTH -1
                         - ((NWORDSLOG2 == 0) ? 0 : DATA_WIDTH*cpu_block_idx)
                         -: DATA_WIDTH] <=  (cpu_rd_data  & ~be_expanded)
                                          | (cpu_wr_data  &  be_expanded);

        linefillbuf.dirty <= 1'b1;
      end
    end // else: !if(~reset_n)


  assign lfill_all_valid  = (& linefillbuf.valid);
  assign linefill_inval   = lfill_all_valid;
  assign load_linefill    = lfill_all_valid;


  assign lfill_hit =   (&linefillbuf.valid[mem_block_idx +: MEM_D_NWORDS])
                    && (linefillbuf.tag   == cpu_addr_tag)
                    && (linefillbuf.index == cpu_line_addr);


  // TAG memory writes
  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      for (integer i = 0; i < ASSOC; i++)
        for (integer j = 0; j < NLINES; j++) begin
          tag_banks[i][j].valid  = 1'b0;
          tag_banks[i][j].dirty  = 1'b0;
        end
    else begin
      if (tag_write)
        tag_banks[bank_sel][cpu_line_addr] <= new_tag;

      if (load_linefill) begin
        tag_banks[linefillbuf.bank][linefillbuf.index].valid  = 1'b1;
        tag_banks[linefillbuf.bank][linefillbuf.index].dirty  =  (linefillbuf.dirty)
                                                               | (cpu_wr & lfill_hit);
        tag_banks[linefillbuf.bank][linefillbuf.index].lfill  = 1'b0;
      end
    end


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      state <= IDLE;
    else
      state <= next_state;


  always_comb
    begin
      next_state               = state;
      new_tag.tag              = tag_banks[bank_sel][cpu_line_addr].tag;
      new_tag.valid            = 1'b0;
      new_tag.dirty            = 1'b0;
      new_tag.lfill            = 1'b0;
      tag_write                = 1'b0;
      data_write_cpu           = 1'b0;
      data_write_cpu_linefill  = 1'b0;
      lfsr_enable              = 1'b0;
      mem_word_count_load      = 1'b0;
      mem_rd                   = 1'b0;
      mem_wr                   = 1'b0;
      inc_addr                 = 1'b0;
      load_cpu_addr            = 1'b0;
      load_wb_wrap_addr        = 1'b0;
      cache_evict              = 1'b0;
      linefill_load_addr       = 1'b0;
      lfill_stall              = 1'b0;


      case (state)
        IDLE: begin
          if (cpu_rd || cpu_wr) begin
            if (cache_hit) begin
              if (cpu_wr) begin
                data_write_cpu           = ~lfill_hit;
                data_write_cpu_linefill  =  lfill_hit;

                tag_write                = ~lfill_hit;
                new_tag.valid            = 1'b1;
                new_tag.dirty            = 1'b1;
              end
            end
            else begin
              if (  tag_banks[bank_sel][cpu_line_addr].dirty
                    & tag_banks[bank_sel][cpu_line_addr].valid ) begin
                lfill_stall  = linefillbuf.in_progress;

                if (~lfill_stall) begin
                  next_state         = WRITEBACK;
                  //mem_word_count_load  = 1'b1;
                  mem_wr             = 1'b1;
                  load_wb_wrap_addr  = 1'b1;

                  new_tag.valid      = 1'b0;
                  new_tag.dirty      = 1'b1;
                  tag_write          = 1'b1;

                  cache_evict        = 1'b1;
                end // if (~lfill_stall)
              end // if (  tag_banks[bank_sel][cpu_line_addr].dirty...
              else begin
                lfill_stall  = linefillbuf.in_progress;

                // Make sure only one linefill is in progress at any one time.
                if (~lfill_stall) begin
                  mem_word_count_load  = 1'b1;
                  mem_rd               = 1'b1;
                  linefill_load_addr   = 1'b1;
                  load_cpu_addr        = 1'b1;

                  new_tag.tag          = cpu_addr_tag;
                  new_tag.valid        = 1'b1; // XXX: ??
                  new_tag.lfill        = 1'b1;
                  tag_write            = 1'b1;

                  lfsr_enable          = 1'b1;
                  cache_evict          = tag_banks[bank_sel][cpu_line_addr].valid;
                end // if (~lfill_stall)
              end // else: !if(  tag_banks[bank_sel][cpu_line_addr].dirty...
            end // else: !if(cache_hit)
          end // if (cpu_rd || cpu_wr)
        end // case: IDLE


        WRITEBACK: begin
          inc_addr  = ~mem_waitrequest;

          if (wr_count == MEM_NWORDS) begin
            mem_word_count_load  = 1'b1;
            mem_rd               = 1'b1;
            linefill_load_addr   = 1'b1;
            load_cpu_addr        = 1'b1;

            new_tag.tag          = cpu_addr_tag;
            new_tag.valid        = 1'b1; // XXX: ??
            new_tag.lfill        = 1'b1;
            tag_write            = 1'b1;

            next_state           = IDLE;
          end
          else
            mem_wr  = 1'b1;
        end // case: WRITEBACK
      endcase // case (state)
    end // always_comb


  assign mem_burst_len = MEM_NWORDS - 1; /* since 0 means 1 */

  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n) begin
      mem_wr_r      <= 1'b0;
      mem_rd_r      <= 1'b0;
      mem_wr_data_r <= 'b0;
    end
    else begin
      mem_wr_r      <= mem_wr;
      mem_wr_data_r <= mem_wr_data;

      if (mem_rd_r & mem_waitrequest)
        mem_rd_r    <= mem_rd_r;
      else
        mem_rd_r    <= mem_rd;
    end



  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      mem_addr_r <= 'b0;
    else if (load_cpu_addr)
      mem_addr_r <= { cpu_addr[31:CPU_PRIV_WIDTH], {CPU_PRIV_WIDTH{1'b0}} };
    else if (load_wb_wrap_addr)
      mem_addr_r <= { tag_banks[bank_sel][cpu_line_addr].tag, cpu_line_addr, {LINE_WIDTH{1'b0}} };
    else if (inc_addr)
      mem_addr_r  <= mem_addr_r + MEM_DATA_WIDTH_BYTES;



  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      cpu_waitrequest_d1 <= 1'b0;
    else
      cpu_waitrequest_d1 <= cpu_waitrequest;

`define _FIRST_CYCLE (~cpu_waitrequest_d1)
  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n) begin
      stat_access <= 'b0;
      stat_misses <= 'b0;
      stat_allocs <= 'b0;
      stat_wbacks <= 'b0;
      stat_evicts <= 'b0;
    end
    else begin
      if (linefill_load_addr)
        stat_allocs <= stat_allocs + 1;
      if (state != WRITEBACK && next_state == WRITEBACK)
        stat_wbacks <= stat_wbacks + 1;
      if (`_FIRST_CYCLE && state == IDLE && !cache_hit && (cpu_rd || cpu_wr))
        stat_misses <= stat_misses + 1;
      if (`_FIRST_CYCLE && state == IDLE && (cpu_rd || cpu_wr))
        stat_access <= stat_access + 1;
      if (cache_evict)
        stat_evicts <= stat_evicts + 1;
    end // else: !if(~reset_n)
`undef _FIRST_CYCLE

`ifdef CACHE_TRACE_ENABLE
  integer trace_file;

  initial begin
    trace_file = $fopen("cache.trace", "w");
  end

  always_ff @(posedge clock)
    begin
      if (cache_evict)
        $fwrite(trace_file, "%d %m evict:     [%d:%x,tag: %x] (%s) for %x\n", $time, bank_sel, cpu_line_addr, tag_banks[bank_sel][cpu_line_addr].tag, (tag_banks[bank_sel][cpu_line_addr].dirty ? "dirty" : "clean"), cpu_addr);

      if (linefill_load_addr)
        $fwrite(trace_file, "%d %m allocate:  [%d:%x,tag: %x]         for %x\n", $time, bank_sel, cpu_line_addr, cpu_addr_tag, cpu_addr);

      if (state != WRITEBACK && next_state == WRITEBACK)
        $fwrite(trace_file, "%d %m writeback: [%d:%x,tag: %x]         for %x\n", $time, bank_sel, cpu_line_addr, tag_banks[bank_sel][cpu_line_addr].tag, cpu_addr);
    end
`endif

endmodule
