import pipTypes::*;

module ex_wrapper #(
                    parameter ROB_DEPTHLOG2 = 4
)(
  input                     clock,
  input                     reset_n,

  input                     dec_inst_t inst,
  input                     inst_valid,
  input [31:0]              A,
  input [31:0]              B,
  input [ROB_DEPTHLOG2-1:0] rob_slot,

  output                    ready,

  output                    rob_data_valid,
  output [ 3:0]             rob_data_idx,
  output                    rob_entry_t rob_data
);

  wire          stall;
  wire          inval_dest_reg;
  wire [31:0]   result;

  // "pipeline" registered signals
  dec_inst_t    inst_r;
  reg           inst_valid_r;
  reg  [31:0]   A_r;
  reg  [31:0]   B_r;
  reg [ROB_DEPTHLOG2-1:0] rob_slot_r;


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

  assign ready           = ~stall;
  assign rob_data_valid  = inst_valid_r & ready;
  assign rob_data_idx    = rob_slot_r;

  assign rob_data.result_lo      = result;
  assign rob_data.dest_reg       = inst_r.dest_reg;
  assign rob_data.dest_reg_valid = inst_r.dest_reg_valid & ~inval_dest_reg;

  ex EX
  (
   .clock          (clock),
   .reset_n        (reset_n),

   .pc             (inst_r.pc),

   .A_val          (A_r),
   .B_val          (B_r),

   .A_reg          (inst_r.A_reg),
   .A_reg_valid    (inst_r.A_reg_valid),
   .B_reg          (inst_r.B_reg),
   .B_reg_valid    (inst_r.B_reg_valid),
   .imm            (inst_r.imm),
   .imm_valid      (inst_r.imm_valid),
   .shamt          (inst_r.shamt),
   .shamt_valid    (inst_r.shamt_valid),
   .shleft         (inst_r.shleft),
   .sharith        (inst_r.sharith),
   .shopsela       (inst_r.shopsela),
   .alu_op         (inst_r.alu_op),
   .alu_res_sel    (inst_r.alu_res_sel),
   .alu_set_u      (inst_r.alu_set_u),
   .alu_inst       (inst_r.alu_inst),

   .dest_reg       (inst_r.dest_reg),
   .dest_reg_valid (inst_r.dest_reg_valid),
   .result         (result),
   .inval_dest_reg (inval_dest_reg),
   .stall          (stall),
   .front_stall    (1'b0)
  );
endmodule
