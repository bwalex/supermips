module circbuf #(
  parameter type T     = integer,
  parameter      DEPTH     = 16,
                 INS_COUNT = 2,
                 EXT_COUNT = 2,
                 DEPTHLOG2 = $clog2(DEPTH)
                 EXTCOUNTLOG2  = $clog2(EXT_COUNT),
                 INSCOUNTLOG2  = $clog2(INS_COUNT)
)(
  input                    clock,
  input                    reset_n,
  input [INSCOUNTLOG2-1:0] new_count,
  input                    T new_elements[INS_COUNT],

  input [EXTCOUNTLOG2-1:0] ext_consumed,
  output [EXT_COUNT-1:0]   ext_valid,
  output                   T out_elements[EXT_COUNT],

  output                   full,
  output                   empty,
  output [DEPTHLOG2-1:0]   used_count
);

  reg [DEPTHLOG2-1:0]      ext_ptr;
  reg [DEPTHLOG2-1:0]      ins_ptr;

  T buffer[DEPTH];


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      ins_ptr <= 'b0;
    else begin
      bit [DEPTHLOG2-1:0] idx  = ins_ptr;

      for (integer i = 0; i < new_count; i++) begin
        buffer[idx] <= new_elements[i];
        idx         += 1;
      end

      ins_ptr <= idx;
    end // else: !if(~reset_n)


  always_comb
    begin
      bit [DEPTHLOG2-1:0] idx  = ext_ptr;

      for (integer i = 0; i < EXT_COUNT; i++) begin
        out_elements[i] <= buffer[idx];
        idx             += 1;
      end
    end


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      ext_ptr <= 'b0;
    else begin
      ext_ptr <= ext_ptr + ext_consumed;
    end


  assign used_count = (ins_ptr - ext_ptr);
  assign empty      = (ext_ptr == ins_ptr);
  assign full       = (used_count == DEPTH-1-INS_COUNT);
endmodule // circbuf
