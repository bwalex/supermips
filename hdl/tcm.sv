module tcm #(
  parameter ADDR_WIDTH = 32,
            DATA_WIDTH = 32,
            MEM_DEPTH  = 65536,
            MEM_FILE   = "",
            BE_WIDTH   = 5//$clog2(DATA_WIDTH) // XXX: ncverilog doesn't support $clog2()
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

  assign mem_addr  = cpu_addr[ADDR_WIDTH-1:BE_WIDTH];


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      $readmemh(MEM_FILE, mem);
    else if (cpu_wr)
      mem[mem_addr] <=  (mem[mem_addr] & ~cpu_wr_be)
                      | (cpu_wr_data   &  cpu_wr_be);


  assign cpu_waitrequest = 1'b0;

  assign cpu_rd_data  = mem[mem_addr];

  assert property (@(posedge clock) ~(cpu_rd & cpu_wr));

endmodule