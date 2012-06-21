module ex #(
  parameter ALU_OP_WIDTH = 12
)(
  input                    clock,
  input                    reset_n,

  input [31:0]             pc,

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
  input                    load_inst,
  input                    store_inst,
  input                    jmp_inst,

  input [ 4:0]             dest_reg,
  input                    dest_reg_valid,

  output [31:0]            result,
  output [31:0]            result_2
);


  wire [6:0]                inst_opc;
  wire [6:0]                inst_funct;

  wire [4:0]                shift_val;

  reg                       flag_carry;
  wire                      flag_zero;

  reg [31:0]                alu_res;
  reg [31:0]                set_res;


  wire [31:0]               A;
  wire [31:0]               B;
  wire [31:0]               B_forwarded;


  // Forward results as required
  assign B_forwarded =  (B_fwd_from == FWD_FROM_EXMEM) ? result_from_ex_mem
                      : (B_fwd_from == FWD_FROM_MEMWB) ? result_from_mem_wb
                      :                                  B_val;

  assign A  =  (A_fwd_from == FWD_FROM_EXMEM) ? result_from_ex_mem
             : (A_fwd_from == FWD_FROM_MEMWB) ? result_from_mem_wb
             :                                  A_val;


  assign B  = (imm_valid) ? imm : B_forwarded;

  assign result_2  = B_forwarded;



  assign inst_opc   = alu_op[11:6];
  assign inst_funct = alu_op[5:0];


  // Detect sllv, srlv, srav
  assign shift_val  = A_reg_valid ? A[4:0] : shamt;


  assign flag_zero  = (alu_res == 0);

  assign result  = (alu_res_sel == RES_ALU) ? alu_res : set_res;



  // XXX: should factor out barrel shifter
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
    // XXX: wrong way round?
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