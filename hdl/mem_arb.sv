module mem_arb #(
                 parameter ADDR_WIDTH = 32,
                 DATA_WIDTH = 32,
                 BURSTLEN_WIDTH = 2

)(
  input                       clock,
  input                       reset_n,

  input [ADDR_WIDTH-1:0]      c1_addr,
  input [BURSTLEN_WIDTH-1:0]  c1_burst_len,
  output [DATA_WIDTH-1:0]     c1_data_out,
  input [DATA_WIDTH-1:0]      c1_data_in,
  input                       c1_wr,
  input                       c1_rd,
  output                      c1_waitrequest,
  output                      c1_rd_valid,

  input [ADDR_WIDTH-1:0]      c2_addr,
  input [BURSTLEN_WIDTH-1:0]  c2_burst_len,
  output [DATA_WIDTH-1:0]     c2_data_out,
  input [DATA_WIDTH-1:0]      c2_data_in,
  input                       c2_wr,
  input                       c2_rd,
  output                      c2_waitrequest,
  output                      c2_rd_valid,

  output [ADDR_WIDTH-1:0]     mm_addr,
  output [BURSTLEN_WIDTH-1:0] mm_burst_len,
  input [DATA_WIDTH-1:0]      mm_data_in,
  output [DATA_WIDTH-1:0]     mm_data_out,
  output                      mm_wr,
  output                      mm_rd,
  input                       mm_waitrequest,
  input                       mm_rd_valid
);

  reg                         sel;
  reg                         next_sel;

  reg [BURSTLEN_WIDTH-1:0]    rd_count;

  wire                        burst_len_int;
  wire                        rd_int;


  reg                        load_count;
  wire                       dec_count;

  typedef enum               { IDLE, RD_BURST } state_t;
  state_t state;
  state_t next_state;

  assign c1_data_out  = mm_data_in;
  assign c2_data_out  = mm_data_in;

  assign mm_addr       = (sel == 1'b0) ? c1_addr      : c2_addr;
  assign burst_len_int = (sel == 1'b0) ? c1_burst_len : c2_burst_len;
  assign mm_data_out   = (sel == 1'b0) ? c1_data_in   : c2_data_in;
  assign mm_wr         = (sel == 1'b0) ? c1_wr        : c2_wr;
  assign rd_int        = (sel == 1'b0) ? c1_rd        : c2_rd;

  assign mm_burst_len  = burst_len_int;
  assign mm_rd         = rd_int;

  assign c1_waitrequest  = (sel == 1'b1);
  assign c2_waitrequest  = (sel == 1'b0);

  assign c1_rd_valid  = (sel == 1'b0) ? mm_rd_valid : 1'b0;
  assign c2_rd_valid  = (sel == 1'b1) ? mm_rd_valid : 1'b0;

  assign dec_count  = (state == BURST_READ) && mm_rd_valid;



  reg [14:0]                  lfsr_r;
  wire                        rand_bit;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      lfsr_r <= LFSR_SEED;
    else begin
      lfsr_r[0] <= lfsr_r[1];
      lfsr_r[1] <= lfsr_r[2];
      lfsr_r[2] <= lfsr_r[3];
      lfsr_r[3] <= lfsr_r[4];
      lfsr_r[4] <= lfsr_r[5];
      lfsr_r[5] <= lfsr_r[6];
      lfsr_r[6] <= lfsr_r[7];
      lfsr_r[7] <= lfsr_r[8];
      lfsr_r[8] <= lfsr_r[9];
      lfsr_r[9] <= lfsr_r[10];
      lfsr_r[10] <= lfsr_r[11];
      lfsr_r[11] <= lfsr_r[12];
      lfsr_r[12] <= lfsr_r[13];
      lfsr_r[13] <= lfsr_r[14];
      lfsr_r[14] <= lfsr_r[0] ^ lfsr_r[1];
    end

  assign rand_bit  = lfsr_r[0];



  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      rd_count <= 'b0;
    else if (load_count)
      rd_count <= burst_len_int;
    else if (dec_count)
      rd_count <= rd_count - 1;


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      sel <= 1'b0;
    else
      sel <= next_sel;


  always_comb
    begin
      next_sel   = sel;
      if (next_state == IDLE)
        next_sel = rand_bit;
    end


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      state <= IDLE;
    else
      state <= next_state;


  always_comb
    begin
      next_state  = state;
      load_count  = 1'b0;

      case (state)
        IDLE: begin
          load_count  = 1'b1;
          if (rd_int == 1'b1 && burst_len_int != 0)
            next_state  = BURST_READ;
        end

        BURST_READ: begin
          if (rd_count == 0)
            next_state  = IDLE;
        end
      endcase
    end


endmodule
