module wb #(
)(
  input         clock,
  input         reset_n,

  input [31:0]  result,
  input [ 4:0]  dest_reg,
  input         dest_reg_valid,

  output [ 4:0] rfile_wr_addr1,
  output        rfile_wr_enable1,
  output [31:0] rfile_wr_data1
);

  assign rfile_wr_enable1 = dest_reg_valid;
  assign rfile_wr_addr1   = dest_reg;
  assign rfile_wr_data1   = result;
endmodule