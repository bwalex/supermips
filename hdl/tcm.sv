module tcm #(
  parameter ADDR_WIDTH = 32,
            DATA_WIDTH = 32,
            MEM_DEPTH  = 65536,
            MEM_FILE   = "",
            BE_WIDTH   = DATA_WIDTH/8
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

  reg [DATA_WIDTH-1:0]    mem[MEM_DEPTH];
  wire [ADDR_WIDTH-1:0]   mem_addr;
  wire [DATA_WIDTH-1:0]   be_expanded;

  assign mem_addr  = cpu_addr >> 2;


  genvar i;
  generate
    for (i = 0; i < BE_WIDTH; i = i+1) begin : EXP_BE
      assign be_expanded[DATA_WIDTH-1-i*8 -: 8]  = { 8{cpu_wr_be[BE_WIDTH-1-i]} };
    end
  endgenerate


  assign be_expanded = { {8{cpu_wr_be[3]} }


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      $readmemh(MEM_FILE, mem);
    else if (cpu_wr)
      mem[mem_addr] <=  (mem[mem_addr] & ~be_expanded)
                      | (cpu_wr_data   &  be_expanded);


  assign cpu_waitrequest = 1'b0;

  assign cpu_rd_data  = mem[mem_addr];

  assert property (@(posedge clock) ~(cpu_rd & cpu_wr));

endmodule