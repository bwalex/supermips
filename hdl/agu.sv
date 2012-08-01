import pipTypes::*;

module agu
(
 input clock,
 input reset_n,

  input [31:0]             A_val,

  input [31:0]             imm,
  input                    imm_valid,

  output [31:0]            agu_address
);

  assign agu_address  = A_val + imm;

endmodule
