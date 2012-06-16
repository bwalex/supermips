module rfile #(
  parameter NREGS      = 32,
            ADDR_WIDTH = 5,
            DATA_WIDTH = 32
)(
  input                   clock,
  input                   reset_n,

  input [ADDR_WIDTH-1:0]  rd_addr1,
  input [ADDR_WIDTH-1:0]  rd_addr2,
  input [ADDR_WIDTH-1:0]  wr_addr1,

  input                   wr_enable1,
  input [DATA_WIDTH-1:0]  wr_data1,

  output [DATA_WIDTH-1:0] rd_data1,
  output [DATA_WIDTH-1:0] rd_data2
);

  reg [DATA_WIDTH-1:0]    regfile[NREGS];


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      for (int i = 0; i < NREGS; i++)
        regfile[i] <= 'b0;
    else begin
      if (wr_enable1)
        regfile[wr_addr1] <= wr_data1;
      // Logic for more write ports goes here
    end


  assign rd_data1  = regfile[rd_addr1];
  assign rd_data2  = regfile[rd_addr2];

endmodule