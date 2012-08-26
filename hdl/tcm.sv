module tcm #(
  parameter ADDR_WIDTH = 32,
            DATA_WIDTH = 32,
            MEM_DEPTH  = 16*1024*1024, /* 8M words -> 32 MB */
            MEM_FILE   = "",
            BE_WIDTH   = DATA_WIDTH/8,
            REL_WIDTH  = DATA_WIDTH/32,
            DATA_WIDTH_BYTES = DATA_WIDTH/8,
            PRIV_WIDTH = `clogb2(DATA_WIDTH_BYTES)
)(
  input                   clock,
  input                   reset_n,

  input [ADDR_WIDTH-1:0]  cpu_addr,
  input [DATA_WIDTH-1:0]  cpu_wr_data,
  input [BE_WIDTH-1:0]    cpu_wr_be,
  input                   cpu_rd,
  input                   cpu_wr,
  output [DATA_WIDTH-1:0] cpu_rd_data,
  output                  cpu_waitrequest
);

  reg [31:0]              staging[MEM_DEPTH];
  reg [DATA_WIDTH-1:0]    mem[MEM_DEPTH/REL_WIDTH];
  wire [ADDR_WIDTH-1:0]   mem_addr;
  wire [DATA_WIDTH-1:0]   be_expanded;

  assign mem_addr  = cpu_addr >> PRIV_WIDTH;


  genvar i;
  generate
    for (i = 0; i < BE_WIDTH; i = i+1) begin : EXP_BE
      assign be_expanded[DATA_WIDTH-1-i*8 -: 8]  = { 8{cpu_wr_be[BE_WIDTH-1-i]} };
    end
  endgenerate


  bit [DATA_WIDTH-1:0] w;
  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n) begin
      if (REL_WIDTH == 1)
        $readmemh(MEM_FILE, mem);
      else begin
        $readmemh(MEM_FILE, staging);
        for (integer i = 0; i < MEM_DEPTH/REL_WIDTH; i++) begin
          for (integer j = 0; j < REL_WIDTH; j++) begin
            w[DATA_WIDTH-1-j*32 -: 32] = staging[i*REL_WIDTH+j];
            mem[i] = w;
          end
        end
      end
    end
    else if (cpu_wr)
      mem[mem_addr] <=  (mem[mem_addr] & ~be_expanded)
                      | (cpu_wr_data   &  be_expanded);


  assign cpu_waitrequest = 1'b0;

  assign cpu_rd_data  = mem[mem_addr];

endmodule
