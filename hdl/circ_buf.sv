module circbuf #(
  parameter type T     = integer,
  parameter      DEPTH     = 16,
                 INS_COUNT = 2,
                 EXT_COUNT = 2,
                 DEPTHLOG2 = $clog2(DEPTH),
                 EXTCOUNTLOG2  = $clog2(EXT_COUNT),
                 INSCOUNTLOG2  = $clog2(INS_COUNT)
)(
  input                    clock,
  input                    reset_n,

  input                    ins_enable,
  input [INSCOUNTLOG2-1:0] new_count,
  input                    T new_elements[INS_COUNT],

  input                    ext_enable,
  input [EXTCOUNTLOG2-1:0] ext_consumed,
  output reg               ext_valid[EXT_COUNT],
  output                   T out_elements[EXT_COUNT],

  output                   full,
  output                   empty,
  output [DEPTHLOG2-1:0]   used_count
);

  wire                     ins_enable_i;
  wire                     ext_enable_i;
  wire [EXTCOUNTLOG2-1:0]  ext_consumed_i;


  reg [DEPTHLOG2-1:0]      ext_ptr;
  reg [DEPTHLOG2-1:0]      ins_ptr;

  T buffer[DEPTH];
  bit valid[DEPTH];

  assign ins_enable_i    = ins_enable & ~full;
  assign ext_enable_i    = ext_enable & ~empty;
  assign ext_consumed_i  = (ext_consumed >= used_count) ? (used_count-1) : ext_consumed;


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      ins_ptr <= 'b0;
    else if (ins_enable_i) begin
      automatic bit [DEPTHLOG2-1:0] idx  = ins_ptr;

      for (integer i = 0; i <= new_count; i++) begin
        buffer[idx] <= new_elements[i];
        idx         += 1;
      end

      ins_ptr <= idx;
    end // else: !if(~reset_n)


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      for (integer i = 0; i < DEPTH; i++)
        valid[i] <= 1'b0;
    else begin
      automatic bit [DEPTHLOG2-1:0] idx;

      if (ins_enable_i) begin
        idx  = ins_ptr;
        for (integer i = 0; i <= new_count; i++) begin
          valid[idx] <= 1'b1;
          idx        += 1;
        end
      end

      if (ext_enable_i) begin
        idx  = ext_ptr;
        for (integer i = 0; i <= ext_consumed_i; i++) begin
          valid[idx] <= 1'b0;
          idx        += 1;
        end
      end
    end



  always_comb
    begin
      automatic bit [DEPTHLOG2-1:0] idx  = ext_ptr;

      for (integer i = 0; i < EXT_COUNT; i++) begin
        out_elements[i] = buffer[idx];
        ext_valid[i]    = valid[idx];
        idx             += 1;
      end
    end


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      ext_ptr <= 'b0;
    else if (ext_enable_i) begin
      ext_ptr <= ext_ptr + ext_consumed_i + 1;
    end


  assign used_count = (ins_ptr - ext_ptr);
  assign empty      = (ext_ptr == ins_ptr);
  assign full       = (used_count >= DEPTH-INS_COUNT);
endmodule // circbuf
