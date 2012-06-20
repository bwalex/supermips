// NOTE: THIS MODULE IS AUTOGENERATED
//       DO NOT EDIT BY HAND!
module pipreg_ex_mem(

  input [31:0] ex_pc,
  input [0:0] ex_load_inst,
  input [0:0] ex_store_inst,
  input [0:0] ex_jmp_inst,
  input [31:0] ex_result,
  input [4:0] ex_dest_reg,
  input [0:0] ex_dest_reg_valid,


  output reg [31:0] mem_pc,
  output reg [0:0] mem_load_inst,
  output reg [0:0] mem_store_inst,
  output reg [0:0] mem_jmp_inst,
  output reg [31:0] mem_result,
  output reg [4:0] mem_dest_reg,
  output reg [0:0] mem_dest_reg_valid,

  input clock,
  input reset_n
);

  always_ff @(posedge clock, negedge reset_n) begin
    if (~reset_n) begin
    
      mem_pc <= 'b0;
      mem_load_inst <= 'b0;
      mem_store_inst <= 'b0;
      mem_jmp_inst <= 'b0;
      mem_result <= 'b0;
      mem_dest_reg <= 'b0;
      mem_dest_reg_valid <= 'b0;
    end
    else begin
    
      mem_pc <= ex_pc;
      mem_load_inst <= ex_load_inst;
      mem_store_inst <= ex_store_inst;
      mem_jmp_inst <= ex_jmp_inst;
      mem_result <= ex_result;
      mem_dest_reg <= ex_dest_reg;
      mem_dest_reg_valid <= ex_dest_reg_valid;
    end
  end

endmodule
