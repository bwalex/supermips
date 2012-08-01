module ifetch #(
  parameter ADDR_WIDTH = 32,
            DATA_WIDTH = 128
)(
  input                   clock,
  input                   reset_n,

  output [ADDR_WIDTH-1:0] cache_addr,
  output                  cache_rd,
  input [DATA_WIDTH-1:0]  cache_data,
  input                   cache_waitrequest,

  output [31:0]           inst_word0,
  output [31:0]           inst_word1,
  output [31:0]           inst_word2,
  output [31:0]           inst_word3,

  output                  inst_word0_valid,
  output                  inst_word1_valid,
  output                  inst_word2_valid,
  output                  inst_word3_valid,

  input                   stall,
  input                   load_pc,
  input [31:0]            new_pc,

  output [31:0]           pc_out0,
  output [31:0]           pc_out1,
  output [31:0]           pc_out2,
  output [31:0]           pc_out3,

  output                  branch_stall
);

  wire [3:0]              align_off;
  wire                    stall_i;
  wire [1:0]              line_idx;
  wire                    aligned;
  reg [31:0]              pc;
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
    else if (~stall_i) begin
      pc <= pc + align_off;
    end


  assign line_idx = pc[3:2];
  assign aligned  = (~|line_idx);


  always_comb
    case (line_idx)
      2'b01:   align_off  = 4'd12;
      2'b02:   align_off  = 4'd08;
      2'b03:   align_off  = 4'd04;
      default: align_off  = 4'd16;
    endcase


  assign inst_word0_valid  = (!cache_waitrequest) && (line_idx == 2'b00);
  assign inst_word1_valid  = (!cache_waitrequest) && (line_idx == 2'b01 || inst_word0_valid);
  assign inst_word2_valid  = (!cache_waitrequest) && (line_idx == 2'b10 || inst_word1_valid);
  assign inst_word3_valid  = (!cache_waitrequest) && (line_idx == 2'b11 || inst_word2_valid);


  assign branch_stall  = cache_waitrequest;

  assign stall_i     = stall | cache_waitrequest;

  assign cache_rd    = 1'b1;
  assign cache_addr  = pc;

  assign inst_word0  = (cache_waitrequest) ? 32'b0 : cache_data[127 -: 32];
  assign inst_word1  = (cache_waitrequest) ? 32'b0 : cache_data[ 95 -: 32];
  assign inst_word2  = (cache_waitrequest) ? 32'b0 : cache_data[ 63 -: 32];
  assign inst_word3  = (cache_waitrequest) ? 32'b0 : cache_data[ 31 -: 32];

  assign pc_out0     = { pc[31:4], 2'b00, 2'b00 };
  assign pc_out1     = { pc[31:4], 2'b01, 2'b00 };
  assign pc_out2     = { pc[31:4], 2'b10, 2'b00 };
  assign pc_out3     = { pc[31:4], 2'b11, 2'b00 };

endmodule
