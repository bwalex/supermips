module trickbox #(
  parameter ADDR_WIDTH = 32,
            TIME_PORT  = 32'hAAAA0000,
            PUTC_PORT  = 32'hAAAA0008,
            ITER_PORT  = 32'hAAAA000C,
            TIME_SCALE_FACTOR = 10,
            ITERATIONS = 32'd100
)(
  input                  clock,
  input                  reset_n,

  input [ADDR_WIDTH-1:0] addr,
  input                  read,
  input                  write,
  input [31:0]           data_in,
  output reg [31:0]      data_out,
  output reg             taken
);

  reg [63:0]             cycle_count;
  string                 strbuf;
  integer                char_count;

  byte                   character;
  reg                    flush_char;
  reg                    append_char;


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      cycle_count <= 64'b0;
    else
      cycle_count <= cycle_count + 1;

  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n) begin
      char_count <= 0;
      strbuf      = "";
    end
    else if (append_char) begin
      char_count <= char_count + 1;
      strbuf = { strbuf, " " };
      strbuf.putc(char_count, character);
    end
    else if (flush_char) begin
      char_count <= 0;
      while (strbuf[strbuf.len()-1] == "\n")
        strbuf = strbuf.substr(0,strbuf.len()-2);
      $display("%d: trickbox: %s", $time, strbuf);
      strbuf      = "";
    end


  always_comb begin
    data_out     = 32'b0;
    taken        = 1'b0;
    flush_char   = 1'b0;
    append_char  = 1'b0;
    character    = data_in[7:0];

    if (read) begin
      case (addr)
        TIME_PORT: begin
          taken     = 1'b1;
          data_out  = cycle_count/TIME_SCALE_FACTOR;
        end

        ITER_PORT: begin
          taken     = 1'b1;
          data_out  = ITERATIONS;
        end
      endcase
    end
    else if (write) begin
      case (addr)
        PUTC_PORT: begin
          taken  = 1'b1;
          if (data_in[7:0] == 8'b0)
            flush_char   = 1'b1;
          else begin
            append_char  = 1'b1;
          end
        end
      endcase
    end
  end
endmodule
