`timescale 1ns/10ps

module lfsr_tb;
  parameter LFSR_SEED  = 11'd101;
  parameter LFSR_BITS  = 11;
  parameter RAND_BITS  = 2;

  reg [LFSR_BITS-1:0]         lfsr;
  wire [RAND_BITS-1:0]        rand_bits;


  logic                       clock;
  logic                       reset_n;

  integer                     rand_vals[(1<<RAND_BITS)];
  integer                     lfsr_vals[(1<<LFSR_BITS)];


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      lfsr     <= LFSR_SEED;
    else begin
      lfsr[0]  <= lfsr[2];
      lfsr[1]  <= lfsr[3];
      lfsr[2]  <= lfsr[4];
      lfsr[3]  <= lfsr[5];
      lfsr[4]  <= lfsr[6];
      lfsr[5]  <= lfsr[7];
      lfsr[6]  <= lfsr[8];
      lfsr[7]  <= lfsr[9];
      lfsr[8]  <= lfsr[10];
      lfsr[9]  <= lfsr[0]  ^ lfsr[2];
      lfsr[10] <= lfsr[1]  ^ lfsr[3];
    end

  assign rand_bits  = lfsr[RAND_BITS-1:0];


    // 100 MHz clock
  always
  begin
         clock = 0;
    #5   clock = 1;
    #5   clock = 0;
  end

  initial begin
    reset_n      = 1;
    #5  reset_n  = 0;
    #16 reset_n  = 1;
    @(posedge clock);

    for (integer i = 0; i < (1 << RAND_BITS); i++)
      rand_vals[i]  = 0;

    for (integer i = 0; i < (1 << LFSR_BITS); i++)
      lfsr_vals[i] = 0;

    for (integer i = 0; i < (1 << LFSR_BITS) -1; i++) begin
      rand_vals[rand_bits] += 1;
      lfsr_vals[lfsr]      += 1;
      @(posedge clock);
    end

    $display("Random value occurence:");
    for (integer i = 0; i < (1 << RAND_BITS); i++)
      $display("%b: %d times", i[RAND_BITS-1:0], rand_vals[i]);

    assert(lfsr_vals[0] == 0);

    for (integer i = 1; i < (1 << LFSR_BITS); i++) begin
      assert(lfsr_vals[i] == 1);
`ifdef TRACE_ENABLE
      if (lfsr_vals[i] != 1)
        $display("Sequence %b occured %d times (expected: 1)", i[LFSR_BITS-1:0], lfsr_vals[i]);
`endif
    end

    $finish();
  end

endmodule
