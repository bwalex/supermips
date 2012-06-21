package pipTypes;
  typedef enum {
                FWD_NONE,
                FWD_FROM_EXMEM,
                FWD_FROM_MEMWB,
                FWD_FROM_MEMWB_LATE
                } fwd_t;

  typedef enum {
                OP_ADD,
                OP_SUB,
                OP_OR,
                OP_XOR,
                OP_NOR,
                OP_AND,
                OP_SLL,
                OP_SRL,
                OP_SLA,
                OP_SRA,
                OP_LUI,
                OP_PASS_A,
                OP_PASS_B
                } alu_op_t;

  typedef enum {
                RES_ALU,
                RES_SET
                } alu_res_t;


  typedef enum {
                OP_LS_WORD,
                OP_LS_HALFWORD,
                OP_LS_BYTE
                } ls_op_t;
endpackage