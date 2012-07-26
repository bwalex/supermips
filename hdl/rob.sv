module rob #(
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

  // Reservation interface
  input                    reserve,
  input [INSCOUNTLOG2-1:0] reserve_count,
  output [DEPTHLOG2-1:0]   reserved_slots[INS_COUNT],
  output                   full,

  // Store interface
  input [DEPTHLOG2-1:0]    write_slot[INS_COUNT],
  input                    write_valid[INS_COUNT],
  input                    T write_data[INS_COUNT],

  // Retrieve interface
  input [EXTCOUNTLOG2-1:0] consume_count,
  output                   T slot_data[EXT_COUNT],
  output                   slot_valid[EXT_COUNT],
  output                   empty,

  output [DEPTHLOG2-1:0]   used_count
);

  // Reservation interface
  always_comb begin
    for (integer i = 0; i < INS_COUNT; i++)
      reserved_slots[i]  = ins_ptr + i;
  end

  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      ins_ptr <= 'b0;
    else if (reserve)
      ins_ptr <= ins_ptr + reserve_count;


  // Common
  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      ;
    else
      for (integer i = 0; i < INS_COUNT; i++) begin
        if (reserve)
          valid[ins_ptr + i]   <= 1'b0;
        if (write_valid[i])
          valid[write_slot[i]] <= 1'b1;
      end


  // Store interface
  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      ;
    else
      for (integer i = 0; i < INS_COUNT; i++)
        if (write_valid[i])
          buffer[write_slot[i]] <= write_data[i];



  // Consume interface
  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      ext_ptr <= 'b0;
    else
      ext_ptr <= ext_ptr + (consume_count <= used_count) ? consume_count : used_count;

  always_comb
    begin
      for (integer i = 0; i < INS_COUNT; i++) begin
        slot_data[i]   = buffer[ext_ptr + i];
        slot_valid[i]  = valid[ex_ptr + i];
      end
    end


  assign used_count = (ins_ptr - ext_ptr);
  assign empty      = (ext_ptr == ins_ptr);
  assign full       = (used_count == DEPTH-1-INS_COUNT);
endmodule
