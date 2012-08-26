module memory #(
                parameter ADDR_WIDTH = 32,
                          DATA_WIDTH = 32,
                          BURSTLEN_WIDTH = 2,
                          MEM_FILE = "",
                          DEPTH = 16*1024*1024, // 16Mwords
                          REL_WIDTH  = DATA_WIDTH/32,
                          DATA_WIDTH_BYTES = DATA_WIDTH/8,
                          PRIV_WIDTH = `clogb2(DATA_WIDTH_BYTES)
)(
  input                       clock,
  input                       reset_n,

  input [ADDR_WIDTH-1:0]      addr,
  input [BURSTLEN_WIDTH-1:0]  burst_len,
  output reg [DATA_WIDTH-1:0] data_out,
  input [DATA_WIDTH-1:0]      data_in,
  input                       wr,
  input                       rd,
  output                      waitrequest,
  output reg                  rd_valid
);

  typedef enum               { IDLE, BURST_READ } state_t;


  reg [BURSTLEN_WIDTH-1:0]   burst_count_r;

  reg [31:0]                 staging[DEPTH];
  reg [DATA_WIDTH-1:0]       mem[DEPTH/REL_WIDTH];

  wire [ADDR_WIDTH-1:0]      addr_int;
  reg [ADDR_WIDTH-1:0]       burst_addr;

  reg                        load_burst_count;
  reg                        dec_burst_count;


  state_t                    next_state;
  state_t                    state;


  assign waitrequest  = 1'b0;

  assign addr_int  = addr >> PRIV_WIDTH;

  bit [DATA_WIDTH-1:0]       w;
  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n) begin
      if (REL_WIDTH == 1)
        $readmemh(MEM_FILE, mem);
      else begin
        $readmemh(MEM_FILE, staging);
        for (integer i = 0; i < DEPTH/REL_WIDTH; i++) begin
          for (integer j = 0; j < REL_WIDTH; j++) begin
            w[DATA_WIDTH-1-j*32 -: 32] = staging[i*REL_WIDTH+j];
            mem[i] = w;
          end
        end
      end
    end
    else if (wr) begin
      //$display("mem write: %x (%x) => %x", addr, addr_int, data_in);
      mem[addr_int] <= data_in;
    end



  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n) begin
      burst_count_r <= 'b0;
      burst_addr    <= 'b0;
    end
    else if (load_burst_count) begin
      burst_count_r <= burst_len;
      burst_addr    <= addr_int;
    end
    else if (dec_burst_count && burst_count_r > 0) begin
      burst_count_r <= burst_count_r - 1;

      // wrap burst logic; we always assume wrap bursts
      if ((burst_addr & burst_len)  == burst_len)
        burst_addr <= burst_addr & ~burst_len;
      else
        burst_addr <= burst_addr + 1;
    end


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n) begin
      rd_valid <= 1'b0;
      data_out <= 'b0;
    end
    else begin
      rd_valid <= dec_burst_count;
      //if (dec_burst_count)
        //$display("mem read: %x (%x) => %x", burst_addr << 2, burst_addr, mem[burst_addr]);

      data_out <= mem[burst_addr];
    end


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      state <= IDLE;
    else
      state <= next_state;


  always_comb
    begin
      next_state        = state;
      load_burst_count  = 1'b0;
      dec_burst_count   = 1'b0;


      case (state)
        IDLE: begin
          load_burst_count     = 1'b1;
          if (rd)
            next_state  = BURST_READ;
        end

        BURST_READ: begin
          dec_burst_count  = 1'b1;
          if (burst_count_r == 0)
            next_state  = IDLE;
        end
      endcase
    end


endmodule
