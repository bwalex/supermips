import pipTypes::*;

module circ_buf #(
  parameter type T     = iq_entry_t,
  parameter      DEPTH     = 16,
                 INS_COUNT = 4,
                 EXT_COUNT = 4
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

  input                    flush,

  output                   full,
  output                   empty,
  output reg [DEPTHLOG2:0] used_count
);
  localparam DEPTHLOG2  = $clog2(DEPTH);
  localparam EXTCOUNTLOG2  = $clog2(EXT_COUNT);
  localparam INSCOUNTLOG2  = $clog2(INS_COUNT);

  wire                     ins_enable_i;
  wire                     ext_enable_i;
  wire [EXTCOUNTLOG2-1:0]  ext_consumed_i;


  T buffer[$];

  assign ins_enable_i    = ins_enable & ~full;
  assign ext_enable_i    = ext_enable & ~empty;
  assign ext_consumed_i  = (ext_consumed >= used_count-1) ? (used_count-1) : ext_consumed;


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      buffer <= { };
    else begin
      if (ext_enable_i)
        for (integer i = 0; i <= ext_consumed_i; i++) begin
          automatic iq_entry_t e = buffer.pop_front();
`ifdef IQ_TRACE_ENABLE
          $fwrite(trace_file, "%d IQ: extract from slot %d, pc=%x, iw=%x, rob_slot=%d\n",
                  $time, i, e.dec_inst.pc, e.dec_inst.inst_word, e.rob_slot);
`endif
        end

      if (ins_enable_i)
        for (integer i = 0; i <= new_count; i++) begin
          buffer.push_back(new_elements[i]);
`ifdef IQ_TRACE_ENABLE
          $fwrite(trace_file, "%d IQ: insert at slot %d, pc=%x, iw=%x, rob_slot=%d\n",
                  $time,
                  buffer.size()-1, new_elements[i].dec_inst.pc, new_elements[i].dec_inst.inst_word,
                  new_elements[i].rob_slot);
`endif
        end

      if (flush) begin
`ifdef IQ_TRACE_ENABLE
        $fwrite(trace_file, "%d IQ: flush %d instructions\n", $time, buffer.size());
`endif
        buffer  = {};
      end
    end


  always_comb begin
    for (integer i = 0; i < buffer.size(); i++) begin
      out_elements[i]  = buffer[i];
      ext_valid[i]     = 1'b1;
    end
    for (integer i = buffer.size(); i < EXT_COUNT; i++) begin
      ext_valid[i]     = 1'b0;
    end
  end

  always_comb
    used_count  = buffer.size();

  assign empty      = (used_count == 0);
  assign full       = (used_count > DEPTH-INS_COUNT);



`ifdef IQ_TRACE_ENABLE
  integer trace_file;

  initial begin
    trace_file  = $fopen("iq.trace", "w");
  end

  always_ff @(posedge clock) begin
    $fwrite(trace_file, "%d IQ: used_count: %d, empty: %b, full: %b\n",
            $time, used_count, empty, full);
  end
`endif


endmodule // circbuf
