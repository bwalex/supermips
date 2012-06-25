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

  output [DATA_WIDTH-1:0] pc_out
);

  reg [DATA_WIDTH-1:0]    pc;


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      pc <= 'b0;
    else if (~stall && load_pc)
      pc <= new_pc;
    else if (~stall)
      pc <= pc + 4;


  // XXX: need to deal with pipeline and cache stalls

  assign cache_rd   = 1'b1;
  assign cache_addr = pc;

  assign inst_word  = cache_data;
  assign pc_out     = pc;
endmodule
