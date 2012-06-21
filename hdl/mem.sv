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

  wire [31:0]               word_st;
  wire [ 1:0]               word_idx;
  reg [31:0]                word_from_cache;
  reg [31:0]                word_to_cache;


  assign word_st  = (B_fwd_from == FWD_FROM_MEMWB_LATE) ? result_from_mem_wb : result_2;
  assign word_idx = alu_result[1:0];

  // XXX: need to handle stalls and bubble in.
  assign stall  = cache_waitrequest;

  assign result        = (load_inst) ? word_from_cache : alu_result;
  assign cache_addr    = alu_result >> 2;
  assign cache_wr      = store_inst;
  assign cache_rd      = load_inst;
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
    cache_wr_be    = 'b0;

    if (ls_op == OP_LS_BYTE) begin
      word_to_cache[31-(word_idx << 3) -: 8]  = word_st[7:0];
      cache_wr_be[3-word_idx]                 = 1'b1;
    end
    else if (ls_op == OP_LS_HALFWORD) begin
      word_to_cache[31-(word_idx << 3) -: 8]  = word_st[15:0];
      cache_wr_be[3-word_idx -: 1]            = 2'b11;
    end
  end
endmodule // mem
