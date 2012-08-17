import pipTypes::*;

module id#(
           parameter ROB_DEPTHLOG2 = 4
)(
 input [31:0]              inst_word[4],
 input [31:0]              inst_pc[4],
 input                     inst_word_valid[4],
 output                    stall,

 // ROB reservation interface + forwarding setup interface
 output [4:0]              dest_reg[4],
 output                    dest_reg_valid[4],
 input                     fwd_info_t fwd_info[4],

 output                    reserve,
 output reg [1:0]          reserve_count,
 input [ROB_DEPTHLOG2-1:0] reserved_slots[4],
 input                     rob_full,

 // IQ store interface
 output                    ins_enable,
 output [1:0]              new_count,
 output                    iq_entry_t new_elements[4],
 input                     iq_full
);

  dec_inst_t dec_inst[4];
  reg         insns_valid;

  idec dec0
  (
   .pc         (inst_pc[0]),
   .inst_word  (inst_word[0]),
   .di         (dec_inst[0])
  );

  idec dec1
  (
   .pc         (inst_pc[1]),
   .inst_word  (inst_word[1]),
   .di         (dec_inst[1])
  );

  idec dec2
  (
   .pc         (inst_pc[2]),
   .inst_word  (inst_word[2]),
   .di         (dec_inst[2])
  );

  idec dec3
  (
   .pc         (inst_pc[3]),
   .inst_word  (inst_word[3]),
   .di         (dec_inst[3])
  );


  always_comb
    begin
      reserve_count  = -1;
      insns_valid    = 1'b0;
      for (integer i = 0; i < 4; i++) begin
        insns_valid |= inst_word_valid[i];
        if (inst_word_valid[i])
          reserve_count += 1;
      end
    end

  assign stall       = rob_full | iq_full;
  assign reserve     = ~stall   & insns_valid;
  assign ins_enable  = ~stall;

  assign new_count   = reserve_count;


  always_comb
    begin
      if (inst_word_valid[0]) begin
        new_elements[0]  = '{ dec_inst[0], fwd_info[0] };
      end
      else if (~inst_word_valid[0] & inst_word_valid[1]) begin
        new_elements[0]  = '{ dec_inst[1], fwd_info[1] }; //.... effectively 1;
      end
      else if (~inst_word_valid[0] & ~inst_word_valid[1] & inst_word_valid[2]) begin
        new_elements[0]  = '{ dec_inst[2], fwd_info[2] }; //.... effectively 2;
      end
      else begin
        new_elements[0]  = '{ dec_inst[3], fwd_info[3] }; //.... effectively 3;
      end
    end

  always_comb
    begin
      if (inst_word_valid[0] & inst_word_valid[1]) begin
        new_elements[1]  = '{ dec_inst[1], fwd_info[1] }; //.... effectively 1;
      end
      else if (~inst_word_valid[0] & inst_word_valid[1] & inst_word_valid[2]) begin
        new_elements[1]  = '{ dec_inst[2], fwd_info[2] }; //.... effectively 2;
      end
      else begin
        new_elements[1]  = '{ dec_inst[3], fwd_info[3] }; //.... effectively 3;
      end
    end

  always_comb
    begin
      if (inst_word_valid[0] & inst_word_valid[1] & inst_word_valid[2]) begin
        new_elements[2]  = '{ dec_inst[2], fwd_info[2] }; //.... effectively 2;
      end
      else begin
        new_elements[2]  = '{ dec_inst[3], fwd_info[3] }; //.... effectively 3;
      end
    end

  always_comb
    begin
      new_elements[3]    = '{ dec_inst[3], fwd_info[3] }; //.... effectively 3;
    end


  genvar i;
  generate
    for (i = 0; i < 4; i++) begin : ID_DEST_REG_SIGNALS
      assign dest_reg[i]        = dec_inst[i].dest_reg;
      assign dest_reg_valid[i]  = dec_inst[i].dest_reg_valid;
    end
  endgenerate
endmodule