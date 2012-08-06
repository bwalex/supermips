module wb #(
)(
  input         clock,
  input         reset_n,

  output        consume,
  output [ 1:0] consume_count,
  input         rob_entry_t slot_data[4],
  input         slot_valid[4],
  input         empty,

  output [ 4:0] rfile_wr_addr[4],
  output        rfile_wr_enable[4],
  output [31:0] rfile_wr_data[4]
);


  genvar        i;
  generate
    for (i = 0; i < 4; i++) begin
      assign rfile_wr_addr[i]    = slot_data[i].dest_reg;
      assign rfile_wr_enable[i]  = slot_data[i].dest_reg_valid & slot_valid[i];
      assign rfile_wr_data[i]    = slot_data[i].result_lo;
    end
  endgenerate

  assign consume        = 1'b1;
  assign consume_count  =   (slot_valid[0] & slot_valid[1] & slot_valid[2] & slot_valid[3]) ? 2'd3
                          : (slot_valid[0] & slot_valid[1] & slot_valid[2])                 ? 2'd2
                          : (slot_valid[0] & slot_valid[1])                                 ? 2'd1
                          : (slot_valid[0])                                                 ? 2'd0
                          ;
endmodule
