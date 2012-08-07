module ISS
(
  input        clock,
  input        reset_n,

 // IQ interface
  output       ext_enable,
  output [1:0] ext_consumed,
  input        ext_valid[4],
  input        iq_entry_t insns[4],
  input        empty,


 // ROB forwarding interface
  output [3:0] A_rob_idx[4],
  output [3:0] B_rob_idx[4],
  output [3:0] C_rob_idx[4],
  input        A_val_valid,
  input        B_val_valid,
  input        C_val_valid,
  input [31:0] A_val,
  input [31:0] B_val,
  input [31:0] C_val,

 
);


endmodule