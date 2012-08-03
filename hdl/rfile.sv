module rfile #(
  parameter NREGS      = 32,
            ADDR_WIDTH = 5,
            DATA_WIDTH = 32,
            READ_PORTS = 4,
            WRITE_PORTS = 4
)(
  input                    clock,
  input                    reset_n,

  input  [ADDR_WIDTH-1:0]  rd_addr[READ_PORTS],
  output [DATA_WIDTH_1:0]  rd_data[READ_PORTS],

  input  [ADDR_WIDTH-1:0]  wr_addr[WRITE_PORTS],
  input                    wr_enable[WRITE_PORTS],
  input  [DATA_WIDTH-1:0]  wr_data[WRITE_PORTS]
);

  reg [DATA_WIDTH-1:0]    regfile[NREGS];


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      for (int i = 0; i < NREGS; i++)
        regfile[i] <= 'b0;
    else begin
      for (int i = 0; i < WRITE_PORTS; i++)
        if (wr_enable[i])
          regfile[wr_addr[i]] <= wr_data[i];
  end

  genvar i;
  generate
    for (i = 0; i < READ_PORTS; i++)
      assign rd_data[i]  = regfile[rd_addr[i]];
  endgenerate

endmodule