import pipTypes::*;

module ls_wrapper #(
                    parameter ROB_DEPTHLOG2 = 4
)(
  input                      clock,
  input                      reset_n,

  input                      dec_inst_t inst,
  input                      inst_valid,
  input [31:0]               A,
  input [31:0]               B,
  input [ROB_DEPTHLOG2-1:0]  rob_slot,

  output                     ready,

  output                     rob_data_valid,
  output [ROB_DEPTHLOG2-1:0] rob_data_idx,
  output                     rob_entry_t rob_data,

  input                      fwd_info_t fwd_info,
  output [ROB_DEPTHLOG2-1:0] A_lookup_idx,
  output [ROB_DEPTHLOG2-1:0] B_lookup_idx,
  input [31:0]               A_fwd,
  input [31:0]               B_fwd,

  output                     cache_rd,
  output                     cache_wr,
  output [31:0]              cache_addr,
  output [31:0]              cache_wr_data,
  output [ 3:0]              cache_wr_be,
  input [31:0]               cache_data,
  input                      cache_waitrequest
);

  wire          stall;
  wire          inval_dest_reg;
  wire   [31:0] result;
  wire   [31:0] agu_address;

  reg    [31:0] agu_address_r;
  reg           load_inst_r;
  reg           store_inst_r;

  reg           stall_d1;

  wire          load_inst_i;
  wire          store_inst_i;

  // "pipeline" registered signals
  dec_inst_t    inst_r;
  dec_inst_t    inst_r_r;
  reg           inst_valid_r;
  reg    [31:0] A_r;
  reg    [31:0] B_r;
  wire   [31:0] A_i;
  wire   [31:0] B_i;
  reg    [31:0] B_r_r;
  reg           inst_valid_r_r;
  reg [ROB_DEPTHLOG2-1:0] rob_slot_r;
  reg [ROB_DEPTHLOG2-1:0] rob_slot_r_r;


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n) begin
      inst_valid_r <= 1'b0;
      A_r          <= 'b0;
      B_r          <= 'b0;
      rob_slot_r   <= 'b0;
    end
    else if (ready) begin
      inst_r       <= inst;
      inst_valid_r <= inst_valid;
      A_r          <= A;
      B_r          <= B;
      rob_slot_r   <= rob_slot;
    end

  assign A_lookup_idx  = fwd_info.A_rob_slot;
  assign B_lookup_idx  = fwd_info.B_rob_slot;

  assign A_i  = (fwd_info.A_fwd) ? A_fwd : A_r;
  assign B_i  = (fwd_info.B_fwd) ? B_fwd : B_r;

  // Reverse pipeline register between LS and AGU
  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      stall_d1 <= 1'b0;
    else
      stall_d1 <= stall;


  // Pipeline reg between AGU and LS
  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n) begin
      agu_address_r  <= 32'b0;
      load_inst_r    <= 1'b0;
      store_inst_r   <= 1'b0;
      B_r_r          <= 32'b0;
      rob_slot_r_r   <= 'b0;
      inst_valid_r_r <= 1'b0;
    end
    else if (~stall) begin
      agu_address_r  <= agu_address;
      load_inst_r    <= load_inst_i;
      store_inst_r   <= store_inst_i;
      B_r_r          <= B_i;
      inst_r_r       <= inst_r;
      rob_slot_r_r   <= rob_slot_r;
      inst_valid_r_r <= inst_valid_r;
    end


  assign ready           = ~stall; // was stall_d1
  assign rob_data_valid  = inst_valid_r_r & ready;
  assign rob_data_idx    = rob_slot_r_r;

  assign rob_data.result_lo      = result;
  assign rob_data.dest_reg       = inst_r_r.dest_reg;
  assign rob_data.dest_reg_valid = inst_r_r.dest_reg_valid;

  assign load_inst_i   = inst_valid_r ? inst_r.load_inst  : 1'b0;
  assign store_inst_i  = inst_valid_r ? inst_r.store_inst : 1'b0;

  agu AGU
  (
   .clock             (clock),
   .reset_n           (reset_n),

   .A_val             (A_i),

   .imm               (inst_r.imm),
   .imm_valid         (inst_r.imm_valid),

   .agu_address       (agu_address)
  );

  mem MEM
  (
   .clock             (clock),
   .reset_n           (reset_n),

   .pc                (inst_r_r.pc),

   .cache_rd          (cache_rd),
   .cache_wr          (cache_wr),
   .cache_addr        (cache_addr),
   .cache_wr_data     (cache_wr_data),
   .cache_wr_be       (cache_wr_be),
   .cache_data        (cache_data),
   .cache_waitrequest (cache_waitrequest),

   .load_inst         (load_inst_r),
   .store_inst        (store_inst_r),

   .ls_op             (inst_r_r.ls_op),
   .ls_sext           (inst_r_r.ls_sext),

   .dest_reg          (inst_r_r.dest_reg),
   .dest_reg_valid    (inst_r_r.dest_reg_valid),

   .agu_address       (agu_address_r),
   .B_val             (B_r_r),

   .result            (result),
   .stall             (stall)
  );

endmodule
