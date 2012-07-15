import pipTypes::*;

module mem #(
  parameter ADDR_WIDTH = 32,
            DATA_WIDTH = 32,
            BE_WIDTH   = DATA_WIDTH/8
)(
  input                     clock,
  input                     reset_n,

  output                    cache_rd,
  output                    cache_wr,
  output [ADDR_WIDTH-1:0]   cache_addr,
  output [DATA_WIDTH-1:0]   cache_wr_data,
  output reg [BE_WIDTH-1:0] cache_wr_be,
  input [DATA_WIDTH-1:0]    cache_data,
  input                     cache_waitrequest,

  input                     load_inst,
  input                     store_inst,

  input ls_op_t             ls_op,
  input                     ls_sext,

  input [ 4:0]              dest_reg,
  input                     dest_reg_valid,

  input [31:0]              alu_result, // soon to be agu_result
  input [31:0]              result_2,
  input [31:0]              result_from_mem_wb,
  input fwd_t               B_fwd_from,

  output [31:0]             result,
  output                    stall
);

  wire                      trickbox_taken;
  wire [31:0]               trickbox_out;


  wire [31:0]               word_st;
  wire [ 1:0]               word_idx;
  reg [31:0]                word_from_cache;
  reg [31:0]                word_to_cache;
  reg [31:0]                result_from_mem_wb_retained;
  reg                       stall_d1;


  trickbox#(
            .ADDR_WIDTH(ADDR_WIDTH)
  ) trickbox (
              .clock(clock),
              .reset_n(reset_n),
              .addr(alu_result),
              .read(load_inst),
              .write(store_inst),
              .data_in(word_st),
              .data_out(trickbox_out),
              .taken(trickbox_taken)
              );



  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      stall_d1 <= 1'b0;
    else
      stall_d1 <= stall;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      result_from_mem_wb_retained <= 32'b0;
    else if (stall & ~stall_d1)
      result_from_mem_wb_retained <= result_from_mem_wb;


  assign word_st  = (B_fwd_from == FWD_FROM_MEMWB_LATE) ? (stall_d1) ? result_from_mem_wb_retained : result_from_mem_wb : result_2;
  assign word_idx = alu_result[1:0];

  assign stall  = cache_waitrequest;

  assign result        = (load_inst) ? (trickbox_taken) ? trickbox_out : word_from_cache : alu_result;
  assign cache_addr    = alu_result;
  assign cache_wr      = ~trickbox_taken & store_inst;
  assign cache_rd      = ~trickbox_taken & load_inst;
  assign cache_wr_data = word_to_cache;


  always_comb begin
    word_from_cache  = cache_data;
    if (ls_op == OP_LS_BYTE) begin
      word_from_cache[ 7: 0] = cache_data[31-(word_idx << 3) -: 8];
      word_from_cache[31: 8] = (ls_sext) ? {24{word_from_cache[7]}} : 24'b0;
    end
    else if (ls_op == OP_LS_HALFWORD) begin
      word_from_cache[15: 0] = cache_data[31-(word_idx << 3) -: 16];
      word_from_cache[31:16] = (ls_sext) ? {16{word_from_cache[15]}} : 16'b0;
    end
  end // always_comb

  always_comb begin
    word_to_cache  = word_st;
    cache_wr_be    = 4'b1111;

    if (ls_op == OP_LS_BYTE) begin
      word_to_cache[31-(word_idx << 3) -: 8]  = word_st[7:0];
      cache_wr_be                             = 4'b0000;
      cache_wr_be[3-word_idx]                 = 1'b1;
    end
    else if (ls_op == OP_LS_HALFWORD) begin
      word_to_cache[31-(word_idx << 3) -: 8]  = word_st[15:0];
      cache_wr_be                             = 4'b0000;
      cache_wr_be[3-word_idx -: 2]            = 2'b11;
    end
  end
endmodule // mem
