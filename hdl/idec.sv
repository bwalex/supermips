module idec #(
  parameter ALU_OPC_WIDTH = 12
)(
  input                      clock,
  input                      reset_n,

  input [31:0]               pc,
  input [31:0]               inst_word,

  output [ 4:0]              rfile_rd_addr1,
  output [ 4:0]              rfile_rd_addr2,

  input [31:0]               rfile_rd_data1,
  input [31:0]               rfile_rd_data2,

  output [31:0]              A,
  output [31:0]              B,
  output reg [ 4:0]          A_reg,
  output reg [ 4:0]          B_reg,
  output                     B_imm,
  output reg [ 4:0]          shamt,
  output [ALU_OPC_WIDTH-1:0] alu_op,

  output reg                 alu_inst,
  output reg                 mem_inst,
  output reg                 jmp_inst,

  output reg [ 4:0]          dest_reg,
  output reg                 dest_reg_valid
);

  wire [5:0]                 inst_opc;
  wire [4:0]                 inst_rs;
  wire [4:0]                 inst_rt;
  wire [4:0]                 inst_rd;
  wire [15:0]                inst_imm;
  wire [25:0]                inst_addr;
  wire [4:0]                 inst_shamt;
  wire [5:0]                 inst_funct;

  reg                        inst_rformat;
  reg                        inst_jformat;
  reg                        inst_iformat;

  reg                        imm_sext;
  wire [31:0]                imm_extended;


  // XXX: could use A_reg, B_reg (more "correct") but
  //      using inst_{rs,rt} is good enough and is
  //      faster.
  assign rfile_rd_addr1  = inst_rs;
  assign rfile_rd_addr2  = inst_rt;

  assign inst_opc   = inst_word[31:26];
  assign inst_rs    = inst_word[25:21];
  assign inst_rt    = inst_word[20:16];
  assign inst_rd    = inst_word[15:11];
  assign inst_imm   = inst_word[15: 0];
  assign inst_addr  = inst_word[25: 0];
  assign inst_shamt = inst_word[10: 6];
  assign inst_funct = inst_word[ 5: 0];

  assign alu_op     = { inst_opc, inst_funct };


  always_comb begin
    A_reg           = 0;
    B_reg           = 0;
    dest_reg        = inst_rt;
    shamt           = 0;
    alu_inst        = 1'b0;
    mem_inst        = 1'b0;
    jmp_inst        = 1'b0;
    dest_reg_valid  = 1'b1;
    imm_sext        = 1'b0;
    inst_rformat    = 1'b0;
    inst_iformat    = 1'b1;
    inst_jformat    = 1'b0;

    case (inst_opc)
      6'h00: begin
        inst_rformat    = 1'b1;
        inst_iformat    = 1'b0;

        shamt           = inst_shamt;

        A_reg           = inst_rs;

        case (inst_funct)
          6'h08: begin
            // JR
            jmp_inst  = 1'b1;
            dest_reg  = 5'd31;
          end
          6'h09: begin
            // JALR
            jmp_inst  = 1'b1;
            dest_reg  = 5'd31;
          end
          default: begin
            B_reg     = inst_rt;
            dest_reg  = inst_rd;
            alu_inst  = 1'b1;
          end
        endcase
      end // case: 6'h00

      6'h08: begin
        // addi
        imm_sext  = 1'b1;
        alu_inst  = 1'b1;
      end

      6'h09: begin
        // addiu
        imm_sext  = 1'b1;
        alu_inst  = 1'b1;
      end

      6'h0a: begin
        // slti
        imm_sext  = 1'b1;
        alu_inst  = 1'b1;
      end

      6'h0b: begin
        // sltiu
        imm_sext  = 1'b1;
        alu_inst  = 1'b1;
      end

      6'h0c: begin
        // andi
        alu_inst  = 1'b1;
      end

      6'h0d: begin
        // ori
        alu_inst  = 1'b1;
      end

      6'h0e: begin
        // xori
        alu_inst  = 1'b1;
      end
    endcase
  end


  assign imm_extended  = (imm_sext)
                         ? { {16{inst_imm[15]}}, inst_imm }
                         : { 16'd0, inst_imm };


  assign B_imm  = inst_iformat;


  assign A  = rfile_rd_data1;
  assign B  = (inst_iformat) ? imm_extended : rfile_rd_data2;
endmodule