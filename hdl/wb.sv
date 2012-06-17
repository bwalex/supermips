module wb #(
)(
  input         clock,
  input         reset_n,

  input [31:0]  result,
  input [ 4:0]  dest_reg,
  input         dest_reg_valid,

  output [ 4:0] cache_wr_addr1,
  output        cache_wr_enable1,
  output [31:0] cache_wr_data1
);

  assign cache_wr_enable1 = dest_reg_valid;
  assign cache_wr_addr1   = dest_reg;
  assign cache_wr_data1   = result;
endmodule