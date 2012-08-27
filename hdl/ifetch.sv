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

  output reg [31:0]       inst_word0_r,
  output reg [31:0]       inst_word1_r,
  output reg [31:0]       inst_word2_r,
  output reg [31:0]       inst_word3_r,

  output reg              inst_word0_valid_r,
  output reg              inst_word1_valid_r,
  output reg              inst_word2_valid_r,
  output reg              inst_word3_valid_r,

  output reg              inst_stream_r,

  input                   stall,
  input                   load_pc,
  input [31:0]            new_pc,

  output reg [31:0]       pc_out0_r,
  output reg [31:0]       pc_out1_r,
  output reg [31:0]       pc_out2_r,
  output reg [31:0]       pc_out3_r,

  output                  branch_stall
);

  reg [3:0]               align_off;
  wire                    stall_i;
  wire [1:0]              line_idx;
  wire                    aligned;
  reg [31:0]              pc;
  reg                     cache_waitrequest_d1;

  wire [31:0]             inst_word0;
  wire [31:0]             inst_word1;
  wire [31:0]             inst_word2;
  wire [31:0]             inst_word3;

  wire                    inst_word0_valid;
  wire                    inst_word1_valid;
  wire                    inst_word2_valid;
  wire                    inst_word3_valid;

  reg                     inst_stream;

  wire [31:0]             pc_out0;
  wire [31:0]             pc_out1;
  wire [31:0]             pc_out2;
  wire [31:0]             pc_out3;




  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n) begin
      inst_word0_r       <= 32'b0;
      inst_word1_r       <= 32'b0;
      inst_word2_r       <= 32'b0;
      inst_word3_r       <= 32'b0;

      inst_word0_valid_r <= 1'b0;
      inst_word1_valid_r <= 1'b0;
      inst_word2_valid_r <= 1'b0;
      inst_word3_valid_r <= 1'b0;

      inst_stream_r       <= 1'b0;

      pc_out0_r          <= 32'b0;
      pc_out1_r          <= 32'b0;
      pc_out2_r          <= 32'b0;
      pc_out3_r          <= 32'b0;
    end
    else if (~stall) begin
      inst_word0_r       <= inst_word0;
      inst_word1_r       <= inst_word1;
      inst_word2_r       <= inst_word2;
      inst_word3_r       <= inst_word3;

      inst_word0_valid_r <= inst_word0_valid;
      inst_word1_valid_r <= inst_word1_valid;
      inst_word2_valid_r <= inst_word2_valid;
      inst_word3_valid_r <= inst_word3_valid;

      inst_stream_r       <= inst_stream;

      pc_out0_r          <= pc_out0;
      pc_out1_r          <= pc_out1;
      pc_out2_r          <= pc_out2;
      pc_out3_r          <= pc_out3;
    end


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      inst_stream <= 1'b0;
    else if (load_pc & ~branch_stall)
      inst_stream <= ~inst_stream;


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      cache_waitrequest_d1 <= 1'b0;
    else
      cache_waitrequest_d1 <= cache_waitrequest;


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      pc <= 'b0;
    else if (load_pc & ~branch_stall)
      pc <= new_pc;
    else if (~stall_i) begin
      pc <= pc + align_off + 1;
    end


  assign line_idx = pc[3:2];
  assign aligned  = (~|line_idx);


  always_comb
    case (line_idx)
      2'd01:   align_off  = 4'd11;
      2'd02:   align_off  = 4'd07;
      2'd03:   align_off  = 4'd03;
      default: align_off  = 4'd15;
    endcase


  assign inst_word0_valid  = (!stall_i) && (line_idx == 2'b00);
  assign inst_word1_valid  = (!stall_i) && (line_idx == 2'b01 || inst_word0_valid);
  assign inst_word2_valid  = (!stall_i) && (line_idx == 2'b10 || inst_word1_valid);
  assign inst_word3_valid  = (!stall_i) && (line_idx == 2'b11 || inst_word2_valid);


  assign branch_stall  = cache_waitrequest & load_pc;

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
