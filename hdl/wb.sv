import pipTypes::*;

module wb #(
            parameter RETIRE_COUNT = 4,
                      COUNT_WIDTH  = $clog2(RETIRE_COUNT)
)(
  input                        clock,
  input                        reset_n,

  output                       consume,
  output reg [COUNT_WIDTH-1:0] consume_count,
  input                        rob_entry_t slot_data[RETIRE_COUNT],
  input                        slot_valid[RETIRE_COUNT],
  input                        empty,

  output [ 4:0]                rfile_wr_addr[RETIRE_COUNT],
  output                       rfile_wr_enable[RETIRE_COUNT],
  output [31:0]                rfile_wr_data[RETIRE_COUNT]
);

  wire   [RETIRE_COUNT-1:0] in_order;

  genvar        i, j;
  generate
    for (i = 1; i < RETIRE_COUNT; i++)
      assign in_order[i]  = slot_valid[i-1] & in_order[i-1];
  endgenerate

  assign in_order[0] = 1'b1;


  genvar        i;
  generate
    for (i = 0; i < RETIRE_COUNT; i++) begin
      assign rfile_wr_addr[i]    = slot_data[i].dest_reg;
      assign rfile_wr_enable[i]  = slot_data[i].dest_reg_valid & slot_valid[i] & in_order[i];
      assign rfile_wr_data[i]    = slot_data[i].result_lo;
    end
  endgenerate

  assign consume  = slot_valid[0];
  always_comb begin
    automatic bit [COUNT_WIDTH-1:0] c = 'b0;
    for (i = 1; i < RETIRE_COUNT; i++)
      if (slot_valid[i])
        c += 1;
      else
        break;

    consume_count  = c;
  end

endmodule
