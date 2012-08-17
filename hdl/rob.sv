import pipTypes::*;

module rob #(
  parameter type T     = rob_entry_t,
  parameter      DEPTH     = 16,
                 INS_COUNT = 4,
                 EXT_COUNT = 4,
                 AS_COUNT  = 4,
                 WR_COUNT  = 4,
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
  input [4:0]                dest_reg[INS_COUNT],
  input                      dest_reg_valid[INS_COUNT],
  input dec_inst_t           instructions[INS_COUNT],

  // Associate lookup interface
  input [DEPTHLOG2-1:0]      as_query_idx[AS_COUNT],
  input [4:0]                as_areg[AS_COUNT],
  input [4:0]                as_breg[AS_COUNT],
  output reg [31:0]          as_aval[AS_COUNT],
  output reg [31:0]          as_bval[AS_COUNT],
  output reg                 as_aval_valid[AS_COUNT],
  output reg                 as_bval_valid[AS_COUNT],
  output reg                 as_aval_present[AS_COUNT],
  output reg                 as_bval_present[AS_COUNT],

  // Store interface
  input [DEPTHLOG2-1:0]      write_slot[WR_COUNT],
  input                      write_valid[WR_COUNT],
  input                      T write_data[WR_COUNT],

  // Retrieve interface
  input                      consume,
  input [EXTCOUNTLOG2-1:0]   consume_count,
  output                     T slot_data[EXT_COUNT],
  output reg                 slot_valid[EXT_COUNT],
  output                     empty,

  // Flush interface
  input                      flush,
  input [DEPTHLOG2-1:0]      flush_idx,

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

  // XXX: temporary
  dec_inst_t insns[DEPTH];



  // Overflow and underflow protected signals
  assign reserve_i        = reserve & ~full;
  assign consume_i        = consume & ~empty;
  assign consume_count_i  = (consume_count >= used_count-1) ? (used_count-1) : consume_count;




  // High-level associative lookup interface
  always_comb begin
    automatic bit [DEPTHLOG2-1:0] k;
    for (integer i = 0; i < AS_COUNT; i++) begin
      as_aval_valid[i]    = 1'b0;
      as_aval_present[i]  = 1'b0;
      as_aval[i]          = 32'b0;

      $display("AS query_idx: %d", as_query_idx[i]);
      if (as_query_idx[i] != ext_ptr) begin
        for (k = as_query_idx[i]-1; k >= ext_ptr; k--) begin
	  $display("k: %d", k);
          if (buffer[k].dest_reg == as_areg[i] && buffer[k].dest_reg_valid) begin
            as_aval[i]          = buffer[k].result_lo;
            as_aval_valid[i]    = valid[k];
            as_aval_present[i]  = 1'b1;
            break;
          end
          if (k == 0 && ext_ptr == 0)
            break;
        end
      end
    end
  end // always_comb

  always_comb begin
    automatic bit [DEPTHLOG2-1:0] k;
    for (integer i = 0; i < AS_COUNT; i++) begin
      as_bval_valid[i]    = 1'b0;
      as_bval_present[i]  = 1'b0;
      as_bval[i]          = 32'b0;

      if (as_query_idx[i] != ext_ptr) begin
        for (k = as_query_idx[i]-1; k >= ext_ptr; k--) begin
	  $display("k: %d", k);
          if (buffer[k].dest_reg == as_breg[i] && buffer[k].dest_reg_valid) begin
            as_bval[i]          = buffer[k].result_lo;
            as_bval_valid[i]    = valid[k];
            as_bval_present[i]  = 1'b1;
            break;
          end
          if (k == 0 && ext_ptr == 0)
            break;
        end
      end
    end
  end // always_comb


  // Reservation interface
  always_comb begin
    for (integer i = 0; i < INS_COUNT; i++)
      reserved_slots[i]  = ins_ptr + i;
  end

  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      ins_ptr <= 'b0;
    else if (flush)
      ins_ptr <= flush_idx + 2; // leave the branch and BDS in place; idx is the branch
    else if (reserve_i)
      ins_ptr <= ins_ptr + reserve_count + 1;


  // Common
  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      ;
    else begin
      for (integer i = 0; i < INS_COUNT; i++) begin
        if (reserve_i) begin
          valid[ins_ptr + i]      <= 1'b0;
          in_transit[ins_ptr + i] <= 1'b0;
        end
      end
      for (integer i = 0; i < WR_COUNT; i++)
        if (write_valid[i])
          valid[write_slot[i]] <= 1'b1;
    end


  // Store interface
  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      ;
    else begin
      for (integer i = 0; i <= reserve_count; i++) begin
        buffer[reserved_slots[i]].dest_reg        <= dest_reg[i];
        buffer[reserved_slots[i]].dest_reg_valid  <= dest_reg_valid[i];
      end
      for (integer i = 0; i < WR_COUNT; i++)
        if (write_valid[i])
          buffer[write_slot[i]] <= write_data[i];
    end


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
    else if (flush)
      used_count <=  used_count
                   - (ins_ptr - flush_idx - 1)
                   - ((consume_count_i + 1) & {(EXTCOUNTLOG2+1){consume_i}});
    else
      used_count <=  used_count
                   + ((reserve_count   + 1) & {(INSCOUNTLOG2+1){reserve_i}})
                   - ((consume_count_i + 1) & {(EXTCOUNTLOG2+1){consume_i}});


  assign empty      = (used_count == 0);
  assign full       = (used_count > DEPTH-INS_COUNT);



`ifdef ROB_TRACE_ENABLE
  integer trace_file;

  initial begin
    trace_file  = $fopen("rob.trace", "w");
  end

  always_ff @(posedge clock) begin
    for (integer i = 0; i <= reserve_count; i++) begin
      insns[reserved_slots[i]] <= instructions[i];
    end
  end


  always_ff @(posedge clock) begin
    if (reserve) begin
      for (integer i = 0; i <= reserve_count; i++)
        $fwrite(trace_file, "ROB: Reserve slot %d for pc=%x (dest_reg=%d [valid=%b])\n",
                 reserved_slots[i], instructions[i].pc, dest_reg[i],
                 dest_reg_valid[i]);
    end
    for (integer i = 0; i < WR_COUNT; i++) begin
      if (write_valid[i])
        $fwrite(trace_file, "ROB: Write slot %d, pc=%x, data=%x, dest_reg=%d, dest_reg_valid=%b\n",
                 write_slot[i], insns[write_slot[i]].pc, write_data[i].result_lo,
                 write_data[i].dest_reg, write_data[i].dest_reg_valid);
    end
    if (consume) begin
      for (integer i = 0; i <= consume_count; i++)
        $fwrite(trace_file, "ROB: Consume slot %d, pc=%x, data=%x, dest_reg=%d, dest_reg_valid=%b\n",
                 ext_ptr + i, insns[ext_ptr+i].pc, buffer[ext_ptr+i].result_lo,
                 buffer[ext_ptr+i].dest_reg, buffer[ext_ptr+i].dest_reg_valid);
    end

    $fwrite(trace_file, "ROB: ins_ptr: %d, ext_ptr: %d, used_count: %d, empty: %b, full: %b\n",
            ins_ptr, ext_ptr, used_count, empty, full);

  end
`endif


endmodule
