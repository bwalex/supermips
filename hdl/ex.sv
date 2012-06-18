module ex #(
  parameter ALU_OPC_WIDTH = 12
)(
  input                     clock,
  input                     reset_n,

  input [31:0]              pc,

  input [31:0]              A,
  input [31:0]              B,
  input [ 4:0]              A_reg,
  input [ 4:0]              B_reg,
  input                     B_imm,
  input [ 4:0]              shamt,
  input [ALU_OPC_WIDTH-1:0] alu_op,
  input                     alu_inst,
  input                     mem_inst,
  input                     jmp_inst,

  input [ 4:0]              dest_reg,
  input                     dest_reg_valid,

  output [31:0]             result
);

  typedef enum { OP_ADD, OP_SUB, OP_OR, OP_XOR, OP_NOR, OP_AND, OP_SLL, OP_SRL, OP_SLA, OP_SRA, OP_LUI, OP_PASS_A, OP_PASS_B } op_t;

  typedef enum { RES_ALU, RES_SET } result_unit_t;


  wire [6:0]                inst_opc;
  wire [6:0]                inst_funct;

  wire [4:0]                shift_val;

  reg                       flag_carry;
  wire                      flag_zero;

  reg [31:0]                alu_res;
  reg [31:0]                set_res;

  op_t                      op;
  result_unit_t             res_sel;
  reg                       set_u;


  assign inst_opc   = alu_op[11:6];
  assign inst_funct = alu_op[5:0];


  // Detect sllv, srlv, srav
  assign shift_val  = (inst_funct == 6'h4 || inst_funct == 6'h6 || inst_funct == 6'h7) ? A[4:0] : shamt;


  assign flag_zero  = (alu_res == 0);

  assign result  = (res_sel == RES_ALU) ? alu_res : set_res;


  always_comb begin
    op       = OP_PASS_A;
    res_sel  = RES_ALU;
    set_u    = 1'b0;

    case (inst_opc)
      6'd00: begin
        case (inst_funct)
          6'd00: // sll
            op  = OP_SLL;
          6'd02: // srl
            op  = OP_SRL;
          6'd03: // sra
            op  = OP_SRA;
          6'd04: // sllv
            op  = OP_SLL;
          6'd06: // srlv
            op  = OP_SRL;
          6'd07: // srav
            op  = OP_SRA;
          6'd32: // add
            op  = OP_ADD;
          6'd33: // addu
            op  = OP_ADD;
          6'd34: // sub
            op  = OP_SUB;
          6'd35: // subu
            op  = OP_SUB;
          6'd36: // and
            op  = OP_AND;
          6'd37: // or
            op  = OP_OR;
          6'd38: // xor
            op  = OP_XOR;
          6'd39: // nor
            op  = OP_NOR;
          6'd42: begin // slt
            op       = OP_SUB;
            res_sel  = RES_SET;
          end
          6'd43: begin // sltu
            op       = OP_SUB;
            res_sel  = RES_SET;
            set_u    = 1 'b1;
          end
        endcase // case (inst_funct)

      end
      6'h08: // addi
        op  = OP_ADD;
      6'h09: // addiu
        op  = OP_ADD;
      6'h0a: begin // slti
        op       = OP_SUB;
        res_sel  = RES_SET;
      end
      6'h0b: begin // sltiu
        op       = OP_SUB;
        res_sel  = RES_SET;
        set_u    = 1'b1;
      end
      6'h0c: // andi
        op  = OP_AND;
      6'h0d: // ori
        op  = OP_OR;
      6'h0e: // xori
        op  = OP_XOR;
      6'h0f: // lui
        op  = OP_LUI;
    endcase // case (inst_opc)
  end // always_comb



  // XXX: should factor out barrel shifter
  always_comb begin
    alu_res     = 0;
    flag_carry  = 1'b0;

    case (op)
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
    endcase // case (op)
  end


  always_comb begin
    if (set_u) begin
      // slt(i)u
      set_res  = { 31'b0, (A[31] & ~B[31]) | (alu_res[31] & (~A[31] ^ B[31])) };
    end
    else begin
      // slt(i)
      set_res  = { 31'b0, ~flag_carry };
    end
  end
endmodule