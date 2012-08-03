module rob #(
  parameter type T     = rob_entry_t,
  parameter      DEPTH     = 16,
                 INS_COUNT = 2,
                 EXT_COUNT = 2,
                 REG_COUNT = 32,
                 DEPTHLOG2 = $clog2(DEPTH),
                 EXTCOUNTLOG2  = $clog2(EXT_COUNT),
                 INSCOUNTLOG2  = $clog2(INS_COUNT)
)(
  input                      clock,
  input                      reset_n,

  // Reservation interface
  input                      reserve,
  input [INSCOUNTLOG2-1:0]   reserve_count,
  output reg [DEPTHLOG2-1:0] reserved_slots[INS_COUNT],
  output                     full,

  // Forwarding and forward querying interface (hand in hand with reserv. interface)
  input [4:0]                dest_reg[INS_COUNT],
  input                      dest_reg_valid[INS_COUNT],

  input [4:0]                A_reg[INS_COUNT],
  input [4:0]                B_reg[INS_COUNT],
  output                     fwd_info_t fwd_info[INS_COUNT],

  input [DEPTHLOG2-1:0]      A_rob_idx[INS_COUNT],
  input [DEPTHLOG2-1:0]      B_rob_idx[INS_COUNT],
  output [31:0]              A_val[INS_COUNT],
  output [31:0]              B_val[INS_COUNT],

  // Store interface
  input [DEPTHLOG2-1:0]      write_slot[INS_COUNT],
  input                      write_valid[INS_COUNT],
  input                      T write_data[INS_COUNT],

  // Retrieve interface
  input                      consume,
  input [EXTCOUNTLOG2-1:0]   consume_count,
  output                     T slot_data[EXT_COUNT],
  output reg                 slot_valid[EXT_COUNT],
  output                     empty,

  output reg [DEPTHLOG2:0]   used_count
);

  wire                     reserve_i;
  wire                     consume_i;
  wire [EXTCOUNTLOG2-1:0]  consume_count_i;

  reg [DEPTHLOG2-1:0]      ext_ptr;
  reg [DEPTHLOG2-1:0]      ins_ptr;

  T buffer[DEPTH];
  bit valid[DEPTH];
  bit in_transit[DEPTH];
  rob_reg_info_t reg_info[REG_COUNT];



  // Overflow and underflow protected signals
  assign reserve_i        = reserve & ~full;
  assign consume_i        = consume & ~empty;
  assign consume_count_i  = (consume_count >= used_count-1) ? (used_count-1) : consume_count;



  genvar i;
  generate
    for (i = 0; i < INS_COUNT; i++) begin
      assign A_val[i]  = buffer[A_rob_idx].result_lo;
      assign B_val[i]  = buffer[B_rob_idx].result_lo;
    end
  endgenerate



  // Reservation interface
  always_comb begin
    for (integer i = 0; i < INS_COUNT; i++)
      reserved_slots[i]  = ins_ptr + i;
  end

  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      ins_ptr <= 'b0;
    else if (reserve_i)
      ins_ptr <= ins_ptr + reserve_count + 1;


  // Common
  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      ;
    else
      for (integer i = 0; i < INS_COUNT; i++) begin
        if (reserve_i) begin
          valid[ins_ptr + i]      <= 1'b0;
          in_transit[ins_ptr + i] <= 1'b0;
        end
        if (write_valid[i])
          valid[write_slot[i]] <= 1'b1;
      end


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      reg_info[0].rfile <= 1'b1; // $0 is always valid in reg file
    else begin
      if (consume_i) begin
        for (integer i = 0; i <= consume_count_i; i++) begin
          if (buffer[i].dest_reg_valid)
            reg_info[buffer[i].dest_reg] <= 1'b1;
        end
      end

      if (reserve_i) begin
        for (integer i = 0; i < INS_COUNT; i++) begin
          if (dest_reg_valid[i]) begin
            reg_info[dest_reg[i]].rfile   <= 1'b0;
            reg_info[dest_reg[i]].rob_idx <= ins_ptr + i;
          end
        end
      end
    end


  always_comb begin
    for (integer i = 0; i < INS_COUNT; i++) begin
      fwd_info[i].A_fwd_from_rfile  = reg_info[A_reg[i]].rfile;
      fwd_info[i].A_fwd_rob_idx     = reg_info[A_reg[i]].rob_idx;
      fwd_info[i].B_fwd_from_rfile  = reg_info[B_reg[i]].rfile;
      fwd_info[i].B_fwd_rob_idx     = reg_info[B_reg[i]].rob_idx;

      for (integer k = 0; k < i; k++) begin
        if (dest_reg_valid[k] && (dest_reg[k] == A_reg[i])) begin
          fwd_info[i].A_fwd_from_rfile  = 1'b0;
          fwd_info[i].A_fwd_rob_idx     = reserved_slots[k];
        end
        if (dest_reg_valid[k] && (dest_reg[k] == B_reg[i])) begin
          fwd_info[i].B_fwd_from_rfile  = 1'b0;
          fwd_info[i].B_fwd_rob_idx     = reserved_slots[k];
        end
      end
    end
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
    else if (consume_i)
      ext_ptr <= ext_ptr + consume_count_i + 1;

  always_comb
    begin
      for (integer i = 0; i < INS_COUNT; i++) begin
        slot_data[i]   = buffer[ext_ptr + i];
        slot_valid[i]  = valid[ext_ptr + i];
      end
    end


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      used_count <= 0;
    else
      used_count <=  used_count
                   + ((reserve_count   + 1) & {(INSCOUNTLOG2+1){reserve_i}})
                   - ((consume_count_i + 1) & {(EXTCOUNTLOG2+1){consume_i}});


  assign empty      = (used_count == 0);
  assign full       = (used_count > DEPTH-INS_COUNT);
endmodule
