import pipTypes::*;

module ex #(
  parameter ALU_OP_WIDTH = 12
)(
  input                    clock,
  input                    reset_n,

  input [31:0]             pc,

  input [31:0]             pc_plus_8,

  input [31:0]             A_val,
  input [31:0]             B_val,
  input [31:0]             result_from_ex_mem,
  input [31:0]             result_from_mem_wb,
  input [ 4:0]             A_reg,
  input                    A_reg_valid,
  input fwd_t              A_fwd_from,
  input [ 4:0]             B_reg,
  input                    B_reg_valid,
  input fwd_t              B_fwd_from,
  input [31:0]             imm,
  input                    imm_valid,
  input [ 4:0]             shamt,
  input alu_op_t           alu_op,
  input alu_res_t          alu_res_sel,
  input                    alu_set_u,
  input                    alu_inst,
  input muldiv_op_t        muldiv_op,
  input                    muldiv_op_u,
  input                    load_inst,
  input                    store_inst,
  input                    jmp_inst,
  input                    branch_inst,
  input cond_t             branch_cond,

  input [ 4:0]             dest_reg,
  input                    dest_reg_valid,

  output [31:0]            result,
  output [31:0]            result_2,
  output [31:0]            new_pc,
  output                   new_pc_valid
);


  wire [6:0]                inst_opc;
  wire [6:0]                inst_funct;

  wire [4:0]                shift_val;

  reg                       flag_carry;
  wire                      flag_zero;

  wire                      branch_cond_ok;
  wire                      AB_equal;
  wire                      AB_gez;
  wire                      A_gtz;

  reg [31:0]                alu_res;
  reg [31:0]                set_res;


  wire [31:0]               A;
  wire [31:0]               B;
  wire [31:0]               B_forwarded;



  reg [31:0]                hi_r;
  reg [31:0]                lo_r;
  reg [31:0]                next_hi;
  reg [31:0]                next_lo;

  wire                      load_hi;
  wire                      load_lo;


  // MUL, DIV "unit"
  //
  // XXX: not really synthesizable and/or practical. need proper
  // multiplication and division algorithms.

  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      hi_r <= 32'b0;
    else if (load_hi)
      hi_r <= next_hi;

  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      lo_r <= 32'b0;
    else if (load_lo)
      lo_r <= next_lo;

  assign load_hi =  (muldiv_op == OP_MTHI)
                 || (muldiv_op == OP_MUL)
                 || (muldiv_op == OP_DIV);

  assign load_lo =  (muldiv_op == OP_MTLO)
                 || (muldiv_op == OP_MUL)
                 || (muldiv_op == OP_DIV);

  always_comb begin
    next_hi        = A;
    next_lo        = A;
    if (muldiv_op == OP_MUL) begin
      if (muldiv_op_u)
        {next_hi, next_lo}  = A*B;
      else
        {next_hi, next_lo}  = $signed(A)*$signed(B);
    end
    else if (muldiv_op == OP_DIV) begin
      if (muldiv_op_u) begin
        next_hi  = A%B;
        next_lo  = A/B;
      end
      else begin
        next_hi  = $signed(A)%$signed(B);
        next_lo  = $signed(A)/$signed(B);
      end
    end
  end

  // END MUL, DIV "unit"



  // Forward results as required
  assign B_forwarded =  (B_fwd_from == FWD_FROM_EXMEM) ? result_from_ex_mem
                      : (B_fwd_from == FWD_FROM_MEMWB) ? result_from_mem_wb
                      :                                  B_val;

  assign A  =  (A_fwd_from == FWD_FROM_EXMEM) ? result_from_ex_mem
             : (A_fwd_from == FWD_FROM_MEMWB) ? result_from_mem_wb
             :                                  A_val;


  assign B  = (imm_valid) ? imm : B_forwarded;

  // Use B_forwarded for AB_equal, which is used for branches, since
  // B will contain the PC because imm_valid is true.
  assign AB_equal  = (A == B_forwarded);
  assign A_gtz     = (A >  0);
  assign A_gez     = (A >= 0);

  assign result_2  = B_forwarded;


  assign new_pc    = (imm_valid) ? imm : A;

  assign new_pc_valid    = jmp_inst | (branch_inst & branch_cond_ok);
  assign branch_cond_ok  = (branch_cond == COND_UNCONDITIONAL)
                         | (branch_cond == COND_EQ && AB_equal)
                         | (branch_cond == COND_NE && ~AB_equal)
                         | (branch_cond == COND_GT && A_gtz)
                         | (branch_cond == COND_GE && A_gez)
                         | (branch_cond == COND_LT && ~A_gez)
                         | (branch_cond == COND_LE && ~A_gtz);


  assign inst_opc   = alu_op[11:6];
  assign inst_funct = alu_op[5:0];


  // Detect sllv, srlv, srav
  assign shift_val  = A_reg_valid ? A[4:0] : shamt;


  assign flag_zero  = (alu_res == 0);

  assign result =  (jmp_inst | branch_inst) ? pc_plus_8
                 : (alu_res_sel == RES_ALU) ? alu_res
                 : (muldiv_op == OP_MFHI)   ? hi_r
                 : (muldiv_op == OP_MFLO)   ? lo_r
                 :                            set_res;


  // XXX: should factor out (barrel) shifter
  always_comb begin
    alu_res     = 0;
    flag_carry  = 1'b0;

    case (alu_op)
      OP_ADD:
        { flag_carry, alu_res }  = A + B;
      OP_SUB:
        { flag_carry, alu_res }  = A - B;
      OP_OR:
        alu_res  = A | B;
      OP_XOR:
        alu_res  = A ^ B;
      OP_NOR:
        alu_res  = ~(A | B);
      OP_AND:
        alu_res  = A & B;
      OP_PASS_A:
        alu_res  = A;
      OP_PASS_B:
        alu_res  = B;
      OP_SLL:
        alu_res  = B << shift_val;
      OP_SRL:
        alu_res  = B >> shift_val;
      OP_SLA:
        alu_res  = B <<< shift_val;
      OP_SRA:
        alu_res  = B >>> shift_val;
      OP_LUI:
        alu_res  = { B[15:0], 16'b0 };
    endcase // case (alu_op)
  end


  always_comb begin
    if (alu_set_u) begin
      // slt(i)u
      set_res  = { 31'b0, (A[31] & ~B[31]) | (alu_res[31] & (~A[31] ^ B[31])) };
    end
    else begin
      // slt(i)
      set_res  = { 31'b0, ~flag_carry };
    end
  end
endmodule
