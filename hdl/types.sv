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
                OP_MUL_LO,
                OP_PASS_A,
                OP_PASS_B,
                OP_MOVZ,
                OP_MOVN,
                OP_SEB,
                OP_SEH,
                OP_EXT,
                OP_INS
                } alu_op_t;

  typedef enum {
                OP_NONE,
                OP_MUL,
                OP_DIV,
                OP_MADD,
                OP_MFHI,
                OP_MFLO,
                OP_MTHI,
                OP_MTLO
                } muldiv_op_t;

  typedef enum {
                RES_ALU,
                RES_SET,
                RES_SHIFT
                } alu_res_t;


  typedef enum {
                OP_LS_WORD,
                OP_LS_HALFWORD,
                OP_LS_BYTE
                } ls_op_t;

  typedef enum {
                COND_UNCONDITIONAL,
                COND_EQ,
                COND_NE,
                COND_GT,
                COND_LT,
                COND_GE,
                COND_LE
               } cond_t;
endpackage
