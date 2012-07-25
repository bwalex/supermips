module ifetch #(
  parameter ADDR_WIDTH = 32,
            DATA_WIDTH = 32
)(
  input                   clock,
  input                   reset_n,

  output [ADDR_WIDTH-1:0] cache_addr,
  output                  cache_rd,
  input [DATA_WIDTH-1:0]  cache_data,
  input                   cache_waitrequest,

  output [31:0]           inst_word,

  input                   stall,
  input                   load_pc,
  input [DATA_WIDTH-1:0]  new_pc,

  output [DATA_WIDTH-1:0] pc_out,

  output                  branch_stall
);

  wire                    stall_i;
  reg [DATA_WIDTH-1:0]    pc;
  reg                     cache_waitrequest_d1;


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      cache_waitrequest_d1 <= 1'b0;
    else
      cache_waitrequest_d1 <= cache_waitrequest;


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      pc <= 'b0;
    else if (load_pc & ~stall_i)
      pc <= new_pc;
    else if (~stall_i)
      pc <= pc + 4;


  assign branch_stall  = cache_waitrequest;

  // XXX: need to deal with pipeline and cache stalls
  assign stall_i    = stall | cache_waitrequest;

  assign cache_rd   = 1'b1;
  assign cache_addr = pc;

  assign inst_word  = ((load_pc & ~cache_waitrequest_d1) | cache_waitrequest) ? 32'b0 : cache_data;
  assign pc_out     = pc;
endmodule
