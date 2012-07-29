module shifter #(
  parameter DATA_WIDTH  = 32,
            SHAMT_WIDTH = 5
)(
  input      [ DATA_WIDTH-1:0] in,
  input      [SHAMT_WIDTH-1:0] shamt,
  input                        shleft,
  input                        sharith,
  output reg [ DATA_WIDTH-1:0] out
);

  always_comb begin
    if (shleft)
      if (sharith)
        out  = in <<< shamt;
      else
        out  = in <<  shamt;
    else
      if (sharith)
        out  = in >>> shamt;
      else
        out  = in >>  shamt;
  end
endmodule
