import pipTypes::*;

module exmul #(
  parameter ALU_OP_WIDTH = 12,
            MUL_CYCLES   = 5,
            DIV_CYCLES   = 35,
            DIVCOUNT_WIDTH = `clogb2(DIV_CYCLES)+1 // assume div always takes longer than mul/madd
)(
  input                    clock,
  input                    reset_n,

  input [31:0]             pc,

  input [31:0]             A_val,
  input [31:0]             B_val,
  input [ 4:0]             A_reg,
  input                    A_reg_valid,

  input [ 4:0]             B_reg,
  input                    B_reg_valid,

  input [31:0]             imm,
  input                    imm_valid,
  input [ 4:0]             shamt,
  input                    shamt_valid,
  input                    shleft,
  input                    sharith,
  input                    shopsela,
  input alu_op_t           alu_op,
  input alu_res_t          alu_res_sel,
  input                    alu_set_u,
  input                    alu_inst,
  input                    muldiv_inst,
  input muldiv_op_t        muldiv_op,
  input                    muldiv_op_u,

  input [ 4:0]             dest_reg,
  input                    dest_reg_valid,

  output [31:0]            result,
  output                   inval_dest_reg,
  output                   stall,

  input                    front_stall
);

  wire [4:0]                shift_val;
  wire [31:0]               shift_operand;
  wire [31:0]               shift_res;

  reg                       flag_carry;
  wire                      flag_zero;

  wire                      B_eqz;
  wire                      A_eqz;

  reg [31:0]                alu_res;
  reg [31:0]                set_res;


  wire [31:0]               A;
  wire [31:0]               B;

  wire [4:0]                ext_msbd;
  wire [4:0]                ext_lsb;
  reg [31:0]                ext_msbd_mask;
  wire [31:0]               ext_msbd_mask_ins;

  reg [31:0]                hi_r;
  reg [31:0]                lo_r;
  reg [31:0]                next_hi;
  reg [31:0]                next_lo;

  wire                      load_hi;
  wire                      load_lo;

  wire                      load_muldiv_count;

  reg                       stall_d1;

  reg [DIVCOUNT_WIDTH-1:0]  muldiv_count;


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      stall_d1 <= 1'b0;
    else
      stall_d1 <= stall;



  // MUL, DIV "unit"
  //
  // XXX: not really synthesizable and/or practical. need proper
  // multiplication and division algorithms.


  assign stall =  (muldiv_op == OP_MUL )                    ? (muldiv_count != MUL_CYCLES)
                : (muldiv_op == OP_MADD)                    ? (muldiv_count != MUL_CYCLES)
                : (muldiv_op == OP_DIV )                    ? (muldiv_count != DIV_CYCLES)
                :                                             front_stall;



  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      muldiv_count <= 0;
    else if (load_muldiv_count)
      muldiv_count <= 1;
    else
      muldiv_count <= muldiv_count + 1;


  assign load_muldiv_count =  (~stall_d1 && (
                              (muldiv_op == OP_MUL)
                           || (muldiv_op == OP_DIV)
                           || (muldiv_op == OP_MADD)));


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      hi_r <= 32'b0;
    else if (load_hi & ~stall)
      hi_r <= next_hi;


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      lo_r <= 32'b0;
    else if (load_lo & ~stall)
      lo_r <= next_lo;


  // XXX: would be cleaner to integrate ~stall with load_hi,lo
  // XXX: probably shouldn't load_foo if it's mul (instead of mult, etc)
  assign load_hi =  (muldiv_op == OP_MTHI)
                 || (muldiv_op == OP_MUL)
                 || (muldiv_op == OP_DIV)
                 || (muldiv_op == OP_MADD);

  assign load_lo =  (muldiv_op == OP_MTLO)
                 || (muldiv_op == OP_MUL)
                 || (muldiv_op == OP_DIV)
                 || (muldiv_op == OP_MADD);

  always_comb begin
    next_hi        = A;
    next_lo        = A;
    if (muldiv_op == OP_MUL) begin
      if (muldiv_op_u)
        {next_hi, next_lo}  = A*B;
      else
        {next_hi, next_lo}  = $signed(A)*$signed(B);
    end
    else if (muldiv_op == OP_MADD) begin
      if (muldiv_op_u)
        {next_hi, next_lo}  = {hi_r, lo_r} + A*B;
      else
        {next_hi, next_lo}  = {hi_r, lo_r} + $signed(A)*$signed(B);
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


  assign A  = A_val;

  assign B  = (imm_valid) ? imm : B_val;


  assign ext_msbd  = imm[15:11];
  assign ext_lsb   = imm[10: 6];


  assign A_eqz     = (A == 0);
  assign B_eqz     = (B == 0);


  assign shift_val      = shamt_valid ? shamt : A[4:0];
  assign shift_operand  = shopsela    ? A     : B;


  assign flag_zero  = (alu_res == 0);

  assign result =  (muldiv_op == OP_MFHI)     ? hi_r
                 : (muldiv_op == OP_MFLO)     ? lo_r
                 : (alu_res_sel == RES_SHIFT) ? shift_res
                 : (alu_res_sel == RES_ALU)   ? alu_res
                 :                              set_res;


  assign inval_dest_reg =  (alu_op == OP_MOVZ) ? ~B_eqz
                         : (alu_op == OP_MOVN) ?  B_eqz
                         :                        1'b0;


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
      OP_LUI:
        alu_res  = { B[15:0], 16'b0 };
      OP_MUL_LO:
        alu_res  = next_lo;
      OP_MOVZ:
        alu_res  = A;
      OP_MOVN:
        alu_res  = A;
      OP_SEB:
        alu_res  = { {24{B[ 7]}}, B[ 7:0] };
      OP_SEH:
        alu_res  = { {16{B[15]}}, B[15:0] };
      OP_EXT:
        alu_res  = shift_res & ext_msbd_mask;
      OP_INS:
        // B_val, since imm_valid overrides B
        alu_res  =  (shift_res & ext_msbd_mask_ins)
                  | (B_val     & ~(shift_res & ext_msbd_mask_ins));
    endcase // case (alu_op)
  end


  always_comb
    begin
      case (ext_msbd)
        5'd0:    ext_msbd_mask  = 32'h00000001;
        5'd1:    ext_msbd_mask  = 32'h00000003;
        5'd2:    ext_msbd_mask  = 32'h00000007;
        5'd3:    ext_msbd_mask  = 32'h0000000f;
        5'd4:    ext_msbd_mask  = 32'h0000001f;
        5'd5:    ext_msbd_mask  = 32'h0000003f;
        5'd6:    ext_msbd_mask  = 32'h0000007f;
        5'd7:    ext_msbd_mask  = 32'h000000ff;
        5'd8:    ext_msbd_mask  = 32'h000001ff;
        5'd9:    ext_msbd_mask  = 32'h000003ff;
        5'd10:   ext_msbd_mask  = 32'h000007ff;
        5'd11:   ext_msbd_mask  = 32'h00000fff;
        5'd12:   ext_msbd_mask  = 32'h00001fff;
        5'd13:   ext_msbd_mask  = 32'h00003fff;
        5'd14:   ext_msbd_mask  = 32'h00007fff;
        5'd15:   ext_msbd_mask  = 32'h0000ffff;
        5'd16:   ext_msbd_mask  = 32'h0001ffff;
        5'd17:   ext_msbd_mask  = 32'h0003ffff;
        5'd18:   ext_msbd_mask  = 32'h0007ffff;
        5'd19:   ext_msbd_mask  = 32'h000fffff;
        5'd20:   ext_msbd_mask  = 32'h001fffff;
        5'd21:   ext_msbd_mask  = 32'h003fffff;
        5'd22:   ext_msbd_mask  = 32'h007fffff;
        5'd23:   ext_msbd_mask  = 32'h00ffffff;
        5'd24:   ext_msbd_mask  = 32'h01ffffff;
        5'd25:   ext_msbd_mask  = 32'h03ffffff;
        5'd26:   ext_msbd_mask  = 32'h07ffffff;
        5'd27:   ext_msbd_mask  = 32'h0fffffff;
        5'd28:   ext_msbd_mask  = 32'h1fffffff;
        5'd29:   ext_msbd_mask  = 32'h3fffffff;
        5'd30:   ext_msbd_mask  = 32'h7fffffff;
        5'd31:   ext_msbd_mask  = 32'hffffffff;
        default: ext_msbd_mask  = 32'h00000001;
      endcase
    end

  assign ext_msbd_mask_ins  = {1'b0, ext_msbd_mask[31:1]};


  always_comb begin
    if (alu_set_u) begin
      // slt(i)u
      set_res  = { 31'b0, flag_carry }; //~
    end
    else begin
      // slt(i)
      set_res  = { 31'b0, (A[31] & ~B[31]) | (alu_res[31] & (~A[31] ^ B[31])) };
    end
  end


  shifter#
    (
     .DATA_WIDTH(32),
     .SHAMT_WIDTH(5)
     ) shifter
    (
     .in       (shift_operand),
     .shamt    (shift_val),
     .shleft   (shleft),
     .sharith  (sharith),
     .out      (shift_res)
     );

endmodule
