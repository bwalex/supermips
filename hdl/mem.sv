module mem #(
  parameter ADDR_WIDTH = 32,
            DATA_WIDTH = 32
)(
  input                   clock,
  input                   reset_n,

  output                  cache_rd,
  output                  cache_wr,
  output [ADDR_WIDTH-1:0] cache_addr,
  output [DATA_WIDTH-1:0] cache_wr_data,
  input [DATA_WIDTH-1:0]  cache_data,
  input                   cache_waitrequest,

  input                   load_inst,
  input                   store_inst,

  input [ 4:0]            dest_reg,
  input                   dest_reg_valid,

  input [31:0]            alu_result, // soon to be agu_result
  input [31:0]            result_2,
  input [31:0]            result_from_mem_wb,
  input [ 1:0]            B_fwd_from,

  output [31:0]           result,
  output                  stall
);

  wire [31:0]             word_st;
  wire [ 1:0]             word_idx;

  assign word_st  = (B_fwd_from == FWD_FROM_MEMWB_LATE) ? result_from_mem_wb : result_2;
  assign word_idx = alu_result[1:0];

  // XXX: need to handle stalls and bubble in.
  assign stall  = cache_waitrequest;

  // XXX: need to handle byte and half-word loads and stores
  assign result        = (load_inst) ? cache_data : alu_result;
  assign cache_addr    = alu_result >> 2;
  assign cache_wr      = store_inst;
  assign cache_rd      = load_inst;
  assign cache_wr_data = word_st;

endmodule // mem
